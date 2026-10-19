---
title: Openplanet for Emacs
---

# Openplanet for Emacs

AngelScript editing and Openplanet language services through Eglot or lsp-mode.
Requires Emacs 29.1+ and a separately installed `openplanet-lsp` server.

![Real Emacs with live Eglot diagnostics](assets/emacs-eglot.png)

[Installation and usage](https://github.com/clankercode/lsp-openplanet-emacs#readme)
· [Verification](verification.md) · [Publishing status](publishing.md)

```elisp
(package-vc-install
 '(openplanet :url "https://github.com/clankercode/lsp-openplanet-emacs"
              :main-file "openplanet.el"))
(require 'openplanet)
(openplanet-setup)
```

Open a `.as` file and run `M-x openplanet-eglot`. Optional `info.toml` support
retains TOML editing and leaves other TOML files alone.

Choose Unlicense OR CC0-1.0. Full license texts are in the repository.
