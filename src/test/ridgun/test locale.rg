-- ============================================================
-- src/test/ridgun/test locale.rg
-- Automated Unit & Functional Test Suite for locale.rg
-- @tests TS-LOCALE-001
-- ============================================================

import test
import locale

fn :: loc join strs [String] => String
      loc join strs []       =  ""
      loc join strs (x:[])   =  x
      loc join strs (x:rest) =  x + "," + (loc join strs rest)

-- @tests TS-LOCALE-001
fn :: test locale autonyms normalization and registry => ()
      test locale autonyms normalization and registry =
        assert str eq (loc join strs (supported locales)) "es,ca,eu,gl,pt,sv,en" "AC1: supported locales order"
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

-- @tests TS-LOCALE-001
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
        assert str eq (plural category cldr "es" 0) "other" "AC2: strict CLDR es 0 -> other"
        assert str eq (plural category cldr "eu" 1000000) "other" "AC2: strict CLDR eu 1000000 -> other"
        assert str eq (loc join strs (plural categories cldr "es")) "one,many,other" "AC2: strict CLDR categories es"
        assert str eq (loc join strs (plural categories cldr "sv")) "one,other" "AC2: strict CLDR categories sv"
        ()

-- @tests TS-LOCALE-001
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

-- @tests TS-LOCALE-001
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

fn :: main => ()
      main =
        test locale autonyms normalization and registry
        test locale plural rules
        test locale dates and datetimes
        test locale numbers
        echo "[PASS] test locale: TS-LOCALE-001 passed"
