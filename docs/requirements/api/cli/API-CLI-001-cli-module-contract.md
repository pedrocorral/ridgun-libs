---
id: API-CLI-001
title: Public lib contract for cli (cli.rglib / libcli.so)
status: approved
implements: [FR-CLI-001]
auth: none
---
# API-CLI-001 — Public lib contract for `cli` (`cli.rg`)

## Request
- Imported via `import cli`.
- Command-Line Parsing (`[String]`):
  - `cli has flag [String] String String => Bool`
  - `cli get opt [String] String String String => String`
  - `cli get int opt [String] String String Int => Int`
  - `cli positionals [String] => [String]`
  - `cli positionals with opts [String] [String] => [String]`
  - `cli subcommand [String] => String`
- Typed Environment Variable Readers:
  - `env get or String String => String`
  - `env get int or String Int => Int`
  - `env get bool or String Bool => Bool`

## Responses
| Code | When | Body |
|---|---|---|
| `Bool` / `String` / `Int` / `[String]` | Flag check, option lookup, positional extraction, or env lookup | Parsed value or caller-supplied default fallback |

## Rules
- All argument parsing functions respect `--` as the POSIX end-of-options delimiter.
