---
id: FR-CLI-001
title: Provide pure-Ridgun command-line flag, option, positional argument parsing, and typed environment variable readers
type: functional
status: implemented
priority: must
domain: CLI
depends_on: []
related: [ADR-0002, VUL-INPUT-001]
tests: [TS-CLI-001]
---
# FR-CLI-001 — Provide pure-Ridgun command-line flag, option, positional argument parsing, and typed environment variable readers

## Statement
The `cli` library SHALL provide pure-Ridgun command-line argument parsing over `[String]` argument lists (`cli has flag`, `cli get opt`, `cli get int opt`, `cli positionals`, `cli positionals with opts`, `cli subcommand`) supporting `--flag`, `-f`, combined short flags (`-la`), `--key=value`, `--key value`, `-k value`, and `--` end-of-options markers, together with typed environment variable readers (`env get or`, `env get int or`, `env get bool or`).

## Rationale
System utilities (`unix-tools`) and servers (`Solstice`) require ergonomic, deterministic CLI flag/option parsing and environment configuration without invoking external shell parsers.

## Acceptance criteria
- AC1: Given an argument list `[String]`, when `cli has flag args "--verbose" "-v"` is called, then it returns `True` when `--verbose`, `-v`, or a combined short flag group containing `v` (such as `-la` for `-l` and `-a`) appears before `--`, and ignores any token appearing after `--`.
- AC2: Given an argument list `[String]`, when `cli get opt args "--port" "-p" "8080"` and `cli get int opt args "--port" "-p" 8080` are called, then they extract the option value from either `--port=9090`, `--port 9090`, or `-p 9090` before `--`, returning the default fallback when absent or non-numeric.
- AC3: Given an argument list `[String]` and environment variable queries, when `cli positionals`, `cli positionals with opts`, `cli subcommand`, `env get or`, `env get int or`, and `env get bool or` are called, then positional arguments (including flags after `--`) are returned in order, and environment readers return parsed values or safe defaults when unset or malformed.

## Actors & permissions
- Any Ridgun program or lib importing `cli`.

## Constraints & edge cases
- Tokens after `--` are always treated as positional arguments and never matched as flags or options.
- `cli get int opt` and `env get int or` validate that the string is a valid signed decimal integer before converting, returning `default_val` on malformed input.

## Data & privacy
- Pure in-memory argument parsing and read-only environment inspection via `sys_getenv`.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by validating numeric option/env strings and respecting `--` option termination so positional file paths starting with `-` cannot be misinterpreted as flags after `--`.

## Out of scope
- Interactive terminal `readline` line editing.
