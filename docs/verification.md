# Verification

## Local evidence — 2026-10-19

Host: CachyOS Linux x86_64. Emacs was absent; the official Arch Emacs 31.1-2
package and its missing `libotf` / `libgccjit` libraries were extracted under
`/tmp/openplanet-emacs-runtime`. No system package install or update was run.
`/tmp/openplanet-emacs` sets the relocated runtime paths. Runtime and optional
dependencies are not bundled in this repository.

- GNU Emacs **31.1**; built-in Eglot **1.24.31** (version reported in initialize).
- Installed language server **openplanet-lsp 0.8.0** at
  `/home/xertrov/.local/bin/openplanet-lsp`, always launched with `--lsp`.
- Real lsp-mode **20261009.1332**, installed via MELPA in
  `/tmp/openplanet-emacs-packages`; source revision
  `a6c47c7867955fea450f833ba4f38b93411d7ea5`.
- package-lint **20260903.2119**; built-in checkdoc.

Commands (run in the repository):

```sh
make EMACS=/tmp/openplanet-emacs check
make EMACS=/tmp/openplanet-emacs install-test
make EMACS=/tmp/openplanet-emacs integration
OPENPLANET_PACKAGE_DIR=/tmp/openplanet-emacs-packages \
  make EMACS=/tmp/openplanet-emacs lsp-test
/tmp/openplanet-emacs --batch -Q \
  -L /tmp/openplanet-emacs-packages/package-lint-20260903.2119 \
  -l package-lint -f package-lint-batch-and-exit openplanet.el
/tmp/openplanet-emacs --batch -Q \
  --eval '(progn (require (quote checkdoc)) (checkdoc-file "openplanet.el"))'
```

Results:

- Byte compilation with warnings treated as errors: **PASS**.
- Nine ERT tests: **PASS**, including source association/indentation, manifest
  opt-in/opt-out and negative names, executable spaces/invalid paths/no fallback,
  risky-local-variable metadata, remote refusal, nearest roots, fallback root,
  idempotent registration, TOML coexistence, and non-Openplanet command refusal.
- Emacs 29 compatibility regression: the new language-ID test **fails against
  the previous implementation** and passes after separate source/manifest
  registrations are used for old Eglot. All nine tests also pass with the
  actual upstream Emacs 29.4 `eglot.el` loaded in the Emacs 31.1 runtime.
- `package-install-file`, generated autoloads, `.as` association, Eglot setup:
  **PASS** in an empty temporary package directory.
- Two tests against actual installed lsp-mode: **PASS**. Checked registration,
  language IDs, other TOML/C++/text exclusion, dynamic executable checking,
  and no initialization overrides. These are API tests, not a live lsp-mode
  transport session.
- Live Eglot/server test: **PASS**. Actual initialized server, `didOpen` with
  `angelscript`, Flymake undefined-identifier diagnostic, Eglot CAPF completion
  containing `Greeting`, hover signature, same-server manifest attachment using
  `toml`, and invalid manifest value diagnostics after save. Initialize emitted
  **`initializationOptions: {}`**, preserving server configuration precedence.
- package-lint and checkdoc: **PASS**, no diagnostics for `openplanet.el`.

Captured logs are in [`evidence/`](evidence/). The live integration test deliberately
introduces invalid source and a manifest `timeout` string to assert diagnostics.
On shutdown the installed server did not exit before Eglot's grace period;
Eglot logged a sentinel warning and terminated it (status 9). This is preserved
in the log, not hidden or counted as a graceful server exit. No server code was
changed by this integration repository.

## Actual editor screenshot

[`assets/emacs-eglot.png`](assets/emacs-eglot.png) is a **1440 × 1000 PNG** of
GNU Emacs's real GUI, using the built-in Modus Vivendi theme. It was captured
with ImageMagick `import -window root` on a private `xvfb-run` display.
No HTML editor replica, manufactured diagnostic, or composited overlay is used.

```sh
EMACS=/tmp/openplanet-emacs bash scripts/screenshot.sh
```

The capture script copies [`examples/hello`](../examples/hello) to `/tmp`, adds
the explicitly labeled invalid identifier, starts Eglot, and waits for a real
Flymake diagnostic mentioning `MissingName` before capture. The original minimal
plugin follows Openplanet's documented Main/Render callbacks and is licensed
under the same dual license; it is not claimed to be a third-party plugin.

Capture evidence directory: `/tmp/openplanet-emacs-capture.fayr8yzf` (source,
manifest, Emacs log, and readiness marker). The Xvfb session and Emacs process
were cleaned up. Visual inspection of the full image and diagnostic crop
confirmed legible source, real Eglot mode-line status, and the undefined
identifier. The long secondary unused-variable explanation extends off-screen;
the primary undefined-identifier diagnostic is fully visible.

## Limits

- Local runtime tests cover Linux x86_64 with Emacs 31.1. Windows, macOS,
  terminal-only Emacs, Emacs 29/30, and live lsp-mode transport were not run
  locally. Public CI separately checks Emacs 29.4, 30.2, and snapshot.
- A live attempt to load old Emacs 29 Eglot in Emacs 31 reached an incompatible
  EIEIO slot error (`unbound-slot ... managed-buffers`) and was stopped. This is
  not counted as native Emacs 29 integration verification. Native versions are
  tested by CI; the local older-source run covers only the nine unit tests.
- Screenshot and language tests do not run the example inside Trackmania or
  Openplanet. The installed server detects the host's game type information;
  no fixture type database is substituted for a production database.
- C-family syntax and indentation are intentionally approximate; there is no
  new standalone AngelScript grammar or tree-sitter dependency.
- MELPA has no package yet. See [publishing](publishing.md) for the month-long
  public maintenance requirement and human review handoff.
- Upstream graph tooling was requested but unavailable as a callable tool in
  this child session. No upstream implementation changes were made.
