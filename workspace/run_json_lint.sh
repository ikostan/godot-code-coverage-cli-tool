#!/bin/bash
# Copyright (C) 2026 Egor Kostan
# SPDX-License-Identifier: GPL-3.0-or-later

echo "Running JSON Lint..."
python3 -I workspace/json_lint.py "$@"
if [ $? -ne 0 ]; then echo "JSON lint failed."; exit 1; fi

echo "JSON Lint completed!"
