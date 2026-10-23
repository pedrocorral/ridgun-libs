-- ============================================================
-- src/test/ridgun/test ini.rg
-- Comprehensive test suite for ini.rg inspired by rust-ini & dotenvy
-- @tests TS-INI-001
-- ============================================================

import test
import ini

fn :: ini_sec_count [String] => Int
      ini_sec_count []       =  0
      ini_sec_count (_:xs)   =  1 + (ini_sec_count xs)

-- 1. Global keys, multiple sections, inline comments (; and #), quoted '#' preservation, and typed getters
-- @tests TS-INI-001
fn :: test_ini_sections_and_typed_getters => ()
      test_ini_sections_and_typed_getters =
        nl = char_from_code 10
        src = "# Global header comment" + nl + "; Secondary comment" + nl + "global_env = production" + nl + nl + "[database]" + nl + "host = \"127.0.0.1\"" + nl + "port = 5432 ; default pg" + nl + "timeout = -1 # infinite" + nl + "password = \"p@ss#word;123\"" + nl + "ssl = true" + nl + "pool_enabled = yes" + nl + "readonly = 0" + nl + "debug_sql = no" + nl + nl + "[server]" + nl + "workers = 4" + nl + "enabled = 1" + nl
        doc = ini parse src
        _ = assert str eq (ini get doc "" "global_env" "") "production" "AC1: global sectionless key in root '' section"
        _ = assert str eq (ini get doc "database" "host" "") "127.0.0.1" "AC1: ini get quoted string"
        _ = assert int equals (ini get int doc "database" "port" 0) 5432 "AC1: ini get int with ';' inline comment"
        _ = assert int equals (ini get int doc "database" "timeout" 0) (-1) "AC1: ini get negative int with '#' inline comment"
        _ = assert str eq (ini get doc "database" "password" "") "p@ss#word;123" "AC1: quoted '#' and ';' preserved inside string"
        _ = assert true (ini get bool doc "database" "ssl" False) "AC1: ini get bool 'true'"
        _ = assert true (ini get bool doc "database" "pool_enabled" False) "AC1: ini get bool 'yes'"
        _ = assert false (ini get bool doc "database" "readonly" True) "AC1: ini get bool '0'"
        _ = assert false (ini get bool doc "database" "debug_sql" True) "AC1: ini get bool 'off'"
        _ = assert int equals (ini get int doc "server" "workers" 0) 4 "AC1: ini get second section"
        _ = assert true (ini get bool doc "server" "enabled" False) "AC1: ini get bool '1'"
        _ = assert str eq (ini get doc "server" "missing" "default_v") "default_v" "AC1: ini get fallback on missing key"
        _ = assert str eq (ini get doc "no_such_section" "k" "fallback") "fallback" "AC1: ini get fallback on missing section"
        secs = ini sections doc
        _ = assert int equals (ini_sec_count secs) 3 "AC1: 3 sections (root '', database, server)"
        ()

-- 2. Dotenv export, single/double quotes, chained ${VAR} interpolation, and ini set/stringify round-trip
-- @tests TS-INI-001
fn :: test_dotenv_interpolation_and_roundtrip => ()
      test_dotenv_interpolation_and_roundtrip =
        nl = char_from_code 10
        lb = char_from_code 123
        rb = char_from_code 125
        env_src = "# .env test" + nl + "export BASE_DIR=/srv/app" + nl + "APP_NAME='solstice'" + nl + "LOG_DIR=\"$" + lb + "BASE_DIR" + rb + "/$" + lb + "APP_NAME" + rb + "/logs\"" + nl + "WITH_UNKNOWN=\"prefix_$" + lb + "UNDEFINED_VAR" + rb + "_suffix\"" + nl + "PORT=8080 # inline comment" + nl
        env = dotenv parse env_src
        _ = assert str eq (dotenv get env "BASE_DIR" "") "/srv/app" "AC2: dotenv export key"
        _ = assert str eq (dotenv get env "APP_NAME" "") "solstice" "AC2: dotenv single-quoted value"
        _ = assert str eq (dotenv get env "LOG_DIR" "") "/srv/app/solstice/logs" "AC2: dotenv multiple variable interpolations"
        _ = assert str eq (dotenv get env "WITH_UNKNOWN" "") "prefix__suffix" "AC2: dotenv undefined variable expands to empty"
        _ = assert str eq (dotenv get env "PORT" "") "8080" "AC2: dotenv inline comment stripped"
        _ = assert str eq (dotenv get env "MISSING_KEY" "def") "def" "AC2: dotenv missing key fallback"

        doc0 = ini parse ("[app]" + nl + "name = demo" + nl + "port = 3000" + nl)
        doc1 = ini set doc0 "app" "version" "1.0"
        doc2 = ini set doc1 "app" "port" "9090"
        doc3 = ini set doc2 "metrics" "enabled" "true"
        out_s = ini stringify doc3
        doc_rt = ini parse out_s
        _ = assert str eq (ini get doc_rt "app" "name" "") "demo" "AC3: ini stringify round-trip name"
        _ = assert str eq (ini get doc_rt "app" "version" "") "1.0" "AC3: ini set new key + round-trip"
        _ = assert int equals (ini get int doc_rt "app" "port" 0) 9090 "AC3: ini set overwrite existing key + round-trip"
        _ = assert true (ini get bool doc_rt "metrics" "enabled" False) "AC3: ini set new section + round-trip"
        ()

-- @tests TS-INI-001
fn :: main => ()
      main =
        _ = test_ini_sections_and_typed_getters
        _ = test_dotenv_interpolation_and_roundtrip
        echo "[PASS] test ini: TS-INI-001 passed"
