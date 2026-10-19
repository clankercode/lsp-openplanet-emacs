;;; package-vc-install.el --- VC install -*- lexical-binding: t; no-byte-compile: t; -*-
;; SPDX-License-Identifier: Unlicense OR CC0-1.0
(require 'package)
(require 'package-vc)
(require 'ert)
(setq package-user-dir (make-temp-file "openplanet-vc-installed-" t))
(package-initialize)
(unwind-protect
    (progn
      (package-vc-install
       '(openplanet :url "https://github.com/clankercode/lsp-openplanet-emacs"
                    :main-file "openplanet.el"))
      (should (package-installed-p 'openplanet))
      (require 'openplanet)
      (openplanet-setup)
      (with-temp-buffer
        (setq buffer-file-name "/tmp/vc-example.as")
        (set-auto-mode)
        (should (eq major-mode 'openplanet-angelscript-mode)))
      (princ "PASS: public package-vc-install, load, setup, and .as association\n"))
  (delete-directory package-user-dir t))
;;; package-vc-install.el ends here
