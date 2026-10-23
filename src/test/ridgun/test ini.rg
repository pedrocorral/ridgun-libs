-- ============================================================
-- src/test/ridgun/test ini.rg
-- Automated test suite for the INI & Dotenv Configuration Library (`ini.rg`)
-- @tests TS-INI-001
-- ============================================================

import test
import ini

-- @tests TS-INI-001
fn :: test_ini_sections_and_typed_getters => ()
      test_ini_sections_and_typed_getters =
        nl = char_from_code 10
        src = "# App config" + nl + "[database]" + nl + "host = \"127.0.0.1\"" + nl + "port = 5432 ; default pg" + nl + "ssl = true" + nl + nl + "[server]" + nl + "workers = 4" + nl
        doc = ini parse src
        _ = assert str eq (ini get doc "database" "host" "") "127.0.0.1" "AC1: ini get quoted string"
        _ = assert int equals (ini get int doc "database" "port" 0) 5432 "AC1: ini get int with inline comment"
        _ = assert true (ini get bool doc "database" "ssl" False) "AC1: ini get bool"
        _ = assert int equals (ini get int doc "server" "workers" 0) 4 "AC1: ini get second section"
        _ = assert str eq (ini get doc "server" "missing" "default_v") "default_v" "AC1: ini get fallback"
        ()

-- @tests TS-INI-001
fn :: test_dotenv_interpolation_and_roundtrip => ()
      test_dotenv_interpolation_and_roundtrip =
        nl = char_from_code 10
        lb = char_from_code 123
        rb = char_from_code 125
        env_src = "export BASE_DIR=/srv/app" + nl + "LOG_DIR=\"$" + lb + "BASE_DIR" + rb + "/logs\"" + nl + "PORT=8080" + nl
        env = dotenv parse env_src
        _ = assert str eq (dotenv get env "BASE_DIR" "") "/srv/app" "AC2: dotenv export key"
        _ = assert str eq (dotenv get env "LOG_DIR" "") "/srv/app/logs" "AC2: dotenv variable interpolation"
        _ = assert str eq (dotenv get env "PORT" "") "8080" "AC2: dotenv simple key"

        doc0 = ini parse ("[app]" + nl + "name = demo" + nl)
        doc1 = ini set doc0 "app" "version" "1.0"
        out_s = ini stringify doc1
        doc2 = ini parse out_s
        _ = assert str eq (ini get doc2 "app" "name" "") "demo" "AC3: ini stringify round-trip name"
        _ = assert str eq (ini get doc2 "app" "version" "") "1.0" "AC3: ini set + ini stringify round-trip"
        ()

-- @tests TS-INI-001
fn :: main => ()
      main =
        _ = test_ini_sections_and_typed_getters
        _ = test_dotenv_interpolation_and_roundtrip
        echo "[PASS] test ini: TS-INI-001 passed"
