# 6 Macros

**[C]** `do_Macro` (Z. 20833), `handle_macro` (Z. 2763), `findit` (Z. 3186),
`getparameter2` (Z. 10947), `findmac` (Z. 11261).

Macros sind rein textuelle Ersetzungen auf der Ebene **tokenisierter**
Zeilen. Sie werden in der Reihenfolge des Quelltexts definiert und sind ab
ihrer Definition bis zum Ende des Compiler-Durchlaufs bekannt. Zu Beginn jedes
Durchlaufs wird die Macro-Liste geleert (Z. 2592); zusätzlich sind die Macros
aus geladenen Resident-Dateien (`.res`, z. B. `all.res`) vordefiniert. Mit
`Residents = "all.res"` im XTRA-Header listet `AmiBlitz3 -dump macro` 244
Macros (MUI-Hilfsmacros wie `HGroup`, `MUIC_*`, außerdem `version` u. a.;
**[V]** `results/round6/r6_macros.txt`). Für einen Nachbau sind die
Resident-Macros eine weitere externe Eingabe.

### 6.1.1 Macros in Resident-Dateien

Eine `.res`-Datei ist eine AmigaOS-Hunk-Datei; ihr erster Hunk enthält die
Listen, die der Compiler beim Laden übernimmt (`fixtypes`, `fixmacs`,
`fixconsts`). Ein Macro-Eintrag hat genau das Format, das `do_Macro` im
Speicher anlegt (**[C]** `fixmacs` Z. 6320, `findlab`):

| Offset | Inhalt |
|---|---|
| +0 | `next.l` – Zeiger auf den nächsten Eintrag (0 = Ende; von LoadSeg reloziert) |
| +4 | `body.l` – Zeiger auf den Rumpf |
| +8 | `length.w` – Rumpflänge in Bytes |
| +10 | `count.w` – Expansionszähler für `` `@ `` |
| +12 | `nameend.b` – Offset hinter dem Namen (= 13 + Namenslänge) |
| +13 | Name, 0-terminiert, auf gerade Adresse aufgefüllt; danach der Rumpf |

Der Rumpf ist tokenisierter Text in derselben Form wie bei einer Definition im
Quelltext (Zeilen durch `:` verbunden, Kopfkommentar als `;…:@:`).
`verification/tools/res_macros.py` extrahiert alle Macros und übersetzt die
Tokens zurück; für `all.res` liefert es dieselben 244 Namen wie
`-dump macro` (**[V]**, `results/resident-macros/all.res.txt`).

Beispiel (`all.res`):

```
Macro version
  ;{version} ;add a standard amiga Version String:@:BRA __version:Even4:Dc.b 0,"$VER: ":Dc.b `1,0:Even:__version
End Macro
```

`!version{"Prog 1.2 (25.10.2026)"}` legt also einen `$VER:`-String in den
Code und springt mit `BRA` darüber; es ist eine Anweisung, kein Ausdruck.
**[V]** V-RES-2: AmigaDOS `Version` liest aus dem Executable
„SpecProbe 1.2 (25.10.26)“.

**Achtung, Token-Nummern:** Die Rümpfe enthalten die Token-Wörter, die beim
Erzeugen der Resident-Datei galten. In `all.res` kommen vier Wörter vor, die
in der aktuellen Token-Tabelle fehlen (`$B58D`, `$B593`, `$DC86`, `$DC87`,
alte Lib-Nummern). Der Compiler bildet solche Wörter in `getchar` über die
Tabelle `replacedat` auf aktuelle Tokens ab; Einträge darin registrieren die
Bibliotheken beim Laden über die Compiler-Funktion `replacelib`
(Funktionstabelle, Offset −60). **[C]** Ein Nachbau braucht diese
Abbildung als weitere Eingabe; sie lässt sich bisher nicht exportieren.

## 6.1 Übersicht

```
Macro add
  (`1 + `2)
End Macro

a = !add{1, 2*3}        ⇒   a = (1 + 2*3)
```

| Element | Bedeutung |
|---|---|
| `Macro name` … `End Macro` | Definition (mehrzeilig oder einzeilig mit `:`) |
| `!name` | Aufruf ohne Parameter |
| `!name{a,b,…}` | Aufruf mit Parametern |
| `!name a,b,…` | Aufruf ohne Klammern (nur New-Syntax-Modus, nur wenn der Rumpf `` ` `` enthält) |
| `` `1 `` … `` `9 ``, `` `a `` … `` `y `` | Parameter 1–9, 10–34 (Buchstaben case-insensitiv) |
| `` `0 `` | Anzahl der übergebenen Parameter, **zweistellig** (`03`) |
| `` `@ `` | laufende Nummer dieser Expansion des Macros (0, 1, 2, …) – für eindeutige Labels |
| `` `{ausdruck} `` | Parameter mit berechneter Nummer |

## 6.2 Definition

### 6.2.1 Syntax

```
macro-def   = %s"Macro" ws macro-name [ws] [ ":" ] [ kopfkommentar ]
              rumpf
              %s"End" [ws] %s"Macro"
```

(`Macro`, `End` sind Tokens; zwischen `End` und `Macro` dürfen Leerzeichen
stehen.)

### 6.2.2 Name

* Der Name wird mit `getparameter2` gelesen: führende Leerzeichen werden
  übersprungen, dann folgt die längste Folge von Nicht-Namenstrennern
  ([04-lexical.md §4.7](04-lexical.md#47-namen)).
* Ist der Name leer (z. B. weil ein Keyword folgt, das zu einem Token wurde),
  ist das ein Syntaxfehler. Ein Macro kann daher **nicht** wie ein Keyword
  heißen – auch nicht wie eines der kleingeschriebenen PPC-Mnemonics.
  **[V]** V-MAC-NAME-2: `Macro neg` → „Syntax error!“.
* Ist der Name bereits als Macro definiert: Fehler „Macro already defined“.
  Groß-/Kleinschreibung ist signifikant. **[V]** V-MAC-NAME-1 (`abc` und `ABC`
  sind verschiedene Macros).

### 6.2.3 Sammeln des Rumpfs

Der Rumpf wird **ohne** Macro-Expansion und **ohne** Auswertung der bedingten
Kompilierung gesammelt (`getcharb`). Algorithmus (normativ):

```
buf := ""; etwasGesammelt := falsch; nest := 0; thenModus := falsch
pos := hinter dem Namen
überspringe Leerzeichen; wenn ":" → überspringe genau ein ":"
wenn ";" → kopiere den Kommentar bis Zeilenende nach buf, hänge ":@" an;
           etwasGesammelt := wahr                    # Kopfkommentar (§6.2.4)
schleife:
    c := getcharb()            # liefert Zeichen bzw. Token-Wort;
                               # Kommentare ";…" werden übersprungen (→ 0 oder ":")
    falls c = 0 (Zeilenende):
        nächste physische Zeile (bei Dateiende: Fehler, „End Macro“ fehlt)
        wenn etwasGesammelt:
            überspringe führende Leerzeichen der neuen Zeile
            wenn thenModus: buf += ":" + [End] + [If]; thenModus := falsch
            buf += ":"
        weiter
    falls c = "@" und das nächste Zeichen ist "@":
        Rest der Zeile verwerfen, mit nächster physischer Zeile fortfahren
        (ohne ":" einzufügen)
    falls c = [Macro]: nest += 1; buf += c
    falls c = [Object] und ein Object ist offen: Fehler
    falls c = [Then]: thenModus := wahr
    falls c = [End]:
        n := nächstes Nicht-Leerzeichen (vorausschauend)
        wenn n ∈ {0, ":", ";"}: buf += [End]
        sonst: n verbrauchen
               wenn n = [Macro]: nest -= 1; wenn nest < 0: ENDE
               (wenn thenModus und n = [If]: thenModus := falsch)
               buf += [End] + n
        weiter
    sonst: buf += c; etwasGesammelt := wahr
ENDE:
    entferne abschließende ":" aus buf (nur ":" – keine Leerzeichen!)
    der Rest der Zeile hinter "End Macro" wird ignoriert
```

Folgerungen:

* Zeilen des Rumpfs werden durch `:` verbunden; der Rumpf ist eine einzige
  „Zeile“ aus Anweisungen. Leere Zeilen ergeben leere Anweisungen (`::`).
* Führende Leerzeichen der Folgezeilen werden entfernt, innere und
  abschließende Leerzeichen bleiben erhalten.
* **Einzeilige Form – Falle:** Bei `Macro sq : ((`1)*(`1)) : End Macro` endet
  der Rumpf auf `" : "` (das Leerzeichen vor `End` verhindert, dass das `:`
  entfernt wird). Der Rumpf ist dann nur als **ganze Anweisung** verwendbar;
  in einem Ausdruck beendet das eingesetzte `:` die Anweisung.
  **[V]** V-MN-6/7, V-MAC-TR: `NPrint Sqr(!sq{3})` → „'(' or '{' brackets not
  paired correctly“, `NPrint !tr{a},"|"` → „Syntax error!“.
  Ohne Leerzeichen vor `End` (`((`1)*(`1)):End Macro`) oder in mehrzeiliger
  Form funktioniert es (**[V]** V-MN-8, V-MN-1–7 in
  `r3_mac_multiline.ab3`). Das Beispiel der Dokumentation (Kapitel 2.10:
  `MACRO myFuncMacro : ((`1) * (`2)) : End MACRO`) ist von diesem Problem
  betroffen, sobald das Macro in einem Ausdruck steht.
* Kommentare im Rumpf werden entfernt – **außer** dem Kopfkommentar.
* **Then-Modus:** Eine Zeile `If a Then b` wird zu `If a Then b:End If`, damit
  die folgenden Rumpfzeilen nicht zum `Then`-Teil gehören. **[V]** V-MAC-then.
* Verschachtelte `Macro … End Macro` im Rumpf werden als Text gespeichert und
  erst bei der Expansion des äußeren Macros definiert (siehe
  `Tests/nested-macros.ab3`). Weil der expandierte Rumpf eine einzige Zeile
  ist und der Rest der Zeile hinter `End Macro` ignoriert wird, geht **alles,
  was im äußeren Rumpf nach dem inneren `End Macro` steht, verloren**.
  **[V]** V-MAC-AE-2 (`outer2` wird nicht ausgegeben), V-MAC-nest (`!t2` im
  Rumpf von `t1` wird nicht ausgeführt; das innere Macro ist danach aber
  definiert).
* Code hinter `End Macro` in derselben Zeile wird **stillschweigend
  ignoriert**: `Macro m : NPrint "m" : End Macro : NPrint "after"` gibt
  `after` nie aus. **[V]** V-MAC-AE-1, V-MAC-DEF-3. (Die Ursache liegt in der
  Rückkehr aus `do_Macro`; der genaue Mechanismus ist nicht analysiert.)
* Max. Rumpfgröße: Größe des Macro-Puffers (Standard 40 000 Bytes,
  `#DEFAULT_MACROBUFFERSIZE`), sonst Fehler „'Macro/Object' too big“.

**Quirks:**

* `getcharb` beendet einen Kommentar an `:@`, überspringt das `@` aber
  **nicht** (anders als `getchar`). Beobachtet: Code hinter `:@` in einem
  Rumpf-Kommentar wird nicht ausgeführt, ein Fehler entsteht nicht.
  **[V]** V-MAC-DEF-4.
* Folgt auf `End` im Rumpf kein Token (z. B. `End d0`), so wird das nächste
  Zeichen als 16-Bit-Wort mit High-Byte `0` gespeichert, was den Rumpf an
  dieser Stelle abschneidet. **[V]** V-MAC-DEF-5: `If 0 : End d0 : EndIf` im
  Rumpf → „'If' without 'End If'“ beim Aufruf.
* Das `@@`-Erkennen im Rumpf prüft nicht, ob man sich in einem String
  befindet (`"a@@b"` im Rumpf verbindet Zeilen). **[V]** V-MAC-DEF-6:
  `NPrint "[a@@b]"` im Rumpf → „No terminating quote“ beim Aufruf.

### 6.2.4 Kopfkommentar

Ein Kommentar auf der `Macro`-Zeile wird als `;Kommentar:@` vor den Rumpf
gestellt. Er dient der IDE als Hilfetext (Instruction Browser) und wird bei der
Expansion wieder entfernt (§6.4, Schritt 3; **[V]** V-MAC-hc). Beispiel aus der Doku:

```
Macro my_func ; {a.w, b.l}   Kommentar = Syntaxhilfe
Function.l my_func{a.w, b.l}
  …
End Function
End Macro
```

## 6.3 Aufruf

### 6.3.1 Erkennen

Vor dem Parsen **jeder Anweisung** wird die Anweisung (ab ihrem Beginn bis zum
ersten `:` oder `;` außerhalb eines Strings, bzw. bis Zeilenende) nach einem
`!` außerhalb von Strings durchsucht. Token-Wörter werden als Einheit
übersprungen. Wird ein `!` gefunden, wird expandiert (§6.4) und die Suche
beginnt **erneut am Anfang der Anweisung** im expandierten Text – so lange,
bis die Anweisung kein `!` mehr enthält. Während übersprungener
CNIF-Bereiche findet keine Expansion statt.

Ein `!` außerhalb von Strings und Kommentaren ist damit **immer** ein
Macro-Aufruf.

### 6.3.2 Name

Nach dem `!` werden Leerzeichen übersprungen und der Name gelesen (wie in
§6.2.2). Leerer Name → Syntaxfehler; unbekannter Name → Fehler
„'Macro/Object' not found“.

### 6.3.3 Parameterliste

Sei *p* die Position direkt hinter dem Namen und *q* die Position nach
weiteren Leerzeichen. Die Entscheidung, ob und wie Parameter gelesen werden:

```
wenn src[q] = ",":                         keine Parameter, Rest ab p
sonst wenn New-Syntax-Modus:
    wenn der Rumpf kein "`" enthält:       keine Parameter, Rest ab p
    c := src[q]
    wenn c = "{":                          q += 1; LISTE
    wenn c ist Token oder kein Namenstrenner
         oder c ∈ {",", "#", "$", "-"}:    LISTE  (ohne Klammern)
    sonst:                                 keine Parameter, Rest ab p
sonst (klassischer Modus):
    wenn src[q] ≠ "{":                     keine Parameter, Rest ab p
    q += 1; überspringe Leerzeichen; LISTE
LISTE:
    wenn src[q] = 0:                       keine Parameter
    sonst Parameter lesen (unten); Rest ab dem Ende der Liste
```

**Parameter lesen** (`findit`): Ab *q* werden Parameter gelesen. Alle
Parameter beginnen direkt hinter `{` bzw. dem trennenden `,` – führende
Leerzeichen gehören zum Parametertext. **Ausnahme:** Im klassischen Modus
werden Leerzeichen direkt hinter `{` übersprungen. **[V]** V-MAC-sp
(New-Syntax: `!sp{ x , y }` → ` x `, ` y `) und V-MAC-sp-cls (klassisch: → `x `,
` y `).
Innerhalb eines Parameters gilt:

| Zeichen (außerhalb von Strings) | Wirkung |
|---|---|
| `(` oder `{` | Schachtelungstiefe + 1 |
| `)` | Tiefe − 1 |
| `}` bei Tiefe 0 | Parameter **und** Liste enden; `}` wird verbraucht |
| `}` bei Tiefe > 0 | Tiefe − 1 |
| `,` bei Tiefe 0 | Parameter endet, nächster beginnt |
| `:` oder `;` (bei jeder Tiefe) | Parameter und Liste enden; Zeichen bleibt stehen |
| Zeilenende | Parameter und Liste enden |
| `@@` | Parameter endet; die Liste wird am Anfang der **nächsten physischen Zeile** fortgesetzt (siehe unten) |
| `"` | String-Modus umschalten (darin ist nichts davon wirksam) |
| Token-Wort | zwei Bytes, normaler Inhalt |

`[` und `]` werden **nicht** gezählt: `!m{a(1,2)}` hat einen Parameter,
`!m{a[1,2]}` zwei. **Quirk**, **[V]** V-MAC-cnt.

Der Parametertext ist die Bytefolge ohne den Terminator, unverändert
(Leerzeichen, Tokens, Strings eingeschlossen).

`@@` in der Argumentliste: Laut Code wirkt `@@` wie ein `,` – der laufende
Parameter endet, und der nächste beginnt am Anfang der nächsten physischen
Zeile. Die Zeilenverwaltung wird dabei aber nicht weitergeschaltet: Die
Folgezeile wird **anschließend noch einmal als eigene Zeile übersetzt**.
**[V]** V-MAC-ARG-4: `!cnt{a,@@` ⏎ `b}` → „Garbage at the end of line
→ b}“, in der IDE identisch (V-JOIN-6b). In der Praxis ist `@@` in Macro-Argumenten damit **unbrauchbar**; ein
Nachbau sollte es entweder korrekt implementieren oder ablehnen. In
Include-Dateien ist `@@` hier ein Fehler (**[C]**).

Beispiele (New-Syntax-Modus, Rumpf enthält `` ` ``):

| Aufruf | Parameter | Rest der Zeile | Beleg |
|---|---|---|---|
| `!m` | – (`` `0 `` = `00`) | | [V] |
| `!m{1,2}` | `1`, `2` | | [V] |
| `!m{ 1 , 2 }` | ` 1 `, ` 2 ` | | [V] V-MAC-sp |
| `!m{}` | `` (einer, leer; `` `0 `` = `01`) | | [V] |
| `!m 1,2,3` | `1`, `2`, `3` | | [V] |
| `!m -1` | `-1` | | [V] V-MAC-neg |
| `!m $10` | `$10` | | [V] V-MAC-neg |
| `!m(1)` | – | `(1)` | [C] |
| `!m , x` | – | ` , x` | [C] |
| `!m{f(a,b),"x,y"}` | `f(a,b)`, `"x,y"` | | [V] V-MAC-cnt |
| `!m{ (a , b) }` | ` (a , b) ` | | [V] V-MAC-sp2 |
| `!m{a:b}` | `a` | `:b}` | [C] |
| `!m{a}+1` | `a` | `+1` | [C] |

Klassischer Modus: `!m{}` hat einen leeren Parameter (**[V]** V-MAC-cls),
`!m 1,2` hat **keine** Parameter (Rest ` 1,2`, **[C]**).
New-Syntax-Modus und Rumpf ohne `` ` ``: `!m{}` hat keine Parameter, und `{}`
bleibt als Text stehen → „Syntax error!“. **[V]** V-MAC-CALL-7.

## 6.4 Expansion

Gegeben: Anweisungsbeginn *S*, Position des `!` *b*, Rumpf *R* (Bytes),
Parameter *P₁…Pₙ* (n = Anzahl), Rest *T* (ab dem Ende der Parameterliste bzw.
direkt hinter dem Namen bis einschließlich Zeilenende), Expansionszähler *k*
des Macros (beginnt bei 0, wird bei jeder Expansion um 1 erhöht).

```
neu := text[S .. b-1] + ersetze(R) + T
die Anweisung beginnt nun am Anfang von neu; zurück zu §6.3.1
```

`ersetze(R)` läuft byteweise über *R*:

1. Token-Wörter (Byte ≥ `$80`) werden unverändert (2 Bytes) übernommen.
2. Ein Byte ≠ `` ` `` wird übernommen.
3. **Kopfkommentar:** Solange noch kein `"` und kein `:` im Rumpf gesehen
   wurde, beginnt ein `;` einen Kommentar, der bis einschließlich der Folge
   `:@:` übersprungen wird. (Damit wird der Kopfkommentar `;…:@` samt dem
   folgenden Zeilentrenner entfernt.)
4. `` ` `` gefolgt von *x*:

   | *x* | Ersetzung |
   |---|---|
   | `@` | *k* dezimal (ohne führende Nullen) – **[V]** V-MAC-uq (`0`, `1`, `2`) |
   | `{` | konstanter Ausdruck bis `}` → Wert *v* ≥ 0 (sonst „Illegal constant“), weiter wie Ziffer *v* – **[V]** V-MAC-ev |
   | `0`–`9` | *v* = Ziffernwert – **[V]** |
   | `a`–`y`, `A`–`Y` | *v* = 10 … 34 – **[V]** V-MAC-let |
   | `z`, `Z`, sowie alle *x* mit (*x* OR `$20`) ≥ `$7A` (z. B. `[ \ ] ^ _ { \| } ~`, Tokens) | Fehler „Illegal constant“ – **[C]** |
   | sonstige (Satzzeichen, Leerzeichen, `:`…`?`) | wie *v* = 0 **(Quirk)** – **[V]** V-MAC-pc (`` `: `` → `02`) |

   Für *v*: ist *v* = 0, wird *n* **zweistellig** dezimal eingesetzt
   (`00`–`99`; bei *n* ≥ 100 undefiniert). Ist 1 ≤ *v* ≤ *n*, wird
   *Pᵥ* eingesetzt; ist *v* > *n*, wird **nichts** eingesetzt.
5. Parameterersetzung erfolgt auch **innerhalb von Strings** im Rumpf
   (`"`1"` → `"wert"`). **[V]** (alle Macro-Probes).
6. Enthält ein eingesetzter Parametertext die Folge `@@`, so wird an dieser
   Stelle die **nächste physische Quellzeile** konsumiert (Zeilenzähler +1)
   und das Kopieren dort fortgesetzt. **Quirk** (betrifft praktisch nur
   `@@` in String-Argumenten). In Include-Dateien: Fehler.

Grenzen: Die expandierte Zeile darf den Macro-Puffer (40 000 Bytes) nicht
überschreiten, sonst „Macro buffer overflow“. Unendliche Rekursion endet so.

### 6.4.1 Beispiel: Expansion Schritt für Schritt

```
OPTIMIZE 4
Macro sq
  ((`1)*(`1))
End Macro
Macro hyp
  Sqr(!sq{`1}+!sq{`2})
End Macro
x = !hyp{3,4} : NPrint x
```

(Mehrzeilige Definitionen, damit der Rumpf kein abschließendes `:` enthält –
siehe §6.2.3. **[V]** V-MN-7: Ergebnis `5`.)

1. Anweisung `x = !hyp{3,4}` enthält `!` → Name `hyp`, Parameter `3`, `4`,
   Rest ` : NPrint x`.
   → `x = Sqr(!sq{3}+!sq{4}) : NPrint x`
   (Rümpfe sind hier ohne die führenden Leerzeichen dargestellt; die der
   ersten Rumpfzeile bleiben tatsächlich erhalten.)
2. Erneute Suche ab Anweisungsbeginn: `!sq{3}` → `((3)*(3))`
   → `x = Sqr(((3)*(3))+!sq{4}) : NPrint x`
3. `!sq{4}` → `x = Sqr(((3)*(3))+((4)*(4))) : NPrint x`
4. Kein `!` mehr bis zum `:` → Parser übersetzt `x = …`; danach wird
   `NPrint x` als nächste Anweisung behandelt.

(`Sqr` und `NPrint` sind Tokens, die durch die Expansion unverändert
weitergereicht werden.)

### 6.4.2 Beispiel: eindeutige Labels

```
Macro waitkey
  'loop`@ : BTST #6,$bfe001 : BNE 'loop`@
End Macro
!waitkey : !waitkey
```

Erste Expansion: `'loop0`, zweite: `'loop1`.

## 6.5 Wechselwirkungen

* **Tokenizer:** Der Rumpf liegt tokenisiert vor. Ein Parameter, der zusammen
  mit dem umgebenden Rumpftext ein Keyword ergäbe (z. B. Rumpf `` N`1 `` mit
  Parameter `Print`), wird **nicht** zum Token – es findet keine
  Neu-Tokenisierung statt. **[V]** V-MAC-TOK-1 (`N` wird zum Label, `[Print]` gibt ohne Zeilenumbruch aus).
* **Bedingte Kompilierung:** siehe [05-conditional.md §5.5](05-conditional.md#55-wechselwirkung-mit-macros).
* **Zeilennummern:** Fehler in expandiertem Text werden der Zeile des Aufrufs
  zugeordnet.
* **`:@` in Kommentaren:** Die Aufrufsuche endet an `;`; ein `!` hinter `:@`
  wird erst gefunden, wenn diese Anweisung an der Reihe ist. **[?]**
