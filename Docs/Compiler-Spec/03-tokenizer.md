# 3 Keyword-Tokenizer (Schicht L1)

**[C]** `preproc_Tokenize` in `Sourcecodes/Shared/preprocessor.include.ab3`.
Derselbe Algorithmus wird von der IDE (PED) beim Laden/Bearbeiten und vom
Compiler beim Laden von Haupt- und Include-Dateien benutzt.

## 3.1 Aufgabe

Der Tokenizer kopiert den Quelltext Byte für Byte und

* ersetzt jeden Bezeichner, der **exakt** (case-sensitiv) einem Namen aus der
  Token-Tabelle entspricht, durch das zugehörige 2-Byte-Token-Wort,
* wandelt Zeilenenden in `0`-Bytes um,
* wandelt Tabulatoren in Leerzeichen um,
* entfernt sonstige Steuerzeichen außerhalb von Strings und Kommentaren,
* ersetzt Bytes ≥ `$80` außerhalb von Strings und Kommentaren durch `?`.

Er kennt **keine** Zahlen, Operatoren oder sonstige Syntax.

## 3.2 Token-Tabelle

Die Token-Tabelle ist eine Abbildung *Name → Token-Wort*. Sie wird aus den
geladenen BlitzLibs aufgebaut (eingebaute Systemlib mit Lib-Nummer 0, dann die
Bibliotheken aus `BlitzLibs/*Libs`). Ist ein Name mehrfach vorhanden, gilt der
**erste** in Ladereihenfolge. **[C]** `preproc_QueryTokens`. Das Ergebnis wird
als `System/TokenList.hashmap` zwischengespeichert.

Für einen Nachbau ist die Token-Tabelle ein **externer Eingabeparameter**. Für
die BlitzLibs lässt sie sich direkt aus den BigLib-Dateien erzeugen
([09-blitzlibs.md](09-blitzlibs.md)); die vollständige Tabelle des Originals
kann mit

```
AmiBlitz3 -dump token RAM:tokens.txt
```

als Textdatei mit Zeilen `TOKEN <lib>/<index> <name> <hilfetext>` exportiert
werden (Reihenfolge = Ladereihenfolge). **[C]** `WriteDump`.

Eigenschaften der Tabelle der Standardinstallation (`AB3`-Distribution,
Commit `6efd21ef`; **[V]** V-TOK-0/7, `results/round2/tokens.txt`):

* 4653 Einträge aus 233 Bibliotheken; 9 Namen sind doppelt (u. a. `fadd`,
  `STOP`, `MakeDir`, `PeekMax$`) – es gilt der erste.
* Alle Namen beginnen mit einem Buchstaben. Außer Buchstaben und Ziffern
  kommen `_` (2127×), `$` (88×), `.` (6×: `Largest.l`, `Avg.q` …) und `#`
  (2×: `Hex#`, `Bin#`) vor.
* Namen mit `.` können **nie** erkannt werden, weil `.` den Kandidaten beendet
  und nicht zum Kandidaten gehört (`STOP`, nicht `IS`).
* **325 Namen sind kleingeschrieben**, vor allem PPC-/FPU-Assembler-Mnemonics
  (Lib 217/218: `add`, `and`, `or`, `sub`, `neg`, `li`, `mr`, `fmove`, `bne` …).
  Diese Wörter sind damit in *jedem* Kontext Keywords und können nicht als
  Variablen-, Label- oder Macro-Namen verwendet werden (**[V]** V-MAC-NAME-2:
  `Macro neg` → Syntaxfehler).

## 3.3 Zeichenklassen

Jedes Byte hat eine Menge von Flags (vollständige Tabelle:
[grammar/charclasses.csv](grammar/charclasses.csv), Spalten `tok_*`):

| Flag | Bedeutung | Bytes |
|---|---|---|
| `FIRST` | kann ein Token beginnen | `A`–`Z`, `a`–`z` |
| `IS` | kann in einem Token vorkommen | `A`–`Z`, `a`–`z`, `0`–`9`, `_`, `#`, `$` |
| `STOP` | beendet ein Token (löst Lookup aus) | alle außer Buchstaben, Ziffern, `_` |
| `NEW` | danach darf ein neues Token beginnen | alle außer Buchstaben, Ziffern, `_`, `#`, `$`, `'`, `.`, `@`, `\` |
| `COPY` | wird in die Ausgabe kopiert | `$20`–`$7E` |
| `QUOT` | Stringbegrenzer | `"` |
| `COMMENT` | Kommentarbeginn | `;` |
| `EOL` | Zeilenende | `$00`, `$0A` |
| `TAB` | Tabulator (wird zu Leerzeichen) | `$09` |

Bytes ≥ `$80` werden vor der Klassifikation durch `?` ersetzt (außer in
Strings/Kommentaren), haben also effektiv die Flags von `?`
(`STOP NEW COPY`).

Folge der `NEW`-Regel: Nach `#`, `$`, `'`, `.`, `@`, `\`, einer Ziffer, einem
Buchstaben oder `_` wird **kein** neues Token begonnen. Deshalb werden z. B. die
Namen in `#Print`, `.Print`, `x.Print`, `\Print`, `@Print`, `'Print`, `_Print`,
`1Print` nicht tokenisiert.

## 3.4 Algorithmus

Normativer Pseudocode (Eingabe `src[0..n-1]`, Ausgabe `out`):

```
L      := 0          # Länge des aktuellen Token-Kandidaten
start  := 0          # Position des Kandidaten in out
accept := wahr       # darf ein neues Token beginnen?
i      := 0
solange i < n:
    c := src[i]
    wenn c ≥ $80: c := $3F                         # '?'
    f := FLAGS[c]

    # 1. Kandidat abschließen
    wenn L > 0 und STOP ∈ f:
        name := out[start .. start+L-1]
        wenn c = '$' und name+"$" ∈ TABELLE:
            ersetze out[start..] durch TOKEN(name+"$"); L := 0; accept := falsch
            f := {}                                 # das '$' ist verbraucht
        sonst wenn name ∈ TABELLE:
            ersetze out[start..] durch TOKEN(name);  L := 0; accept := falsch

    # 2. Kandidat fortsetzen / beginnen
    wenn L > 0:
        wenn IS ∈ f: L := L + 1   sonst: L := 0
    sonst wenn FIRST ∈ f und accept:
        L := 1; start := |out|

    # 3. Strings, Kommentare, Tab, Zeilenende
    wenn QUOT ∈ f:                                  # String
        wiederhole:
            out += c; i += 1
            c := src[i]  (roh, ohne '?'-Ersetzung); wenn c = $09: c := ' '
            f := FLAGS[c]
        bis QUOT ∈ f oder EOL ∈ f oder i ≥ n
    wenn COMMENT ∈ f:                               # Kommentar bis Zeilenende
        wiederhole:
            out += c; i += 1
            c := src[i]  (roh); wenn c = $09: c := ' '
            f := FLAGS[c]
        bis EOL ∈ f oder i ≥ n
    wenn TAB ∈ f: out += ' '
    wenn EOL ∈ f: out += $00

    # 4. Folgezustand und Kopie
    wenn NEW ∈ f: accept := wahr; L := 0  sonst: accept := falsch
    wenn COPY ∈ f: out += c
    i := i + 1
```

Anmerkungen:

* Ein Kandidat wird **nur bei einem `STOP`-Zeichen** nachgeschlagen. Endet die
  Datei unmittelbar nach einem Bezeichner (ohne Zeilenumbruch), bleibt dieser
  untokenisiert. **Quirk**, **[V]** V-EOF-2: letzte Zeile
  `If 1 : NPrint "z" : EndIf` ohne LF → „'If' without 'End If'“.
* `#` und `$` sind sowohl `STOP` als auch `IS`: Ist der Teil vor `#`/`$` kein
  Token, läuft der Kandidat über das Zeichen hinweg weiter (`ab#cd` ist ein
  Kandidat). Ist er ein Token, wird ersetzt und `#`/`$` kopiert.
  Beispiel: `Print#1` → `[Print]#1`.
* Ein `$` hinter einem Kandidaten wird bevorzugt mit in den Namen genommen
  (`Str$` vor `Str`).
* Nach einem ersetzten Token ist `accept` falsch, bis ein `NEW`-Zeichen folgt:
  `PrintPrint` ist **ein** Kandidat (kein Token, falls nicht in der Tabelle).
* `CR` (`$0D`) und andere Steuerzeichen werden außerhalb von Strings und
  Kommentaren entfernt (kein `COPY`); `DEL` (`$7F`) ebenfalls.
* Innerhalb eines Strings wird ein `CR` **mitkopiert** (z. B. bei einem
  unterminierten String in einer CRLF-Datei). **Quirk.**

## 3.5 Strings und Kommentare

* Ein String beginnt mit `"` und endet am nächsten `"` oder am Zeilenende.
  Sein Inhalt wird unverändert kopiert (Tab → Leerzeichen; Bytes ≥ `$80`
  bleiben erhalten). Ein Backslash hat für den Tokenizer **keine** Bedeutung;
  ein `"` kann also nicht escaped werden (dafür gibt es `\\22`, siehe
  [04-lexical.md](04-lexical.md#452-escape-sequenzen)).
* Ein Kommentar beginnt mit `;` (außerhalb eines Strings) und reicht bis zum
  Zeilenende. Er wird unverändert kopiert (Tab → Leerzeichen).
  **Achtung:** Auch der Teil hinter `:@` (siehe
  [04-lexical.md §4.3](04-lexical.md#43-kommentare)) wird vom Tokenizer als
  Kommentar behandelt, Keywords darin werden also **nicht** tokenisiert.
  **[V]** V-CMT-2: `; c :@ NPrint "x"` → „Garbage at the end of line“.
* Ein unterminierter String endet am Zeilenende; der Compiler meldet später
  „No terminating quote“.

## 3.6 Ausgabeformat

Die Ausgabe ist eine Folge tokenisierter Zeilen (siehe
[01-pipeline.md §1.1](01-pipeline.md#11-begriffe)). Für die Rückwandlung
(Detokenisierung, z. B. für Fehlermeldungen) wird jedes Token-Wort durch den
Namen ersetzt; außerhalb von Strings/Kommentaren beginnt jedes Byte ≥ `$80` ein
Token-Wort. **[C]** `preproc_Detokenize`.

## 3.7 Token-Tabelle

Siehe §3.2. Die Tabelle enthält neben BASIC-Befehlen auch die
68000-Assembler-Mnemonics (`MOVE`, `LEA`, `Dc`, `Even`, …; Token-Wörter `$803C`
bis `$80B2`) und Direktiven (`CNIF`, `Macro`, `XINCLUDE`, …). Da der Vergleich
case-sensitiv ist, werden z. B. `else`, `move` oder `dc` **nicht** als Keyword
erkannt, sondern bleiben Bezeichner (vgl. GitHub-Issue #37: `else` wird als
Label übersetzt). Umgekehrt sind die kleingeschriebenen PPC-Mnemonics (§3.2)
immer Keywords.

Ein Token wird durch Macro-Expansion **nicht** neu gebildet: Rumpf `` N`1 ``
mit Parameter `Print` ergibt `N` + `[Print]`, nicht `[NPrint]`. **[V]**
V-MAC-TOK-1 (Ausgabe ohne Zeilenumbruch, `N` wurde als Label übersetzt).

## 3.8 Fest verdrahtete Token-Wörter

Der Compiler vergleicht an einigen Stellen direkt mit Token-Wörtern der
Systemlib (**[C]** Z. 722–768). Für Tokenizing und Macros relevant:

| Token | Wort | Verwendung |
|---|---|---|
| `End` | `$8002` | `End Macro` |
| `If` | `$800B` | `End If` in Macros (Then-Modus) |
| `Macro` | `$800D` | Macro-Definition |
| `INCLUDE` | `$8012` | Include |
| `XINCLUDE` | `$8013` | Include (einmalig) |
| `CNIF` | `$801C` | bedingte Kompilierung |
| `CSIF` | `$801D` | bedingte Kompilierung |
| `CELSE` | `$801E` | bedingte Kompilierung |
| `CEND` | `$801F` | bedingte Kompilierung |
| `Then` | `$8021` | Then-Modus in Macros |
| `Else` | `$8022` | wirkt als Anweisungstrenner |
| `Object` | `$80D7` | `End Object` in Macros |

## 3.9 Beispiele

Quelle (`·` = Leerzeichen, `→` = Tab, `⏎` = LF):

```
If·a$="x"·Then·NPrint·Str$(a)→;·Print·hier⏎
```

Ergebnis (Token in eckigen Klammern, Bytes in Hex):

```
[If] ·a$="x"· [Then] · [NPrint] · [Str$] (a) ·;·Print·hier 00
```

* `a$`: `a` ist kein Token; `$` ist `IS` → Kandidat `a$` → kein Token → bleibt
  Text.
* `Str$`: Lookup von `Str$` erfolgreich, das `$` wird verbraucht.
* `Print` im Kommentar wird nicht ersetzt.

```
MOVE.l·#SizeOf.EasyStruct,d0
```

→ `[MOVE].l·#SizeOf.EasyStruct,d0` – `SizeOf` folgt auf `#` und wird daher
**nicht** tokenisiert; der Compiler sieht eine Konstante `#SizeOf`. Dies ist
das in der Dokumentation (Abschnitt „Ooh, nasty“) beschriebene Problem;
Abhilfe: `#·SizeOf.EasyStruct` (Leerzeichen ist `NEW`). **[C][D]**
