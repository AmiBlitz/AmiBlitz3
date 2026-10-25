# AmiBlitz3 – Spezifikation: Tokenizing und Macro-Expansion

Diese Spezifikation beschreibt, wie der AmiBlitz3-Compiler (Version 3.14.x,
`Sourcecodes/Amiblitz3/Compiler/AmiBlitz3.ab3`) Quelltext einliest, in Tokens
umsetzt und Macros expandiert. Sie ist die Grundlage für einen Nachbau des
Compilers. Der Parser (Ausdrücke, Anweisungen, Typen) und die Codeerzeugung
sind **nicht** Gegenstand dieses Dokuments.

## Aufbau

| Datei | Inhalt |
|---|---|
| [01-pipeline.md](01-pipeline.md) | Überblick über die Verarbeitungsschichten, Begriffe, Notation |
| [02-source-files.md](02-source-files.md) | Dateiformate (`.ab3`, `.ab2`, `.bb2`), XTRA-Header, Zeilenstruktur |
| [03-tokenizer.md](03-tokenizer.md) | Keyword-Tokenisierung (ASCII → Token-Wörter) |
| [04-lexical.md](04-lexical.md) | Lexikalische Elemente auf Compiler-Ebene: Leerraum, Kommentare, Strings, Zahlen, Namen, Präfixe, `@@` |
| [05-conditional.md](05-conditional.md) | Bedingte Kompilierung (`CNIF`, `CSIF`, `CELSE`, `CEND`) |
| [06-macros.md](06-macros.md) | Macro-Definition, -Aufruf, Parameter, Expansionsalgorithmus |
| [07-verification.md](07-verification.md) | Offene Punkte, Testplan für die Verifikation mit Amiberry |
| [08-doc-differences.md](08-doc-differences.md) | Abweichungen zwischen Dokumentation und Compiler (mögliche Bugs) |
| [09-blitzlibs.md](09-blitzlibs.md) | BlitzLib-Format: BigLib-Dateien, Header, Token-Einträge, Aufrufkonvention, Einbinden |
| [10-assembler-usage.md](10-assembler-usage.md) | Wie die vorhandenen Quellen Inline-Assembler nutzen (Statistik, Muster, Auffälligkeiten) |
| [11-issues.md](11-issues.md) | Gesammelte Liste aller gefundenen Probleme und möglichen Bugs |
| [12-abi.md](12-abi.md) | ABI: feste Register, Prozeduren, Assembler-Blöcke (d0-Regel), Brücken-Befehle, BlitzLib- und AmigaOS-Aufrufe |
| [grammar/lexical.abnf](grammar/lexical.abnf) | Maschinenlesbare Grammatik (ABNF, RFC 5234 / RFC 7405) |
| [grammar/charclasses.csv](grammar/charclasses.csv) | Zeichenklassen-Tabellen des Tokenizers und des Compilers |
| [verification/](verification/) | Probe-Programme, Skriptgenerator, Ergebnisse der Amiberry-Läufe |

## Belegstatus

Jede normative Aussage trägt einen Belegstatus:

| Marke | Bedeutung |
|---|---|
| **[C]** | Aus dem Quelltext des Compilers abgeleitet (mit Fundstelle). |
| **[D]** | Aus der bestehenden Dokumentation (`Docs/Amiblitz3.guide`) übernommen, nicht im Code nachgeprüft. |
| **[V]** | Mit dem Original-Compiler in Amiberry verifiziert (mit Testfall aus `07-verification.md`). |
| **[?]** | Vermutung / unklar – muss verifiziert werden. |

Wo Code und Dokumentation sich widersprechen, gilt der Code; der Widerspruch
wird vermerkt.

## Normative Sprache

„muss“, „darf nicht“, „soll“ werden im Sinne von RFC 2119 verwendet. Ein
Verhalten, das als **Quirk** markiert ist, beschreibt das tatsächliche (oft
unbeabsichtigte) Verhalten des Originals. Ein Nachbau sollte Quirks entweder
exakt nachbilden („Kompatibilitätsmodus“) oder eine Diagnose ausgeben – er darf
sie aber nicht stillschweigend anders interpretieren.

## Quellen

* `Sourcecodes/Shared/preprocessor.include.ab3` – ASCII-Tokenizer (`preproc_Tokenize`)
* `Sourcecodes/Includes/hashmap.include.ab3` – Keyword-Lookup
* `Sourcecodes/Amiblitz3/Compiler/AmiBlitz3.ab3` – Compiler (Zeilennummern beziehen sich auf Commit `6efd21ef`)
* `Sourcecodes/Amiblitz3/Compiler/CLIModeSupport.ab3` – Laden der Quelldatei im CLI-Modus
* `Docs/Amiblitz3.guide` – Sprachdokumentation
