#!/usr/bin/env python3
"""Acceptance tests for ridgun-libs, written outside the libraries' own test suites (see README.md).

Usage: python3 tests/run.py [test_name ...]      (default: the import check and every tests/test_*.rg)
       python3 tests/run.py --no-imports ...     (skip the import check)

Builds against the published bundles (target/bundles/*.rglib), the way a project that depends on ridgun-libs sees
them. The work folder is ~/.cache/ridgun-lib-tests/work: only the bundles are copied, never the repository.
Every build and run is capped at 4 GB of address space and a time limit.
"""
import os, re, resource, shutil, subprocess, sys, time

TESTS = os.path.dirname(os.path.abspath(__file__))
LIBS = os.path.dirname(TESTS)
BUNDLES = os.path.join(LIBS, "target/bundles")
WORK = os.path.join(os.path.expanduser("~"), ".cache", "ridgun-lib-tests", "work")
RIDGUNC = shutil.which("ridgunc") or "/home/boogie/ridgun/ridgun/bin/ridgunc"
BUILD_SECONDS, RUN_SECONDS = 600, 300


def cap():
    resource.setrlimit(resource.RLIMIT_AS, (4_000_000 * 1024, 4_000_000 * 1024))


def sh(cmd, timeout):
    try:
        p = subprocess.run(cmd, cwd=WORK, capture_output=True, text=True, errors="replace", timeout=timeout, preexec_fn=cap)
        return p.returncode, p.stdout + p.stderr
    except subprocess.TimeoutExpired:
        return -1, f"timed out after {timeout} s"


def build(src, name):
    out = os.path.join(WORK, "target", name)
    if os.path.exists(out):
        os.remove(out)
    code, text = sh([RIDGUNC, "build", src, "-o", out], BUILD_SECONDS)
    # ridgunc can report success without writing the file (Solstice register RG-081): check the file.
    return (code == 0 and os.path.exists(out)), text


def first_errors(text, n=6):
    errs = re.findall(r"type error in function '[^']*': [^,\]]*", text) or [l for l in text.splitlines() if l.strip()][-3:]
    return "\n       ".join(errs[:n]) + (f"\n       … {len(errs) - n} more" if len(errs) > n else "")


def prepare():
    shutil.rmtree(WORK, ignore_errors=True)
    os.makedirs(os.path.join(WORK, ".stable/deps"))
    os.makedirs(os.path.join(WORK, "src/main/ridgun/lib"))
    os.makedirs(os.path.join(WORK, "target"))
    bundles = sorted(f for f in os.listdir(BUNDLES) if f.endswith(".rglib"))
    for b in bundles:
        shutil.copy(os.path.join(BUNDLES, b), os.path.join(WORK, ".stable/deps", b))
    shutil.copy(os.path.join(TESTS, "lt.rg"), os.path.join(WORK, "src/main/ridgun/lib/lt.rg"))
    return [b[:-len(".rglib")] for b in bundles]


def import_check(modules):
    """Every library alone, then all of them in one program: a duplicate definition anywhere fails here."""
    rows = []
    for m in modules:
        src = os.path.join(WORK, f"imp_{m}.rg")
        open(src, "w").write(f"import {m}\n\nfn :: main => ()\n      main =  echo \"ok\"\n")
        ok, text = build(src, f"imp_{m}")
        rows.append((f"import {m} (alone)", ok, "" if ok else first_errors(text)))
    src = os.path.join(WORK, "imp_all.rg")
    open(src, "w").write("".join(f"import {m}\n" for m in modules) + "\nfn :: main => ()\n      main =  echo \"ok\"\n")
    ok, text = build(src, "imp_all")
    rows.append((f"import all {len(modules)} libraries together", ok, "" if ok else first_errors(text, 12)))
    return rows


def run_test(path):
    name = os.path.basename(path)[:-3]
    src = os.path.join(WORK, os.path.basename(path))
    shutil.copy(path, src)
    t0 = time.time()
    ok, text = build(src, name)
    if not ok:
        return (name, False, "does not build:\n       " + first_errors(text))
    code, out = sh([os.path.join(WORK, "target", name)], RUN_SECONDS)
    fails = [l for l in out.splitlines() if l.startswith("FAIL") or l.startswith("       ")]
    summary = [l for l in out.splitlines() if l.startswith("ok   ") or l.startswith("[FAIL]")]
    detail = "\n".join(fails) + ("\n" if fails else "") + "\n".join(summary)
    if code != 0 and not fails and not summary:
        detail = f"exit {code} with no report (crash?):\n" + "\n".join(out.splitlines()[-8:])
    return (name, code == 0, detail.strip() + f"   [{time.time() - t0:.0f} s]")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    modules = prepare()
    head = subprocess.run(["git", "-c", f"safe.directory={LIBS}", "log", "-1", "--format=%h %cd", "--date=format:%Y-%m-%d %H:%M"], cwd=LIBS, capture_output=True, text=True).stdout.strip()
    stamp = time.strftime("%Y-%m-%d %H:%M", time.localtime(max(os.path.getmtime(os.path.join(BUNDLES, f)) for f in os.listdir(BUNDLES))))
    print(f"ridgun-libs {head}; newest bundle {stamp}; {RIDGUNC}\n", flush=True)
    rows = []
    if "--no-imports" not in sys.argv and not args:
        for r in import_check(modules):
            rows.append(r)
            print(("ok   " if r[1] else "FAIL ") + r[0] + ("" if r[1] else "\n       " + r[2]), flush=True)
    tests = [os.path.join(TESTS, (a if a.endswith(".rg") else a + ".rg")) for a in args] or sorted(
        os.path.join(TESTS, f) for f in os.listdir(TESTS) if f.startswith("test_") and f.endswith(".rg"))
    for t in tests:
        r = run_test(t)
        rows.append(r)
        print(("\nok   " if r[1] else "\nFAIL ") + r[0] + "\n" + r[2], flush=True)
    failed = [r[0] for r in rows if not r[1]]
    print(f"\n{len(rows) - len(failed)} of {len(rows)} passed" + (": failing " + ", ".join(failed) if failed else ""))
    sys.exit(1 if failed else 0)


main()
