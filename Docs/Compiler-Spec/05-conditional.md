# 5 Bedingte Kompilierung

**[C]** `getchar` (Z. 10606–10710), `do_cnif`/`do_csif`/`compare`
(Z. 19897–19961), `collif` (Z. 21066), `getStringParameter`, `strcom`.

## 5.1 Syntax

```
cnif   = %s"CNIF" konstanter-ausdruck   (":" / EOL)
csif   = %s"CSIF" string vergleich string (":" / EOL)
celse  = %s"CELSE"
cend   = %s"CEND"
vergleich = "<" / "=" / ">" / "<=" / "=<" / ">=" / "=>" / "<>" / "><"
string = DQUOTE *( %x01-21 / %x23-FF ) DQUOTE
```

`CNIF`, `CSIF`, `CELSE`, `CEND` sind Tokens der Systemlib (`$801C`–`$801F`).
`CERR "text"` erzeugt einen Compilerfehler mit *text* (normale Anweisung).

## 5.2 Semantik

Der Compiler führt einen Zustand *compile* (wahr = übersetzen) und einen Stapel
gespeicherter Zustände sowie einen Zähler *nest* für verschachtelte Blöcke, die
im übersprungenen Bereich beginnen.

Die vier Tokens werden **innerhalb der Zeichen-Fetch-Funktion** verarbeitet,
also an jeder Stelle, an der der Parser ein Zeichen liest – nicht nur am
Zeilenanfang. Sie werden nie an den Parser weitergegeben.

```
bei CNIF/CSIF:
    wenn compile:
        Bedingung auswerten → b
        push(compile); compile := b
        das nächste Nicht-Leerzeichen muss ":" oder Zeilenende sein,
        sonst Syntaxfehler; die Leseposition wird danach auf dieses
        Zeichen zurückgesetzt
    sonst:
        nest := nest + 1
bei CELSE:
    wenn nest = 0: compile := nicht compile
bei CEND:
    wenn nest > 0: nest := nest - 1
    sonst: wenn Stapel leer → Fehler "'CEND' without 'CNIF/CSIF'"
           compile := pop()
```

Am Ende der Übersetzung müssen Stapel und *nest* leer sein, sonst Fehler.
**[C]** Z. 3722.

Solange *compile* falsch ist, verwirft die Fetch-Funktion **jedes** Zeichen bis
auf das Zeilenende; der Parser sieht also leere Anweisungen. Dabei gilt:

* Kommentare werden weiterhin erkannt (ein `CEND` in einem Kommentar zählt
  nicht – **[V]** V-CNIF-6). Auch `:@` im Kommentar wird erkannt, ist aber folgenlos.
* Strings werden weiterhin verfolgt (`"` schaltet um).
* **Macros werden nicht expandiert** (die Expansion prüft *compile*,
  [06-macros.md §6.4](06-macros.md#64-expansion)); `Macro`-Definitionen im
  übersprungenen Bereich werden nicht angelegt.

`CELSE` darf mehrfach vorkommen; jedes `CELSE` auf derselben Ebene kehrt den
Zustand um. **Quirk**, **[V]** V-CNIF-5 (`CNIF 0 … CELSE two CELSE three` → nur `two`).

Wichtig: Steht `CNIF` mitten in einer Zeile, wirkt es ab dort – auch auf den
Rest derselben Zeile:

```
a=1 : CNIF #x=0 : b=2 : CEND : c=3
```

übersetzt `b=2` nur, wenn `#x=0` gilt; `a=1` und `c=3` immer. **[V]** V-CNIF-4.

## 5.3 CNIF-Bedingung

`CNIF` wertet einen konstanten Ausdruck aus (wie bei `#k = …`). Übersetzt wird,
wenn der Wert **≠ 0** ist. Vergleichsoperatoren gehören zum Ausdruck
(`CNIF #a=1`, `CNIF #a<>0 AND #b`). **[C]** `do_cnif` (`D1=5` → `cif_ne`,
`numcom` = `TST.l D3`).

**Definiertheitstest:** Beginnt die Bedingung mit `@`, so wird im gesamten
folgenden Ausdruck jede Konstante `#name` durch 1 (definiert) bzw. 0 (nicht
definiert) ersetzt (`incnif`-Flag, `fetch_Constant`). Beispiel:

```
CNIF @#DEBUG=0          ; übersetzen, wenn #DEBUG nicht definiert ist
```

* Die Dokumentation nennt −1 für „definiert“; tatsächlich ist es 1.
  **[V]** V-CNIF-3: `CNIF @#X=1` übersetzt, `CNIF @#X=-1` nicht; `CNIF @#X`
  und `CNIF @#Y … CELSE` verhalten sich wie erwartet.
* Da das Flag für den ganzen Ausdruck gilt, ist `CNIF @#A AND #B=2` ein
  Definiertheitstest auch für `#B`. **Quirk.**

## 5.4 CSIF-Bedingung

Zwei String-Literale werden byteweise verglichen (vorzeichenbehaftet,
`CMP.b`; ein Präfix ist kleiner als der längere String). Die Literale werden
ohne Escape-Auswertung gelesen. Ein typischer Einsatz ist der Vergleich von
Macro-Parametern:

```
Macro typecheck
  CSIF "`1"="w"
    …
  CEND
End Macro
```

**[V]** V-CSIF-1–3: `"abc" < "abd"`, `"ab" < "abc"`, `"x" >< "y"` sind wahr.

Zulässige Vergleichsoperatoren (Code `a + 3·(b+1)` aus den beiden Zeichen,
**[C]** `collif`):

| Operator | Bedeutung |
|---|---|
| `<` | kleiner |
| `=` | gleich |
| `>` | größer |
| `<=`, `=<` | kleiner oder gleich |
| `>=`, `=>` | größer oder gleich |
| `<>`, `><` | ungleich |
| `<<`, `==`, `>>` | Syntaxfehler |

## 5.5 Wechselwirkung mit Macros

Da Macro-Rümpfe beim Definieren **ohne** Auswertung der bedingten Kompilierung
gesammelt werden (`getcharb`), werden `CNIF`/`CSIF` in einem Macro-Rumpf erst
bei jeder Expansion ausgewertet – mit den dann eingesetzten Parametern.
**[C]** `do_Macro` (Z. 20879: „get next character, but not conditional stuff“).
