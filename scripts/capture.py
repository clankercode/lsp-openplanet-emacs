#!/usr/bin/env python3
"""Capture the real Emacs GUI in a display owned by xvfb-run."""
# SPDX-License-Identifier: Unlicense OR CC0-1.0
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

repo = Path(__file__).resolve().parent.parent
capture = Path(tempfile.mkdtemp(prefix="openplanet-emacs-capture."))
for name in ("Main.as", "info.toml"):
    shutil.copyfile(repo / "examples" / "hello" / name, capture / name)
environment = dict(os.environ, OPENPLANET_CAPTURE_DIR=str(capture))
output = Path(sys.argv[1]) if len(sys.argv) > 1 else repo / "docs/assets/emacs-eglot.png"
with (capture / "emacs.log").open("w") as log:
    process = subprocess.Popen(
        [os.environ.get("EMACS", "emacs"), "-Q", "-L", str(repo),
         "-l", str(repo / "scripts/screenshot.el")],
        env=environment, stdout=log, stderr=subprocess.STDOUT)
    try:
        deadline = time.monotonic() + 60
        while not (capture / "ready").exists():
            if process.poll() is not None or time.monotonic() > deadline:
                raise RuntimeError((capture / "emacs.log").read_text())
            time.sleep(0.25)
        subprocess.run(["import", "-window", "root", str(output)], check=True)
        print((capture / "ready").read_text(), end="")
        print(f"Capture evidence: {capture}")
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
