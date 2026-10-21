-- ============================================================
-- src/test/ridgun/test_cli.rg
-- Automated test suite for cli.rg (TS-CLI-001)
-- @tests TS-CLI-001
-- ============================================================

import test
import cli

-- @tests TS-CLI-001
fn :: test cli flags and options => ()
      test cli flags and options =
        args = ["serve", "-la", "--verbose", "--port=9090", "-h", "127.0.0.1", "--", "--ignored-flag", "file.rg"]
        _    = assert_true (cli has flag args "--verbose" "-v") "long flag --verbose"
        _    = assert_true (cli has flag args "--all" "-a") "bundled short flag -a in -la"
        _    = assert_true (cli has flag args "--list" "-l") "bundled short flag -l in -la"
        _    = assert_false (cli has flag args "--quiet" "-q") "missing flag"
        _    = assert_false (cli has flag args "--ignored-flag" "") "flag after -- is ignored"
        _    = assert_str_eq (cli get opt args "--port" "-p" "8080") "9090" "--port=9090"
        _    = assert_str_eq (cli get opt args "--host" "-h" "0.0.0.0") "127.0.0.1" "-h 127.0.0.1"
        _    = assert_str_eq (cli get opt args "--mode" "-m" "prod") "prod" "fallback default"
        _    = assert_int_equals (cli get int opt args "--port" "-p" 8080) 9090 "cli_get_int_opt 9090"
        _    = assert_int_equals (cli get int opt args "--host" "-h" 8080) 8080 "non-int falls back to default"
        ()

-- @tests TS-CLI-001
fn :: test cli positionals subcommand and env => ()
      test cli positionals subcommand and env =
        args = ["build", "-v", "--output", "target/app", "--", "-dashfile.rg", "main.rg"]
        _    = assert_str_eq (cli subcommand args) "build" "cli_subcommand"
        _    = assert_str_eq (cli subcommand ["--help"]) "" "cli_subcommand empty when only flags"
        pos  = cli positionals with opts args ["--output"]
        _    = assert eq pos ["build", "-dashfile.rg", "main.rg"]
        -- Environment variable readers
        _    = assert_true ((str_len (env get or "PATH" "")) > 0) "env_get_or PATH non-empty"
        _    = assert_str_eq (env get or "RIDGUN_NONEXISTENT_ENV_999" "fallback_val") "fallback_val" "env_get_or fallback"
        _    = assert_int_equals (env get int or "RIDGUN_NONEXISTENT_ENV_999" 42) 42 "env_get_int_or fallback"
        _    = assert_true (env get bool or "RIDGUN_NONEXISTENT_ENV_999" True) "env_get_bool_or True fallback"
        _    = assert_false (env get bool or "RIDGUN_NONEXISTENT_ENV_999" False) "env_get_bool_or False fallback"
        ()

fn :: main => ()
      main =
        _ = test cli flags and options
        _ = test cli positionals subcommand and env
        echo "[PASS] test_cli: TS-CLI-001 passed"
