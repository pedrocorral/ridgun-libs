-- ============================================================
-- src/test/ridgun/test uuid.rg
-- Automated test suite for uuid.rg (TS-UUID-001)
-- @tests TS-UUID-001
-- ============================================================

import test
import uuid

fn :: prng seed (Int Int) => Int
      prng seed (s, _)    =  s

fn :: prng val (Int Int) => Int
      prng val (_, v)    =  v

-- @tests TS-UUID-001
fn :: test uuidv4 and uuidv7 => ()
      test uuidv4 and uuidv7 =
        u4a = uuid v4
        u4b = uuid v4
        _   = assert int equals (str len u4a) 36 "uuid v4 len 36"
        _   = assert true (uuid is valid u4a) "uuid v4 valid"
        _   = assert true (uuid is valid u4b) "uuid v4 second valid"
        _   = assert false (u4a == u4b) "two uuid v4 calls are distinct"
        _   = assert int equals (uuid version u4a) 4 "uuid v4 version == 4"
        u7a = uuid v7 at 1700000000000
        u7b = uuid v7 at 1800000000000
        _   = assert true (uuid is valid u7a) "uuid v7 valid"
        _   = assert int equals (uuid version u7a) 7 "uuid v7 version == 7"
        _   = assert str eq (str slice u7a 0 8) "018bcfe5" "uuid v7 timestamp prefix 1700000000000"
        _   = assert str eq (str slice u7b 0 8) "01a3185c" "uuid v7 timestamp prefix 1800000000000"
        _   = assert false (uuid is valid "not-a-uuid") "invalid uuid length"
        _   = assert false (uuid is valid "550e8400-e29b-41d4-1716-446655440000") "invalid RFC 9562 variant nibble 1"
        _   = assert int equals (uuid version "not-a-uuid") (0 - 1) "invalid uuid version -> -1"
        ()

-- @tests TS-UUID-001
fn :: test checksums and prng => ()
      test checksums and prng =
        _  = assert int equals (fnv1a 32 "foobar") 3214735720 "FNV-1a 32 foobar == 0xbf9cf968"
        _  = assert int equals (adler32 "Wikipedia") 300286872 "Adler-32 Wikipedia == 0x11e60398"
        _  = assert int equals (crc32 "123456789") 3421780262 "CRC-32 123456789 == 0xcbf43926"
        s1 = prng next 42
        s2 = prng next 42
        _  = assert int equals s1 s2 "prng next deterministic"
        r1 = prng range 42 10 20
        v1 = prng val r1
        _  = assert true (v1 >= 10 and v1 <= 20) "prng range within [10, 20]"
        ()

fn :: main => ()
      main =
        _ = test uuidv4 and uuidv7
        _ = test checksums and prng
        echo "[PASS] test uuid: TS-UUID-001 passed"
