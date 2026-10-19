# Publishing

The public source repository is the current install channel:
https://github.com/clankercode/lsp-openplanet-emacs

The Emacs package name is `openplanet`, version `0.1.0`. `package-vc-install`,
manual load-path installation and `package-install-file` need no marketplace
account. Git tags use `v0.1.0` style, compatible with MELPA stable version parsing.

## MELPA status: eligible after the public maintenance period

On 2026-10-19 the current
[MELPA submission template](https://github.com/melpa/melpa/blob/master/.github/PULL_REQUEST_TEMPLATE.md)
requires the package to have been maintained publicly for **one month or more**.
[CONTRIBUTING](https://github.com/melpa/melpa/blob/master/CONTRIBUTING.org) also
requires the human author to be the first and most thorough reviewer of
AI-assisted output. `openplanet.el` includes the requested `Assisted-by` header.

No registry PR has been opened: the new repository does not yet meet the
maintenance requirement, and parent/human review is pending. Earliest possible
submission is 2026-11-19 if publicly maintained from 2026-10-19. This is a
maintainer policy gate, not a need for a paid package account.

Ready recipe: [`recipes/openplanet`](../recipes/openplanet). At submission:

1. Have Max review the source, tests, screenshot, and package maintenance plan.
2. Fork `melpa/melpa` with a GitHub account, clone it to a separate directory,
   create a dedicated recipe branch, and copy the recipe into `recipes/openplanet`.
3. Run `make recipes/openplanet`; also run
   `MELPA_CHANNEL=stable make recipes/openplanet` after the release tag exists.
   Install the resulting package with `M-x package-install-file`, rerun the
   Eglot smoke test, byte compilation, package-lint, and checkdoc.
4. Open a PR titled `Add recipe for openplanet`, using MELPA's current template.
   Link this repository and verification evidence; identify Max as maintainer
   and disclose AI assistance. Check only statements actually satisfied.
5. Respond to maintainer review; do not claim MELPA availability until merged
   and an archive build exists.

GNU ELPA and NonGNU ELPA are separate curated channels requiring maintainer
coordination; no submission has been made there. This repository does not need
an npm publication: users install the existing `openplanet-lsp` server package.

## Documentation site

GitHub Pages serves the Markdown documentation from `/docs` on `main` using the
standard GitHub Pages build. It requires repository administration, not another
account. The README remains the canonical package installation guide.
