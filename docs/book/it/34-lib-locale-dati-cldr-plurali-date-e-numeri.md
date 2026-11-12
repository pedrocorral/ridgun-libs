# Capitolo 34: La lib `locale` — Regole dei Plurali CLDR, Formattazione UTC di Date e Numeri e Autonimi delle Lingue

## 34.1. Perché esiste la lib `locale`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `locale` scritta da zero in Ridgun puro invece di dipendere da `setlocale()` di `libc` o trascinare 30 MB di `libicu`?»*

Nei sistemi reali (come gateway i18n, modelli multilingue e motori di cataloghi `.po` nello stile di `babel`), `setlocale()` in C muta uno stato globale condiviso tra i thread e `libicu` appesantisce qualsiasi distribuzione statica. La lib **`locale`** (`src/main/ridgun/lib/locale.ridgun`, dominio `LOCALE`) incorpora direttamente in Ridgun puro le tabelle **Unicode CLDR 46** e il calendario civile UTC in $O(1)$ di Howard Hinnant:

1. **Regole dei plurali CLDR in doppia modalità (`.po` a 2 forme predefinita + CLDR 46 rigorosa con `"many"`)**: `plural category`, `plural categories` e `plural index` offrono per impostazione predefinita la modalità compatibile con i cataloghi Gettext `.po` (`["one", "other"]` per `it`, `es`, `ca`, `gl`, `eu`, `en`, `pt`, `sv`, `de`, `nl`; regola `n == 0 or n == 1` per `fr`; 3 forme slave per `ru`, `uk`, `pl`; 6 forme per `ar`; invariante per `ja`, `zh`, `ko`), mentre `plural category cldr` e `plural categories cldr` attivano la categoria `"many"` di CLDR 46 per i milioni esatti (`1000000`, `2000000`...) in `it`, `es`, `ca`, `pt` e `fr`.
2. **Formattazione di date e timestamp UTC (`format date`, `format datetime`, `month name`, `weekday name`)**: converte i secondi Unix epoch tramite l'algoritmo civile di Howard Hinnant in $O(1)$ e applica i pattern `short`, `medium`, `long` e `full` di ciascuna lingua (ad es. `"sabato 31 ottobre 2026"` in italiano).
3. **Formattazione numerica con raggruppamento delle migliaia e arrotondamento decimale *half-away-from-zero* (`format int`, `format decimal`)**: applica i separatori delle migliaia (`.`, `,`, spazio o NBSP `\u00a0`) e il separatore decimale secondo il locale, con scomposizione binaria IEEE-754 a 53 passi senza `libc`.
4. **Autonimi nativi (`language name`) e normalizzazione BCP-47 (`normalize locale`)**: converte tag come `"it_IT.UTF-8"` o `"pt-BR"` nel codice base (`"it"`, `"pt"`) con fallback deterministico a `"en"` e restituisce l'autonimo nativo (`"Italiano"`, `"Español"`, `"Català"`, `"Galego"`, `"Euskara"`, `"English"`, `"Português"`, `"Svenska"`, ecc.).

---

## 34.2. Artefatti nativi, importazione e catalogo completo dell'API di `locale`

```ridgun
type LocaleDatePatterns =
  ldp_short  : String
  ldp_medium : String
  ldp_long   : String
  ldp_full   : String

type LocaleSpec =
  loc_code          : String
  loc_autonym       : String
  loc_plural_family : String
  loc_thousands_sep : String
  loc_decimal_sep   : String
  loc_months_full   : [String]
  loc_months_short  : [String]
  loc_weekdays_full : [String]
  loc_weekdays_short: [String]
  loc_date_patterns : LocaleDatePatterns
```

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
|---|---|---|
| `1` | `fn :: loc ascii lower char Int` | `Int` |
| `2` | `fn :: loc tag base char String Int Int String Int` | `String` |
| `3` | `fn :: loc tag base loop String Int Int String` | `String` |
| `4` | `fn :: loc extract base tag String` | `String` |
| `5` | `fn :: loc nth str [String] Int String` | `String` |
| `6` | `fn :: loc replace all loop String String String Int Int Int String` | `String` |
| `7` | `fn :: loc replace all String String String` | `String` |
| `8` | `fn :: loc nbsp` | `String` |
| `9` | `fn :: loc spec es` | `LocaleSpec` |
| `10` | `fn :: loc spec ca` | `LocaleSpec` |
| `11` | `fn :: loc spec eu` | `LocaleSpec` |
| `12` | `fn :: loc spec gl` | `LocaleSpec` |
| `13` | `fn :: loc spec pt` | `LocaleSpec` |
| `14` | `fn :: loc spec sv` | `LocaleSpec` |
| `15` | `fn :: loc spec en` | `LocaleSpec` |
| `16` | `fn :: loc spec it` | `LocaleSpec` |
| `17` | `fn :: supported locales` | `[String]` |
| `18` | `fn :: default locales` | `[LocaleSpec]` |
| `19` | `fn :: register locale LocaleSpec [LocaleSpec]` | `[LocaleSpec]` |
| `20` | `fn :: loc spec code LocaleSpec` | `String` |
| `21` | `fn :: loc spec autonym LocaleSpec` | `String` |
| `22` | `fn :: loc spec plural rule LocaleSpec` | `String` |
| `23` | `fn :: loc spec group sep LocaleSpec` | `String` |
| `24` | `fn :: loc spec dec sep LocaleSpec` | `String` |
| `25` | `fn :: loc spec months wide LocaleSpec` | `[String]` |
| `26` | `fn :: loc spec months short LocaleSpec` | `[String]` |
| `27` | `fn :: loc spec weekdays wide LocaleSpec` | `[String]` |
| `28` | `fn :: loc spec weekdays short LocaleSpec` | `[String]` |
| `29` | `fn :: loc spec date patterns LocaleSpec` | `LocaleDatePatterns` |
| `30` | `fn :: loc find in registry [LocaleSpec] String` | `LocaleSpec` |
| `31` | `fn :: loc lookup base with [LocaleSpec] String` | `LocaleSpec` |
| `32` | `fn :: lookup locale with [LocaleSpec] String` | `LocaleSpec` |
| `33` | `fn :: loc lookup base String` | `LocaleSpec` |
| `34` | `fn :: lookup locale String` | `LocaleSpec` |
| `35` | `fn :: normalize locale String` | `String` |
| `36` | `fn :: language name String` | `String` |
| `37` | `fn :: loc abs int Int` | `Int` |
| `38` | `fn :: loc eval plural an String Int Bool` | `String` |
| `39` | `fn :: loc eval plural rule String Int Bool` | `String` |
| `40` | `fn :: loc categories for rule String Bool` | `[String]` |
| `41` | `fn :: plural category String Int` | `String` |
| `42` | `fn :: plural categories String` | `[String]` |
| `43` | `fn :: plural category cldr String Int` | `String` |
| `44` | `fn :: plural categories cldr String` | `[String]` |
| `45` | `fn :: loc cat to index String` | `Int` |
| `46` | `fn :: plural index String Int` | `Int` |
| `47` | `fn :: loc floor div qr Int Int` | `Int` |
| `48` | `fn :: loc floor div Int Int` | `Int` |
| `49` | `fn :: loc floor mod r Int Int` | `Int` |
| `50` | `fn :: loc floor mod Int Int` | `Int` |
| `51` | `fn :: loc ymd month Int` | `Int` |
| `52` | `fn :: loc ymd year Int Int` | `Int` |
| `53` | `fn :: loc days to ymd Int` | `Int Int Int` |
| `54` | `fn :: loc iso weekday norm Int` | `Int` |
| `55` | `fn :: loc iso weekday from days Int` | `Int` |
| `56` | `fn :: loc pad2 Int` | `String` |
| `57` | `fn :: loc pad4 Int` | `String` |
| `58` | `fn :: month name String Int` | `String` |
| `59` | `fn :: month short name String Int` | `String` |
| `60` | `fn :: loc norm weekday idx Int` | `Int` |
| `61` | `fn :: loc weekday wide by nw String Int` | `String` |
| `62` | `fn :: weekday name String Int` | `String` |
| `63` | `fn :: loc weekday short by nw String Int` | `String` |
| `64` | `fn :: weekday short name String Int` | `String` |
| `65` | `fn :: loc ca prep char String Int` | `String` |
| `66` | `fn :: loc ca prep month String` | `String` |
| `67` | `fn :: loc eu genitive len String Int` | `String` |
| `68` | `fn :: loc eu genitive month String` | `String` |
| `69` | `fn :: loc select date pattern LocaleDatePatterns String` | `String` |
| `70` | `fn :: loc select dt join LocaleDatePatterns` | `String` |
| `71` | `fn :: loc render date pattern LocaleSpec String Int Int Int Int` | `String` |
| `72` | `fn :: format date String String Int` | `String` |
| `73` | `fn :: loc format time style String Int Int Int` | `String` |
| `74` | `fn :: format datetime String String Int` | `String` |
| `75` | `fn :: loc join grouped String String String` | `String` |
| `76` | `fn :: loc group digits loop String Int String String` | `String` |
| `77` | `fn :: loc format uint digits String String` | `String` |
| `78` | `fn :: loc pos int digits Int String` | `String` |
| `79` | `fn :: loc uint to digits Int` | `String` |
| `80` | `fn :: loc prepend neg Int String` | `String` |
| `81` | `fn :: format int String Int` | `String` |
| `82` | `fn :: loc pow10 Int Int` | `Int` |
| `83` | `fn :: loc pow10 real Int Real` | `Real` |
| `84` | `fn :: loc real to int loop Real Int Real Int` | `Int` |
| `85` | `fn :: loc real to uint Real` | `Int` |
| `86` | `fn :: loc pad left zeros String Int` | `String` |
| `87` | `fn :: loc abs float Real` | `Real` |
| `88` | `fn :: loc sign str float Real` | `String` |
| `89` | `fn :: loc clamp frac digits Int` | `Int` |
| `90` | `fn :: loc format decimal scaled String String String Real Int` | `String` |
| `91` | `fn :: loc format decimal impl String String String Real Int` | `String` |
| `92` | `fn :: format decimal String Real Int` | `String` |

---

## 34.3. Esplorare `locale` a fondo: Esempi passo dopo passo di ogni funzionalità

### 34.3.1. Esempio 1: Regole dei plurali CLDR (modalità `.po` a 2 forme e modalità rigorosa CLDR 46 con `"many"`)

```ridgun
fn :: test locale plural rules => ()
      test locale plural rules =
        assert str eq (plural category "es" 1) "one" "AC2: es 1 -> one"
        assert str eq (plural category "es" 0) "other" "AC2: es 0 -> other"
        assert str eq (plural category "es" 5) "other" "AC2: es 5 -> other"
        assert str eq (plural category "es" 1000000) "other" "AC2: es 1000000 default .po -> other"
        assert str eq (plural category "eu" 1) "one" "AC2: eu 1 -> one"
        assert str eq (plural category "eu" 2) "other" "AC2: eu 2 -> other"
        assert str eq (plural category "sv" 1) "one" "AC2: sv 1 -> one"
        assert str eq (plural category "sv" 2) "other" "AC2: sv 2 -> other"
        assert str eq (plural category "ca" 1) "one" "AC2: ca 1 -> one"
        assert str eq (plural category "gl" 1) "one" "AC2: gl 1 -> one"
        assert str eq (plural category "pt" 1) "one" "AC2: pt 1 -> one"
        assert str eq (plural category "en" 1) "one" "AC2: en 1 -> one"
        assert str eq (plural category "zz" 1) "one" "AC2: unknown 1 -> one"
        assert str eq (plural category "zz" 3) "other" "AC2: unknown 3 -> other"

        assert str eq (loc join strs (plural categories "es")) "one,other" "AC2: default plural categories es"
        assert str eq (loc join strs (plural categories "eu")) "one,other" "AC2: default plural categories eu"

        assert int equals (plural index "es" 1) 0 "AC2: plural index 1 -> 0"
        assert int equals (plural index "es" 5) 1 "AC2: plural index 5 -> 1"

        assert str eq (plural category cldr "es" 1000000) "many" "AC2: strict CLDR es 1000000 -> many"
        assert str eq (plural category cldr "ca" 2000000) "many" "AC2: strict CLDR ca 2000000 -> many"
        assert str eq (plural category cldr "pt" 1000000) "many" "AC2: strict CLDR pt 1000000 -> many"
        assert str eq (plural category cldr "it" 1000000) "many" "AC2: strict CLDR it 1000000 -> many"
        assert int equals (plural index cldr "it" 1) 0 "AC2: plural index cldr it 1 -> 0 (one)"
        assert int equals (plural index cldr "it" 1000000) 1 "AC2: plural index cldr it 1000000 -> 1 (many)"
        assert int equals (plural index cldr "it" 5) 2 "AC2: plural index cldr it 5 -> 2 (other)"
        assert str eq (plural category cldr "es" 0) "other" "AC2: strict CLDR es 0 -> other"
        assert str eq (plural category cldr "eu" 1000000) "other" "AC2: strict CLDR eu 1000000 -> other"
        assert str eq (loc join strs (plural categories cldr "es")) "one,many,other" "AC2: strict CLDR categories es"
        assert str eq (loc join strs (plural categories cldr "sv")) "one,other" "AC2: strict CLDR categories sv"
        ()
```

### 34.3.2. Esempio 2: Formattazione di date e timestamp UTC (`short`, `medium`, `long`, `full`)

```ridgun
fn :: test locale dates and datetimes => ()
      test locale dates and datetimes =
        ts_oct30 = 1793318400
        assert str eq (format date "es" "long" ts_oct30) "30 de octubre de 2026" "AC3: es long date 2026-10-30"
        assert str eq (format date "es" "short" ts_oct30) "30/10/2026" "AC3: es short date"
        assert str eq (format date "es" "medium" ts_oct30) "30 oct 2026" "AC3: es medium date"
        assert str eq (format date "es" "full" ts_oct30) "viernes, 30 de octubre de 2026" "AC3: es full date"

        assert str eq (format date "ca" "long" ts_oct30) "30 d'octubre de 2026" "AC3: ca long date vowel elision d'octubre"
        ts_may15 = 1778803200
        assert str eq (format date "ca" "long" ts_may15) "15 de maig de 2026" "AC3: ca long date consonant de maig"

        assert str eq (format date "eu" "short" ts_oct30) "2026/10/30" "AC3: eu short date Y/M/D"
        assert str eq (format date "eu" "long" ts_oct30) "2026(e)ko urriaren 30a" "AC3: eu long date genitive"
        assert str eq (format date "eu" "full" ts_oct30) "2026(e)ko urriaren 30a, ostirala" "AC3: eu full date"

        assert str eq (format date "gl" "long" ts_oct30) "30 de outubro de 2026" "AC3: gl long date"
        assert str eq (format date "pt" "long" ts_oct30) "30 de outubro de 2026" "AC3: pt long date"
        assert str eq (format date "pt" "full" ts_oct30) "sexta-feira, 30 de outubro de 2026" "AC3: pt full date"

        assert str eq (format date "sv" "short" ts_oct30) "2026-10-30" "AC3: sv short date ISO"
        assert str eq (format date "sv" "long" ts_oct30) "30 oktober 2026" "AC3: sv long date"
        assert str eq (format date "sv" "full" ts_oct30) "fredag 30 oktober 2026" "AC3: sv full date"

        assert str eq (format date "en" "long" ts_oct30) "October 30, 2026" "AC3: en long date"
        assert str eq (format date "en" "full" ts_oct30) "Friday, October 30, 2026" "AC3: en full date"

        assert str eq (format datetime "es" "long" (ts_oct30 + 52245)) "30 de octubre de 2026, 14:30:45" "AC3: es long datetime"
        assert str eq (format datetime "sv" "short" (ts_oct30 + 52245)) "2026-10-30 14:30" "AC3: sv short datetime"

        assert str eq (month name "es" 10) "octubre" "AC3: month name es 10"
        assert str eq (month name "eu" 10) "urria" "AC3: month name eu 10"
        assert str eq (weekday name "es" 5) "viernes" "AC3: weekday name es 5"
        assert str eq (weekday name "sv" 7) "söndag" "AC3: weekday name sv 7"
        assert str eq (weekday name "sv" 0) "söndag" "AC3: weekday name sv 0"
        ()
```

### 34.3.3. Esempio 3: Formattazione di interi e decimali con raggruppamento delle migliaia per locale

```ridgun
fn :: test locale numbers => ()
      test locale numbers =
        nbsp = (char from code 194) + (char from code 160)
        assert str eq (format int "es" 1234567) "1.234.567" "AC4: format int es 1234567"
        assert str eq (format int "ca" 1234567) "1.234.567" "AC4: format int ca 1234567"
        assert str eq (format int "eu" 1234567) "1.234.567" "AC4: format int eu 1234567"
        assert str eq (format int "gl" 1234567) "1.234.567" "AC4: format int gl 1234567"
        assert str eq (format int "pt" 1234567) "1.234.567" "AC4: format int pt 1234567"
        assert str eq (format int "sv" 1234567) ("1" + nbsp + "234" + nbsp + "567") "AC4: format int sv 1234567 with NBSP"
        assert str eq (format int "en" 1234567) "1,234,567" "AC4: format int en 1234567"
        assert str eq (format int "es" (-1234567)) "-1.234.567" "AC4: format int es negative"
        assert str eq (format int "es" 42) "42" "AC4: format int es small"
        assert str eq (format int "es" 0) "0" "AC4: format int es zero"

        assert str eq (format decimal "es" 1234567.89 2) "1.234.567,89" "AC4: format decimal es"
        assert str eq (format decimal "sv" 1234.5 2) ("1" + nbsp + "234,50") "AC4: format decimal sv"
        assert str eq (format decimal "en" 1234.5 2) "1,234.50" "AC4: format decimal en"
        assert str eq (format decimal "es" (-19.99) 2) "-19,99" "AC4: format decimal negative"
        ()
```

### 34.3.4. Esempio 4: Autonimi delle lingue (`language name`) e normalizzazione BCP-47 / POSIX

```ridgun
fn :: test locale autonyms normalization and registry => ()
      test locale autonyms normalization and registry =
        assert str eq (loc join strs (supported locales)) "es,ca,eu,gl,pt,sv,en,it" "AC1: supported locales order"
        assert str eq (language name "it") "Italiano" "AC1: language name it"
        assert str eq (language name "es") "Español" "AC1: language name es"
        assert str eq (language name "ca") "Català" "AC1: language name ca"
        assert str eq (language name "eu") "Euskara" "AC1: language name eu"
        assert str eq (language name "gl") "Galego" "AC1: language name gl"
        assert str eq (language name "pt") "Português" "AC1: language name pt"
        assert str eq (language name "sv") "Svenska" "AC1: language name sv"
        assert str eq (language name "en") "English" "AC1: language name en"
        assert str eq (language name "unknown") "English" "AC1: unknown locale falls back to English"
        assert str eq (language name "root") "English" "AC1: root locale falls back to English"
        assert str eq (normalize locale "es-ES") "es" "AC1: normalize locale es-ES"
        assert str eq (normalize locale "CA_ES.UTF-8") "ca" "AC1: normalize locale CA_ES.UTF-8"
        assert str eq (normalize locale "pt-BR") "pt" "AC1: normalize locale pt-BR"
        assert str eq (normalize locale "xx-YY") "en" "AC1: normalize unknown locale to en"

        fr_spec = LocaleSpec "fr" "Français" "one_zero_one" " " "," ["janvier"] ["janv."] ["lundi"] ["lun."] (LocaleDatePatterns "%DD/%MM/%YYYY" "%D %MMM %YYYY" "%D %MMMM %YYYY" "%EEEE %D %MMMM %YYYY" " ")
        reg2 = register locale fr_spec (default locales)
        found_fr = lookup locale with reg2 "fr-FR"
        assert str eq (loc spec autonym found_fr) "Français" "AC1: data-only LocaleSpec registration and lookup"
        ()
```

---

## 34.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e conclusione del libro

- **Garanzia algoritmica e di sicurezza**: Funzioni 100% pure e prive di stato globale mutabile (`TZ` / `LC_ALL`), calendario civile UTC in $O(1)$ con validazione degli anni bisestili e fallback deterministico a `"en"` per i tag sconosciuti.
- **Complessità dello stack $O(1)$ con TCO**: Tutte le scansioni di sostituzione e raggruppamento in `src/main/ridgun/lib/locale.ridgun` sono ricorsive di coda.
- **Verifica continua**: Testata in modo esaustivo con `src/test/ridgun/test locale.ridgun`.

Hai completato il percorso esaustivo attraverso tutte le **34 lib standard di `ridgun-libs`**!
