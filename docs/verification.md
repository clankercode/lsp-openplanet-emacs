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
  make EMACS=/tmp/openplanet-emacs lsp-test lsp-integration
/tmp/openplanet-emacs --batch -Q \
  -L /tmp/openplanet-emacs-packages/package-lint-20260903.2119 \
  -l package-lint -f package-lint-batch-and-exit openplanet.el
/tmp/openplanet-emacs --batch -Q \
  --eval '(progn (require (quote checkdoc)) (checkdoc-file "openplanet.el"))'
```

Results:

- Byte compilation with warnings treated as errors: **PASS**.
- Ten ERT tests: **PASS**, including source association/indentation, manifest
  opt-in/opt-out and negative names, executable spaces/invalid paths/no fallback,
  risky-local-variable metadata, remote refusal, nearest roots, fallback root,
  idempotent registration, TOML coexistence, and non-Openplanet command refusal.
- Emacs 29 compatibility regression: the new language-ID test **fails against
  the previous implementation** and passes after separate source/manifest
  registrations are used for old Eglot. All ten tests also pass with the
  actual upstream Emacs 29.4 `eglot.el` loaded in the Emacs 31.1 runtime.
  A tenth regression verifies absolute roots when Emacs abbreviates paths
  under the home directory; its red test and corrected result are preserved.
- `package-install-file`, generated autoloads, `.as` association, Eglot setup:
  **PASS** in an empty temporary package directory.
- Public `package-vc-install` with the documented recipe: **PASS**, using
  published revision `9202f1a`. One package file compiled and eight developer
  files skipped as intended; load, setup, and `.as` association passed.
- Two tests against actual installed lsp-mode: **PASS**. Checked registration,
  language IDs, other TOML/C++/text exclusion, dynamic executable checking,
  and no initialization overrides. These remain API tests; the separate live
  test below verifies the real transport.
- Live lsp-mode/server test: **PASS**, through `M-x openplanet-lsp`'s actual
  command implementation and the installed lsp-mode package. Verified a live
  initialized process running `openplanet-lsp --lsp` with the temporary plugin
  root; Flymake's undefined-identifier diagnostic for `MissingName`; CAPF
  completion containing `Greeting`; and the same workspace handling opt-in
  `info.toml` with TOML syntax and an invalid `timeout` diagnostic. Source and
  manifest diagnostics cleared after repairs. The source repair additionally
  waits for a new unused-local-variable diagnostic, so a cleared UI alone
  cannot satisfy it. The protocol trace confirms `angelscript` and `toml`
  didOpen language IDs and **omitted `initializationOptions`**, preserving
  server configuration precedence. A temporary negative-control copy renamed
  the source function to `Welcome`: initialization and diagnostics still ran,
  but the `Greeting` CAPF assertion failed as expected. No product defect was
  found and `openplanet.el` was unchanged.
- Live Eglot/server test: **PASS**. Actual initialized server, `didOpen` with
  `angelscript`, Flymake undefined-identifier diagnostic, Eglot CAPF completion
  containing `Greeting`, hover signature, same-server manifest attachment using
  `toml`, and invalid manifest value diagnostics after save. Initialize emitted
  **`initializationOptions: {}`**, preserving server configuration precedence.
- package-lint and checkdoc: **PASS**, no diagnostics for `openplanet.el`.

Native GitHub CI for revision `ff5af39`: **all three matrix jobs PASS**.
[Check run](https://github.com/clankercode/lsp-openplanet-emacs/actions/runs/39216767438).
Emacs **29.4**, **30.2**, and **snapshot** passed all ten unit tests, byte
compilation, isolated package installation, and actual Eglot/server integration.
Emacs 30.2 initially rejected Flymake on untrusted temporary files. The test
now dynamically trusts only its own generated fixture directory; product code
does not change trust.

Documentation is published at https://clankercode.github.io/lsp-openplanet-emacs/
and was fetched successfully over HTTPS. Repository description and all six
requested topics are configured. Package version is `0.1.0`.

Read-only independent review initially found Emacs 29's single-language-ID
behavior and old lookup result shape. Both were fixed; the second review
returned PASS on `80c82c1`. It also independently inspected the screenshot
and returned PASS. The later absolute-root fix was driven by native CI and
has a red/green regression. No broad source or upstream server changes occurred.

The live lsp-mode test is reproducible with `make lsp-integration` and needs
installed lsp-mode plus the server on `exec-path`. `OPENPLANET_PACKAGE_DIR` selects
the package directory. It uses `-Q`, a generated plugin, and a temporary Emacs
session directory and temporary `XDG_CONFIG_HOME`; it trusts only that fixture
for Flymake and disables the inherited C compiler backend in the test buffer. It neither installs packages
nor edits personal configuration. The protocol trace defaults to
`/tmp/openplanet-lsp-mode-events.log`; set `OPENPLANET_LSP_EVENTS` to change it.
Native CI for revision `05012af29b7aeb56452baf0a2eaffd0fb1d636c3`:
**all three matrix jobs PASS**, including the two lsp-mode API tests and the
live transport test on Emacs **29.4**, **30.2**, and **snapshot 32.0.50**, all
with lsp-mode **20261009.1332** and server **0.8.0**. The source/manifest
repairs and CAPF assertions passed in each job. See the
[check run](https://github.com/clankercode/lsp-openplanet-emacs/actions/runs/39217411255)
and [checked CI step output](evidence/lsp-mode-ci.log). Pages also deployed
successfully for that revision.

CI now installs the optional client into a runner-temporary package directory
and runs both API and live tests on each existing Emacs matrix entry.

Checked evidence: [`lsp-mode-integration.log`](evidence/lsp-mode-integration.log),
[`lsp-mode-events.log`](evidence/lsp-mode-events.log), and the intentional
[`lsp-mode-negative-completion.log`](evidence/lsp-mode-negative-completion.log).
The trace is the actual test traffic, including the deliberately invalid source.
The company-mode warnings in the test output mean that optional popup frontend
is absent; the actual CAPF assertion passes without it. Cleanup requests
lsp-mode shutdown, then terminates its own still-running server process. This
is **not** a successful graceful server shutdown.

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
  and terminal-only interactive Emacs were not run. Local live lsp-mode transport
  is verified with the version above; other lsp-mode versions are not a
  compatibility claim. Native Emacs 29/30 coverage is supplied by CI rather than
  the local machine.
- A live attempt to load old Emacs 29 Eglot in Emacs 31 reached an incompatible
  EIEIO slot error (`unbound-slot ... managed-buffers`) and was stopped. This is
  not counted as native Emacs 29 integration verification. Native versions are
  tested by CI; the local older-source run covers only the ten unit tests.
- Screenshot and language tests do not run the example inside Trackmania or
  Openplanet. The installed server detects the host's game type information;
  no fixture type database is substituted for a production database.
- C-family syntax and indentation are intentionally approximate; there is no
  new standalone AngelScript grammar or tree-sitter dependency.
- MELPA has no package yet. See [publishing](publishing.md) for the month-long
  public maintenance requirement and human review handoff.
- Upstream graph tooling was requested but unavailable as a callable tool in
  this child session. No upstream implementation changes were made.
