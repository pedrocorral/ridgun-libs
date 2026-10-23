---
id: DM-Ini
title: INI sectioned configuration and Dotenv models
status: approved
related: [FR-INI-001, API-INI-001, ADR-0002]
---
# DM-Ini — INI sectioned configuration and Dotenv models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| section_name | String | Trimmed identifier or `""` for root/dotenv scope | Section header `[section]` in INI documents |

## Relations
- Used by `ini.rg` (`IniDoc`) to parse, interpolate (`${VAR}`), query, and serialize `.ini` and `.env` configuration files.

## Invariants
- Blank lines and comment lines starting with `#`, `;`, or `--` are ignored during parsing.
- Quoted values (`"..."` and `'...'`) strip outer quotes and unescape `\n`, `\t`, and `\"`.

## Lifecycle
- Parsed in memory via `ini parse` or `dotenv parse`, queried via `ini get` / `dotenv get`, and serialized via `ini stringify`.
