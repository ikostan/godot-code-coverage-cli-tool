#!/usr/bin/env python3
# Copyright (C) 2026 Egor Kostan
# SPDX-License-Identifier: GPL-3.0-or-later
"""Lint the repository's tracked JSON files.

Checks every file for:
  - strict JSON (no NaN/Infinity, no duplicate object keys)
  - UTF-8 without a BOM
  - LF line endings only, no trailing whitespace
  - exactly one final newline

Layout is deliberately NOT enforced: the corpus goldens keep one
line_mapping object per line so diffs read line by line against source.gd,
which a reformatter like `json.tool` or prettier would undo.

Usage:
  python -I workspace/json_lint.py            # all tracked *.json files
  python -I workspace/json_lint.py a.json ... # only the given files
"""

import json
import os
import subprocess
import sys

# Never linted: generated, vendored, or owned by a submodule.
EXCLUDED_PREFIXES = (".godot/", "addons/", "contrib/")
IN_GITHUB_ACTIONS = os.environ.get("GITHUB_ACTIONS") == "true"


def tracked_json_files():
    out = subprocess.run(
        ["git", "ls-files", "-z", "--", "*.json"],
        check=True,
        capture_output=True,
    ).stdout.decode("utf-8")
    return sorted(p for p in out.split("\0") if p and not p.startswith(EXCLUDED_PREFIXES))


def _no_duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate key {key!r}")
        result[key] = value
    return result


def _reject_constant(name):
    raise ValueError(f"non-standard JSON constant {name}")


def check(path):
    """Return a list of (line, message) problems; line is None when not applicable."""
    problems = []
    with open(path, "rb") as handle:
        raw = handle.read()

    if raw.startswith(b"\xef\xbb\xbf"):
        problems.append((1, "UTF-8 BOM found"))
    if b"\r" in raw:
        first_cr_line = raw[: raw.index(b"\r")].count(b"\n") + 1
        problems.append((first_cr_line, "CR found; use LF line endings"))
    if not raw.endswith(b"\n"):
        problems.append((None, "missing final newline"))
    elif raw.endswith(b"\n\n"):
        problems.append((None, "more than one final newline"))

    try:
        text = raw.decode("utf-8-sig")
    except UnicodeDecodeError as error:
        return problems + [(None, f"not valid UTF-8: {error}")]

    for number, line in enumerate(text.split("\n"), start=1):
        if line.rstrip("\r") != line.rstrip("\r").rstrip(" \t"):
            problems.append((number, "trailing whitespace"))

    try:
        json.loads(
            text,
            object_pairs_hook=_no_duplicate_keys,
            parse_constant=_reject_constant,
        )
    except json.JSONDecodeError as error:
        problems.append((error.lineno, error.msg))
    except ValueError as error:
        problems.append((None, str(error)))
    return problems


def report(path, line, message):
    if IN_GITHUB_ACTIONS:
        location = f"file={path},line={line}" if line else f"file={path}"
        print(f"::error {location}::{message}")
    else:
        print(f"{path}:{line}: {message}" if line else f"{path}: {message}")


def main(argv):
    paths = argv or tracked_json_files()
    if not paths:
        print("No JSON files to lint.")
        return 0
    failed = 0
    for path in paths:
        problems = check(path)
        for line, message in problems:
            report(path, line, message)
        failed += bool(problems)
    print(f"Linted {len(paths)} JSON file(s): {failed} with problems.")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
