# 4 Lexikalische Elemente (Schichten L4/L5)

Der Compiler liest die tokenisierten Zeilen zeichenweise. Welche lexikalische
Einheit an einer Stelle gelesen wird, entscheidet der Parser anhand des
aktuellen Zeichens; es gibt keinen vorgelagerten Token-Strom. Dieses Kapitel
beschreibt die Einheiten so, dass ein Nachbau sie in einem eigenständigen Lexer
erzeugen kann. Die ABNF-Regeln stehen in
[grammar/lexical.abnf](grammar/lexical.abnf).

## 4.1 Zeichen-Fetch  **[C]** `getchar`, `get1byte_`, `get1bytemain` (Z. 10565 ff.)

`getchar` liefert das nächste „Zeichen“ als 16-Bit-Wert:

* `0` am Zeilenende,
* ein Byte < `$80` als Zeichen,
* bei einem Byte ≥ `$80` das 16-Bit-Token-Wort (zwei Bytes),
* `;` (außerhalb eines Strings) leitet einen Kommentar ein, siehe §4.3,
* `"` schaltet den Zustand *im String* um,
* die Token `CNIF`, `CSIF`, `CELSE`, `CEND` werden sofort verarbeitet und
  nicht an den Parser geliefert (siehe [05-conditional.md](05-conditional.md)),
* während *Überspringen* aktiv ist (bedingte Kompilierung), wird jedes Zeichen
  außer `0` verworfen,
* Zeichen `$02` (Ende einer USEPATH-Einfügung) und `$01` (Ende einer
  `~…~`-Einfügung) springen an die ursprüngliche Leseposition zurück (§4.9,
  §4.10).

`get1bytemain` überspringt zusätzlich **Leerzeichen außerhalb von Strings** und
meldet „Anweisungsende“ (Z-Flag) bei `0`, `:` und dem Token `Else`.

### 4.1.1 Folgen für die Syntax

* **Leerzeichen sind fast überall bedeutungslos.** Sie trennen nur Namen
  (siehe §4.7) und spielen in Strings eine Rolle. Insbesondere werden sie
  *innerhalb* von Zahlliteralen überlesen: `12 34` ist dieselbe Zahl wie `1234`,
  `$F F` wie `$FF`, `% 1 0 1` wie `%101`. **[C]** `atoi` benutzt `fget`,
  `fetch_HexValue` `get1bytemain`. **Quirk**, **[V]** V-WS-1a–c.
* Ein Keyword-Token ist ein einzelnes Zeichen im Sinne des Parsers; zwischen
  einem Token und dem folgenden Text ist kein Trenner nötig (`[Print]a`).

## 4.2 Anweisungs- und Zeilenstruktur

```
zeile      = [anweisung *( ":" anweisung )] [kommentar] EOL
```

* `:` außerhalb eines Strings trennt Anweisungen.
* Das Token `Else` beendet die vorangehende Anweisung ebenfalls (für
  `If … Then … Else …` in einer Zeile). **[C]** `get1bytemain`.
* Leere Anweisungen sind erlaubt (`a = 1 :: …`, eine Zeile nur aus `:` oder `::`,
  `:` am Zeilenanfang oder -ende). **[V]** V-EMPTY-1–4.

## 4.3 Kommentare

```
kommentar  = ";" *( kommentarzeichen ) [ ":@" fortsetzung ]
```

* `;` außerhalb eines Strings beginnt einen Kommentar bis zum Zeilenende.
* **Code im Kommentar:** Enthält der Kommentar die Zeichenfolge `:@`, so endet
  der Kommentar dort; `:@` wirkt wie ein Anweisungstrenner `:` und der Rest der
  Zeile wird als Code übersetzt. **[C]** `getchar` (Z. 10586–10594),
  `getcharb`, `makename4`. **[D]** „compiler changes“:
  `; Hi this is a comment :@b=1`.
  * Das funktioniert **nur dort, wo der Parser den Kommentar über `getchar`
    erreicht**: am Zeilenanfang und nach der Parameterliste eines Befehls.
    Nach einem Ausdruck (z. B. einer Zuweisung) wird `;` vom Ausdrucksleser
    (`fget`) als Zeilenende behandelt und der Rest ignoriert – ohne Fehler.
    **[V]**:

    | Zeile | Ergebnis |
    |---|---|
    | `; line comment :@ a = 2` | ausgeführt (V-CMT-3) |
    | `NPrint "x" ; c :@ a = 3` | ausgeführt (V-CMT-4) |
    | `a = 1 ; c :@ a = 2` | **ignoriert** (V-CMT-1) |
    | `b = 5 ; c :@ b = 6` | **ignoriert** (V-CMT-5) |
    | im Macro-Rumpf `NPrint "in" ; c :@ a = 2` | **ignoriert** (V-MAC-DEF-4) |

  * Kein New-Syntax-Modus nötig (anders als die Dokumentation sagt). **[V]**
    V-CMT-1 (gleiches Verhalten mit und ohne `OPTIMIZE 4`).
  * Da der Tokenizer den Rest der Zeile als Kommentar betrachtet, werden
    Keywords hinter `:@` **nicht** tokenisiert (`; x :@ NPrint 1` →
    „Garbage at the end of line“). **[V]** V-CMT-2. Praktisch nutzbar ist `:@`
    also nur für Code ohne Keywords (z. B. Zuweisungen).
* In einer Macro-Definition wird der Kommentar der `Macro`-Zeile gespeichert
  (siehe [06-macros.md §6.2](06-macros.md#62-definition)).

## 4.4 Leerraum

Leerraum ist das Leerzeichen `$20` (Tabs wurden vom Tokenizer bereits in
Leerzeichen umgewandelt, `CR` entfernt). Siehe §4.1.1.

## 4.5 String-Literale

```
string     = DQUOTE *strzeichen ( DQUOTE / EOL )
strzeichen = %x01-21 / %x23-FF        ; alles außer NUL und "
```

* Der Inhalt wird byteweise übernommen, Bytes ≥ `$80` inklusive. **[C]**
  `litstring` (`'writestring`, Z. 16210 ff.).
* Fehlt das schließende `"`, meldet der Compiler „No terminating quote“.
* Es gibt keine Möglichkeit, `"` direkt zu escapen; im New-Syntax-Modus steht
  `\\22` zur Verfügung.

### 4.5.1 Zeichenliterale `@"…"`  (nur New-Syntax-Modus)

`@"` gefolgt von 1–4 Zeichen und `"` ergibt eine Ganzzahl aus den Zeichencodes
(Big Endian), z. B. `@"ILBM"` = `$494C424D`. Die zulässige Länge hängt vom
Zieltyp ab (Byte: 1, Word: 2, Long: 4). **[C]** Z. 15149 ff.; **[D]**
„Casting strings to longs“; **[V]** V-CHR-1/2 (`@"ILBM"` → `494C424D`,
`@"AB"` → `4142`). Ohne New-Syntax-Modus: Syntaxfehler.

### 4.5.2 Escape-Sequenzen  **[C]** `litstring` + `check_newconstants` (Z. 26915)

Nur im New-Syntax-Modus (**[V]** V-ESC-cls: ohne `OPTIMIZE 4` bleibt `"\\41"`
unverändert `\\41`). Eine Escape-Sequenz beginnt mit **zwei** Backslashes
`\\`; ein einzelner `\` ist ein normales Zeichen (**[V]** V-ESC-0a/b:
`"[\41]"` → `[\41]`, `"[\\41]"` → `[A]`). Der Text hinter `\\` wird
**case-insensitiv** ausgewertet (**[V]** V-ESC-ci, V-ESC-hx).

> **Zur Zählung der Backslashes:** Gemeint sind zwei tatsächliche Bytes `$5C $5C`
> in der Quelldatei – keine Darstellungskonvention. Belege: Der Compiler
> vergleicht in `litstring` (Z. 16218 f.) zweimal mit `#"\"` (Assembler-Zeichenkonstanten
> haben keine Escape-Verarbeitung, also genau ein `$5C`), und die Quelltexte im
> Repository enthalten auf der Platte `22 5C 5C 31 42` für `"\\1B`. In
> `Amiblitz3.guide` erscheinen die Sequenzen wegen des AmigaGuide-Escapings
> (`\\` = angezeigtes `\`) teils verdoppelt oder halbiert. **[V]** V-ESC-0.

| Form | Ergebnis | verbrauchte Zeichen nach `\\` | Beleg |
|---|---|---|---|
| `\\\\` | `\\` (Regel 6) | – | [V] V-ESC-6a |
| `\\__DATE__` | Datum `mm.dd.yyyy` (z. B. `10.25.2026`) | 8 | [V] V-ESC-dt |
| `\\__DATE_GER__` | Datum `dd.mm.yyyy` (z. B. `25.10.2026`) | 12 | [V] V-ESC-dg |
| `\\__VER_MAJOR` | Hauptversion (XTRA `Version` = `a.b.c` → `a`) | 11 | [V] V-ESC-vr |
| `\\__VER_MINOR` | Nebenversion (`b`) | 11 | [V] |
| `\\__VER_PATCH` | Patchlevel (`c`) | 11 | [V] |
| `\\__VER_BUILD` | `NumberOfBuilds` aus dem XTRA-Header | 11 | [V] |
| `\\__THIS_FUNCTION` | Name der aktuellen Function/Statement, sonst `GLOBAL` | 15 | [V] V-ESC-fn/tf |
| `\\__THIS_INCLUDE` | Dateiname der aktuellen Include-Datei | 14 | [C] |
| `\\__THIS_POINTER` | Adresse der aktuellen Funktion (hex) | 14 | [C] |
| `\\__CODELINE` | aktuelle globale Zeilennummer, gezählt ab der ersten Zeile **nach** dem XTRA-Header | 10 | [V] V-ESC-cl |
| `\\R` *d d c* | `UCase(c)` *dd*-mal, danach *c* selbst (Regel 3) | 3 | [V] V-ESC-3 |
| `\\N` | Zeilenvorschub `$0A` | 1 | [V] V-ESC-n |
| `\\` *h h* | Byte mit Hex-Code *hh* | 2 | [V] V-ESC-0b/hx |

Regeln im Detail:

1. Präfixvergleich: Es wird nur ein fester Präfix geprüft, z. B. bei
   `__DATE` nur die 6 Zeichen `DATE__`/`DATE_G`, bei `__THIS_FUNC` nur
   `THIS_FUNC`. Danach werden **feste** Längen übersprungen (Tabelle).
   **Quirk**, **[V]**: `\\__THIS_FUNCTIONXY` → `GLOBALXY`,
   `\\__THIS_FUNCXYZABCD` → `GLOBALBCD` (15 Zeichen `__THIS_FUNCXYZA`
   übersprungen).
2. `__VER_` mit unbekanntem Rest liefert `{unknown compiler constant}`; es
   werden trotzdem 11 Zeichen übersprungen. **[V]** V-ESC-vu.
3. `\\R`: Die Wiederholungszahl wird mit `Vallong` aus zwei Zeichen gelesen,
   also **dezimal**. Das wiederholte Zeichen wird **in Großbuchstaben**
   eingefügt, und weil nur 3 Zeichen (`R` + 2 Ziffern) übersprungen werden,
   wird das Zeichen danach **noch einmal** normal gelesen. **[V]** V-ESC-3:
   `\\R05*` → `******` (6), `\\R12-` → 13× `-`, `\\R01*` → `**`,
   `\\R03ab` → `AAAab`. Die Dokumentation („Character string escape
   sequences“: hexadezimal, *n*-mal) ist in beiden Punkten falsch.
4. `\\` + zwei Hexziffern (`0-9a-fA-F`): ein Byte. `\\R` und `\\N` haben
   Vorrang vor Hex (`\\4E` ist Hex `N`, `\\N4` ist Newline + `4`).
5. **Unbekannte Escape-Sequenz** (keine der obigen Formen): Warnung
   „detected unknown const: […]“ (zweimal, einmal je Compiler-Durchlauf), und
   der **gesamte Rest der Zeile in Großbuchstaben** – einschließlich
   schließendem `"` – wird eingefügt; anschließend wird der Rest *nochmals*
   normal gelesen. **[V]** V-ESC-5: `"[\\qq]abc"` → `[QQ]ABC"qq]abc`.
6. `\\\\`: Folgt auf `\\` unmittelbar wieder `\\`, so wird ein `\` ausgegeben
   und drei der vier Backslashes werden verbraucht; der vierte `\` wird danach
   normal gelesen (nur dann Escape-Beginn, wenn ihm ein weiterer `\` folgt).
   **[V]** V-ESC-6: `"\\\\"` → `\\`, `"\\\\41"` → `\\41`.
7. **Leeres Ergebnis:** Liefert eine erkannte Sequenz einen leeren Text bei
   positiver Überspringlänge (z. B. `\\__THIS_INCLUDE` im Hauptquelltext,
   `\\__THIS_POINTER` außerhalb einer Funktion, `\\R00x`), läuft die
   Kopierschleife (`DBF` mit Zähler −1) über bis zu 65 536 Bytes. **[V]**
   V-ESC-7: kein Absturz, aber der String enthält danach ein NUL-Byte (Ausgabe
   `[` + NUL, Rest fehlt). Ein Nachbau sollte einen leeren Text einfügen und
   kann warnen.
8. Escapes werden auch in `Dc.b "…"` ausgewertet (`version_string_dc`,
   nur `__VER_*`). **[C]**, nicht getestet.

## 4.6 Zahlliterale  **[C]** Z. 15100–15420, 17255–17460

```
zahl        = dezimal / bruch / hex / binaer
dezimal     = 1*DIGIT [ "." *DIGIT ] [ exponent ]
bruch       = "." 1*DIGIT [ exponent ]
exponent    = ("e" / "E") [ "+" / "-" ] 1*2DIGIT      ; Wert ≤ 18
hex         = "$" 1*8HEXDIG                            ; Ziffern case-insensitiv
binaer      = "%" 1*32("0" / "1")
```

* Leerzeichen innerhalb eines Literals werden überlesen (§4.1.1). **[V]**
* `1.5e2` = 150, `2E+1` = 20, `.25` = 0.25. **[V]** V-NUM-e
* Überlauf (mehr als 32 Bit) ergibt den Fehler „Overflow“. Ohne FPU-Modus
  muss der ganzzahlige Teil einer Fließkommazahl < `$800000` sein.
* Ein Literal mit `.` oder Exponent ist ein Fließkommaliteral (Typ Quick/Float
  je nach Kontext).
* Vorzeichen sind keine Bestandteile des Literals, sondern unäre Operatoren.
* Weitere konstante Ausdrücke: `True`/`On` (= −1), `False`/`Off` (= 0), `Pi`,
  `SizeOf.typ[\feld]` – das sind Tokens, kein Teil der Lexik.

## 4.7 Namen

Ein **Name** (Variable, Label, Funktion, Macro, Konstante ohne `#`, Typ, Feld)
ist eine maximal lange Folge von Bytes, die **keine Namenstrenner** sind.
**[C]** `getparameter2`/`makename4` (Z. 10947), Tabelle `chartab` (Z. 1161).

Namenstrenner (Spalte `name_delim` in
[grammar/charclasses.csv](grammar/charclasses.csv)):

```
NUL $01 $02 Leerzeichen , ; : ( ) = + - * / $ % . [ ] { } \ > < & | ^ DEL
sowie alle Bytes ≥ $80 (d. h. jedes Token beendet einen Namen)
```

Folglich dürfen in Namen u. a. die Zeichen `#`, `@`, `!`, `?`, `` ` ``, `'`,
`"`, `~` vorkommen (**[V]** V-TILDE-1: `a~b.l = 3`, V-NAME-3: `c#d.l = 4`
funktionieren). Ein `!` in einem Namen löst allerdings immer einen
Macro-Aufruf aus (§6.3.1). Welche Zeichen ein Name **beginnen** darf, hängt vom
Kontext ab (Parser):

| Kontext | erstes Zeichen | **[C]** |
|---|---|---|
| Variable / Anweisungsbeginn | Buchstabe | `compile_term`, `tstlab` |
| Assembler-Operand | Buchstabe oder `_` | Z. 15125 |
| Macro-Name (nach `!`) | jedes Nicht-Trennzeichen | `handle_macro` |
| Konstante (nach `#`) | jedes Nicht-Trennzeichen | `fetch_Constant` |

Nach einem Namen werden Leerzeichen überlesen; das nächste Nicht-Leerzeichen
bestimmt, wie es weitergeht (z. B. `a .w` ≡ `a.w`, `f {…}` ≡ `f{…}`).
**[V]** V-NAME-2 (`d .w`, `e .l = 9`).

### 4.7.1 Typ-Suffixe und Präfixe von Variablen

```
variable    = [ "*" ] name [ typsuffix ] [ "(" … ]
typsuffix   = "." name / "$"
```

`*` kennzeichnet einen Zeiger, `$` eine String-Variable, `.name` den Typ
(`.b .w .l .q .f .d .s` oder ein NEWTYPE). `(` beginnt Array-Indizes.
Details: Parser.

## 4.8 Präfixzeichen (Übersicht)

| Zeichen | Bedeutung (abhängig vom Kontext) |
|---|---|
| `#name` | Konstante; `#name = …` am Anweisungsbeginn definiert sie |
| `#@name` | Auto-Konstante: erhält den Wert von `#__autoconstantnum`, der danach erhöht wird **[C]** `fetch_Constant` |
| `@#name` | in `CNIF`: 1, wenn Konstante definiert, sonst 0 (Doku: −1) **[V]** V-CNIF-3 |
| `.name` | Label-Definition am Anweisungsbeginn; sonst Typsuffix |
| `name:` | Label-Definition (ohne `:` nur im New-Syntax-Modus) |
| `'name` | lokales Label |
| `?name` | Adresse eines Labels |
| `&name` | Adresse einer Variablen |
| `*name` | Zeigervariable |
| `\name` | NEWTYPE-Feld bzw. USEPATH-Ersetzung (§4.9) |
| `!name` | Macro-Aufruf ([06-macros.md](06-macros.md)) |
| `` `x `` | Macro-Parameter (nur im Macro-Rumpf) |
| `@name` | optionaler Parameter in einer Function/Statement-Deklaration |
| `$…` / `%…` | Hex-/Binärliteral |
| `+` am Anweisungsbeginn | Typprüfung für diese Anweisung aus **[C]** Z. 4186 |

## 4.9 USEPATH-Ersetzung  **[C]** `getparameter` (Z. 12885), `do_USEPATH` (Z. 26581)

`USEPATH text` speichert *text* (bis Anweisungsende, Leerzeichen entfernt,
keine Tokens erlaubt). Steht danach am Beginn eines Variablennamens ein `\`,
so wird gelesen, als stünde *text* unmittelbar davor:

```
USEPATH aliens()
\x = 160          ⇒   aliens()\x = 160
```

**[V]** V-PATH-1.

Mit `\\name` wird der zweite Pfad verwendet, der mit `USEPATH2 text` gesetzt
wird (Token 1/88, `do_usepath2`; **[C]**, Name aus der Token-Tabelle **[V]**
V-PATH-2).
`USELASTPATH` stellt den vorherigen Pfad wieder her. Die Ersetzung ist rein
textuell und gilt bis zur nächsten `USEPATH`-Anweisung (unabhängig von der
Blockstruktur).

## 4.10 Konstanten-Einfügung `~ausdruck~` (Legacy)

`getchar` kennt eine Form, bei der zwischen zwei Zeichen `$7F` ein konstanter
Ausdruck steht; dessen Wert wird dezimal in den Text eingefügt (z. B. für
Namen wie `var~#n~`). **[C]** `'cmake` (Z. 10624). Der ASCII-Tokenizer
**entfernt** jedoch `$7F` und kopiert `~` (`$7E`) unverändert; `~` ist kein
Namenstrenner (**[V]** V-TILDE-1: `a~b` ist ein normaler Variablenname).
Aus ASCII-Quelltexten ist diese Funktion damit **nicht erreichbar**
(vermutlich nur aus alten `.bb2`-Dateien). Ein Nachbau braucht sie nur für
`.bb2`-Unterstützung.

## 4.11 Zeilenfortsetzung `@@`

`@@` erlaubt es, eine logische Zeile auf mehrere physische Zeilen zu verteilen.
Es gibt **keine** allgemeine Vorverarbeitung dafür; `@@` wird nur an bestimmten
Stellen erkannt **[C]**:

| Stelle | Fundstelle |
|---|---|
| zwischen Parametern einer Befehls-/Funktions-Parameterliste (nach `,`) | `fetchpees3` Z. 8116, 8283–8300 |
| in Ausdrücken (beendet den Ausdruck; Fortsetzung in der nächsten Zeile) | `eval2` Z. 13586 |
| in Wertelisten von NEWTYPE-Zuweisungen (`typ\x = 1,2,@@`) | Z. 23658 |
| in Macro-Aufrufargumenten | `findit` Z. 3222 |
| in Macro-Rümpfen (Definition) | `do_Macro` Z. 20885, 20986 |
| in Argumenttext bei der Parameterersetzung | `handle_macro` Z. 3111 |

Regeln:

* Hinter `@@` wird der Rest der physischen Zeile ignoriert; das Lesen wird am
  Anfang der nächsten Zeile fortgesetzt (Zeilen, die nur aus Leerzeichen und
  einem Kommentar bestehen, werden übersprungen **[C]** Z. 3121–3130).
* Für Include-Dateien gibt es eigene Codepfade (der Include-Puffer ist
  zusammenhängend); an einigen Stellen wird stattdessen der Fehler
  „Joining lines with @ @ does not work in includes“ ausgelöst. **[C]**

**Beobachtetes Verhalten im CLI-Modus** (**[V]**, Runde 1):

| Fall | Ergebnis |
|---|---|
| Include: `NPrint "a", @@` ⏎ `"b"` | funktioniert, Ausgabe `ab` (V-JOIN-3) |
| Hauptdatei, New-Syntax: dieselben Zeilen | Syntaxfehler, Folgefehler in den nächsten Zeilen (V-JOIN-1/2/5) |
| Hauptdatei, klassisch | Syntaxfehler (V-JOIN-4) |
| Macro-Argumente `!m{a,@@` ⏎ `b}` | die Folgezeile wird für die Argumente gelesen **und danach noch einmal als eigene Zeile übersetzt** → „Garbage at the end of line“ (V-MAC-ARG-4) |

Der Fehler in der Hauptdatei tritt **auch in der IDE** auf (per ARexx
`LOAD`/`COMPILE` gesteuert: „Syntax error“ in der Zeile mit `@@`). **[V]**
V-JOIN-6a. Es ist also kein CLI-spezifisches Problem; `@@` hinter einem
Befehlsparameter funktioniert in dieser Compiler-Version (3.14.0) in der
Hauptdatei nicht, obwohl `Tests/macro_test.ab3` es so verwendet. Auch der Fehler bei
`@@` in Macro-Argumenten tritt in der IDE identisch auf. **[V]** V-JOIN-6b. `@@` ist damit im Wesentlichen ein
Parser-Thema; für einen Nachbau empfiehlt sich eine saubere, allgemeine
Zeilenfortsetzung in Schicht L2 (Kompatibilitätsentscheidung).

## 4.12 Operatoren und Satzzeichen

Operatoren werden vom Parser zeichenweise gelesen; mehrzeichige Operatoren
(`<>`, `><`, `<=`, `=<`, `>=`, `=>`) entstehen aus aufeinanderfolgenden
Zeichen, zwischen denen Leerzeichen erlaubt sind (§4.1.1). **[?]** Wortoperatoren
(`AND`, `OR`, `NOT`, `MOD`, `LSL`, …) sind Tokens. Die vollständige
Operatorliste gehört zum Parser (Tabelle `operators`, Z. 13590).
