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
