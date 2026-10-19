#!/usr/bin/env bash
# SPDX-License-Identifier: Unlicense OR CC0-1.0
set -euo pipefail
cd "$(dirname "$0")/.."
exec xvfb-run -a -s '-screen 0 1440x1000x24' python3 scripts/capture.py "$@"
