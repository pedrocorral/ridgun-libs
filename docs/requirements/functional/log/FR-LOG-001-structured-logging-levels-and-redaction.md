---
id: FR-LOG-001
title: Provide pure-Ridgun level-filtered text and NDJSON structured logging with automatic secret redaction
type: functional
status: implemented
priority: must
domain: LOG
depends_on: []
related: [ADR-0002, NFR-OBS-001, VUL-INPUT-001]
tests: [TS-LOG-001]
---
# FR-LOG-001 — Provide pure-Ridgun level-filtered text and NDJSON structured logging with automatic secret redaction

## Statement
The `log` library SHALL provide pure-Ridgun structured logging primitives (`log level rank`, `log level name`, `log should emit`, `log is sensitive key`, `log redact fields`, `log format text`, `log format json`).

## Rationale
Applications and servers require structured text and JSON (`NDJSON`) log formatting with severity filtering (`DEBUG`, `INFO`, `WARN`, `ERROR`) and automatic redaction of credentials (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key`) so sensitive values never leak into log streams.

## Acceptance criteria
- AC1: Given severity strings (`"DEBUG"`, `"INFO"`, `"WARN"`, `"ERROR"`), when `log level rank`, `log level name`, and `log should emit min_level msg_level` are called, then `log should emit "WARN" "INFO"` returns `False` and `log should emit "WARN" "ERROR"` returns `True`.
- AC2: Given key-value field lists `[(String, String)]`, when `log is sensitive key` and `log redact fields` are called, then keys matching `password`, `passwd`, `secret`, `token`, `api_key`, `apikey`, `authorization`, `cookie`, or `private_key` (case-insensitively) have their values replaced with `"[REDACTED]"`, while non-sensitive fields remain intact.
- AC3: Given a level, message, and field list `[(String, String)]`, when `log format text` and `log format json` are called, then they produce sanitized text (`[LEVEL] msg key=val`) and escaped single-line JSON (`{"level":"...","msg":"...",...}`) with sensitive fields redacted.

## Actors & permissions
- Any Ridgun program or lib importing `log`.

## Constraints & edge cases
- Control characters (`"`, `\`, `\n`, `\r`, `\t`) in log messages and field values are escaped in both text and JSON output to prevent log injection.

## Data & privacy
- Automatically redacts secret/credential keys to `[REDACTED]`.

## Security & observability notes
- Implements `NFR-OBS-001` and mitigates `VUL-INPUT-001` (log injection and secret leakage).

## Out of scope
- Remote syslog UDP transport (use `socket` + `log format json`).
