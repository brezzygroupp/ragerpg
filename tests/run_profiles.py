#!/usr/bin/env python3
"""Build and run the Profiles module against a deterministic DataStore mock."""
from pathlib import Path
import argparse
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def long_string(source: str) -> str:
    for length in range(1, 16):
        separator = "=" * length
        if f"]{separator}]" not in source:
            return f"[{separator}[\n{source}]{separator}]"
    raise ValueError("Could not safely quote Luau source")


parser = argparse.ArgumentParser()
parser.add_argument("--luau", required=True)
args = parser.parse_args()
template = (ROOT / "tests/profiles_harness.luau.tmpl").read_text(encoding="utf-8")
for marker, source in {
    "__CONFIG_SOURCE__": ROOT / "src/shared/Config.lua",
    "__ECONOMY_SOURCE__": ROOT / "src/server/Economy.lua",
    "__PROFILES_SOURCE__": ROOT / "src/server/Profiles.lua",
}.items():
    template = template.replace(marker, long_string(source.read_text(encoding="utf-8")), 1)
with tempfile.NamedTemporaryFile("w", suffix=".lua", encoding="utf-8") as runner:
    runner.write(template)
    runner.flush()
    subprocess.run([args.luau, runner.name], cwd=ROOT, check=True)
