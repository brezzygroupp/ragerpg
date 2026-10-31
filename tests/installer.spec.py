#!/usr/bin/env python3
"""Regression checks for the offline Studio installer bootstrap."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
bundle = (ROOT / "dist/Brumavale.commandbar.lua").read_text(encoding="utf-8")

checks = {
    "runnable scripts start disabled": 'object:IsA("BaseScript") then object.Enabled = false' in bundle,
    "client reference is retained": 'local client = make("LocalScript","BrumavaleClient"' in bundle,
    "server is enabled": "main.Enabled = true" in bundle,
    "client is enabled": "client.Enabled = true" in bundle,
    "activation is verified": "assert(main.Enabled and client.Enabled" in bundle,
    "version two is installed": 'shared:SetAttribute("Version",2)' in bundle,
}
failed = [name for name, passed in checks.items() if not passed]
if failed:
    raise SystemExit("Installer regression: " + ", ".join(failed))
print(f"PASS installer bootstrap ({len(checks)} checks)")
