#!/usr/bin/env python3
"""Compatibility entry point for existing Codex installations."""
from pathlib import Path
import runpy

runpy.run_path(
    str(Path(__file__).resolve().parents[1] / "shared/hooks/guard-dangerous-commands.py"),
    run_name="__main__",
)
