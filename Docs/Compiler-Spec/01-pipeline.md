# 1 Verarbeitungsschichten

Der Originalcompiler hat **keinen** klassischen, vom Parser getrennten Lexer.
Stattdessen gibt es zwei Stufen:

1. einen **Keyword-Tokenizer**, der den kompletten ASCII-Text vorab in eine
   Byte-Darstellung umsetzt, in der bekannte Befehlsnamen durch 2-Byte-Token
   ersetzt sind, und
2. eine **zeichenweise Lesefunktion** (`getchar` und Varianten), die der Parser
   bei Bedarf aufruft und die nebenbei Kommentare, bedingte Kompilierung und
   einige Textersetzungen erledigt. Macros werden vor dem Parsen jeder Anweisung
   textuell expandiert.

Für einen Nachbau ist es zweckmäßig, diese Verarbeitung in die folgenden
Schichten zu zerlegen. Die Schichten sind so definiert, dass ihr Ergebnis dem
Original entspricht; die Reihenfolge der Seiteneffekte (z. B. dass `OPTIMIZE`
erst ab der Zeile wirkt, in der es ausgeführt wird) muss erhalten bleiben.

```
 Datei (.ab3/.ab2)          Datei (.bb2/.bb)
        │                          │
 L0  XTRA-Header überspringen      │ (bereits tokenisiert)
        │                          │
 L1  Keyword-Tokenizer             │
        └────────────┬─────────────┘
                     │  tokenisierte Zeilen (0-terminiert)
 L2  Zeilenverwaltung, INCLUDE/XINCLUDE (fügt L0/L1-Ergebnis von Includes ein)
                     │
 L3  Anweisungsweise Macro-Expansion  (vor jeder Anweisung, rekursiv)
                     │
 L4  Zeichenstrom für den Parser:
       – Kommentare ( ; … bzw. ; … :@ )
       – bedingte Kompilierung (CNIF/CSIF/CELSE/CEND)
       – USEPATH-Ersetzung (\feld)
       – Leerzeichen überspringen
                     │
 L5  Lexikalische Elemente (vom Parser kontextabhängig gelesen):
       Namen, Zahlen, Strings mit Escapes, Operatoren, Präfixe, @@-Zeilenfortsetzung
                     │
                  Parser (nicht Teil dieser Spezifikation)
```

## 1.1 Begriffe

**Quellbyte** – ein Byte der Quelldatei (0–255). Der Zeichensatz ist ISO-8859-1
(Amiga-Standard); die Spezifikation arbeitet aber byteweise.

**Token-Wort** – zwei Bytes `hi lo` (Big Endian) mit gesetztem Bit 15. Ein
Token-Wort steht für einen Befehlsnamen einer Bibliothek:

```
  Bit 15    Bits 14..7       Bits 6..0
  ┌───┬──────────────────┬──────────────┐
  │ 1 │ Bibliotheksnummer│ Token-Index  │
  └───┴──────────────────┴──────────────┘
  Token-Wort = $8000 | (lib << 7) | index        [C] preproc_AddToken
```

Das Systemlib-Token für `Macro` ist z. B. `$800D` (lib 0, index 13).
Einige im Compiler fest verdrahtete Token-Wörter sind in
[03-tokenizer.md](03-tokenizer.md#38-fest-verdrahtete-token-wörter) aufgeführt.

**Tokenisierte Zeile** – eine Bytefolge, die mit einem `0`-Byte endet. Jedes
Byte < `$80` ist ein normales Zeichen; ein Byte ≥ `$80` ist das erste Byte eines
Token-Worts – **außer** innerhalb von String-Literalen und Kommentaren, in
denen Bytes ≥ `$80` unverändert als Zeichen vorkommen (siehe
[03-tokenizer.md §3.5](03-tokenizer.md#35-strings-und-kommentare)).

**Anweisung (Statement)** – Abschnitt einer (ggf. macro-expandierten) Zeile bis
zum nächsten `:` außerhalb eines Strings, bis zu einem `Else`-Token oder bis zum
Zeilenende.

**New-Syntax-Modus** – Zustand, der durch Bit 2 des Arguments von `OPTIMIZE`
eingeschaltet wird (`OPTIMIZE 4`, `OPTIMIZE 5`, …). Er beeinflusst u. a. den
Macro-Aufruf ohne `{}`, String-Escapes und `@"…"`-Literale (`@@` und `:@`
wirken auch ohne ihn, [04-lexical.md §4.11](04-lexical.md#411-zeilenfortsetzung-)).
`OPTIMIZE n` setzt alle Optimierungsflags neu, d. h. `OPTIMIZE 1` *schaltet den
New-Syntax-Modus aus*. Zu Beginn jedes Compiler-Durchlaufs ist er aus.
**[C]** `do_OPTIMIZE` (Z. 26829), Rücksetzen Z. 2584.

## 1.2 Notation

* Bytes werden hexadezimal mit `$` (Amiga-Konvention) oder als ABNF-Wert
  `%xNN` angegeben.
* Grammatiken stehen in ABNF nach RFC 5234; String-Literale `"…"` sind dort
  case-insensitiv, `%s"…"` (RFC 7405) case-sensitiv.
* Algorithmen werden in Pseudocode angegeben; sie sind normativ, soweit sie
  beobachtbares Verhalten festlegen.
