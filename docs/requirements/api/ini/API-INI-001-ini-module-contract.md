---
id: API-INI-001
title: Public lib contract for ini (ini.rglib / libini.so)
status: approved
implements: [FR-INI-001]
auth: none
---
# API-INI-001 — Public lib contract for `ini` (`ini.rg`)

## Request
- Imported via `import ini`.
- Public Types (see `DM-Ini`):
  - `type IniSection = section_name: String, entries: [(String, String)]`
  - `type IniDoc = sections: [IniSection]`
- Parsing & Serialization:
  - `ini parse String => IniDoc`
  - `dotenv parse String => [(String, String)]`
  - `ini stringify IniDoc => String`
- Queries & Mutation:
  - `ini get IniDoc String String String => String`
  - `ini get int IniDoc String String Int => Int`
  - `ini get bool IniDoc String String Bool => Bool`
  - `ini set IniDoc String String String => IniDoc`
  - `ini sections IniDoc => [String]`
  - `dotenv get [(String, String)] String String => String`

## Responses
| Code | When | Body |
|---|---|---|
| `IniDoc` | `ini parse` or `ini set` | Parsed or updated INI document |
| `[(String, String)]` | `dotenv parse` | Interpolated key-value pairs |
| `String` / `Int` / `Bool` | `ini get*` / `dotenv get` | Resolved configuration value or fallback |

## Rules
- Keys before the first `[section]` header reside in the `""` root section.
