---
id: FR-TST-001
title: Provide RG-011 test assertion library with message-annotated and concise assertion helpers
type: functional
status: implemented
priority: must
domain: TST
depends_on: []
related: [ADR-0002]
tests: [TS-TST-001]
---
# FR-TST-001 — Provide RG-011 test assertion library with message-annotated and concise assertion helpers

## Statement
The `test` library SHALL provide the `RG-011` message-annotated test assertions (`assert_equals actual expected label => ()`, `assert_true cond label => ()`, `assert_false cond label => ()`, `assert_str_eq actual expected label => ()`) as well as concise assertion helpers (`assert eq`, `assert ok`, `assert false`, `check eq`, `check true`) that exit with code `1` and print diagnostic failure details when an assertion fails.

## Rationale
`stable test` and Solstice test suites (`RG-011`) require `import test` to expose `assert_equals a b msg` and `assert_true cond msg` that fail the test binary with a non-zero exit code on mismatch while remaining silent or clear on pass.

## Acceptance criteria
- AC1: Given equal values `a` and `b` and `cond == True`, when `assert_equals a b "msg"` and `assert_true cond "msg"` are called, then both return `()` without exiting the process.
- AC2: Given non-equal values `a != b` or `cond == False`, when `assert_equals a b "msg"` or `assert_true cond "msg"` (or `assert_false True "msg"`) is called, then it prints a diagnostic failure message containing `"FAIL"` and `"msg"` and terminates the test process with exit code `1` (or returns `False` for non-exiting `check eq` / `check true` predicates).
- AC3: Given existing 2-argument `assert eq a b` and 1-argument `assert ok cond` calls across test suites, when invoked, then they remain fully supported alongside the 3-argument `assert_equals` and 2-argument `assert_true` functions.

## Actors & permissions
- Any Ridgun test suite (`src/test/ridgun/test_*.rg`) importing `test`.

## Constraints & edge cases
- Must compile as a reusable `.rglib` and `.so` without a `main` entrypoint.

## Data & privacy
- No persistent data or PII.

## Security & observability notes
- Emits deterministic `"FAIL: <label>"` diagnostics on assertion failure (`NFR-OBS-001`).

## Out of scope
- Parallel test runner orchestration (handled by `stable test`).
