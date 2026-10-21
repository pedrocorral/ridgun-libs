---
id: TS-CLI-001
title: Verify CLI flag, option, combined short-flag, positional argument parsing, and typed environment variable readers
level: unit
covers: [FR-CLI-001, API-CLI-001]
status: automated
automated_in: [src/test/ridgun/test_cli.rg]
---
# TS-CLI-001 — Verify CLI flag, option, combined short-flag, positional argument parsing, and typed environment variable readers

## Preconditions / fixtures
- Pure-Ridgun `cli` module (`src/main/ridgun/lib/cli.rg`).

## Steps / inputs
1. Call `cli has flag` with long flags (`--verbose`), short flags (`-v`), combined short flags (`-la`), absent flags, and flags appearing after `--`.
2. Call `cli get opt` and `cli get int opt` with `--port=9090`, `--port 9090`, `-p 9090`, missing options, and invalid integer options (`--port=abc`).
3. Call `cli positionals`, `cli positionals with opts`, `cli subcommand`, `env get or`, `env get int or`, and `env get bool or` across set (`PATH`, `HOME`) and unset environment variables.

## Expected results (map to acceptance criteria)
- AC1 → `cli has flag` accurately detects long, short, and bundled short flags before `--` and ignores tokens after `--`.
- AC2 → `cli get opt` and `cli get int opt` extract `--key=val`, `--key val`, and `-k val` and return fallback defaults when absent or invalid.
- AC3 → `cli positionals`, `cli positionals with opts`, `cli subcommand`, and `env get *_or` return exact positional arguments and environment values/defaults.

## Not covered here (to avoid duplication)
- Subprocess execution is covered in `TS-IO-001` and `TS-POSIX-001`.
