# Independent review receipt

Two read-only T3-native Codex review rounds were performed. No CLI agents were
used and no review agent changed repository files.

## Round 1

Found two compatibility issues: Emacs 29 returns a different internal Eglot
lookup shape, and its Eglot server supports only one language ID. The original
grouped registration could send the wrong ID for manifests. Tests now handle
both lookup shapes; older Eglot gets separate source/manifest registrations.
A regression fails against the earlier implementation and passes after the fix.

Executable validation, risky-local-variable metadata, selective TOML behavior,
package/autoload structure, and MELPA deferral passed review.

Screenshot review passed: all 22 source lines, Eglot status and the full
`MissingName` error are visible. The long secondary unused-variable explanation
is clipped. That does not hide the primary diagnostic.

## Round 2

Reviewed `80c82c1`, returned **PASS**, with no unresolved findings. Independently
reran all nine then-current unit tests against both current Eglot and upstream
Emacs 29.4 Eglot source in the local Emacs 31 runtime. Confirmed the compatibility
fix and unchanged screenshot. This was not a native Emacs 29 runtime test.

## Subsequent CI fixes

Native CI found home-directory abbreviation in project roots. The returned
root is now expanded consistently, with a tenth red/green unit test. Public
package-vc installation exposed unnecessary compilation of developer-only
tests; those files now declare `no-byte-compile` and the public install compiles
cleanly. Native Emacs 30 requires trust for Flymake; only generated test/capture
fixture directories are trusted within a dynamic scope. Product code never
changes a user's trust settings.

Final matrix results and test limits are recorded in [verification](verification.md).
