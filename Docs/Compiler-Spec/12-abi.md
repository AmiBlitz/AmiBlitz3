# 12 ABI: Register- und Aufrufkonventionen

Dieses Kapitel legt die Konventionen fest, die erzeugter Code, Inline-Assembler,
BlitzLibs und AmigaOS-Libraries miteinander verbinden. Es ist **normativ** für
einen Nachbau: Was hier nicht zugesagt wird, darf Assembler-Code nicht
voraussetzen. Grundlage sind die Messungen aus
[10-assembler-usage.md §10.8](10-assembler-usage.md#108-registerinhalte-über-basic-anweisungen-hinweg),
das BlitzLib-Format ([09-blitzlibs.md](09-blitzlibs.md)) und die
AmigaOS-Autodocs in `Docs/AmigaLibs/`.

## 12.1 Feste Register

| Register | Bedeutung | gilt |
|---|---|---|
| **a5** | Basisadresse der globalen Variablen (`name@(a5)` in Assembler) | im ganzen Programm |
| **a4** | Basisadresse der lokalen Variablen der aktuellen Prozedur | innerhalb von Statements/Functions |
| **a7** | Stackpointer | immer |

Diese drei Register sind die einzigen, die über Basic-Anweisungen hinweg
erhalten bleiben. Alle anderen Register sind nach einer Basic-Anweisung
**undefiniert**; dass der alte Compiler bei einfachen Anweisungen d2–d6
unverändert lässt, ist Zufall und keine Zusage (§10.8.1, §10.8.4) **[V]**.

Der Inhalt von a4 außerhalb von Prozeduren ist nicht festgelegt. Lokale
Variablen lassen sich in Assembler nicht über `name@(a4)` ansprechen
**[V]** (I-49).

## 12.2 Prozeduren (Statement, Function)

| Punkt | Regel | Beleg |
|---|---|---|
| Parameter | 1.–6. Parameter in **d0–d5** in der Reihenfolge der Deklaration, weitere auf dem Stack (vor der Rücksprungadresse) | [D] BPG „Using assembler with procedures“, AB3G „moreargs“ |
| Rückgabewert einer Function | in **d0** | [D] BPG |
| Assembler-Rumpf | Verlassen mit `AsmExit`; a4–a6 müssen dann wiederhergestellt sein | [D] BPG |
| Registerverbrauch | Eine Prozedur darf alle Register außer a4, a5, a7 verändern; der Aufrufer darf sich auf nichts anderes verlassen | [V] §10.8.1 (`gn{}`) |

## 12.3 Assembler-Blöcke

Ein Assembler-Block ist eine maximale Folge von Assembler-Anweisungen und
Brücken-Befehlen ohne Basic-Anweisung dazwischen (Definition und
Optimierungsgrenze: [§10.6.3](10-assembler-usage.md#1063-anforderungen-an-einen-nachbau)).

**Beim Eintritt** in einen Block gilt:

1. a5, a4 (in Prozeduren) und a7 haben ihre festen Werte (12.1).
2. Alle Basic-Variablen, die der Block erreichen kann, stehen im Speicher.
3. **d0-Regel:** d0 enthält den Wert, den die unmittelbar vorangehende
   Basic-Anweisung zuletzt berechnet hat:
   * bei einer Zuweisung den zugewiesenen Wert (auch bei Array-Elementen und
     NEWTYPE-Feldern),
   * bei einem Funktionsaufruf als Anweisung (Basic- oder Lib-Funktion) dessen
     Ergebnis,
   * bei `PushD0 x` den Wert x.

   **[V]** `r12_bridges.ab3` (D1–D5), `r10_regs.ab3`. Folgt der Block auf
   keine solche Anweisung (z. B. auf ein Label, eine Kontrollstruktur oder den
   Prozedurbeginn), ist d0 undefiniert; am Prozedurbeginn gilt stattdessen
   12.2.
4. Alle anderen Register sind undefiniert.

**Beim Verlassen** eines Blocks muss gelten:

1. a4 und a5 haben wieder ihre festen Werte (a6 darf verändert sein; die
   Regel „a4–a6 wiederherstellen“ der BPG wird in den Quellen nicht
   eingehalten, siehe §10.3).
2. Der Stack ist ausgeglichen: Werte, die der Block auf den Stack legt, nimmt
   er auch wieder herunter. Werte über Basic-Anweisungen hinweg auf dem Stack
   zu lassen, ist nicht zulässig (I-48; der alte Compiler toleriert es).
3. Alle anderen Register und alle Speicherinhalte darf der Block verändert
   haben; der Compiler liest Variablen danach neu.

Für das C-Backend folgt aus der d0-Regel: Das zuletzt berechnete Ergebnis
einer Anweisung wird in einer temporären Variablen gehalten und dem
folgenden Block als Eingabe in d0 übergeben
(`register long r __asm("d0") = tmp;` bzw. Registerparameter bei vbcc).

## 12.4 Brücken-Befehle

Brücken-Befehle verbinden Assembler und Basic. Sie gehören zum Block, in dem
sie stehen, und haben eine feste Registerwirkung.

| Befehl | Wirkung auf Register | Code | Beleg |
|---|---|---|---|
| `GetReg rN,ausdruck` | rN := Wert des Ausdrucks; **alle anderen Register bleiben erhalten** | Ausdruck zwischen `MOVEM`-Sicherungen | [C] `do_GetReg` |
| `PutReg rN,variable` | Variable := rN; **alle Register bleiben erhalten** | `MOVEM` d0–a6 um den Speicherzugriff | [C] `do_PutReg` |
| `GetD0 a[,b[,c]]`, `GetRegD0 …` | d0 := a, d1 := b, d2 := c; sonstige Register undefiniert | nur Auswertung der Argumente | [V] B-5, B-6 |
| `… = PutD0`, `… = PutRegD0` | liefert den Wert von d0 **am Beginn der Anweisung**, auch wenn danach noch eine Zieladresse berechnet wird oder `PutRegD0` Teil eines Ausdrucks ist | kein Code | [V] B-1 – B-4 |
| `PushD0 ausdruck` | d0 := Wert, Wert zusätzlich auf den Stack (`MOVE.l d0,-(a7)` inline) | Auswertung + 1 Befehl | [V] D5, §9.3.2 |

Für die Codeerzeugung bedeutet das:

* `GetReg`/`PutReg` müssen **registertransparent** übersetzt werden (alle
  Register außer dem Ziel sichern und wiederherstellen), weil Assembler-Code
  im selben Block Werte in anderen Registern hält.
* `PutD0`/`PutRegD0` müssen d0 lesen, **bevor** irgendein Code der Anweisung
  d0 verändert. Im C-Backend ist d0 daher eine Ausgabe des vorangehenden
  Blocks (`"=d"`-Operand bzw. Rückgabewert der Block-Funktion).
* `GetD0`/`GetRegD0` legen ihre Werte als Eingaben des folgenden Blocks in
  d0–d2. Dass die Auswertung des zweiten und dritten Arguments d0 bzw. d1
  nicht zerstört, muss der Codegenerator sicherstellen (der alte Compiler
  tut es, B-6).

## 12.5 BlitzLib-Aufrufe

Siehe [09-blitzlibs.md §9.3](09-blitzlibs.md#93-aufrufkonvention). Kurz:
Argumente in d0–d5 (weitere auf dem Stack), zusätzliche Werte laut `!libs` in
den angeforderten Registern, Ergebnis in d0, String-Ergebnisse über a3. Eine
Lib-Routine darf alle Register außer a4, a5, a7 verändern **[V]** (§10.8.1:
`NPrint` verändert u. a. a2, a3, a6 und d7). Inline-Routinen (`$A0 $00`) und
Routinen ohne Code verhalten sich wie in §9.3.2 beschrieben.

Einige Lib-Aufrufe erzeugt der Compiler selbst, ohne dass ein Token im
Quelltext steht. Ein Nachbau muss diese Nummern kennen. Ein Beispiel ist der
Operator `^` auf Fließkommawerten: Ohne FPU-Modus ruft er Token `$1601` auf
(Lib 44, „mathtranslib“), mit FPU-Modus wird ein FPU-Befehl inline erzeugt.
**[C]** Z. 14555–14566. In BlitzBasic 2.10 ist es Lib 192 (Original-Compiler
`blitz2.s`, `mathq`). Weitere solche Einsprünge sind die compilerinternen
Lib-Tokens aus [§9.1](09-blitzlibs.md#91-dateien).

## 12.6 AmigaOS-Library-Aufrufe

Aufrufe von Funktionen der Betriebssystem-Libraries (exec, dos, intuition …)
folgen der AmigaOS-Konvention. Quelle: Autodocs in `Docs/AmigaLibs/`, die
FD-/SFD-Dateien des NDK (z. B. `ndk/lib/fd/intuition_lib.fd`) und das
Amiga ROM Kernel Reference Manual.

| Punkt | Regel | Beispiel |
|---|---|---|
| Aufruf | Library-Basis in **a6**, `JSR LVO(a6)`; LVO = −(`##bias` + 6·n), bei den meisten Libraries `##bias 30` | `JSR _LVOOpenLibrary(a6)` |
| Argumente | in den Registern, die **für jede Funktion einzeln** festgelegt sind (Autodoc „SYNOPSIS“, FD-Datei). Meist Daten in D-, Zeiger in A-Registern, aber **nicht** systematisch fortlaufend | `BuildEasyRequestArgs(RefWindow, easyStruct, IDCMP, Args)` → **A0, A1, D0, A3** (intuition.doc, `intuition_lib.fd`: `(a0/a1,d0/a3)`) |
| Ausnahme dos.library | auch Zeiger in Datenregistern, Zählung ab **D1** | `Open(name, accessMode)(d1,d2)`, `Read(file,buffer,length)(d1,d2,d3)`, `SetIoErr(result)(d1)` |
| Ergebnis | in **d0**; einige Funktionen liefern ein zweites Ergebnis in **d1** | `quotient:remainder = UDivMod32(dividend,divisor)` → D0:D1 (utility.doc) |
| veränderte Register | **d0, d1, a0, a1** dürfen verändert werden, alle anderen (auch a6) bleiben erhalten | RKM-Konvention |
| Parameter in a4/a5 | Einige Funktionen erwarten Argumente in **a4** oder **a5**. Diese Register tragen in Basic die Variablenbasen (12.1). Der Compiler legt deshalb vor einem solchen Aufruf `MOVEM.l a4/a5,-(a7)` und danach `MOVEM.l (a7)+,a4/a5` in den Code (`checka4a5`/`restorea4a5`, Z. 27110–27135: Registercode `$14`/`$15` in der Argumentbeschreibung). BlitzBasic 2.10 sichert die beiden nicht (Original-Compiler `blitz2.s`, `stamigalib`); nach dem Aufruf sind dort die Variablenbasen verloren | **[C]** |
| Varargs-Varianten | `…Tags`/Varargs-Stubs (z. B. `BuildEasyRequest`) sind Funktionen aus `amiga.lib` bzw. Inline-Stubs, keine LVO-Einsprünge | intuition.doc „Varargs stub“ |

Die Bibliotheks-Wrapper in den Includes (`amissl.include.ab3` …, §10.3)
bilden genau diese Konvention mit `GetReg`/`JSR`/`PutRegD0` nach. Ein
C-Backend kann solche Aufrufe direkt über die NDK-Header (`proto/*.h`)
erzeugen; der C-Compiler kennt die Registerzuordnung dann selbst.

## 12.7 Zusammenfassung für die Codeerzeugung

Über die gewöhnliche Codeerzeugung hinaus muss ein Backend nur Folgendes
sicherstellen:

1. a5 (und a4 in Prozeduren) zeigen in Funktionen mit Assembler-Blöcken auf
   die Variablenblöcke; a7 ist bei Eintritt in jeden Block der Stackpointer.
2. Variablen, die ein Block erreichen kann, stehen vor dem Block im Speicher
   und werden danach neu gelesen (Optimierungsgrenze pro Block).
3. d0-Regel beim Eintritt in Blöcke (12.3).
4. Die Brücken-Befehle mit genau der Registerwirkung aus 12.4.
5. Bei direkten OS-Aufrufen die Konvention aus 12.6; bei BlitzLib-Aufrufen
   §9.3.

Register darüber hinaus zu sichern oder wiederherzustellen ist nicht nötig:
Kein Code darf erwarten, dass andere Register eine Basic-Anweisung, einen
Prozedur- oder einen Library-Aufruf überleben.
