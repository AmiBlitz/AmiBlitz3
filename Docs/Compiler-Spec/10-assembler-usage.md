# 10 Nutzung von Inline-Assembler in den vorhandenen Quellen

Dieses Kapitel fasst zusammen, **wie** AmiBlitz-Quelltexte Assembler
verwenden. Es dient als Grundlage für die Entscheidung, wie ein neuer
Compiler Inline-Asm unterstützen muss (eigenes 68k-Backend, C-Backend mit
gcc/vbcc, Thunks).

Werkzeug: `verification/tools/asm_usage.py`. Es tokenisiert jede Datei nach
[03-tokenizer.md](03-tokenizer.md), zerlegt sie in Anweisungen und ordnet jede
Assembler-Anweisung einem Kontext zu. Als Assembler zählen die 68k-Mnemonics
(Token `$803C`–`$80B2`), die FPU-/PPC-Befehle aus Lib 217/218, `Dc`, `Ds`,
`Dcb`, `Even`, `Even4`, `AsmExit`. „Brücken-Befehle“ sind `GetReg`, `PutReg`,
`GetD0`, `PutD0`, `GetRegD0`, `PutRegD0`.

## 10.1 Formen der Assembler-Nutzung

| Form | Beschreibung | Quelle |
|---|---|---|
| **Inline im Basic-Code** | 68k-Befehle stehen direkt zwischen Basic-Anweisungen. Zugriff auf Variablen über `GetReg`/`PutReg` oder direkt als Offset (`MOVE.l var@(a5),d0` global, `var(a4)` lokal). | BPG „GetReg & PutReg“, AB3G „compiler changes“ |
| **Prozedur in Assembler** | Rumpf eines `Statement`/`Function` in Assembler; Parameter in d0–d5, Rückgabe in d0, Verlassen mit `AsmExit`. a4–a6 müssen beim Verlassen wiederhergestellt sein. | BPG „Using assembler with procedures“ |
| **Assembler in Macros** | Macro-Rümpfe mit Assembler, oft als Wrapper (siehe 10.3). | – |
| **Plugin-Programm** (`!initasm`, `!basic`, `!asm`) | Das Programm ist im Kern Assembler und wechselt für einzelne Abschnitte in Basic. `!basic` sichert die Assembler-Register (d1–d7/a0–a6) unterhalb des Stacks und lädt a5/a4 für Basic; `!asm` stellt sie wieder her. Definiert in `usefullasmmacs.ab3`. | Compiler, PED |
| **BlitzLib-Quelltexte** | Reine Assembler-Programme mit `!libheader` usw. | [09-blitzlibs.md](09-blitzlibs.md) |

`!asm`/`!basic` ist damit **keine** Klammer um Assembler-Code in einem
Basic-Programm, sondern umgekehrt die Klammer um **Basic**-Abschnitte in einem
Assembler-Programm. Gewöhnlicher Inline-Assembler braucht keine Klammer.

## 10.2 Zahlen

Anzahl der **Anweisungen** (nicht Zeilen), Stand Commit `6efd21ef`:

| Bereich | Dateien | mit Asm | Asm im Basic-Fluss | Asm in Prozeduren | Asm in Macros | Asm im Plugin-Modus | Brücken-Befehle | `!asm`/`!basic` |
|---|---|---|---|---|---|---|---|---|
| `Sourcecodes/Includes` | 570 | 125 | 5 711 | 3 126 | 4 926 | 0 | 11 499 | 2 |
| `Sourcecodes/Examples` | 221 | 37 | 464 | 577 | 88 | 0 | 16 | 2 |
| Compiler | 4 | 4 | 17 675¹ | 35 | 162 | 651¹ | 62 | 226 |
| PED | 4 | 3 | 609 | 13 | 3 | 38 | 27 | 49 |
| `Shared` | 3 | 2 | 175 | 0 | 62 | 0 | 21 | 0 |
| Debugger | 4 | 4 | 691 | 39 | 5 | 0 | 34 | 0 |
| `Tools` | 15 | 5 | 18 | 55 | 0 | 0 | 0 | 0 |
| `Tests` | 69 | 26 | 373 | 0 | 1 | 0 | 13 | 0 |
| Resident-Quellen | 22 | 5 | 1 | 0 | 359 | 0 | 5 | 0 |
| BlitzLib-Quellen | 132 | 132 | 56 806 | 0 | 2 417 | 0 | 0 | 0 |

¹ Compiler und PED sind Plugin-Programme. Ob eine Assembler-Routine im
Plugin- oder im Basic-Modus läuft, hängt vom Kontrollfluss ab (z. B.
`!asm : RTS` als früher Rücksprung aus einem Basic-`If`); die statische
Zuordnung ist dort nur grob. Zusammen sind es rund 18 300 Assembler-Anweisungen.

Beobachtungen:

* Ohne Compiler, PED und BlitzLib-Quellen enthält gut **ein Fünftel** der
  Anwenderquellen (Includes, Beispiele, Tools, Tests: 193 von 875 Dateien)
  Assembler.
* In den Includes steht Assembler zu ungefähr gleichen Teilen direkt im
  Basic-Fluss, in Prozeduren und in Macros.
* Die meisten Brücken-Befehle (≈ 11 500) stammen aus generierten
  Wrapper-Macros für Betriebssystem-Libraries (10.3).
* `!asm`/`!basic` kommt außerhalb von Compiler und PED praktisch nicht vor
  (je ein `!initasm`-Plugin in Includes und Beispielen).

## 10.3 Wrapper-Macros für OS-Libraries

Die größten Includes (`amissl.include.ab3`, `agl.include.ab3`,
`sdl.include.ab3` …) sind von FD2Include erzeugt und bestehen fast nur aus
Macros dieser Form:

```
Macro amisslmaster_OpenAmiSSLCipher;{ret.l,last}
!__AmiSSLBase_SaveRegs                      ; MOVE.l a4/a5/a6/d7 auf den Stack
GetReg d0,`2                                ; Argumente in Register
GetReg a6,*_AmiSSLMasterBase                ; Library-Basis nach a6
JSR _LVO_AMISSLMASTERBASE_OpenAmiSSLCipher(a6)
!__AmiSSLBase_RestoreRegs
`1 = PutRegD0                               ; Ergebnis aus d0
End Macro
```

`GetReg` wird dabei – anders als in der BPG beschrieben („only data
registers“) – auch mit Adressregistern benutzt. Für ein C-Backend sind diese
Macros der einfachste Fall: Sie entsprechen genau einem Library-Aufruf und
können durch einen direkten Aufruf über die NDK-Header (`proto/*.h`) ersetzt
werden, ohne jedes Assembler.

## 10.4 Auffälligkeiten

Geprüft wurde heuristisch auf zwei Fehlermuster:

1. **Basic-Anweisung in einem Assembler-Abschnitt** (zwischen `!asm` und dem
   nächsten `!basic`): **1 Fund**. `Compiler/AmiBlitz3.ab3` Z. 26912,
   `Clear_Residents_table`: Die per `JSR` aus Assembler aufgerufene Routine
   endet nach `!asm` mit dem Basic-Befehl `Return` statt `RTS`. Das
   funktioniert vermutlich, weil `Return` zu `RTS` übersetzt wird; mit
   eingeschaltetem Laufzeit-Debugger prüft `Return` aber den Gosub-Stack
   (`#chkret`). **Wahrscheinlich ein Bug.**
2. **a4/a5/a6 verändert und nicht wiederhergestellt** innerhalb eines
   zusammenhängenden Assembler-Blocks im Basic-Fluss oder in einer Prozedur:
   26 Kandidaten außerhalb der BlitzLib-Quellen. Stichprobe:
   * `MOVE.l …globalbase,a5` am Anfang von Funktionen, die als eigener
     Task/Thread laufen (`Examples/…/Thread_Demo.ab3`, `Includes/NTUI/filelistener.ab3`,
     `Includes/NTUI/runasync.ab3`): **gewollt** – der neue Kontext muss a5
     erst setzen.
   * `EXG d0,a5 … EXG d0,a5` (`darts_wire.ab3`): **korrekt**, wird
     zurückgetauscht (die Heuristik erkennt das nicht).
   * `benchgfxbus.ab3`: a4 als Arbeitsregister im Hauptprogramm zwischen
     Basic-Anweisungen. Funktioniert, weil a4 außerhalb von Prozeduren nicht
     benutzt wird, ist aber **zerbrechlich** (bricht, sobald der Code in eine
     Prozedur wandert oder ein Compiler a4 anders nutzt).
   * In den BlitzLib-Quellen (109 Kandidaten) gelten andere Regeln; sie
     wurden nicht bewertet.

## 10.5 Folgerungen für einen Nachbau

* Inline-Assembler im Basic-Fluss und in Prozeduren ist **der Normalfall**,
  nicht die Ausnahme. Er greift über feste Register auf Basic-Variablen zu:
  a5 = globale Variablen, a4 = lokale Variablen, Parameter in d0–d5.
  Ein Backend muss diese Konvention für alle Funktionen mit Asm einhalten.
* Asm-Code verwendet Variablen als **Speicheradressen** (`var@(a5)`,
  `GetReg a0,&var`, `GetReg a6,*ptr`). Ein C-Backend muss für solche
  Variablen Zeiger (bzw. die Basisadresse des Variablenblocks) an den
  Assembler-Code übergeben können. Das geht mit beiden Compilern: bei gcc über
  Extended Asm oder Registervariablen, bei vbcc über Registerparameter
  (`__reg("a0")`, verwendet z. B. in `SDI_compiler.h`).
* Rein generierte Library-Wrapper (10.3) lassen sich ohne Assembler durch
  native Library-Aufrufe ersetzen.
* Plugin-Programme (`!initasm`/`!asm`/`!basic`) setzen ein Register- und
  Stack-Layout voraus, das sich in C nicht nachbilden lässt; sie betreffen
  praktisch nur Compiler und PED selbst und brauchen das 68k-Backend.
  Einzelheiten in 10.6.

## 10.6 Der Wechsel zwischen Assembler- und Basic-Modus

### 10.6.1 Es gibt keinen „Modus“ im Compiler

`!initasm`, `!basic`, `!asm` und `!exitasm` sind gewöhnliche Macros aus
`BlitzLibs/Residents/blitzbasic/usefullasmmacs.ab3` (in `all.res`). Der
Compiler kennt keinen Asm- oder Basic-Modus. Er übersetzt die Macros wie
jeden anderen Assembler-Code und die Basic-Anweisungen dazwischen wie immer.
**[C]**

„Modus“ ist ein **Laufzeitzustand**: welcher Registersatz gerade gültig ist –
der des Assembler-Programms oder der, den Basic-Code erwartet (a5 = globale
Variablen, a4 = lokale Variablen). Welcher Zustand an einer Stelle gilt, hängt
vom **Kontrollfluss** ab und lässt sich aus dem Quelltext im Allgemeinen nicht
ablesen. Beispiele aus dem Compiler-Quelltext:

```
.menu_run:                          ; Basic-Abschnitt in einer Asm-Routine
  !basic
  If PeekW(?anyerrs) <> 0
    log2PED{"…"}
    Pop If
    !asm                            ; früher Rücksprung: nur in diesem Zweig
    RTS                             ; wird in den Asm-Zustand gewechselt
  EndIf
  check_fpu_mode.b = …              ; hier gilt weiterhin Basic
```

```
.ab3_WriteDebugFile:
  TST.w word_WriteDebugFileNow : BEQ 'skipdebugfile
    !basic                          ; wird übersprungen, wenn das Flag 0 ist
    If dbg_fid>=0 … End If
    !asm
 'skipdebugfile                     ; beide Wege kommen im Asm-Zustand an
RTS
```

Die Analyse in 10.2 behandelt `!asm` gefolgt von `RTS`/`JMP`/`BRA` deshalb
als frühen Rücksprung; trotzdem ist die Zuordnung bei Compiler und PED nur
näherungsweise richtig.

### 10.6.2 Was die Macros tun

**[C]** `usefullasmmacs.ab3`

| Macro | Wirkung |
|---|---|
| `!initasm` | Steht am Programmanfang eines Plugins. Merkt sich a5 (Basis der globalen Variablen) in `basicvars`, einem `Dc.l` **mitten im Code**; holt die Register zurück, die der Startcode beim Aufruf gesichert hat (`MOVEM.l (a7)+,d0-d7/a0-a6 : LEA 12(a7),a7`), damit das Plugin die Register seines Aufrufers sieht. |
| `!basic` | Sichert d1–d7/a0–a6 des Assembler-Teils in einen Bereich am **unteren Ende des Task-Stacks** (`tc_SPLower + #__distance_from_top_of_stack`, = +64), lädt a4 aus diesem Bereich und a5 aus `basicvars`. d0 wird nicht gesichert. |
| `!asm` | Schreibt das aktuelle a4 in den Bereich zurück und lädt d1–d7/a0–a6 des Assembler-Teils. |
| `!exitasm` | Gegenstück zu `!initasm` vor dem Programmende. |

Layout des Sicherungsbereichs (relativ zu `tc_SPLower + 64`):

| Offset | Inhalt |
|---|---|
| +4 | a4 des Basic-Teils (lokale Variablen) |
| +8 … +$3F | d1–d7, a0–a6 des Assembler-Teils (a0 bei +$24) |

Folgen dieser Konstruktion:

* **Nicht verschachtelbar:** Es gibt genau einen Sicherungsbereich pro Task;
  ein zweites `!basic` vor dem passenden `!asm` überschreibt die gesicherten
  Register.
* **Nicht interruptfest** (so auch der Kommentar im Macro) und nicht für
  mehrere Tasks mit gemeinsamem Stack geeignet.
* **Stack-Reserve:** Die untersten 128 Byte des Task-Stacks dürfen nicht
  anderweitig benutzt werden; ein tiefer Stack überschreibt sonst die
  gesicherten Register (ohne Fehlermeldung).
* **Daten im Code:** `basicvars`, `localvars` und `asmregisters` liegen im
  Codebereich und werden zur Laufzeit beschrieben.
* **Gemischte Rücksprünge:** Assembler-Routinen werden teils mit dem
  Basic-Befehl `Return` verlassen (10.4, `Clear_Residents_table`), und
  Basic-Labels werden aus Assembler mit `JSR`/`BSR` angesprungen
  (`JSR Clear_Residents_table`, `BSR.w get1bytemain`).

### 10.6.3 Anforderungen an einen Nachbau

1. **Die Macros unverändert übersetzen können.** Da sie nur Assembler-Code
   sind, braucht der neue Compiler keine eigene Logik für den Moduswechsel –
   aber er muss alles unterstützen, was die Macros benutzen: Daten (`Dc`) im
   Codebereich, beschreibbaren Code, Labels im Code als Datenadressen, die
   Konstante `#__distance_from_top_of_stack`, die Startsequenz, deren
   gesicherte Register `!initasm` vom Stack holt (Aufbau und die zusätzlichen
   12 Byte müssen identisch bleiben).
2. **Assembler-Blöcke als Optimierungsgrenze.** Weil der Compiler nicht
   wissen kann, welcher Registersatz gilt und welche Variablen ein
   Assembler-Abschnitt liest oder schreibt, muss er Assembler als
   Optimierungsgrenze behandeln. Es genügt, das **pro Block** zu tun, nicht pro
   Anweisung:
   * **Asm-Block** = maximale Folge von Assembler-Anweisungen (einschließlich
     expandierter Macros wie `!asm`/`!basic` und der Brücken-Befehle
     `GetReg`/`PutReg`/`GetD0`/`PutD0`), zwischen denen keine Basic-Anweisung
     steht. Ein Block darf über mehrere Zeilen gehen.
   * Ein Block **endet** außerdem an jedem Label, das von außerhalb des
     Blocks angesprungen werden kann. Lokale Asm-Labels (`'loop`), die nur
     innerhalb des Blocks Ziel von Sprüngen sind, beenden ihn nicht; globale
     Labels (`.name`, `name:`) und Labels, die aus Basic (`Goto`/`Gosub`) oder
     aus anderen Blöcken angesprungen werden, schon. Ohne vollständige
     Referenzanalyse gilt: jedes globale Label beendet den Block.
   * **Vor** einem Block müssen alle Basic-Variablen, die Asm erreichen kann,
     im Speicher stehen; **danach** gelten sie als verändert und werden neu
     geladen. „Erreichbar“ sind globale Variablen, alle Variablen, deren
     Adresse genommen wurde (`&var`, `?label`, Übergabe als Zeiger), und alle
     lokalen Variablen der Prozedur (Asm adressiert sie über a4 mit
     beliebigem Offset). Lokale Variablen einer Prozedur **ohne** Asm-Block
     sind davon nicht betroffen.
   * Alle Register außer a4, a5, a7 gelten nach dem Block als verändert (Regel
     aus der BPG: a4–a6 müssen wiederhergestellt werden; a6 wird in der Praxis
     trotzdem oft verändert, siehe 10.3).
   * Innerhalb eines Blocks optimiert der Compiler nichts – der Assembler-Code
     wird unverändert übernommen.

   **Beliebige Zugriffe auf Basic-Variablen.** Die Grenze pro Block reicht
   auch dann, wenn der Assembler-Code „wild“ auf Variablen zugreift – über
   `var@(a5)`, beliebige Offsets zu a4, berechnete Zeiger oder Adressen, die
   vorher per `&var` geholt wurden. Innerhalb des Blocks läuft kein
   Basic-Code des Compilers; beim Eintritt stehen alle erreichbaren
   Variablen im Speicher, und nach dem Austritt lädt der Compiler sie neu.
   Was der Assembler-Code dazwischen mit dem Speicher macht, spielt für den
   Compiler keine Rolle. Reiner Assembler-Code muss deshalb **nicht** in
   mehrere Blöcke aufgeteilt werden.

   **Brücken-Befehle im Block.** `GetReg`/`PutReg` (und `GetD0`/`PutD0` …)
   sind die einzige Stelle, an der *innerhalb* eines Blocks Code des
   Compilers läuft. Der alte Compiler übersetzt sie **registertransparent**
   **[C]** (`do_GetReg`, `do_PutReg`, Z. 6485/6524):
   * `GetReg dN,ausdruck`: alle Register außer dN sichern
     (`MOVEM.l …,-(a7)`), Ausdruck auswerten, Ergebnis nach dN, Register
     wiederherstellen.
   * `PutReg dN,var`: d0–a6 sichern, Inhalt von dN in die Variable im
     **Speicher** schreiben, d0–a6 wiederherstellen.

   Ein Nachbau muss genau das einhalten: Der Ausdruck in `GetReg` liest
   Variablen aus dem Speicher (der Assembler-Code davor kann sie verändert
   haben), `PutReg` schreibt sofort in den Speicher (der Assembler-Code
   danach kann sie lesen), und beide verändern kein Register außer dem
   Ziel. Mit diesen Regeln bleibt der Block **ein** Block.

   **Aufteilen wäre in einem C-Backend sogar falsch:** Zwischen zwei
   getrennten `asm`-Anweisungen darf der C-Compiler Register frei benutzen.
   Ein Wert, den der Assembler-Code vor einem `GetReg` in d3 ablegt und danach
   weiterverwendet, ginge verloren. Der Block muss deshalb einschließlich der
   Brücken-Befehle als **eine** Einheit ausgegeben werden. Umsetzung:
   * Einfache Fälle (Variable, Konstante, `&var`) übersetzt der Compiler
     direkt in Assembler-Text (`MOVE.l var@(a5),d3`).
   * Komplexe Ausdrücke werden zu einer vom Compiler erzeugten Hilfsfunktion
     in C, die die Variablen über die Zeiger auf die Variablenblöcke liest;
     im Assembler-Text steht dann
     `MOVEM.l <Register>,-(a7) : JSR __ab3_getreg_n : MOVE.l d0,dN : MOVEM.l (a7)+,<Register>`.
     Das funktioniert mit gcc und vbcc gleichermaßen, weil die Hilfsfunktion
     eine gewöhnliche C-Funktion ist.
   * Damit der Assembler-Code die Variablen findet, lädt der Block-Prolog a5
     (globale Variablen) und gegebenenfalls a4 (lokale Variablen) aus den
     Zeigern, die das C-Backend übergibt, und stellt die Register des
     C-Compilers am Blockende wieder her (gcc verwendet a5 als
     Frame-Pointer).

   In einem C-Backend entspricht ein Block genau einem
   `asm volatile ("…" ::: "memory", <Register>)` bei gcc bzw. einem Aufruf
   einer externen Assembler-Funktion bei vbcc; der Compiler erzeugt dann die
   Speicher-Synchronisation selbst. Variablen, die Asm über a4/a5 adressiert,
   liegen dafür in einem Variablenblock mit festem Layout (globale relativ zu
   a5, lokale relativ zu a4).

   **Nicht abbildbar** ist Code, der Registerinhalte **über Basic-Anweisungen
   hinweg** weiterverwendet, z. B. `benchgfxbus.ab3` (a4 wird in einem Block
   geladen und in einem späteren Block nach einer Basic-Anweisung benutzt).
   Ob das im alten Compiler funktioniert, hängt davon ab, dass die
   Basic-Anweisung dazwischen das Register zufällig nicht benutzt; ein
   Nachbau muss das nicht unterstützen (siehe [11-issues.md](11-issues.md)).

   Wie weit der alte Compiler Werte über Anweisungsgrenzen in Registern hält,
   ist nicht untersucht **[?]**; bekannt ist nur `RegLoad`/`RegSave` für
   FPU-Register, das der Programmierer ausdrücklich anfordert.
3. **Labels gemeinsam halten.** Basic- und Assembler-Labels bilden einen
   gemeinsamen Namensraum; Sprünge und Aufrufe gehen in beide Richtungen
   (`JSR` auf Basic-Label, `Gosub` auf Assembler-Routine, `Return` als
   Rücksprung aus einer per `JSR` aufgerufenen Routine). Ein Backend, das
   Basic-Prozeduren in C-Funktionen und Assembler in separate Dateien trennt,
   muss diese Labels als exportierte Symbole mit identischer Aufrufkonvention
   (Rücksprung per `RTS`, keine Rahmen-/Stackänderung) bereitstellen.
4. **Stack-Layout erhalten.** Der Sicherungsbereich am unteren Stack-Ende
   und die vom Startcode gesicherten Register setzen ein bestimmtes
   Stack-Layout voraus. Code, den ein C-Compiler erzeugt, darf das nicht
   verändern (z. B. keine eigene Stack-Prüfung oder -Erweiterung, die den
   Bereich am unteren Ende benutzt).
5. **Praktische Konsequenz:** Plugin-Programme sind kaum sinnvoll über ein
   C-Backend abzubilden. Für sie – praktisch Compiler und PED selbst – ist das
   eigene 68k-Backend nötig. Ein C-Backend sollte Quellen mit `!initasm`
   erkennen und zurückweisen bzw. an das 68k-Backend verweisen.
6. **Funktionsprolog/-epilog eines C-Backends.** Ein C-Compiler erzeugt für
   jede Funktion Prolog und Epilog (Register sichern, ggf. `LINK`/`UNLK`).
   Abschalten muss man das nur, wenn Code ohne diesen Rahmen angesprungen
   werden soll. Das betrifft:
   * Statements/Functions, deren Rumpf vollständig Assembler ist (`AsmExit`):
     Sie werden als Funktion in einer Assembler-Datei erzeugt – kein
     C-Prolog nötig.
   * Basic-Labels, die aus Assembler per `JSR`/`BSR` angesprungen werden, und
     `Gosub` auf Assembler-Routinen: Ein Basic-Label im Inneren einer
     C-Funktion ist kein aufrufbarer Einsprungpunkt, auch nicht mit
     abgeschaltetem Prolog. Solche Quellen gehören zum 68k-Backend (siehe 5).
   Mit dieser Aufteilung muss ein C-Backend Prolog/Epilog **nicht**
   abschalten. (gcc bietet `__attribute__((naked))` nur für einige
   Zielarchitekturen; ob m68k dazugehört, ist nicht geprüft **[?]**. Bei vbcc
   ist keine entsprechende Möglichkeit bekannt.)
