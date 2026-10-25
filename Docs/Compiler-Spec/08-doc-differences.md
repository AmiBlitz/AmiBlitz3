# 8 Abweichungen zwischen Dokumentation und Compiler

Dieses Kapitel vergleicht die Aussagen der beiden Handbücher mit dem
tatsächlichen Verhalten des Compilers (AmiBlitz3 3.14.0, Commit `6efd21ef`),
soweit es Tokenizing, Lexik, bedingte Kompilierung und Macros betrifft.

* **BPG** = `Docs/BlitzProgrammers.guide` (Blitz2-Handbuch)
* **AB3G** = `Docs/Amiblitz3.guide` (AmiBlitz3-Ergänzungen)

Jede Abweichung ist im Original verifiziert (**[V]**, Test-ID aus
[07-verification.md](07-verification.md)). Die Doku-Beispiele wurden dafür
wörtlich übernommen (`verification/probes/docs/`, Ergebnisse in
`results/round8-docs/`).

Einordnung:

* **Bug** – der Compiler verhält sich offensichtlich nicht wie beabsichtigt;
  Doku und Absicht stimmen überein.
* **Doku** – die Dokumentation ist falsch oder veraltet; das Verhalten des
  Compilers ist plausibel.
* **Unklar** – beides denkbar; der Maintainer sollte entscheiden.

## 8.1 Übersicht

| Nr. | Thema | Einordnung | Belege |
|---|---|---|---|
| [A1](#a1-zeilenfortsetzung--in-der-hauptdatei) | `@@` in der Hauptdatei | Bug | V-JOIN-1/4/6a |
| [A2](#a2--in-macro-argumenten) | `@@` in Macro-Argumenten | Bug | V-MAC-ARG-4, V-JOIN-6b |
| [A3](#a3-einzeilige-macros-in-ausdrücken) | Einzeilige Macros in Ausdrücken | Bug | V-MN-6/7, V-MAC-TR, D-AB3G-2 |
| [A4](#a4-code-hinter-end-macro) | Code hinter `End Macro` ignoriert | Bug | V-MAC-AE-1/2 |
| [A5](#a5-cmake-zeichen--funktioniert-nicht-mehr) | CMake-Zeichen `~` | Bug (Regression) | V-TILDE-1, D-BPG-6 |
| [A6](#a6-r-wiederholung) | `\\R`-Wiederholung | Bug + Doku | V-ESC-3, D-AB3G-3 |
| [A7](#a7-unbekannte-und-leere-escape-sequenzen) | Unbekannte/leere Escapes | Bug | V-ESC-5/7 |
| [A8](#a8--im-kommentar) | `:@` im Kommentar | Bug + Doku | V-CMT-1–5 |
| [A9](#a9-macro-aufruf-mit-leeren-klammern) | `!m{}` ohne Parameter | Bug + Doku | V-MAC-CALL-7, D-AB3G-5 |
| [A10](#a10-satzzeichen-nach--im-macro-rumpf) | Satzzeichen nach `` ` `` | Bug | V-MAC-pc, D-BPG-3b |
| [A11](#a11-weitere-kleinere-fehler) | Weitere kleinere Fehler | Bug | div. |
| [B1](#b1-schreibweise-der-keywords) | Schreibweise der Keywords | Doku | D-AB3G-1, D-BPG-8 |
| [B2](#b2-werte-von-__include-und-) | `#__include`, `@#name` | Unklar | V-INC-1, V-CNIF-3 |
| [B3](#b3-macro-parameter-a-z-und-0) | Macro-Parameter `` `a ``–`` `z ``, `` `0 `` | Doku | V-MAC-let, V-MAC-cnt |
| [B4](#b4-namen-von-variablen-und-labels) | Regeln für Namen | Doku | V-NAME-3, V-TILDE-1, D-BPG-7 |
| [B5](#b5-escape-sequenzen) | Escape-Sequenzen (Datum, `\\n`) | Doku | V-ESC-dt/n |
| [B6](#b6-macros-ohne-) | Macros ohne `{}` | Doku | V-MAC-cnt |
| [B7](#b7-arexx-port) | ARexx-Port | Doku | Runde 4/5 |
| [B8](#b8-version-aus-allres) | `!version` aus `all.res` | Doku | V-RES-1/2 |
| [C](#c-nicht-dokumentiertes-verhalten) | Nicht dokumentiertes Verhalten | – | – |

Die Beispiele aus der BPG zu Macros (`mymacro`, `distance`, `dolist`,
`project`, `Vadd` mit zwei Parametern), zu Exponenten (`3e8`) und zu Namen mit
führendem `_` funktionieren wie beschrieben (D-BPG-1/2/3/4/5/7/9).

## 8.2 Wahrscheinliche Compiler-Bugs

### A1 Zeilenfortsetzung `@@` in der Hauptdatei

* **Doku:** AB3G 2.0.2 und „Multiline Expressions“: Eine Zeile kann mit `@@`
  fortgesetzt werden (New-Syntax-Modus). „compiler changes“: `@@` funktioniert
  **nicht** in Include-Dateien (eigene Fehlermeldung „Joining lines with @ @
  does not work in includes“).
* **Ist:** Genau umgekehrt. In der Hauptdatei führt `NPrint "a", @@` + `"b"`
  zu „Syntax error!“ und Folgefehlern – im CLI-Modus und in der IDE, mit und
  ohne `OPTIMIZE 4`. In einer Include-Datei funktioniert dieselbe Zeile
  (Ausgabe `ab`). `Tests/macro_test.ab3` im Repository verwendet `@@` genau so.
* **Code:** Die Fortsetzung wird an mehreren Stellen ad hoc behandelt
  (`countpees` Z. 7849 ff., `fetchpees3` Z. 8116/8283 ff., `eval2` Z. 13586).
  Für die Hauptdatei wird `sourceline`/`sourceline3` auf die Folgezeile
  gesetzt; der Zeilenzähler der Hauptschleife (`numlines2`) wird aber nicht
  angepasst. Die genaue Ursache des Syntaxfehlers ist nicht analysiert.

### A2 `@@` in Macro-Argumenten

* **Ist:** `!m{a,@@` + `b}` liest die Folgezeile für die Argumente, übersetzt
  sie danach aber **noch einmal** als eigene Zeile → „Garbage at the end of
  line“ (CLI und IDE).
* **Code:** `findit` (Z. 3222 ff.) liest über `sourceline3` weiter, ohne die
  Hauptschleife weiterzuschalten.

### A3 Einzeilige Macros in Ausdrücken

* **Doku:** AB3G 2.10:
  `MACRO myFuncMacro : ((`1) * (`2)) : End MACRO` …
  `Print !myStringConst,!myFuncMacro{2,3}` → „Test6“.
* **Ist:** Auch mit korrekter Schreibweise `Macro`/`End Macro` (siehe B1):
  „Syntax error!“ (D-AB3G-2). Der gespeicherte Rumpf endet auf `" : "`, weil
  beim Abschluss nur abschließende `:` entfernt werden und das Leerzeichen vor
  `End` das verhindert. Das eingesetzte `:` beendet dann mitten im Ausdruck die
  Anweisung.
* **Code:** `do_Macro`, Label `'mclean` (Z. 21004 ff.).
* **Vorschlag:** Beim Abschluss abschließende Leerzeichen **und** `:`
  entfernen.

### A4 Code hinter `End Macro`

* **Doku:** keine Aussage; die BPG verwendet die Form
  `Macro project …:End Macro` am Zeilenende.
* **Ist:** Code in derselben Zeile hinter `End Macro` wird **ohne Fehler
  ignoriert**. Bei verschachtelten Definitionen (Macro-Definition im Rumpf
  eines anderen Macros, vgl. `Tests/nested-macros.ab3`) geht deshalb alles
  verloren, was im äußeren Rumpf nach dem inneren `End Macro` steht.
* **Code:** Rückkehr aus `do_Macro` (`JMP get1bytemain`, Z. 21027); Ursache
  nicht analysiert.

### A5 CMake-Zeichen `~` funktioniert nicht mehr

* **Doku:** BPG „The CMake Character“: `NPrint var~`1~` mit `!Ivar{2+1}`
  wertet `2+1` aus und spricht `var3` an.
* **Ist:** „Garbage at the end of line → `var~2+1~`“ (D-BPG-6). `~` ist ein
  gewöhnliches Namenszeichen (`a~b` ist ein gültiger Variablenname,
  V-TILDE-1).
* **Code:** Der Compiler erwartet als CMake-Zeichen das Byte `$7F`
  (`getchar`, `'cmake`, Z. 10624). Der ASCII-Tokenizer (`preproc_Tokenize`)
  entfernt `$7F` jedoch und lässt `~` (`$7E`) unverändert. Vermutlich hat der
  alte Blitz2-Editor `~` beim Tokenisieren in `$7F` umgesetzt; diese Umsetzung
  fehlt seit dem Wechsel auf ASCII-Quelltexte. **Regression.**
* **Vorschlag:** Im Tokenizer `~` außerhalb von Strings und Kommentaren auf
  `$7F` abbilden (und beim Detokenisieren zurück) – oder `getchar` auf `~`
  umstellen. Achtung: Bestehende Namen mit `~` würden dadurch ungültig.

### A6 `\\R`-Wiederholung

* **Doku:** AB3G „Character string escape sequences“: `\\R<num><char>`, *num*
  zweistellig **hexadezimal**; „New constants“: `\\R05*` = fünf Sterne;
  `\\R09a` = „09 repeated a“.
* **Ist:** *num* ist **dezimal**, das Zeichen wird in **Großbuchstaben**
  wiederholt, und anschließend wird es **noch einmal** im Original
  ausgegeben: `\\R05*` → 6 Sterne, `\\R09a` → `AAAAAAAAAa` (D-AB3G-3).
* **Code:** `check_newconstants` (Z. 26915): Der Rest der Zeile wird mit
  `UCase$` gelesen, und es werden nur 3 Zeichen (`R` + 2 Ziffern)
  übersprungen.
* **Vorschlag:** Zeichen aus dem Original (nicht `UCase$`) nehmen, 4 Zeichen
  überspringen; Doku auf „dezimal“ korrigieren.

### A7 Unbekannte und leere Escape-Sequenzen

* **Ist:**
  * Eine unbekannte Sequenz (z. B. `\\qq`) fügt den **Rest der Zeile in
    Großbuchstaben** ein (einschließlich schließendem `"`), der danach noch
    einmal normal gelesen wird: `"[\\qq]abc"` → `[QQ]ABC"qq]abc` (mit Warnung).
  * Liefert eine bekannte Sequenz einen leeren Text (z. B.
    `\\__THIS_INCLUDE` im Hauptquelltext, `\\__THIS_POINTER` außerhalb einer
    Funktion, `\\R00x`), läuft die Kopierschleife (`DBF` mit −1) über bis zu
    64 KB; der String enthält danach ein NUL-Byte.
* **Code:** `check_newconstants` (Z. 26915–27030).
* **Vorschlag:** Unbekannte Sequenz unverändert übernehmen (oder Fehler);
  leeres Ergebnis vor der Kopierschleife abfangen.

### A8 `:@` im Kommentar

* **Doku:** AB3G „compiler changes“: Code hinter `:@` in einem Kommentar wird
  ausgeführt; benötigt `OPTIMIZE 4`.
* **Ist:**
  * Funktioniert ohne `OPTIMIZE 4`.
  * Funktioniert nur, wenn der Kommentar am Zeilenanfang oder nach den
    Parametern eines Befehls steht – **nicht** nach einer Zuweisung
    (`a = 1 ; x :@ a = 2` ignoriert `a = 2` ohne Fehler) und nicht in
    Macro-Rümpfen.
  * Keywords hinter `:@` werden nicht tokenisiert, weil der Tokenizer den
    Rest der Zeile als Kommentar behandelt (`; x :@ NPrint 1` →
    „Garbage at the end of line“).
* **Code:** `getchar` (Z. 10586 ff.) behandelt `:@`, der Ausdrucksleser
  (`fget`) nicht; `preproc_Tokenize` kennt `:@` gar nicht.

### A9 Macro-Aufruf mit leeren Klammern

* **Doku:** AB3G „compiler changes“: Macros brauchen kein `{}`, „although you
  can still include them for compatibility“.
* **Ist:** Im New-Syntax-Modus führt `!hello{}` bei einem Macro ohne
  Parameter (Rumpf ohne `` ` ``) zu „Syntax error! → {}“ (D-AB3G-5): Die
  Klammern bleiben als Text stehen. Im klassischen Modus funktioniert es.
* **Code:** `handle_macro` (Z. 2853 ff.): Enthält der Rumpf kein `` ` ``,
  werden im New-Syntax-Modus keine Parameter – auch keine leeren Klammern –
  gelesen.

### A10 Satzzeichen nach `` ` `` im Macro-Rumpf

* **Doku:** BPG „The `0 Parameter“:
  `CERR "Illegal number of `!Vadd` Parameters"`.
* **Ist:** Die Fehlermeldung lautet „Illegal number of 01Vadd01Parameters“
  (D-BPG-3b), und es folgt ein Folgefehler „CNIF/CSIF without CEND“. Ein
  `` ` `` gefolgt von einem Satzzeichen oder Leerzeichen wird wie `` `0 ``
  behandelt (Parameteranzahl) und verbraucht das Zeichen. Ein literaler
  Backquote ist in einem Macro-Rumpf nicht möglich.
* **Code:** `handle_macro`, `'notnum`/`'itsgot` (Z. 3037 ff.).
* **Vorschlag:** Nur `0`–`9`, `a`–`z`, `@`, `{` als Parameterreferenz
  behandeln, sonst den Backquote unverändert übernehmen.

### A11 Weitere kleinere Fehler

| Verhalten | Beleg |
|---|---|
| Das letzte Wort einer Datei ohne abschließenden Zeilenumbruch wird nicht tokenisiert (`… : EndIf` → „'If' without 'End If'“). | V-EOF-2 |
| `End <kein Keyword>` im Macro-Rumpf (z. B. `End d0`) schneidet den Rumpf ab. | V-MAC-DEF-5 |
| `@@` in einem **String** im Macro-Rumpf verbindet trotzdem Zeilen. | V-MAC-DEF-6 |
| Zeilen über 250 Bytes werden in der Hauptdatei (CLI) **ohne Meldung** gekürzt, in Include-Dateien nicht. | V-LONG-1–3 |
| Leerzeichen direkt hinter `{` gehören im New-Syntax-Modus zum ersten Macro-Parameter, im klassischen Modus nicht. | V-MAC-sp |
| Die PED-ARexx-Befehle `LOAD`/`LOADNEW` benutzten veraltete globale Lade-Flags; `MAKEEXEC` öffnete immer einen Requester. | Runde 4 – im Branch `compiler-spec` behoben |

## 8.3 Dokumentationsfehler

### B1 Schreibweise der Keywords

Keywords werden **case-sensitiv** erkannt (vgl. GitHub-Issue #37). Mehrere
Doku-Beispiele verwenden eine andere Schreibweise und lassen sich deshalb
nicht übersetzen:

| Doku | Stelle | richtig | Test |
|---|---|---|---|
| `MACRO` … `End MACRO` | AB3G 2.10 | `Macro` … `End Macro` | D-AB3G-1: „Garbage at the end of line“, „'Macro/Object' not found“ |
| `UsePath` | BPG „The UsePath Directive“ | `USEPATH` | D-BPG-8: „Garbage at the end of line“ |
| `DefType` | BPG „Default Types“, „Newtypes“ | `DEFTYPE` | – |
| `Nprint` | BPG „Multiple Commands“, „Boolean operators“ | `NPrint` | – |

Ob die IDE beim Eintippen die Schreibweise korrigiert, wurde nicht geprüft;
beim Laden einer Datei geschieht das nicht.

### B2 Werte von `#__include` und `@#name`

* **Doku:** AB3G 2.8.5: `#__include` = −1 in Include-Dateien;
  `@#constant` = −1, wenn definiert.
* **Ist:** jeweils **1** (V-INC-1, V-CNIF-3). `CNIF @#X` funktioniert, aber
  `CNIF @#X=-1` ist nie wahr.
* **Einordnung:** Unklar. AmiBlitz verwendet sonst −1 für „wahr“; der Code
  setzt aber ausdrücklich 1. Entweder Doku oder Code anpassen.

### B3 Macro-Parameter `` `a ``–`` `z `` und `` `0 ``

* **Doku:** BPG: Parameter `` `1 ``–`` `9 ``, dann `` `a ``–`` `z ``;
  `` `0 `` „returns the number of parameters“.
* **Ist:** Nur `` `a ``–`` `y `` (Parameter 10–34); `` `z `` ergibt „Illegal
  constant“. `` `0 `` wird immer **zweistellig** eingesetzt (`02`) – in
  `CNIF `0=2` unproblematisch, in Strings sichtbar.

### B4 Namen von Variablen und Labels

* **Doku:** BPG „Label and Variable Names“: nur Buchstaben, Ziffern und `_`;
  ein Name darf nicht mit den Buchstaben eines Befehls beginnen.
* **Ist:** Namen dürfen alle Zeichen außer den Namenstrennern enthalten, also
  auch `#`, `@`, `!`, `?`, `` ` ``, `'`, `"`, `~` (V-NAME-3, V-TILDE-1;
  `!` löst allerdings einen Macro-Aufruf aus). Ein Name darf mit einem
  Befehlsnamen **beginnen** (`PrintX` ist erlaubt, **[C]** Tokenizer-Algorithmus) – er darf nur nicht
  vollständig einem Keyword entsprechen. **Nicht dokumentiert:** Die
  Token-Tabelle enthält 325 kleingeschriebene Keywords (PPC-/FPU-Mnemonics wie
  `add`, `and`, `or`, `sub`, `neg`, `li`, `mr`); diese Wörter sind als Namen
  verboten (V-MAC-NAME-2).

### B5 Escape-Sequenzen

| Doku (AB3G) | Ist |
|---|---|
| `\\__DATE__` „US format (mm/dd/yyyy)“ | `mm.dd.yyyy` – `/` wird durch `.` ersetzt (V-ESC-dt) |
| `\\n` „carriage return“ | Zeilenvorschub `$0A` (LF) |
| „two slash characters“ | Gemeint sind zwei **Backslashes** `\\` (V-ESC-0) |
| `\\R` hexadezimal | dezimal, siehe A6 |

### B6 Macros ohne `{}`

* **Doku:** AB3G „compiler changes“: Macros brauchen beim Aufruf kein `{}`.
* **Ist:** Gilt nur im New-Syntax-Modus und nur für Macros, deren Rumpf einen
  Parameter (`` ` ``) enthält; dann werden die Parameter bis Zeilen- bzw.
  Anweisungsende gelesen (`!m 1,2,3`). Siehe auch A9.

### B7 ARexx-Port

* **Doku:** AB3G „The AREXX Port“: Portname `PED_1` …
* **Ist:** `PED.1` (`PED_arexx.ab3` Z. 172 ff.). Der Port wird nur angelegt,
  wenn beim Start von PED RexxMast bereits läuft. Die im Branch
  `compiler-spec` neuen Befehle `ERRORREQ`, `LASTERROR` und
  `MAKEEXEC <datei>` sind noch nicht dokumentiert.

### B8 `!version` aus `all.res`

* **Doku:** AB3G 2.10: „!version – version string“.
* **Ist:** `version` ist eine **Anweisung mit Parameter**:
  `!version{"Prog 1.0 (25.10.2026)"}` legt einen `$VER:`-String in den Code
  (V-RES-1/2). `NPrint !version` ergibt „Syntax error!“.

## 8.4 Nicht dokumentiertes Verhalten (C)

Folgendes Verhalten ist in keinem der Handbücher beschrieben und für einen
Nachbau relevant (verifiziert, sofern nicht **[C]** angegeben):

* Leerzeichen innerhalb von Zahlliteralen werden überlesen (`12 34` = 1234,
  V-WS-1).
* Auto-Konstanten `#@name` (Wert von `#__autoconstantnum`, danach erhöht). **[C]**
* `USEPATH2 text` und `\\feld` für einen zweiten Pfad (V-PATH-2).
* `+` am Anweisungsbeginn schaltet die Typprüfung für diese Anweisung ab. **[C]**
* `CNIF`/`CSIF`/`CELSE`/`CEND` wirken auch mitten in einer Zeile (V-CNIF-4);
  mehrfaches `CELSE` schaltet jedes Mal um (V-CNIF-5).
* Macro-Parameter `` `@ `` (Expansionsnummer) und `` `{ausdruck} ``
  (berechnete Parameternummer) (V-MAC-uq, V-MAC-ev).
* Then-Modus: `If a Then b` im Macro-Rumpf erhält automatisch ein `End If`
  (V-MAC-then).
* Der Kommentar in der `Macro`-Zeile wird als Hilfetext gespeichert und bei
  der Expansion entfernt (V-MAC-hc).
