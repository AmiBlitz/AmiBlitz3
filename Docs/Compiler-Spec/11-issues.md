# 11 Liste der Probleme und möglichen Bugs

Diese Liste sammelt alle Probleme, die bei der Arbeit an dieser
Spezifikation aufgefallen sind – im Compiler, im Tokenizer, in PED, in den
Bibliotheken, in Anwendercode und in der Dokumentation. Die Einträge
verweisen auf die Kapitel mit den Details und Belegen.

**Einstufung:**

* **Bug** – das Verhalten ist offensichtlich nicht beabsichtigt.
* **Fragil** – funktioniert, aber nur zufällig oder unter Bedingungen, die
  leicht verletzt werden.
* **Grenze** – bewusste oder unvermeidbare Einschränkung der Konstruktion,
  die man kennen muss.
* **Doku** – die Dokumentation ist falsch oder unvollständig.
* **Unklar** – Doku und Code widersprechen sich; welche Seite richtig ist,
  muss der Maintainer entscheiden.

**Status:** offen, sofern nicht anders angegeben. Belegstatus wie in der
übrigen Spezifikation: **[V]** = im Original verifiziert, **[C]** = aus dem
Code abgeleitet.

## 11.1 Compiler: Zeilen, Tokenizer, Lexik

| ID | Einstufung | Problem | Beleg | Details |
|---|---|---|---|---|
| I-01 | Bug | Zeilenfortsetzung `@@` hinter Befehlsparametern scheitert in der Hauptdatei (CLI und IDE), funktioniert in Include-Dateien – entgegen der Doku. | [V] V-JOIN-1/4/6a | [§4.11](04-lexical.md#411-zeilenfortsetzung-), [A1](08-doc-differences.md#a1-zeilenfortsetzung--in-der-hauptdatei) |
| I-02 | Bug | Das letzte Wort einer Datei ohne abschließenden Zeilenumbruch wird nicht tokenisiert (`… EndIf` → „'If' without 'End If'“). | [V] V-EOF-2 | [§3.4](03-tokenizer.md#34-algorithmus) |
| I-03 | Bug | Zeilen über 250 Bytes (tokenisiert) werden in der Hauptdatei ohne Meldung abgeschnitten; in Include-Dateien nicht. | [V] V-LONG-1–3 | [§2.3](02-source-files.md#23-zeilen) |
| I-04 | Bug | `:@` (Code im Kommentar) wirkt nur am Zeilenanfang und nach Befehlsparametern, nicht nach Zuweisungen und nicht in Macro-Rümpfen; Keywords dahinter werden nie tokenisiert. Fehlt `:@`, gibt es keine Meldung. | [V] V-CMT-1–5 | [§4.3](04-lexical.md#43-kommentare), [A8](08-doc-differences.md#a8--im-kommentar) |
| I-05 | Bug (Regression) | Das CMake-Zeichen `~…~` funktioniert nicht mehr: Der Compiler erwartet `$7F`, der ASCII-Tokenizer entfernt `$7F` und lässt `~` stehen. | [V] D-BPG-6, V-TILDE-1 | [§4.10](04-lexical.md#410-konstanten-einfügung-ausdruck-legacy), [A5](08-doc-differences.md#a5-cmake-zeichen--funktioniert-nicht-mehr) |
| I-06 | Bug | Bytes ≥ `$80` außerhalb von Strings und Kommentaren werden kommentarlos durch `?` ersetzt. | [C] | [§3.3](03-tokenizer.md#33-zeichenklassen) |
| I-07 | Grenze | 325 kleingeschriebene PPC-/FPU-Mnemonics (`add`, `and`, `or`, `sub`, `neg`, `li`, `mr` …) sind überall Keywords und als Namen gesperrt; in Kombination mit der case-sensitiven Erkennung verwirrend (vgl. GitHub-Issue #37). | [V] V-MAC-NAME-2 | [§3.2](03-tokenizer.md#32-token-tabelle) |
| I-08 | Bug | Token-Namen mit `.` (`Largest.l`, `Smallest.q`, `Avg.l` … in Lib 105) können nie erkannt werden; `Largest.l(a,b)` ruft die untypisierte Variante `Largest` auf. | [C] Tokenizer, Token-Tabelle | [§3.2](03-tokenizer.md#32-token-tabelle) |
| I-09 | Fragil | 9 Token-Namen sind doppelt vergeben (`fadd`, `fsub`, `fmul`, `fdiv`, `fneg`, `STOP`, `DBactive`, `MakeDir`, `PeekMax$`); es gilt die erste Lib in Ladereihenfolge, die übrigen sind unerreichbar. | [V] tokens.txt | [§3.2](03-tokenizer.md#32-token-tabelle) |
| I-10 | Grenze | Leerzeichen innerhalb von Zahlliteralen werden ignoriert (`12 34` = 1234). | [V] V-WS-1 | [§4.1.1](04-lexical.md#411-folgen-für-die-syntax) |
| I-11 | Fragil | Fehlt im Hauptquelltext die Zeile `; /XTRA`, wird die gesamte Datei als Header gelesen; Zeilen mit `=` können Projekteinstellungen verändern. Hauptdatei und Includes erkennen den Header mit unterschiedlichen Algorithmen. | [C] | [§2.2](02-source-files.md#22-xtra-header) |

## 11.2 Compiler: Escape-Sequenzen

| ID | Einstufung | Problem | Beleg | Details |
|---|---|---|---|---|
| I-12 | Bug | `\\Rnnc` wiederholt das Zeichen in Großbuchstaben und gibt es danach noch einmal aus (`\\R05*` → 6 Sterne, `\\R09a` → `AAAAAAAAAa`). | [V] V-ESC-3, D-AB3G-3 | [§4.5.2](04-lexical.md#452-escape-sequenzen), [A6](08-doc-differences.md#a6-r-wiederholung) |
| I-13 | Bug | Unbekannte Escape-Sequenz: Der Rest der Zeile wird in Großbuchstaben eingefügt und danach noch einmal normal gelesen. | [V] V-ESC-5 | [A7](08-doc-differences.md#a7-unbekannte-und-leere-escape-sequenzen) |
| I-14 | Bug | Escape mit leerem Ergebnis (`\\__THIS_INCLUDE` im Hauptquelltext, `\\__THIS_POINTER` außerhalb einer Funktion, `\\R00x`): Kopierschleife über bis zu 64 KB, String enthält danach NUL. | [V] V-ESC-7 | [A7](08-doc-differences.md#a7-unbekannte-und-leere-escape-sequenzen) |
| I-15 | Fragil | Escape-Namen werden nur über feste Präfixe erkannt, danach feste Längen übersprungen (`\\__THIS_FUNCXYZABCD` → `GLOBALBCD`). | [V] V-ESC-tp | [§4.5.2](04-lexical.md#452-escape-sequenzen) |

## 11.3 Compiler: Macros

| ID | Einstufung | Problem | Beleg | Details |
|---|---|---|---|---|
| I-16 | Bug | Einzeilige Macros `Macro m : … : End Macro` behalten ein `:` am Ende (nur `:` wird entfernt, keine Leerzeichen) und sind in Ausdrücken unbrauchbar. Betrifft das Beispiel in der Guide (Kap. 2.10). | [V] V-MN-6/7, V-MAC-TR, D-AB3G-2 | [§6.2.3](06-macros.md#623-sammeln-des-rumpfs), [A3](08-doc-differences.md#a3-einzeilige-macros-in-ausdrücken) |
| I-17 | Bug | Code hinter `End Macro` in derselben Zeile wird ohne Meldung ignoriert; bei verschachtelten Definitionen geht der Rest des äußeren Rumpfs verloren. | [V] V-MAC-AE-1/2 | [A4](08-doc-differences.md#a4-code-hinter-end-macro) |
| I-18 | Bug | `@@` in Macro-Argumenten: Die Folgezeile wird zusätzlich noch einmal als eigene Zeile übersetzt. | [V] V-MAC-ARG-4, V-JOIN-6b | [§6.3.3](06-macros.md#633-parameterliste), [A2](08-doc-differences.md#a2--in-macro-argumenten) |
| I-19 | Bug | `@@` in einem String im Macro-Rumpf verbindet trotzdem Zeilen. | [V] V-MAC-DEF-6 | [§6.2.3](06-macros.md#623-sammeln-des-rumpfs) |
| I-20 | Bug | `End <kein Keyword>` (z. B. `End d0`) im Macro-Rumpf schneidet den Rumpf ab. | [V] V-MAC-DEF-5 | [§6.2.3](06-macros.md#623-sammeln-des-rumpfs) |
| I-21 | Bug | `!m{}` bei einem Macro ohne Parameter ergibt im New-Syntax-Modus einen Syntaxfehler (Doku: Klammern weiterhin erlaubt). | [V] V-MAC-CALL-7, D-AB3G-5 | [A9](08-doc-differences.md#a9-macro-aufruf-mit-leeren-klammern) |
| I-22 | Bug | `` ` `` gefolgt von Satzzeichen oder Leerzeichen wird wie `` `0 `` ersetzt und verschluckt das Zeichen; ein literaler Backquote im Rumpf ist unmöglich (BPG-Beispiel `Vadd`). | [V] V-MAC-pc, D-BPG-3b | [A10](08-doc-differences.md#a10-satzzeichen-nach-dem-backquote-im-macro-rumpf) |
| I-23 | Fragil | Leerzeichen direkt hinter `{` gehören im New-Syntax-Modus zum ersten Parameter, im klassischen Modus nicht. | [V] V-MAC-sp | [§6.3.3](06-macros.md#633-parameterliste) |
| I-24 | Fragil | `[`/`]` werden beim Zerlegen der Macro-Argumente nicht als Klammern gezählt (`!m{a[1,2]}` = zwei Parameter). | [V] V-MAC-cnt | [§6.3.3](06-macros.md#633-parameterliste) |
| I-25 | Unklar | Parameter nur bis `` `y `` (34); `` `z `` ergibt „Illegal constant“ (BPG: bis `` `z ``). | [C] | [B3](08-doc-differences.md#b3-macro-parameter-a-bis-z-und-0) |

## 11.4 Compiler: bedingte Kompilierung und Konstanten

| ID | Einstufung | Problem | Beleg | Details |
|---|---|---|---|---|
| I-26 | Unklar | `#__include` und `@#name` liefern 1 statt −1 (Doku); `CNIF @#X=-1` ist nie wahr. | [V] V-INC-1, V-CNIF-3 | [B2](08-doc-differences.md#b2-werte-von-__include-und-name) |
| I-27 | Fragil | Das `@` in `CNIF @#X` gilt für den ganzen Ausdruck: `CNIF @#A AND #B=2` ist auch für `#B` ein Definiertheitstest. | [C] | [§5.3](05-conditional.md#53-cnif-bedingung) |
| I-28 | Fragil | Jedes weitere `CELSE` auf derselben Ebene schaltet erneut um. | [V] V-CNIF-5 | [§5.2](05-conditional.md#52-semantik) |

## 11.5 Laufzeit, Bibliotheken, Assembler

| ID | Einstufung | Problem | Beleg | Details |
|---|---|---|---|---|
| I-29 | Bug | `Clear_Residents_table` im Compiler wird per `JSR` aus Assembler aufgerufen, endet aber mit dem Basic-Befehl `Return` statt `RTS`. Funktioniert ohne Laufzeit-Debugger; mit Debugger prüft `Return` den Gosub-Stack. | [C] `AmiBlitz3.ab3` Z. 26912 | [§10.4](10-assembler-usage.md#104-auffälligkeiten) |
| I-30 | Grenze | `!basic`/`!asm` sichern die Register in einem festen Bereich am unteren Ende des Task-Stacks: nicht verschachtelbar, nicht interruptfest, keine Prüfung gegen Stack-Überlauf in diesen Bereich. | [C] `usefullasmmacs.ab3` | [§10.6.2](10-assembler-usage.md#1062-was-die-macros-tun) |
| I-31 | Fragil | Anwendercode hält Registerinhalte über Basic-Anweisungen hinweg (`benchgfxbus.ab3`: a4 als Arbeitsregister im Hauptprogramm). Funktioniert nur, solange die Basic-Anweisungen dazwischen das Register nicht benutzen. | [C] | [§10.4](10-assembler-usage.md#104-auffälligkeiten), [§10.6.3](10-assembler-usage.md#1063-anforderungen-an-einen-nachbau) |
| I-46 | Grenze | Asm-Blöcke, die zwischen `GetReg`/`PutReg` Werte in Registern halten, setzen voraus, dass die Brücken-Befehle alle Register außer dem Ziel erhalten (alter Compiler: `MOVEM` um die Auswertung). Ein Nachbau muss das exakt nachbilden. | [C] `do_GetReg`/`do_PutReg` | [§10.6.3](10-assembler-usage.md#1063-anforderungen-an-einen-nachbau) |
| I-32 | Doku | `GetReg` wird in generierten Includes auch mit Adressregistern benutzt (`GetReg a6,*_AmiSSLMasterBase`); die BPG sagt „only data registers“. | [C] | [§10.3](10-assembler-usage.md#103-wrapper-macros-für-os-libraries) |
| I-33 | Fragil | `all.res` enthält Token-Wörter alter Lib-Nummern (`$B58D`, `$B593`, `$DC86`, `$DC87`), die nur über die von den Libs registrierte Tabelle `replacedat` auf aktuelle Tokens abgebildet werden. Fehlt eine Lib, sind die betroffenen Macros defekt. | [V] `res_macros.py` | [§6.1.1](06-macros.md#611-macros-in-resident-dateien) |
| I-34 | Unklar | Argumenttyp `8` bedeutet in `libmacs.ab3` sowohl `#double` (neu in AB3) als auch das Flag `#unknown`. | [C] | [§9.2.2](09-blitzlibs.md#922-token-einträge) |

## 11.6 IDE (PED)

| ID | Einstufung | Problem | Beleg | Status |
|---|---|---|---|---|
| I-35 | Bug | ARexx `LOAD`/`LOADNEW` benutzen veraltete globale Lade-Flags; die Datei wird geladen, aber nicht sichtbar in einen Tab übernommen. | [V] Runde 4 | **behoben** im Branch `compiler-spec` (`4f450f13`) |
| I-36 | Bug | ARexx `MAKEEXEC` öffnet immer den Datei-Requester; Compilerfehler öffnen einen modalen Requester, der ARexx-Skripte blockiert. | [V] Runde 4 | **behoben** im Branch `compiler-spec` (neue Befehle `MAKEEXEC <datei>`, `ERRORREQ`, `LASTERROR`) |
| I-37 | Grenze | Der ARexx-Port wird nur angelegt, wenn RexxMast beim Start von PED schon läuft. | [V] Runde 4 | [§7.1.1](07-verification.md#711-ide-tests-per-arexx) |

## 11.7 Dokumentation

| ID | Einstufung | Problem | Details |
|---|---|---|---|
| I-38 | Doku | Keyword-Schreibweise in Beispielen falsch (`MACRO`, `End MACRO`, `UsePath`, `DefType`, `Nprint`); die Beispiele lassen sich nicht übersetzen. | [B1](08-doc-differences.md#b1-schreibweise-der-keywords) |
| I-39 | Doku | Regeln für Namen in der BPG veraltet (erlaubte Zeichen, Präfix-Regel); kleingeschriebene Keywords nicht dokumentiert. | [B4](08-doc-differences.md#b4-namen-von-variablen-und-labels) |
| I-40 | Doku | Escape-Sequenzen: Datum mit `.` statt `/`, `\\n` ist LF, „two slash characters“ meint Backslashes, `\\R` dezimal. | [B5](08-doc-differences.md#b5-escape-sequenzen) |
| I-41 | Doku | „Macros brauchen kein `{}`“ gilt nur im New-Syntax-Modus und nur für Macros mit Parametern. | [B6](08-doc-differences.md#b6-macros-ohne-) |
| I-42 | Doku | ARexx-Port heißt `PED.1`, nicht `PED_1`; neue ARexx-Befehle fehlen. | [B7](08-doc-differences.md#b7-arexx-port) |
| I-43 | Doku | `!version` ist eine Anweisung mit Parameter, kein String. | [B8](08-doc-differences.md#b8-version-aus-allres) |
| I-44 | Doku | `:@` benötigt keinen New-Syntax-Modus (Doku: `OPTIMIZE 4`). | [A8](08-doc-differences.md#a8--im-kommentar) |
| I-45 | Repo | `Docs/Amiblitz3.guide` wurde im Merge `5dd815f8` mit CRLF committet, obwohl `.gitattributes` LF verlangt; die Datei erscheint nach jedem Checkout als geändert. | **behoben** im Branch `fix-guide-eol` (`043dc10d`) |
