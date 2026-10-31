#!/usr/bin/env python3
"""Run real Luau compilation and economy tests; binaries are passed explicitly."""
import argparse
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--luau", default="luau")
parser.add_argument("--compiler", default="luau-compile")
args = parser.parse_args()
subprocess.run(["python3", "tools/build.py", "--check"], cwd=root, check=True)
files = sorted((root / "src").rglob("*.lua")) + sorted((root / "tests").rglob("*.lua")) + [root / "dist/Brumavale.commandbar.lua"]
for source in files:
    result = subprocess.run([args.compiler, str(source)], capture_output=True, text=True, errors="replace")
    if result.returncode:
        raise SystemExit(f"Compile failed: {source}\n{result.stderr}\n{result.stdout}")
    print(f"COMPILE {source.relative_to(root)}")
subprocess.run([args.luau, "tests/economy.spec.lua"], cwd=root, check=True)
subprocess.run(["python3", "tests/run_profiles.py", "--luau", args.luau], cwd=root, check=True)
