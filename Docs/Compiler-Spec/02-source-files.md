# 2 Quelldateien und Zeilenstruktur

## 2.1 Dateiformate

| Endung | Inhalt | Tokenisierung beim Laden |
|---|---|---|
| `.ab3` | ASCII-Text, Einstellungen im eingebetteten XTRA-Header | ja (L1) |
| `.ab2` | ASCII-Text, Einstellungen in separater Datei `<name>.ab2.xtra` | ja (L1) |
| `.bb2`, `.bb` | bereits tokenisierter Text (BlitzBasic 2), Einstellungen in `<name>.bb2.xtra` | nein |
| jede andere | wie `.ab3` behandelt | ja |

**[C]** `LoadSource` (CLIModeSupport.ab3 Z. 437 ff.). Die Endung wird
case-insensitiv verglichen.

> Hinweis: In `.bb2`-Dateien hängen die Token-Wörter von den beim Speichern
> geladenen Bibliotheksnummern ab („Lib-Clash“). Ein Nachbau, der `.bb2`
> unterstützen will, benötigt dieselbe Token-Tabelle wie das Original
> (siehe [03-tokenizer.md §3.7](03-tokenizer.md#37-token-tabelle)).

## 2.2 XTRA-Header

Der XTRA-Header besteht aus Kommentarzeilen am Dateianfang, beginnend mit
`; XTRA` und endend mit `; /XTRA`. Er enthält Projekteinstellungen
(`ExeFile`, `StringBuffer`, `Version`, `Residents`, `Max <Objekt>` …) und ist
für die Syntax ohne Bedeutung – mit zwei Ausnahmen, die sich auf den Inhalt
von String-Literalen auswirken: `Version` und `NumberOfBuilds` liefern die
Werte der Escapes `\\__VER_*` (siehe [04-lexical.md §4.5.2](04-lexical.md#452-escape-sequenzen)).

Es gibt zwei unterschiedliche Erkennungsalgorithmen:

### 2.2.1 Hauptquelltext (`ParseAB3Header`)

**[C]** ```
offset := 0
für jede Zeile L der Datei (bis /XTRA gefunden oder Dateiende):
    key := alle Zeichen aus L vor dem ersten "=", die in [A-Za-z_/-] liegen
           ("-" wird zu Leerzeichen)
    wenn lower(key) = "/xtra":  offset := Position nach dieser Zeile; Ende
    sonst: Einstellung key = value übernehmen
```

Die Kommentarzeichen `;` werden dabei einfach ignoriert (sie fallen aus dem
Schlüssel heraus). **Quirk:** Fehlt die Zeile `/XTRA`, so wird die gesamte
Datei als Header gelesen (Zeilen mit `=` können Einstellungen verändern), und
der Text wird ab Offset 0 kompiliert.

### 2.2.2 Include-Dateien (`SkipXtraHeader`)

**[C]** ```
pos := 0; zeileHatKommentar := falsch
solange pos < Länge:
    c := byte[pos]
    c = ";"  → zeileHatKommentar := wahr; pos += 1
    c = LF   → wenn nicht zeileHatKommentar: return 0     (kein Header)
               sonst zeileHatKommentar := falsch; pos += 1
    c = "/"  → wenn die 4 folgenden Bytes "xtra", "XTRA" oder "Xtra" sind:
                   pos hinter das nächste LF setzen; return pos
               sonst pos += 1
    sonst    → pos += 1
return 0
```

Ein Header wird also nur erkannt, wenn **jede** Zeile vor `/XTRA` ein `;`
enthält.

## 2.3 Zeilen

1. Der (headerlose) Text wird als Ganzes tokenisiert (L1). Dabei wird jedes
   `LF` ($0A) und jedes `NUL` ($00) zu einem `0`-Byte (Zeilenende); `CR` ($0D)
   wird entfernt. **[C]** `preproc_Tokenize`.
2. Der tokenisierte Text wird an den `0`-Bytes in Zeilen zerlegt.
3. Hauptquelltext (CLI-Modus): Eine tokenisierte Zeile, die einschließlich
   Terminator länger als 250 Bytes (`#MAX_Columns`) ist, wird auf 250 Bytes
   gekürzt – ohne Warnung. Maßgeblich ist die **tokenisierte** Länge (Keywords
   zählen 2 Bytes). **[C]** `LoadSource`, **[V]** V-LONG-1/3: ein
   300-Zeichen-String ergibt „No terminating quote“. Die IDE (PED) hat eine
   entsprechende Begrenzung im Editor. Für Include-Dateien gibt es **keine**
   Kürzung. **[V]** V-LONG-2 (300 Zeichen werden vollständig ausgegeben).
4. Fehlt am Dateiende der Zeilenumbruch, so wird die letzte Zeile trotzdem
   übernommen. **Quirk:** Das letzte Wort einer solchen Zeile wird vom
   Tokenizer nicht in ein Token umgewandelt (siehe
   [03-tokenizer.md §3.4](03-tokenizer.md#34-algorithmus)).

Zeilennummern zählen physische Zeilen ab 1 **nach** dem XTRA-Header (Fehlermeldungen
und `\\__CODELINE`). **[V]** V-ESC-cl, V-EOF-2.

## 2.4 INCLUDE / XINCLUDE

`INCLUDE "datei"` und `XINCLUDE "datei"` (Letzteres nur einmal pro Datei) fügen
die Zeilen der Datei an dieser Stelle in den Zeilenstrom ein. Die eingefügte
Datei durchläuft L0 (Algorithmus 2.2.2) und L1 genauso wie der Hauptquelltext.
Suchreihenfolge für den Dateinamen **[C]** `check_incdir`:

1. Include-Verzeichnis der Konfiguration (`INCLUDEDIR`, Standard
   `Blitz3:Sourcecodes/Includes`) + Name
2. Verzeichnis des Hauptquelltexts + Name
3. Verzeichnis der aktuell einbindenden Include-Datei + Name
4. Include-Verzeichnis + reiner Dateiname (ohne Pfadanteil)

Für jeden Kandidaten werden nacheinander probiert: der Name selbst, dann
Endung ersetzt durch `.ab3`, `.ab2`, `.bb2`, dann Name + `.<alte Endung>.ab3`,
`.ab2`, `.bb2`. **[C]** `ab3_GetIncludeLock`.

Die Konstante `#__include` ist im Hauptquelltext `0` und während der
Verarbeitung einer Include-Datei `1` (nach dem Verlassen der letzten
Include-Ebene wieder `0`). Die Dokumentation nennt `-1`; das ist falsch.
**[C]** Z. 20803–20810, **[V]** V-INC-1.

INCLUDE-Verarbeitung im Detail (Zeitpunkt, Pfade, Verschachtelung) gehört zum
Parser und ist hier nur so weit beschrieben, wie sie den Zeilenstrom betrifft.
