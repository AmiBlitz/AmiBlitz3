# 9 BlitzLib-Format

BlitzLibs sind die Laufzeitbibliotheken von AmiBlitz: fertiger 68k-Code mit
einer Beschreibung jedes Befehls (Name, Parameter, benötigte Register,
Einsprungadressen). Aus ihnen stammen alle Keywords außer den fest im
Compiler eingebauten (Lib 0 und 1), siehe [03-tokenizer.md](03-tokenizer.md#32-token-tabelle).
Für einen Nachbau sind sie in zweifacher Hinsicht wichtig: als **Quelle der
Token-Tabelle** und als **Code, der in jedes Programm eingebunden wird**.

**Quellen:**

* Macros zum Schreiben einer Lib: `Sourcecodes/Amiblitz3/BlitzLibs/Residents/blitzbasic/libmacs.ab3`
  (übersetzt als `BlitzLibs/Residents/libmacs.res`)
* Lib-Nummern: `…/blitzbasic/libnums.ab3`, Einsprünge für `ALibJsr`: `…/blitzbasic/libjsrs.ab3`
* Quelltexte von 141 Libs: `Sourcecodes/Amiblitz3/BlitzLibs/Blitzlibs/*.ab3`
* Compiler: `load_biglibsfile` (Z. 9353), `process_libraries` (Z. 9505),
  `findlib`/`searchinstr` (Z. 9234/9263), `uselib` (Z. 8740), `fixjsrs`/`tokecode` (Z. 8920/8966)

**Werkzeug:** `verification/tools/biglib_dump.py` liest BigLib-Dateien nach
diesem Kapitel. **[V]**: Für die 232 normalen Libs der Distribution erzeugt es
alle 4435 Token-Einträge mit identischem Namen **und** identischer Nummer wie
`AmiBlitz3 -dump token` (`results/blitzlibs/biglibs-tokens.txt`). Eine
vollständige Auflistung aller 257 Libs mit Headern und Aufrufformen steht in
`results/blitzlibs/biglibs-detail.txt`.

## 9.1 Dateien

Die Libs liegen in vier **BigLib-Dateien** im Verzeichnis `BlitzLibs/`:
`baseLibs`, `utilLibs`, `OsLibs`, `csLibs` (Pfade per Tooltype änderbar)
sowie optional einzeln in `BlitzLibs/UserLibs/`. **[C]**

Eine BigLib-Datei ist eine Folge von Einträgen, abgeschlossen durch ein
Langwort 0:

```
biglib    = *( size.l lib-exe ) %x00000000
lib-exe   = AmigaOS-Hunk-Executable mit genau einem HUNK_CODE,
            danach HUNK_RELOC32 (Offsets in den eigenen Hunk),
            optional HUNK_SYMBOL/HUNK_DEBUG, HUNK_END
```

Jede Lib ist also ein eigenständig übersetztes Programm. Der Compiler wertet
die Hunk-Struktur nicht allgemein aus, sondern verlässt sich auf das feste
Layout: Code-Daten ab Offset 32 des Executables, die Relocations unmittelbar
dahinter. **[C]** `load_biglibsfile`

## 9.2 Aufbau einer Lib

```
+0     Header (48 Bytes)            !libheader / !syslibheader
+$30   Token-Einträge               !dumtoke, !astatement…!name, !nullsub
       Abschluss                    !libfin
       Code der Routinen
+error Fehlerprüf-Routinen          nur bei eingeschaltetem Debugger eingebunden
```

### 9.2.1 Header

Der Header beginnt mit `MOVEQ #0,d0 : RTS`, damit die Lib als Programm
gestartet sofort endet. Einige Felder überschreibt der Compiler beim Laden
mit eigenen Verwaltungsdaten (Spalte „im Speicher“). **[C]**

| Offset | Größe | Quelle (`libheader` / `syslibheader`) | im Speicher (Compiler) |
|---|---|---|---|
| $00 | 4 | `MOVEQ #0,d0 : RTS` | Zeiger auf die nächste Lib |
| $04 | 2 | Lib-Nummer (`libnum`) | unverändert |
| $06 | 4 | 0 | Größe der Lib in Bytes |
| $0A | 2 | 0 | Offset der globalen Variable für den Init-Rückgabewert; `uselib` bindet nur ein, wenn hier −1 steht – wo der Wert gesetzt wird, ist nicht geklärt **[?]** |
| $0C | 2 | 0 / `flags` (nur `syslibheader` mit 8 Parametern) | Bit 7: eingebunden; Bit 6: in konstanten Ausdrücken zulässig |
| $0E | 2 | 0 / erstes Token | erstes Token der Lib |
| $10 | 2 | 0 / letztes Token + 1 | letztes Token + 1 |
| $12 | 4 | 0 | Offset hinter den Token-Einträgen (= Code-Beginn) |
| $16 | 4 | `init` – Offset der Init-Routine (0 = keine) | |
| $1A | 2 | `return` – Init liefert einen Wert: 0 nein, 1 Langwort, −1 Wort | |
| $1C | 4 | `finit` – Offset der Aufräum-Routine (0 = keine) | |
| $20 | 4 | 0 | Anzahl der Relocations |
| $24 | 4 | 0 | Zeiger auf die Relocations |
| $28 | 4 | 0 | Adresse der Lib im erzeugten Programm |
| $2C | 4 | `error` – Offset, ab dem die Fehlerprüf-Routinen stehen (0 = keine) | |
| $30 | … | Token-Einträge | |

**Lib-Nummern** **[C]** `libnums.ab3`:

* **Normale Libs:** 1–255. Ihre Token-Wörter sind `$8000 | libnum·128 + i`,
  wobei *i* bei 1 beginnt und für jeden Token-Eintrag (auch `!nullsub` und
  `!dumtoke`) um 1 steigt. Pro Lib sind damit höchstens 127 Einträge möglich.
* **System-Libs:** als Wort ≥ `$8000` (z. B. `#strings1lib = 65235`). Sie
  haben keine Namen und werden nur vom Compiler selbst aufgerufen; ihr
  Token-Bereich steht im Header (`$0E`/`$10`), z. B. `$C600` für strings1lib,
  `$CD00` für datalib. Die Distribution enthält 25 System-Libs.

Gesucht wird ein Token über den Bereich `[$0E, $10)`; für normale Libs setzt
der Compiler diese Felder beim Laden. **[C]** `searchinstr`

### 9.2.2 Token-Einträge

Ab Offset `$30` folgen die Einträge, bis ein Wort mit gesetztem Bit 15 kommt
(`!libfin` beginnt mit `Dc -1`). Jeder Eintrag beginnt mit drei Wörtern
`art, 0, 0`. **[C]** `process_libraries`, **[V]** `biglib_dump.py`.

```
eintrag      = befehl / dumtoke / nullsub
befehl       = art.w 0.w 0.w 1*form namensblock         ; !astatement … !name
dumtoke      = %x0008 0.w 0.w namensblock               ; !dumtoke
nullsub      = art.w 0.w 0.w libs subs                  ; !nullsub, (art & $F) = 0
form         = argkopf.w *argtyp.b [pad] libs subs      ; !args/!repargs, !libs, !subs
libs         = *( libnum.w regcode.w ) %x0000           ; !libs
subs         = fehler1.l code.l fehler2.l               ; !subs{code,fehler1,fehler2}
namensblock  = %xFFFF next.l nummer.w name %x00 hilfe %x00 [pad]   ; !name
```

Bei `dumtoke` fehlt das führende `%xFFFF`; der Namensblock beginnt direkt mit
`next.l`. `pad` gleicht auf eine gerade Adresse aus. Die Felder `next.l` und
`nummer.w` sind in der Datei 0; der Compiler hängt die Namensblöcke beim Laden
zu seiner Token-Liste zusammen und trägt die Nummer ein (genau diese Liste
gibt `-dump token` aus).

**Art** (erstes Wort) **[C]** `libmacs.ab3`:

| Wert | Macro | Bedeutung |
|---|---|---|
| `1` | `!astatement` | Anweisung |
| `typ·256 + 2` | `!afunction{typ}` | Funktion mit Rückgabetyp *typ* |
| `typ·256 + 3` | `!acommand{typ}` | als Anweisung **und** Funktion nutzbar |
| `8 + 1` | `!ustatement` | Anweisung, Typ des Arguments wird auf dem Stack übergeben |
| `8 + 2` | `!ufunction` | Funktion, gewählter Typ auf dem Stack |
| `8` | `!dumtoke` | nur Name (z. B. Objektname `IconInfo` für `Use IconInfo`) |
| `0` (Bits 0–3) | `!nullsub` | Routine ohne Namen (z. B. Init-/Hilfsroutinen), belegt aber eine Token-Nummer |
| Bit 2 gesetzt | – | Altformat, von `libmacs` nicht mehr erzeugt; wird vom Compiler übersprungen |

**Typen** (Rückgabe- und Argumenttypen): 1 Byte, 2 Word, 3 Long, 4 Quick,
5 Float, 7 String, 8 Double (neu in AmiBlitz3; kollidiert mit dem Flag
`#unknown` = 8). Argumenttyp-Flags: 16 `#arrayend`, 32 `#array`, 64 `#push`,
128 `#varptr`.

**Argumentkopf:** `!args{t1,t2,…}` → Wort = Anzahl, danach ein Byte je
Argument. `!repargs{erstes,anzahl,…}` → Wort = `erstes<<12 | anzahl<<8 |
Bytes`, für sich wiederholende Argumentgruppen. Ein Befehl kann **mehrere
Formen** haben (Überladung nach Parameteranzahl), z. B. `AddAppIcon` mit 3
oder 5 Parametern.

**Registercodes in `!libs`:** Vor dem Aufruf lädt der Compiler für jedes Paar
`libnum, regcode` einen Wert, den die Lib *libnum* bereitstellt, in ein
Register:

| Bits | Bedeutung |
|---|---|
| 8–11 | Registernummer |
| 12 | 0 = Datenregister d*n*, 1 = Adressregister a*n* |
| `$FF00` | statt Register: auf den Stack legen (`#lpush`) |
| 0–1 (Modus) | 0 = Rückgabewert der Init-Routine (z. B. Library-Basis), 1 `#base` = erstes Objekt, 2 `#used` = aktuell benutztes Objekt (`Use`), 3 `#max` = eingestelltes Maximum |
| 7 (`#item`) | Objektzeiger aus der Objektnummer berechnen, die als Parameter in d*k* steht; *k* = Bits 0–2 (`#pd0`…`#pd7`) |

Beispiel (`AaronsIconLib`, Lib 62):

```
!afunction{#word}
!args{#word,#string}
!libs{#iconlib,#la6,#aaronsiconlib,#ia2|#pd0}
!subs{IInfo,0,0}
!name{"GetIconInfo","  success.w=GetIconInfo(Info#,filename$) …"}
```

ergibt laut `biglib_dump.py`: Funktion `$1F02`, Argumente Word und String,
`235:$1600` (Basis von icon.library, Lib 235, nach a6) und `62:$1280`
(Objektzeiger aus dem Parameter in d0 nach a2), Code bei `$3E4`.

**`!subs{code,fehler1,fehler2}`** speichert `fehler1, code, fehler2` als
Offsets in die Lib. `fehler1`/`fehler2` sind Prüfroutinen, die nur im
Debug-Modus aufgerufen werden (z. B. Gültigkeit der Objektnummer).

### 9.2.3 Abschluss `!libfin`

```
libfin  = %xFFFF ( %x00000000                                 ; keine Objekte
                 / toke.l load.l save.l use.l free.l 0.w max.w shift.w )
```

Ist das erste Langwort ungleich 0, ist die Lib eine **Objekt-Lib** (Screens,
Windows, Shapes, IconInfo …): `toke` zeigt auf den `!dumtoke` mit dem
Objektnamen, `use` wird bei `Use <Objekt>` aufgerufen, `free` am
Programmende; `max` ist die Standardanzahl der Objekte („Max IconInfo“ im
XTRA-Header), `shift` die Objektgröße als Zweierpotenz. `load`/`save` sind
nicht implementiert.

## 9.3 Aufrufkonvention

Für eine Routine einer normalen Lib gilt **[C]** (Kommentare in
`libmacs.ab3`, Lib-Quelltexte):

* Die Argumente stehen in **d0–d5** in der Reihenfolge von `!args`, weitere
  auf dem Stack (vor der Rücksprungadresse).
* Zusätzlich stehen die in `!libs` angeforderten Werte in den angegebenen
  Registern.
* Rückgabewert in **d0**.
* **Strings:** Argumente kommen als Zeiger auf die (nullterminierten) Zeichen
  in einem Datenregister. Ein String-*Ergebnis* schreibt die Routine ab
  `(a3)` in den String-Puffer des Programms; danach zeigt a3 auf das
  abschließende Nullbyte, und d0 enthält die Länge (`MoveString` in
  `AaronsIconLib.ab3`).
* **Weitere Register:** a5 zeigt auf die globalen Variablen, a4 auf die
  lokalen; die Init-Rückgabewerte aller Libs liegen als globale Variablen
  (Offset im Header-Feld `$0A`) relativ zu a5. Ob und welche Register eine
  Routine verändern darf, ist nicht einheitlich dokumentiert; viele Routinen
  sichern alles außer d0/a3.

### 9.3.1 Aufrufe zwischen Libs

In Lib-Code ruft `ALibJsr token[,form]` eine andere Routine auf. Der
Compiler erzeugt dafür `JSR <Langwort>` mit dem Platzhalter
`($8000 | form)<<16 | token` (`BLibJsr`: `$C000 | form`, Version für den
Blitz-Modus) und einer Relocation. **[C]** `do_ALibJsr`/`do_BLibJsr` (Z. 5092 ff.)

Beim Einbinden erkennt der Compiler solche Relocations daran, dass das
Ziel-Wort Bit 15 gesetzt hat, bindet die referenzierte Lib ebenfalls ein und
setzt die echte Adresse ein (`handlejsrs`, `fixjsrs`, `tokecode`). Die
Einsprünge der System-Libs sind in `libjsrs.ab3` als Konstanten aufgeführt
(z. B. `#localalloc = $C000`).

## 9.4 Einbinden in ein Programm

Wird ein Befehl einer Lib benutzt, bindet der Compiler die **ganze Lib** ein
(„Linking blitzlib: 187, printlib (2964 bytes)“). **[C]** `uselib`:

1. Bei einer Objekt-Lib wird `maxslib` eingebunden und Platz für die
   Objekttabelle in den globalen Variablen reserviert.
2. Der Code ab `$12` (hinter den Token-Einträgen) bis zum Ende der Lib wird
   ans Programm angehängt – **ohne** den Bereich ab `error`, wenn der
   Debugger aus ist.
3. Alle Relocations werden angepasst; Platzhalter mit Bit 15 (siehe 9.3.1)
   werden gesammelt und aufgelöst. Relocations in den Fehlerprüf-Routinen
   entfallen ohne Debugger.
4. Liefert die Init-Routine einen Wert (`return` ≠ 0), wird dafür eine globale
   Variable angelegt.
5. Init- und Aufräum-Routine (`init`, `finit`) werden in die Start- und
   Endsequenz des Programms eingetragen.

Für Tokens, die schon eingebunden sind, merkt sich der Compiler die
Einsprungadresse (`instructionTable`, Cache für `searchinstr`).

## 9.5 Hinweise für einen Nachbau

* **Token-Tabelle:** `biglib_dump.py --tokens` erzeugt sie direkt aus den
  BigLib-Dateien; sie stimmt mit der des Originals überein. Für Lib 0 und 1
  (im Compiler eingebaut) bleibt `-dump token` die Quelle.
* **Aufrufe aus generiertem Code:** Pro benutztem Befehl und Form wird ein
  kleiner Assembler-Thunk erzeugt, der die Argumente in d0–d5/Stack legt, die
  `!libs`-Werte lädt (Library-Basen aus globalen Variablen, Objektzeiger aus
  Objektnummer und Tabelle), a3 auf den String-Puffer setzt und die Routine
  aufruft. Für ein C-Backend sind diese Thunks die einzige Stelle, die die
  Registerkonvention der Libs kennen muss; sie werden vom Linker eingebunden.
* **Lib-Code als Objektdatei:** Jede Lib lässt sich aus dem BigLib-Eintrag in
  eine normale Objektdatei umsetzen (Code ab `$12`, Relocations, Symbole für
  `init`/`finit`/Routinen aus `!subs`). Die `ALibJsr`-Platzhalter werden dabei
  zu externen Symbolen, die der Linker auflöst.
* **Debug-Prüfroutinen:** liegen ab `error` und werden nur für
  Debug-Builds benötigt.
* **Offene Punkte:** Registerverwendung der Routinen (was sie verändern
  dürfen), Bedeutung von `d2` = „Maximum object numbers“ in manchen
  Routinen-Kommentaren, Format der Typ-Argumente bei `!ustatement`/
  `!ufunction`, `BLibJsr`/Blitz-Modus.
