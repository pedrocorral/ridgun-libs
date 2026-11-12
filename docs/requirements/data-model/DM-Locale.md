---
id: DM-Locale
title: CLDR Locale Specification and Date Pattern Model
status: implemented
domain: LOCALE
implements: [FR-LOCALE-001]
verified_by: [TS-LOCALE-001]
---
# DM-Locale — CLDR Locale Specification and Date Pattern Model

## Overview
Defines the data-driven CLDR locale specification types (`LocaleDatePatterns` and `LocaleSpec`) in `src/main/ridgun/lib/locale.ridgun`. New languages can be added purely as `LocaleSpec` data entries without modifying formatting logic.

## Algebraic Data Types
- `LocaleDatePatterns String String String String String`
  - Positional constructors: `short_pattern`, `medium_pattern`, `long_pattern`, `full_pattern`, `datetime_connector`.
- `LocaleSpec String String String String String [String] [String] [String] [String] LocaleDatePatterns`
  - Positional constructors: `code`, `autonym`, `plural_rule`, `group_sep`, `decimal_sep`, `months_wide`, `months_short`, `weekdays_wide`, `weekdays_short`, `date_patterns`.
