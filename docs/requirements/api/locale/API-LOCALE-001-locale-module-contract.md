---
id: API-LOCALE-001
title: Public API Contract for locale.rg
status: implemented
domain: LOCALE
implements: [FR-LOCALE-001]
verified_by: [TS-LOCALE-001]
---
# API-LOCALE-001 — Public API Contract for `locale.rg`

## Module
`src/main/ridgun/lib/locale.rg` (`module :: locale`)

## Types
- `type LocaleDatePatterns = LocaleDatePatterns String String String String String`
- `type LocaleSpec = LocaleSpec String String String String String [String] [String] [String] [String] LocaleDatePatterns`

## Public Functions
- `fn :: supported locales => [String]`
- `fn :: default locales => [LocaleSpec]`
- `fn :: register locale LocaleSpec [LocaleSpec] => [LocaleSpec]`
- `fn :: lookup locale with [LocaleSpec] String => LocaleSpec`
- `fn :: lookup locale String => LocaleSpec`
- `fn :: normalize locale String => String`
- `fn :: language name String => String`
- `fn :: plural category String Int => String`
- `fn :: plural categories String => [String]`
- `fn :: plural category cldr String Int => String`
- `fn :: plural categories cldr String => [String]`
- `fn :: plural index String Int => Int`
- `fn :: plural index cldr String Int => Int`
- `fn :: month name String Int => String`
- `fn :: month short name String Int => String`
- `fn :: weekday name String Int => String`
- `fn :: weekday short name String Int => String`
- `fn :: format date String String Int => String`
- `fn :: format datetime String String Int => String`
- `fn :: format int String Int => String`
- `fn :: format decimal String Real Int => String`
