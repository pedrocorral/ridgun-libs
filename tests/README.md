# Acceptance tests for ridgun-libs

These tests check the libraries the way a project that depends on them sees them. A project like that uses the published bundles in `target/bundles/`, not the sources.

They are written outside the libraries' own suites in `src/test/ridgun/`. They cover what those suites leave out:
- bytes that aren't plain ASCII;
- round trips;
- the standards each library cites;
- time that grows with the size of the input.

## Run them
```bash
python3 tests/run.py                 # import check + every tests/test_*.rg
python3 tests/run.py test_codec      # one file (the import check is skipped)
python3 tests/run.py --no-imports    # every file, no import check
```
Every build uses `ridgunc build --strict`, the canonical style the libraries' own builds enforce. A library that isn't strict-clean fails the import check, and every test that imports it doesn't build.

`run.py` works in `~/.cache/ridgun-lib-tests/work`. It copies there only `target/bundles/*.rglib` and `tests/lt.rg`, never the repository. It caps every build and run at 4 GB of address space and a time limit. It ends with a table and exits with 1 if anything failed.

Build the bundles first. The tests see exactly what `target/bundles/` holds.

## What each file checks
| File | Checks | Sources of the expected values |
|---|---|---|
| (import check, in `run.py`) | Every library builds alone, and all 32 build together in one program. A name defined twice anywhere fails here, as RG-062 (`crypto` + `argon2id`) and RG-080 (`codec` + `json`) do | — |
| `test_crypto.rg` | SHA-256: NIST messages, padding boundaries 55–128 bytes, all 256 byte values, NUL, one million `a` | FIPS 180-4, Python `hashlib` |
| | HMAC-SHA256: RFC 4231 cases 1–7, keys of 0/63/64/65 bytes, binary keys | RFC 4231, Python `hmac` |
| | PBKDF2: RFC 7914 §11, lengths that aren't a multiple of 32, empty and binary inputs | RFC 7914, Python `hashlib` |
| | `ct_equal` | — |
| | `byte_str` and `bytes_*` for every byte value | — |
| | ChaCha20-Poly1305: RFC 8439 §2.8.2, plaintexts at block boundaries, AAD only, tamper and length errors | RFC 8439, Python `cryptography` |
| | Argon2id: one, two and four lanes, minimum memory, binary passwords and salts, verify, limits | OpenSSL 3.5 `openssl kdf ARGON2ID` |
| `test_codec.rg` | `url_encode` and `url_decode` on all 256 byte values; `%zz`, truncated `%`, `%00`, `+` | the contract (FR-CODEC-001), RFC 3986 §2.3 |
| | `query_string_decode`: leading `?`, missing `=`, empty items, duplicates, round trip | the contract |
| | hex and base64 / base64url on all byte values; padding and invalid input | RFC 4648, Python `base64` |
| | `json_escape` of control bytes | RFC 8259 §7 |
| | Time stays linear at 200 KB | — |
| `test_str.rg` | `index_of`, `trim`, `replace`, `split`, `join`, case, `repeat` and `pad` with NUL, bytes ≥ 0x80 and UTF-8; `join (split s sep) sep == s`; case on all 256 byte values | the contract (FR-STR-001), Python |
| | Time stays linear at 200 KB for 7 functions | — |
| `test_json.rg` | Texts any parser must refuse or accept; integers beyond 64 bits never wrapped; escapes; stringify escaping every control byte and round trip | RFC 8259, Python's strict `json` |
| | Getters with the wrong type, `get_path`, `set_field`, size and depth limits | the contract (FR-JSON-001) |
| | 100 000 nested arrays without exhausting the stack; time stays linear at 200 KB | — |
| `test_time.rg` | 20 dates from year 1 to 9999: before 1970, century leap rules, 29 February, 2038 and after. Each goes both ways and through ISO 8601, with its day of the week | Python `datetime` |
| | Impossible dates and malformed text give -1 | Python `datetime` |
| | 10 000 format → parse round trips | — |
| | Duration and backoff, including large attempts | the contract (FR-TIME-001) |

`tests/gen/make_*.py` write the `test_*.rg` files. Each script says where every expected value comes from. Re-run it to derive the values again, and change the script, not the generated file. The scripts need Python 3, the `cryptography` package and `openssl` 3.5 or later.

## How the tests are written
- **Each label says what is being held to.**
  - `[contract]` is what `docs/requirements/` promises.
  - `[RFC 8259 §n]` and similar labels are what a standard requires.
  - When the contract departs from the standard, the label says so. One example is JSON numbers being Int only. Then the failure is a decision to take, not a typo to fix.
- **A failure shows what came back.** `lt.rg` prints the actual value and the expected one, with lengths, as hex when the bytes aren't text. It goes on to the next check, so one run shows every failure (`test`'s `assert_*` stop at the first one).
- **Binary inputs are built from byte lists** (`bytes_from_list`), not with the library under test, and never cut with `str_slice`. That built-in snaps to UTF-8 boundaries, so on bytes ≥ 0x80 it doesn't cut where asked.
- **Time is checked as a ratio.**
  - The same work runs on 20 KB and on 200 KB.
  - Linear code takes about 10× as long; quadratic code takes about 100×.
  - The check fails above 20× or above an absolute limit, so it doesn't depend on the machine's speed.

## Adding a test
1. Put it in the generator for that library (or a new `gen/make_<lib>.py`).
2. Give each expected value a source: the RFC or FIPS section, the requirement id, or an independent implementation. Never use the library under test.
3. Say in the label which one it is.
4. Re-run the generator and check that the file builds: `python3 tests/run.py test_<lib>`.
   - The generators pass their output through `gen/rg_strict.py`, so declarations use spaces (`fn :: crypto t range …`), as `--strict` requires.
   - Calls may keep `_`.
