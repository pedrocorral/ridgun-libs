-- ============================================================
-- src/test/ridgun/test cli.rg
-- Comprehensive test suite for cli.rg inspired by POSIX getopt, GNU long options & Rust clap
-- @tests TS-CLI-001
-- ============================================================

import test
import cli

-- 1. Long flags, short flags, bundled short flags (-la, -xvf), and '--' end-of-options barrier
-- @tests TS-CLI-001
fn :: test cli flags and options => ()
      test cli flags and options =
        args = ["serve", "-la", "--verbose", "--port=9090", "-h", "127.0.0.1", "--workers", "-4", "--", "--ignored-flag", "-z", "file.rg"]
        _ = assert true (cli has flag args "--verbose" "-v") "AC1: long flag --verbose"
        _ = assert true (cli has flag args "--all" "-a") "AC1: bundled short flag -a in -la"
        _ = assert true (cli has flag args "--list" "-l") "AC1: bundled short flag -l in -la"
        _ = assert false (cli has flag args "--quiet" "-q") "AC1: missing flag returns False"
        _ = assert false (cli has flag args "--ignored-flag" "") "AC1: long flag after -- is ignored"
        _ = assert false (cli has flag args "" "-z") "AC1: short flag after -- is ignored"
        _ = assert false (cli has flag [] "--verbose" "-v") "AC1: empty args returns False"

        -- Option extraction: --key=val, --key val, -k=val, -k val, empty value --key=
        _ = assert str eq (cli get opt args "--port" "-p" "8080") "9090" "AC2: --port=9090 inline equals"
        _ = assert str eq (cli get opt args "--host" "-h" "0.0.0.0") "127.0.0.1" "AC2: -h 127.0.0.1 separate token"
        _ = assert str eq (cli get opt args "--mode" "-m" "prod") "prod" "AC2: missing option returns fallback"
        _ = assert int equals (cli get int opt args "--port" "-p" 8080) 9090 "AC2: cli_get_int_opt positive int"
        _ = assert int equals (cli get int opt args "--workers" "-w" 1) (0 - 4) "AC2: cli_get_int_opt negative int"
        _ = assert int equals (cli get int opt args "--host" "-h" 8080) 8080 "AC2: non-numeric option falls back to default int"

        short_eq_args = ["-p=3000", "--empty="]
        _ = assert int equals (cli get int opt short_eq_args "--port" "-p" 80) 3000 "AC2: short option -p=3000"
        _ = assert str eq (cli get opt short_eq_args "--empty" "-e" "def") "" "AC2: explicit empty --empty= returns empty string"
        ()

-- 2. Subcommands, positional arguments with option-value skipping, '--' passthrough, and env readers
-- @tests TS-CLI-001
fn :: test cli positionals subcommand and env => ()
      test cli positionals subcommand and env =
        args = ["build", "-v", "--output", "target/app", "-j", "8", "--", "-dashfile.rg", "--another-literal", "main.rg"]
        _ = assert str eq (cli subcommand args) "build" "AC3: cli_subcommand first positional"
        _ = assert str eq (cli subcommand ["-v", "--release", "test"]) "test" "AC3: cli_subcommand skips leading flags"
        _ = assert str eq (cli subcommand ["--help", "-v"]) "" "AC3: cli_subcommand empty when only flags"
        _ = assert str eq (cli subcommand []) "" "AC3: cli_subcommand empty on []"

        pos = cli positionals with opts args ["--output", "-j"]
        _ = assert eq pos ["build", "-dashfile.rg", "--another-literal", "main.rg"]

        -- Single "-" (stdin/stdout convention) is treated as a positional argument, not a flag!
        stdin_args = ["cat", "-n", "-"]
        _ = assert eq (cli positionals stdin_args) ["cat", "-"]

        -- Environment variable readers
        _ = assert true ((str len (env get or "PATH" "")) > 0) "AC4: env_get_or PATH non-empty"
        _ = assert str eq (env get or "RIDGUN_NONEXISTENT_ENV_999" "fallback_val") "fallback_val" "AC4: env_get_or fallback"
        _ = assert int equals (env get int or "RIDGUN_NONEXISTENT_ENV_999" 42) 42 "AC4: env_get_int_or fallback"
        _ = assert true (env get bool or "RIDGUN_NONEXISTENT_ENV_999" True) "AC4: env_get_bool_or True fallback"
        _ = assert false (env get bool or "RIDGUN_NONEXISTENT_ENV_999" False) "AC4: env_get_bool_or False fallback"
        ()

-- @tests TS-CLI-001
fn :: main => ()
      main =
        _ = test cli flags and options
        _ = test cli positionals subcommand and env
        echo "[PASS] test cli: TS-CLI-001 passed"
