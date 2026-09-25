#!/usr/bin/env python3
"""Fail on engine diagnostics even when Godot returns exit code zero."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("engine")
parser.add_argument("--exported", action="store_true")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
engine = str(Path(args.engine).resolve()) if Path(args.engine).exists() else args.engine
errors = re.compile(r"(SCRIPT ERROR:|ERROR:|Parse Error|Failed to load)", re.I)

with tempfile.TemporaryDirectory(prefix="iron-mario-test-") as temp:
    env = dict(os.environ, XDG_DATA_HOME=temp, APPDATA=temp)
    count = 0

    def run(label, extra, timeout=90, expected=None):
        global count
        log = Path(temp) / f"engine-{count}.log"
        count += 1
        command = [engine, "--headless", "--path", str(Path(engine).parent if args.exported else root), "--log-file", str(log), *extra]
        result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=timeout)
        output = result.stdout + result.stderr
        if log.exists():
            output += log.read_text(encoding="utf-8", errors="replace")
        if result.returncode or errors.search(output) or (expected and expected not in output):
            raise SystemExit(f"FAIL {label} (exit {result.returncode})\n{output}")
        if expected:
            print(result.stdout, flush=True)
        print(f"PASS {label}", flush=True)

    if not args.exported:
        run("editor import", ["--editor", "--import"], 180)
        run("mechanics and transitions", ["tools/runtime_tests.tscn"], expected="RUNTIME TESTS: 0 failures")
        run("hero profiles and touch input", ["tools/mobile_tests.tscn"], expected="MOBILE TESTS: 0 failures")
    run("F5 title startup", ["--quit-after", "60"])
    scenes = sorted((root / "scenes").rglob("*.tscn"))
    for scene in scenes:
        run(str(scene.relative_to(root)), ["res://" + scene.relative_to(root).as_posix(), "--quit-after", "30"])
    print(f"ENGINE CHECKS PASSED: {count}", flush=True)
