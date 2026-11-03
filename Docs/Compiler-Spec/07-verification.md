# 7 Verifikation

Aussagen mit **[?]** oder **Quirk** werden mit dem Originalcompiler (CLI-Modus)
in Amiberry geprüft. Die Probe-Programme liegen in
[verification/probes/](verification/probes/); jedes gibt Zeilen der Form
`<Test-ID> <Ergebnis>` aus. `verification/make_run_script.py` erzeugt das
AmigaDOS-Skript `run.script`, das die Probes übersetzt, ausführt und die
Ausgaben nach `verification/results/` schreibt:

```
results/<probe>.compile.txt   Compilerausgabe (Fehlermeldungen, Warnungen)
results/<probe>.run.txt       Ausgabe des übersetzten Programms
results/tokens.txt            Token-Tabelle (-dump token)
results/progress.txt          zuletzt begonnene Probe
results/done                  Ende-Markierung
```

Die Ergebnisse der bisherigen Läufe liegen in `results/round1/` bis
`results/round3/` (CLI) sowie `results/round4-ide/` und `results/round5-ide/` (IDE); der gcc-Machbarkeitstest steht in `results/round9-spike/` (siehe [10.7](10-assembler-usage.md#107-machbarkeitstest-asm-block-in-einem-gcc-backend)). Runde 14 (`results/round14/`) enthält Nachprüfungen, u. a. zu `@@`, Includes und `CNIF @`.

## 7.1 Testumgebung

* Amiberry (`amiberry --config ~/Amiberry/Configurations/A1200-AB3.uae -G`):
  A1200/AGA, Kickstart 3.1 (47.115), Workbench 3.2, **68020 + 68882**,
  CPU-Geschwindigkeit maximal, JIT (16 MB Cache), 8 MB Chip-RAM,
  128 MB Z3-Fast-RAM.
* `AB3:` = `~/Projekte/AmiBlitz/AmiBlitz3-Original` (eigene Kopie des
  Repositorys, Commit `6efd21ef`, damit der Compiler das Arbeitsverzeichnis
  nicht verändert).
* `SPEC:` = `Docs/Compiler-Spec/verification` (lesen/schreiben).
* `S:User-Startup` führt `SPEC:run.script` aus, falls vorhanden.
* Ein kompletter Lauf (Booten + ~25 Probes) dauert ca. 20 s.

Ablauf auf dem Host:

1. `python3 make_run_script.py [probe …] > run.script`
   (ohne Argumente: alle Probes außer Include-Teildateien).
2. Amiberry starten, auf `results/done` warten, Amiberry beenden.

**Ohne Fenster (Runde 14):** Amiberry lässt sich unsichtbar betreiben, wenn
`DISPLAY`, `WAYLAND_DISPLAY`, `XDG_ACTIVATION_TOKEN` und `DESKTOP_STARTUP_ID`
entfernt und `SDL_VIDEO_DRIVER=offscreen`, `SDL_AUDIO_DRIVER=dummy` gesetzt
sind, mit `use_gui=no` in der Konfiguration. Runde 14 lief so auf einer
A1200-Konfiguration (68020 + 68882, Workbench 3.2). Die Verzeichnisse wurden
als Volumes `AB3:` und `SPEC:` eingehängt, und das Startskript war
`Assign Blitz3: AB3:` gefolgt von `Execute SPEC:run.script`. Achtung: Die
gespeicherte Konfiguration `A1200-AB3.uae` muss `SPEC:` auf **dieses**
Verzeichnis zeigen lassen, sonst schreibt der Lauf woanders hin.

`make_run_script.py` schreibt seit Runde 14 hinter jede Übersetzung den
Rückgabewert (`rc=…`) in die `.compile.txt`. Proben in `SAVE_ONLY` werden nur
mit `-save` tokenisiert (Ergebnis `results/<probe>.bb2`, siehe
[03-tokenizer.md §3.2](03-tokenizer.md#32-token-tabelle)).

### 7.1.1 IDE-Tests per ARexx

Die IDE lässt sich über ihren ARexx-Port fernsteuern (`ped_test.rexx`, von
`run.script` gestartet):

* Der Port heißt **`PED.1`** (Code: `PED_arexx.ab3` Z. 172 ff.), nicht
  `PED_1` wie in der Guide. PED legt ihn nur an, wenn beim Start RexxMast
  läuft → `Run >NIL: SYS:System/RexxMast`, `WaitForPort REXX`, dann
  `Run >NIL: AmiBlitz3 -PED`, `WaitForPort PED.1`.
* Seit der Korrektur in PED (Arbeitskopie vom 25.10.2026) funktioniert der Ablauf
  ohne Benutzereingriff:
  * `ERRORREQ OFF` – Compilerfehler von ARexx-Befehlen öffnen keinen
    Requester mehr,
  * `LOAD <datei>` – lädt wie der Menüpunkt in einen Tab und zeigt die Datei an,
  * `MAKEEXEC <datei>` – erzeugt das Executable ohne Datei-Requester,
  * `LASTERROR` – liefert den Text des letzten Compilerfehlers.
* Ohne diese Korrektur öffnet `MAKEEXEC` immer einen Datei-Requester, und jeder
  Compilerfehler einen modalen Requester, der den Lauf blockiert.

## 7.2 Ergebnisse

Legende: ✔ = Vorhersage aus der Codeanalyse bestätigt, ✘ = Vorhersage falsch
(Spezifikation korrigiert), ◐ = teilweise.

### Tokenizer

| ID | Probe | Ergebnis | |
|---|---|---|---|
| V-TOK-0 | `-dump token` | 4653 Tokens, 233 Libs | ✔ |
| V-TOK-7 | tokens.txt | Namen: Buchstaben, Ziffern, `_ $ . #`; **325 kleingeschriebene** | ◐ |
| V-EOF-1 | eof_nolf | `End` am Dateiende: nicht aussagekräftig | – |
| V-EOF-2 | r2_eof_nolf | `EndIf` ohne LF nicht tokenisiert → „'If' without 'End If'“ | ✔ |
| V-MAC-NAME-2 | r2_mac_negname | `Macro neg` → Syntaxfehler (`neg` ist Token 217/63) | ✔ |

### Lexik

| ID | Probe | Ergebnis | |
|---|---|---|---|
| V-WS-1a–c | whitespace | `12 34` = 1234, `$F F` = 255, `% 1 0 1` = 5 | ✔ |
| V-NAME-2 | whitespace | `d .w`, `e .l = 9` funktionieren | ✔ |
| V-NUM-e | whitespace | `1.5e2` = 150, `2E+1` = 20, `.25` | ✔ |
| V-CHR-1/2 | charlit | `494C424D`, `4142` | ✔ |
| V-TILDE-1, V-NAME-3 | names | `a~b`, `c#d` sind gültige Variablennamen | ✔ |
| V-PATH-1 | usepath | `3 4` | ✔ |
| V-PATH-2 | tokens.txt | Kommando heißt `USEPATH2` | ✔ |
| V-INC-1 | include_main | `#__include`: 0 / 1 / 0 (Doku: −1) | ✔ |

### Kommentare

| ID | Probe | Ergebnis | |
|---|---|---|---|
| V-CMT-1 | comment_code | `a = 1 ; c :@ a = 2` → a = 1 (ignoriert) | ✘ |
| V-CMT-1ns | comment_code_ns | dto. mit `OPTIMIZE 4` | ✘ |
| V-CMT-2 | comment_keyword | Keyword hinter `:@` nicht tokenisiert → „Garbage at the end of line“ | ✔ |
| V-CMT-3 | r2_cmt_contexts | `:@` in Kommentar am Zeilenanfang → ausgeführt | ✔ |
| V-CMT-4 | r2_cmt_contexts | `:@` nach `NPrint "x" ;` → ausgeführt | ✔ |
| V-CMT-5 | r2_cmt_contexts | `:@` nach Zuweisung → ignoriert | ✘ |

### Escape-Sequenzen

| ID | Probe | Ergebnis | |
|---|---|---|---|
| V-ESC-0a/b | esc_newsyntax | `[\41]` / `[A]` – zwei Backslashes nötig | ✔ |
| V-ESC-3a–d | esc_newsyntax, r2_esc_rep | `\\R05*` → 6×, `\\R12-` → 13×, `\\R01*` → `**`, `\\R03ab` → `AAAab` | ✘ (n+1, Großbuchstaben) |
| V-ESC-n | esc_newsyntax | Zeilenumbruch | ✔ |
| V-ESC-6a/b | esc_newsyntax | `[\\]`, `[\\41]` | ✔ |
| V-ESC-hx | esc_newsyntax | `[NNJ]` | ✔ |
| V-ESC-ci | esc_newsyntax | `\\__ver_major` → `1` | ✔ |
| V-ESC-vr | esc_newsyntax | `[1.2.3/42]` | ✔ |
| V-ESC-vu | esc_newsyntax | `[{unknown compiler constant}]` | ✔ |
| V-ESC-tf/tp | esc_newsyntax | `[GLOBALXY]`, `[GLOBALBCD]` | ✔ (feste Länge 15) |
| V-ESC-dt/dg | esc_newsyntax | `10.25.2026`, `25.10.2026` | ✔ |
| V-ESC-cl | esc_newsyntax | `17` = Zeile ohne XTRA-Header | ✔ |
| V-ESC-fn | esc_newsyntax | `[st]` | ✔ |
| V-ESC-cls | esc_classic | `[\\41]` (keine Escapes ohne New-Syntax) | ✔ |
| V-ESC-5 | esc_unknown | `[QQ]ABC"qq]abc` + Warnung (2×) | ✔ |
| V-ESC-7 | esc_empty | kein Absturz; String enthält NUL (`[` + NUL) | ◐ |

### Bedingte Kompilierung

| ID | Probe | Ergebnis | |
|---|---|---|---|
| V-CNIF-3a–d | cnif | `@#X` definiert = 1 (nicht −1) | ✔ |
| V-CNIF-4 | cnif | CNIF mitten in der Zeile: `a`, `c` | ✔ |
| V-CNIF-5 | cnif | doppeltes CELSE → `two` | ✔ |
| V-CNIF-6 | cnif | `CEND` im Kommentar zählt nicht | ✔ |
| V-CSIF-1–3 | cnif | `<`, Präfix-`<`, `><` | ✔ |

### Macros

| ID | Probe | Ergebnis | |
|---|---|---|---|
| V-MAC-cnt | r2_macros | `00 01 02 03 02 02 01` | ✔ |
| V-MAC-uq | r2_macros | `0 1 2` | ✔ |
| V-MAC-sp | r2_macros | New-Syntax: `[ x | y ]` – Leerzeichen hinter `{` bleiben | ✘ |
| V-MAC-sp-cls | r3_mac_classic_space | klassisch: `[x | y ]` | ✔ |
| V-MAC-sp2 | r2_macros | `[ (a , b) ]` | ✔ |
| V-MAC-then | r2_macros | `after` / `yes`, `after` | ✔ |
| V-MAC-ev | r2_macros | `` `{1+1} `` → `q` | ✔ |
| V-MAC-let | r2_macros | `` `a`b`y `` → `AB` | ✔ |
| V-MAC-pc | r2_macros | `` `: `` → `02` | ✔ |
| V-MAC-neg | r2_macros | `!ng -5` → `-5`, `!ng $10` → `16` | ✔ |
| V-MAC-hc | r2_macros | Kopfkommentar entfernt | ✔ |
| V-MAC-DEF-3 / AE-1 | r2_macros, r3_mac_after_end | Code hinter `End Macro` wird **ignoriert** | ✘ |
| V-MAC-nest / AE-2 | r2_macros, r3_mac_after_end | Rest des äußeren Rumpfs nach innerem `End Macro` geht verloren | ✘ |
| V-MAC-CALL-7 | macro_braces_noparam | `!e{}` (Rumpf ohne `` ` ``, New-Syntax) → Syntaxfehler bei `{}` | ✔ |
| V-MAC-cls | macros_classic | `00 01 01 02`, `!e{}` ok | ✔ |
| V-MAC-TOK-1 | macro_tok | keine Neu-Tokenisierung | ✔ |
| V-MAC-NAME-1 | macro_case | Namen case-sensitiv | ✔ |
| V-MAC-DEF-4 | macro_comment_body | `:@` im Rumpf: kein Fehler, Code ignoriert | ✘ |
| V-MAC-ARG-4 | macros_ns, r2_mac_argjoin | `@@` in Argumenten: Folgezeile wird doppelt übersetzt → Fehler | ✘ |
| V-MN-1–5,7 | r3_mac_multiline | mehrzeilige Macros in Ausdrücken: `9 3 25 16 5` | ✔ |
| V-MN-6/7 (einzeilig) | r2_mac_nest* | einzeilige Form mit ` : End Macro` in Ausdrücken → Klammerfehler | ✘ |
| V-MN-8 | r3_mac_oneline_nospace | `…)):End Macro` ohne Leerzeichen → ok | ✔ |
| V-MAC-TR | r3_mac_trailing | einzeiliges Macro gefolgt von `,"|"` → Syntaxfehler | ✔ |

### Zeilenfortsetzung `@@`

| ID | Probe | Ergebnis | |
|---|---|---|---|
| V-JOIN-1/2/5 | join | Hauptdatei (New-Syntax): Syntaxfehler | ✘ |
| V-JOIN-4 | join_classic | Hauptdatei (klassisch): Syntaxfehler | – |
| V-JOIN-3 | join_inc_main | Include: funktioniert (`ab`) | ✘ |
| V-JOIN-6a | ide/ide_join (IDE) | Hauptdatei in der IDE: ebenfalls „Syntax error“ | ✘ |
| V-JOIN-6b | ide/ide_argjoin (IDE) | `@@` in Macro-Argumenten: wie im CLI „Garbage at the end of line → b}“ | ✘ |

### Runde 6: Restpunkte

| ID | Probe | Ergebnis | |
|---|---|---|---|
| V-MAC-DEF-5 | r6_mac_endx | `End d0` im Rumpf schneidet den Rumpf ab → „'If' without 'End If'“ | ✔ |
| V-MAC-DEF-6 | r6_mac_strjoin | `@@` in einem String im Rumpf verbindet Zeilen → „No terminating quote“ | ✔ |
| V-EMPTY-1–4 | r6_empty | leere Anweisungen in allen Varianten erlaubt | ✔ |
| V-LONG-1 | r6_longline | Hauptdatei, 300-Zeichen-String → „No terminating quote“ (Kürzung auf 250) | ✔ |
| V-LONG-2 | r6_longline_inc | Include: 300 Zeichen werden vollständig verarbeitet | ✔ |
| V-LONG-3 | r6_longline_tok | Kürzung nach tokenisierter Länge (mitten im 2. String) | ✔ |
| V-RES-1 | r6_res_macros | `-dump macro` mit `all.res`: 244 Macros, darunter `version`; `NPrint !version` → „Syntax error!“, weil `version` eine Anweisung ist (§6.1.1) | ✔ |
| V-RES-2 | r7_version | `!version{"SpecProbe 1.2 (25.10.2026)"}` → `$VER:`-String im Executable, `Version` liest ihn | ✔ |
| V-RES-3 | `tools/res_macros.py` | Extraktion aus `all.res`: 244 Macros, Namen identisch mit `-dump macro`; 4 unbekannte Token-Wörter (alte Lib-Nummern) | ✔ |

### Runde 8: Beispiele aus der Dokumentation

Wörtlich übernommene Beispiele aus `BlitzProgrammers.guide` (BPG) und
`Amiblitz3.guide` (AB3G); Auswertung in [08-doc-differences.md](08-doc-differences.md).

| ID | Probe (`probes/docs/`) | Ergebnis | |
|---|---|---|---|
| D-BPG-1 | bpg_mymacro | wie beschrieben (`a=2`) | ✔ |
| D-BPG-2 | bpg_distance | `36.05551` | ✔ |
| D-BPG-3 | bpg_vadd_ok | `!Vadd{a,b}` → `a=3` | ✔ |
| D-BPG-3b | bpg_vadd_err | CERR-Text zu „Illegal number of 01Vadd01Parameters“ verstümmelt, Folgefehler | ✘ |
| D-BPG-4 | bpg_dolist | rekursives Macro, 9 Werte | ✔ |
| D-BPG-5 | bpg_project | `317`, `250` | ✔ |
| D-BPG-6 | bpg_cmake | `var~`1~` → „Garbage at the end of line“ | ✘ |
| D-BPG-7 | bpg_names | Name mit führendem `_` | ✔ |
| D-BPG-8 | bpg_usepath_case | `UsePath` (statt `USEPATH`) → Fehler | ✘ |
| D-BPG-9 | bpg_exp | `3e8` → `3E+8` | ✔ |
| D-AB3G-1 | ab3g_macros_verbatim | `MACRO`/`End MACRO` → nicht erkannt, 5 Fehler | ✘ |
| D-AB3G-2 | ab3g_macros_case | mit `Macro`: „Syntax error!“ (Rumpf endet auf `:`) | ✘ |
| D-AB3G-3 | ab3g_esc_r09 | `\\R09a` → `AAAAAAAAAa` | ✘ |
| D-AB3G-4 | ab3g_debug_const | `#__debug` = 0 (ohne Debugger) | ✔ |
| D-AB3G-5 | ab3g_optional_noparam | `!hello{}` → „Syntax error! → {}“ | ✘ |

### Runde 14: Nachprüfungen

Nachprüfung weiterer Aussagen aus der Codeanalyse und von Widersprüchen zu
früheren Runden (`probes/r14_*`,
`results/round14/`).

| ID | Probe | Ergebnis | |
|---|---|---|---|
| V-JOIN-7a/7b | r14_join_plain | Hauptdatei ohne `OPTIMIZE`, Folgezeilen eingerückt: `bc` (alle drei Teile), `Str$(@@` ⏎ `3)` → `3` | ✘ (widerlegt V-JOIN-1/4 als allgemeine Aussage) |
| V-JOIN-7c | r14_join_hdr | dto. mit XTRA-Header: `bc` | ✘ |
| V-JOIN-7d | r14_join_col0 | Folgezeile in Spalte 0 → „Syntax error!“ | ✔ (Ursache der früheren Fehler) |
| V-JOIN-7e/7f | r14_join_ns | `OPTIMIZE 4`: Parameterliste ok, `1 + @@` ⏎ `··2` → „Syntax error!“ | ◐ |
| V-JOIN-7g | r14_join_noparam | `NPrint "a" @@` ⏎ `··,"b"` → `ab` | ✔ |
| V-JOIN-7h | r14_join_inc_main | dto. in einem Include → „Joining lines with @ @ does not work in includes“ | ✔ |
| V-JOIN-7j | r14_join_first | eine Leerstelle Einrückung genügt (`b`) | ✔ |
| V-JOIN-7k | r14_join_macro | `!mk` in Spalte 0 → „Garbage at the end of line → mk“ (das `!` fehlt) | ✔ |
| V-MAC-ARG-5 | r14_mac_argjoin | `!cnt{a,@@` ⏎ `··b}` → „Garbage at the end of line → b}“ | ✔ |
| V-CNIF-7 | r14_cnif_at | `CNIF @#zq + #zq = 2`, `CNIF @#zq + #zr = 1` wahr, `CNIF @#zr` falsch | ✔ |
| V-CNIF-8 | r14_cnif_at_err | `CNIF #zq + @#zq = 6` → „Illegal constant expression“ (auch in den Folgezeilen) | ✔ |
| V-LONG-4 | r14_longline | nach einer Zeile mit 260-Zeichen-Kommentar fehlen alle weiteren Zeilen („2 line(s) compiled“) | ✘ |
| V-INC-2 | r14_inc_nolf_main | Include ohne letzten Zeilenumbruch: letzte Zeile fehlt | ✘ |
| V-INC-3 | r14_inc_h | `INCLUDE "r14_defs.h"` → „You can only include tokenized files (.bb2 \|.bb)“ | ✔ |
| V-INC-4 | r14_inc_bb | Textdatei `r14_text.bb` als tokenisiert gelesen → „Garbage at the end of line“ | ✔ |
| V-INC-5 | r14_xinc | `XINCLUDE` „x.ab3“, `XINCLUDE` „x“, 2× `INCLUDE` „x.ab3“ → 3 Ausgaben | ✔ |
| V-TOK-8 | r14_save | `-save`: tokenisierte Zeilen; `execbase`, `show2` bleiben Namen | ✔ |
| V-CLI-RC | alle | Rückgabewert 0 auch nach Compilerfehlern | ✘ (I-52) |

## 7.3 Offene Punkte

* Abbildung alter Token-Wörter (`replacedat`, von den Bibliotheken registriert) – wird für Resident-Dateien gebraucht; ein Export fehlt noch (z. B. als zusätzliche `-dump`-Option).
* Ursache für „Code hinter `End Macro` wird ignoriert“ im Code nachvollziehen.
* `.bb2`-Eingabe und `~…~` aus `.bb2` (keine Testdatei vorhanden).
* `@@` innerhalb eines Strings außerhalb von Macro-Rümpfen (§4.11).
* Eigene Definition von `#__debug`/`#__include` im Quelltext (§5.3.1).
* Relocations in `BSS`/`Chip`-Abschnitten (I-54) im Original prüfen.
