#!/usr/bin/env python3
"""Writes tests/test_crypto.rg. Every expected value comes from a source independent of ridgun-libs:
FIPS 180-4 / RFC 4231 / RFC 7914 / RFC 8439 published vectors, Python's hashlib/hmac, the `cryptography`
package (ChaCha20-Poly1305) and OpenSSL 3.5's Argon2id (`openssl kdf ... ARGON2ID`). Re-run it to re-derive them."""
import base64, hashlib, hmac, os, subprocess
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rg_strict import strict
from cryptography.hazmat.primitives.ciphers.aead import ChaCha20Poly1305

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "test_crypto.rg")


def rg_bytes(b):
    """A Ridgun expression that builds these exact bytes (no codec involved)."""
    if all(32 <= c < 127 and c not in (34, 92, 123, 125) for c in b):
        return '"' + b.decode() + '"'
    if len(set(b)) == 1 and len(b) > 4:
        return f"(str_repeat (byte_str {b[0]}) {len(b)})"
    return "(bytes_from_list [" + ", ".join(str(c) for c in b) + "])"


def q(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("{", "\\{").replace("}", "\\}")


checks = []


def add(line):
    checks.append(line)


# ── SHA-256 (FIPS 180-4; NIST example messages; padding boundaries; binary input) ──
add('lt_eq "SHA-256 FIPS 180-4: empty message" (sha256_hex "") "%s"' % hashlib.sha256(b"").hexdigest())
add('lt_eq "SHA-256 FIPS 180-4: abc" (sha256_hex "abc") "%s"' % hashlib.sha256(b"abc").hexdigest())
m448 = b"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
add('lt_eq "SHA-256 NIST: 448-bit message (two blocks)" (sha256_hex "%s") "%s"' % (m448.decode(), hashlib.sha256(m448).hexdigest()))
m896 = b"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"
add('lt_eq "SHA-256 NIST: 896-bit message" (sha256_hex "%s") "%s"' % (m896.decode(), hashlib.sha256(m896).hexdigest()))
for n in [55, 56, 57, 63, 64, 65, 119, 120, 127, 128]:
    add('lt_eq "SHA-256 padding boundary: %d bytes" (sha256_hex (str_repeat "x" %d)) "%s"' % (n, n, hashlib.sha256(b"x" * n).hexdigest()))
add('lt_eq "SHA-256 of all 256 byte values 0..255 (NUL and >= 0x80 must be hashed as bytes)" (sha256_hex (bytes_from_list (crypto_t_range 0 256 []))) "%s"' % hashlib.sha256(bytes(range(256))).hexdigest())
add('lt_eq "SHA-256 with a NUL byte inside" (sha256_hex %s) "%s"' % (rg_bytes(b"a\x00b"), hashlib.sha256(b"a\x00b").hexdigest()))
add('lt_eq "SHA-256 NIST: one million a" (sha256_hex (str_repeat "a" 1000000)) "%s"' % hashlib.sha256(b"a" * 1000000).hexdigest())
add('lt_hex "sha256_bytes gives the same digest as 32 raw bytes" (sha256_bytes "abc") "%s"' % hashlib.sha256(b"abc").hexdigest())

# ── HMAC-SHA256 (RFC 4231 §4.2–4.8; key sizes around the 64-byte block) ──
rfc4231 = [("TC1", b"\x0b" * 20, b"Hi There", None), ("TC2", b"Jefe", b"what do ya want for nothing?", None),
           ("TC3", b"\xaa" * 20, b"\xdd" * 50, None), ("TC4", bytes(range(1, 26)), b"\xcd" * 50, None),
           ("TC5 (first 128 bits)", b"\x0c" * 20, b"Test With Truncation", 16),
           ("TC6 (131-byte key)", b"\xaa" * 131, b"Test Using Larger Than Block-Size Key - Hash Key First", None),
           ("TC7 (131-byte key and data)", b"\xaa" * 131, b"This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm.", None)]
for name, k, d, trunc in rfc4231:
    mac = hmac.new(k, d, hashlib.sha256).digest()
    if trunc:
        add('lt_hex "HMAC-SHA256 RFC 4231 %s" (crypto_t_take (hmac_sha256 %s %s) %d) "%s"' % (name, rg_bytes(k), rg_bytes(d), trunc, mac[:trunc].hex()))
    else:
        add('lt_hex "HMAC-SHA256 RFC 4231 %s" (hmac_sha256 %s %s) "%s"' % (name, rg_bytes(k), rg_bytes(d), mac.hex()))
for n in [0, 63, 64, 65]:
    k = b"k" * n
    add('lt_hex "HMAC-SHA256 with a %d-byte key (block size is 64)" (hmac_sha256 (str_repeat "k" %d) "m") "%s"' % (n, n, hmac.new(k, b"m", hashlib.sha256).hexdigest()))
add('lt_hex "HMAC-SHA256 key and message with NUL and high bytes" (hmac_sha256 %s %s) "%s"' % (rg_bytes(b"k\x00\xff"), rg_bytes(b"\x00\x80\xfe"), hmac.new(b"k\x00\xff", b"\x00\x80\xfe", hashlib.sha256).hexdigest()))

# ── PBKDF2-HMAC-SHA256 (RFC 7914 §11; lengths that aren't a multiple of 32; empty and binary inputs) ──
pb = [("RFC 7914 §11: passwd/salt c=1 dkLen=64", b"passwd", b"salt", 1, 64), ("RFC 7914 §11: Password/NaCl c=80000 dkLen=64", b"Password", b"NaCl", 80000, 64),
      ("dkLen 20 (shorter than one block)", b"password", b"salt", 2, 20), ("dkLen 33 (one byte into the second block)", b"password", b"salt", 4096, 33),
      ("empty password and salt", b"", b"", 1, 32), ("NUL bytes in password and salt", b"pass\x00word", b"sa\x00lt", 4096, 16),
      ("bytes >= 0x80 in password and salt", "contraseña".encode(), bytes([0xff, 0x80, 0x00, 0x7f]), 10, 32)]
for name, p, s, c, n in pb:
    add('lt_hex "PBKDF2-HMAC-SHA256 %s" (pbkdf2_hmac_sha256 %s %s %d %d) "%s"' % (name, rg_bytes(p), rg_bytes(s), c, n, hashlib.pbkdf2_hmac("sha256", p, s, c, n).hex()))
add('lt_eq "PBKDF2 with 0 iterations gives \\"\\" (FR-CRYPTO-003)" (pbkdf2_hmac_sha256 "p" "s" 0 32) ""')
add('lt_eq "PBKDF2 with dk_len 0 gives \\"\\" (FR-CRYPTO-003)" (pbkdf2_hmac_sha256 "p" "s" 1 0) ""')

# ── ct_equal ──
add('lt_true "ct_equal: equal strings" (ct_equal "abcdef" "abcdef")')
add('lt_true "ct_equal: two empty strings" (ct_equal "" "")')
add('lt_false "ct_equal: last byte differs" (ct_equal "abcdef" "abcdeg")')
add('lt_false "ct_equal: first byte differs" (ct_equal "abcdef" "bbcdef")')
add('lt_false "ct_equal: a prefix is not equal" (ct_equal "abc" "abcdef")')
add('lt_false "ct_equal: differs only in a byte >= 0x80" (ct_equal %s %s)' % (rg_bytes(b"a\x80"), rg_bytes(b"a\x81")))
add('lt_false "ct_equal: differs only in NUL vs 0x01" (ct_equal %s %s)' % (rg_bytes(b"a\x00"), rg_bytes(b"a\x01")))

# ── Bytes (FR-CRYPTO-003: str_len (byte_str n) == 1 for 0..255, values round-trip) ──
add('lt_true "byte_str n is one byte for every n in 0..255" (crypto_t_all_one_byte 0)')
add('lt_true "bytes_to_list (bytes_from_list 0..255) gives 0..255 back" (crypto_t_same_ints (bytes_to_list (bytes_from_list (crypto_t_range 0 256 []))) (crypto_t_range 0 256 []))')

# ── ChaCha20-Poly1305 (RFC 8439 §2.8.2; and block-boundary lengths, checked with the `cryptography` package) ──
key = bytes(range(0x80, 0xa0))
nonce = bytes.fromhex("070000004041424344454647")
aad = bytes.fromhex("50515253c0c1c2c3c4c5c6c7")
pt = b"Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."
ct = ChaCha20Poly1305(key).encrypt(nonce, pt, aad)
assert ct[-16:].hex() == "1ae10b594f09e26a7e902ecbd0600691"  # the tag printed in RFC 8439 §2.8.2
add('lt_hex "ChaCha20-Poly1305 RFC 8439 §2.8.2: ciphertext || tag" (aead_seal crypto_t_key crypto_t_nonce crypto_t_aad "%s") "%s"' % (q(pt.decode()), ct.hex()))
add('lt_eq "ChaCha20-Poly1305 RFC 8439 §2.8.2: open gives the plaintext back" (crypto_t_opened (aead_open crypto_t_key crypto_t_nonce crypto_t_aad (aead_seal crypto_t_key crypto_t_nonce crypto_t_aad "%s"))) "0 %s"' % (q(pt.decode()), q(pt.decode())))
for n in [0, 1, 63, 64, 65, 128, 1000]:
    p = bytes((i * 7 + 3) % 256 for i in range(n))
    c = ChaCha20Poly1305(key).encrypt(nonce, p, b"")
    add('lt_hex "ChaCha20-Poly1305 with %d bytes of plaintext and no AAD" (aead_seal crypto_t_key crypto_t_nonce "" (bytes_from_list (crypto_t_pattern 0 %d []))) "%s"' % (n, n, c.hex()))
c = ChaCha20Poly1305(key).encrypt(nonce, b"", aad)
add('lt_hex "ChaCha20-Poly1305 with AAD only (empty plaintext)" (aead_seal crypto_t_key crypto_t_nonce crypto_t_aad "") "%s"' % c.hex())
add('lt_int "aead_open of exactly a 16-byte tag (empty plaintext) succeeds" (crypto_t_code (aead_open crypto_t_key crypto_t_nonce crypto_t_aad (aead_seal crypto_t_key crypto_t_nonce crypto_t_aad ""))) 0')
add('lt_int "aead_open with a different AAD fails with -12" (crypto_t_code (aead_open crypto_t_key crypto_t_nonce "other" (aead_seal crypto_t_key crypto_t_nonce crypto_t_aad "secret"))) (0 - 12)')
add('lt_int "aead_open with 15 bytes fails with -7 (too short for a tag)" (crypto_t_code (aead_open crypto_t_key crypto_t_nonce "" (str_repeat "x" 15))) (0 - 7)')
add('lt_eq "aead_seal with a 31-byte key gives \\"\\"" (aead_seal (bytes_from_list (crypto_t_range 128 159 [])) crypto_t_nonce "" "x") ""')
add('lt_eq "aead_seal with an 8-byte nonce gives \\"\\" (RFC 8439 uses 96-bit nonces)" (aead_seal crypto_t_key (bytes_from_list [7, 0, 0, 0, 64, 65, 66, 67]) "" "x") ""')

# ── Argon2id (RFC 9106) against OpenSSL 3.5: several lanes, minimum memory, binary passwords ──
def argon(p, s, m, t, l):
    out = subprocess.run(["openssl", "kdf", "-keylen", "32", "-kdfopt", "hexpass:" + p.hex(), "-kdfopt", "hexsalt:" + s.hex(),
                          "-kdfopt", f"iter:{t}", "-kdfopt", f"memcost:{m}", "-kdfopt", f"lanes:{l}", "ARGON2ID"],
                         capture_output=True, text=True, check=True).stdout.strip().replace(":", "")
    b64 = lambda b: base64.b64encode(b).decode().rstrip("=")
    return f"$argon2id$v=19$m={m},t={t},p={l}${b64(s)}${b64(bytes.fromhex(out))}"
for name, p, s, m, t, l in [("one lane, t=1", b"password", b"somesalt", 64, 1, 1), ("two lanes", b"password", b"somesalt", 64, 2, 2),
                            ("four lanes, t=3", b"password", b"somesaltsomesalt", 128, 3, 4), ("minimum memory m = 8 * lanes", b"pw", b"saltsalt", 16, 1, 2),
                            ("password of 100 bytes", b"p" * 100, b"somesalt", 32, 1, 1), ("password with NUL and bytes >= 0x80", b"pa\x00ss\xff\x80", b"somesalt", 32, 1, 1),
                            ("salt with NUL and bytes >= 0x80", b"password", b"\x00\xff\x80saltx", 32, 1, 1)]:
    add('lt_eq "Argon2id = OpenSSL 3.5: %s" (argon2id_hash %s %s %d %d %d) "%s"' % (name, rg_bytes(p), rg_bytes(s), m, t, l, argon(p, s, m, t, l).replace("$", "$")))
add('lt_true "argon2id_verify accepts the right password" (argon2id_verify "password" (argon2id_hash "password" "somesalt" 32 1 1))')
add('lt_false "argon2id_verify refuses a wrong password" (argon2id_verify "Password" (argon2id_hash "password" "somesalt" 32 1 1))')
add('lt_false "argon2id_verify refuses a PHC string whose tag was changed" (argon2id_verify "password" "%s")' % (argon(b"password", b"somesalt", 32, 1, 1)[:-2] + "AA"))
add('lt_eq "Argon2id with a 7-byte salt gives \\"\\" (RFC 9106 minimum is 8)" (argon2id_hash "password" "7bytes!" 32 1 1) ""')
add('lt_eq "Argon2id with 256 lanes gives \\"\\" (at most 255)" (argon2id_hash "password" "somesalt" 4096 1 256) ""')

body = "\n".join(f"        c{i} = {c}" for i, c in enumerate(checks))
names = ", ".join(f"c{i}" for i in range(len(checks)))
src = f'''-- test_crypto.rg — crypto (and argon2id through crypto) against published vectors and independent references.
-- Generated by tests/gen/make_crypto.py: every expected value there says where it comes from (FIPS 180-4,
-- RFC 4231, RFC 7914, RFC 8439, Python hashlib/hmac, the `cryptography` package, OpenSSL 3.5 Argon2id).
-- Inputs are built with bytes_from_list / byte_str, never with codec, so a codec bug can't hide a crypto one.
-- Binary values are never cut with str_slice: that built-in snaps to UTF-8 boundaries, so on bytes >= 0x80 it
-- doesn't cut where asked (Solstice register RG-087); crypto_t_take cuts byte lists instead.

import test
import str
import crypto
import lt

fn :: crypto_t_range Int Int [Int] => [Int]
      crypto_t_range i n acc =
        | i >= n    = acc
        | otherwise = crypto_t_range (i + 1) n (acc :: [i])

-- (i * 7 + 3) mod 256, the plaintext pattern make_crypto.py uses.
fn :: crypto_t_pattern Int Int [Int] => [Int]
      crypto_t_pattern i n acc =
        | i >= n    = acc
        | otherwise = crypto_t_pattern (i + 1) n (acc :: [(i * 7 + 3) % 256])

fn :: crypto_t_all_one_byte Int => Bool
      crypto_t_all_one_byte n =
        | n > 255                       = True
        | (str_len (byte_str n)) != 1   = False
        | otherwise                     = crypto_t_all_one_byte (n + 1)

fn :: crypto_t_same_ints [Int] [Int] => Bool
      crypto_t_same_ints []     []     =  True
      crypto_t_same_ints (a:as) (b:bs) =  a == b and (crypto_t_same_ints as bs)
      crypto_t_same_ints _      _      =  False

fn :: crypto_t_take String Int => String
      crypto_t_take s n =  bytes_from_list (crypto_t_first (bytes_to_list s) n [])

fn :: crypto_t_first [Int] Int [Int] => [Int]
      crypto_t_first []     _ acc =  acc
      crypto_t_first (b:bs) n acc =
        | n <= 0    = acc
        | otherwise = crypto_t_first bs (n - 1) (acc :: [b])

fn :: crypto_t_key => String
      crypto_t_key =  bytes_from_list (crypto_t_range 128 160 [])

fn :: crypto_t_nonce => String
      crypto_t_nonce =  bytes_from_list [7, 0, 0, 0, 64, 65, 66, 67, 68, 69, 70, 71]

fn :: crypto_t_aad => String
      crypto_t_aad =  bytes_from_list [80, 81, 82, 83, 192, 193, 194, 195, 196, 197, 198, 199]

fn :: crypto_t_code (Int, String) => Int
      crypto_t_code (c, _) =  c

fn :: crypto_t_opened (Int, String) => String
      crypto_t_opened (c, p) =  (int_to_str c) + " " + p

fn :: main => ()
      main =
{body}
        lt_done "crypto" [{names}]
'''
open(OUT, "w").write(strict(src))
print(f"wrote {OUT}: {len(checks)} checks")
