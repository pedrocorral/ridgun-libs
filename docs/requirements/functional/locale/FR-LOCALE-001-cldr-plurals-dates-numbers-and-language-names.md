---
id: FR-LOCALE-001
title: CLDR Locale Data Library for Plurals, UTC Dates, Numbers, and Language Names
status: implemented
domain: LOCALE
depends_on: []
verified_by: [TS-LOCALE-001]
---
# FR-LOCALE-001 — CLDR Locale Data Library for Plurals, UTC Dates, Numbers, and Language Names

## Summary
The `locale` library (`src/main/ridgun/lib/locale.ridgun`) MUST provide a pure-Ridgun, data-driven Unicode CLDR locale data table and formatting functions for Spanish (`es`), Catalan (`ca`), Basque (`eu`), Galician (`gl`), Portuguese (`pt`), Swedish (`sv`), English (`en`), and Italian (`it`), with automatic fallback to `root`/English (`en`) for unknown locales and extensible data-only `LocaleSpec` registration without new code per language.

## Acceptance Criteria
1. **AC1 — Supported Locales, Tag Normalization, and Language Autonyms**:
   - `supported locales` MUST return `["es", "ca", "eu", "gl", "pt", "sv", "en", "it"]` in that exact order.
   - `normalize locale` MUST normalize BCP-47 / POSIX tags (e.g., `"es-ES"`, `"es_MX"`, `"CA"`, `"pt-BR"`, `"it_IT.UTF-8"`) to their lowercase base language code and fall back to `"en"` for unknown tags.
   - `language name` MUST return each language's autonym: `"Español"` (`es`), `"Català"` (`ca`), `"Euskara"` (`eu`), `"Galego"` (`gl`), `"Português"` (`pt`), `"Svenska"` (`sv`), `"English"` (`en` or unknown fallback), and `"Italiano"` (`it`).
   - New locales MUST be registrable purely as `LocaleSpec` data values via `register locale` and queried via `lookup locale with` without adding new code paths per language.
2. **AC2 — Cardinal Plural Categories (`.po`-Compatible Default and Strict CLDR `many`)**:
   - `plural category` and `plural categories` MUST return the `.po`/gettext-compatible 2-form cardinal categories `["one", "other"]` (`"one"` for `1` / `-1`, `"other"` for all other integers) across `es`, `ca`, `eu`, `gl`, `pt`, `sv`, `en`, and `it`.
   - `plural category cldr`, `plural categories cldr`, and `plural index cldr` MUST implement strict CLDR 46 cardinal rules, including `"many"` for exact millions (`n != 0` and `n % 1000000 == 0`) in `es`, `ca`, `pt`, and `it` (`["one", "many", "other"]`).
   - `plural index` MUST return `0` for `"one"` and `1` for `"other"` in `.po` mode, and `plural index cldr` MUST return the 0-based index into `plural categories cldr` (`0` for `"one"`, `1` for `"many"`, `2` for `"other"`).
3. **AC3 — UTC Date and Datetime Formatting (`short`, `medium`, `long`, `full`)**:
   - `format date` and `format datetime` MUST format UTC Unix timestamps in `"short"`, `"medium"`, `"long"`, and `"full"` CLDR styles for all 7 languages, including `format date "es" "long" 1793318400` == `"30 de octubre de 2026"`, Catalan vowel elision (`"30 d'octubre de 2026"` vs `"15 de maig de 2026"`), Basque year-month-day order (`"2026(e)ko urriaren 30a"`), and Swedish patterns (`"2026-10-30"`, `"30 oktober 2026"`).
   - `month name`, `month short name`, `weekday name`, and `weekday short name` MUST return the localized month (`1..12`) and weekday (`1..7`, Monday..Sunday) names.
4. **AC4 — Localized Integer and Decimal Number Formatting**:
   - `format int` MUST group integer digits by thousands using the locale's CLDR separator (`"."` for `es`, `ca`, `eu`, `gl`, `pt`; UTF-8 non-breaking space `"\u00A0"` for `sv`; `","` for `en`), so `format int "es" 1234567` == `"1.234.567"` and `format int "sv" 1234567` == `"1\u00A0234\u00A0567"`.
   - `format decimal` MUST format floating-point values to a specified number of fractional digits using the locale's thousands and decimal separators (`","` for `es`, `ca`, `eu`, `gl`, `pt`, `sv`; `"."` for `en`).
