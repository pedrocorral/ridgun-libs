---
id: API-TST-001
title: Public lib contract for test (test.rglib / libtest.so)
status: approved
implements: [FR-TST-001]
auth: none
---
# API-TST-001 — Public lib contract for `test` (`test.rg`)

## Request
- Imported via `import test`.
- Exported Assertion Functions (`RG-011` & concise helpers):
  - `assert_equals a a String => ()` (3-arg message-annotated equality assertion for `Int`, `String`, `Bool`)
  - `assert_true Bool String => ()` (2-arg message-annotated boolean assertion)
  - `assert_false Bool String => ()` (2-arg message-annotated negated boolean assertion)
  - `assert_str_eq String String String => ()`
  - `assert eq Int Int => ()`, `assert str eq String String => ()`, `assert ok Bool => ()`, `assert false Bool => ()`
  - `check eq Int Int => Bool`, `check str eq String String => Bool`, `check true Bool => Bool`

## Responses
| Code | When | Body |
|---|---|---|
| `()` / `True` | Assertion holds | Returns `()` (or `True` for `check *`) |
| Exit code `1` / `False` | Assertion fails | Prints `"FAIL: <label>"` and calls `sys exit 1` (or returns `False` for `check *`) |

## Rules
- Compatible with both `stable test` and standalone `ridgunc build` test binaries (`RG-011`).
