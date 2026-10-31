---
id: TS-LOCALE-001
title: Unit and Functional Suite for CLDR Locale Plurals, UTC Dates, Numbers, and Language Names
status: automated
level: unit
domain: LOCALE
verifies: [FR-LOCALE-001, API-LOCALE-001, DM-Locale]
test_files:
  - src/test/ridgun/test locale.rg
---
# TS-LOCALE-001 — Unit and Functional Suite for CLDR Locale Plurals, UTC Dates, Numbers, and Language Names

## Scope
Verifies `src/main/ridgun/lib/locale.rg` across all 7 built-in CLDR locales (`es`, `ca`, `eu`, `gl`, `pt`, `sv`, `en`), unknown locale fallback (`root`/`en`), data-only `LocaleSpec` registration, `.po`-compatible and strict CLDR cardinal plural rules, UTC date/datetime formatting across `"short"`, `"medium"`, `"long"`, and `"full"` styles, integer and decimal formatting (including Swedish non-breaking space `\u00A0`), and language autonyms.

## Test Cases
1. **Language Autonyms, Normalization, Fallback & Extensible Registry (`AC1`)**:
   - Verifies `supported locales` (`["es", "ca", "eu", "gl", "pt", "sv", "en"]`), `language name` for all 7 locales + unknown fallback (`"English"`), BCP-47/POSIX tag normalization (`"es-ES"` -> `"es"`, `"ca_ES"` -> `"ca"`), and data-only registration of a custom `LocaleSpec` (`"fr"`).
2. **Cardinal Plural Rules (`.po` 2-Form Default & Strict CLDR `many`) (`AC2`)**:
   - Verifies `plural category`, `plural categories`, `plural index`, `plural category cldr`, and `plural categories cldr` for `1`, `0`, `2`, `5`, and `1000000` across `es`, `ca`, `eu`, `gl`, `pt`, `sv`, and `en`.
3. **UTC Date & Datetime Formatting (`AC3`)**:
   - Verifies `format date "es" "long" 1793318400` == `"30 de octubre de 2026"`, Catalan vowel elision (`"30 d'octubre de 2026"` vs `"15 de maig de 2026"`), Basque YMD order (`"2026(e)ko urriaren 30a"`), Swedish ISO short and long date (`"2026-10-30"`, `"30 oktober 2026"`), `format datetime`, `month name`, and `weekday name`.
4. **Integer and Decimal Number Formatting (`AC4`)**:
   - Verifies `format int "es" 1234567` == `"1.234.567"`, `format int "sv" 1234567` == `"1\u00A0234\u00A0567"`, `format int "en" 1234567` == `"1,234,567"`, negative numbers, and `format decimal` with rounding and localized decimal separators.
