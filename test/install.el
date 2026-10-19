;;; install.el --- Install smoke test -*- lexical-binding: t; no-byte-compile: t; -*-
;; SPDX-License-Identifier: Unlicense OR CC0-1.0
(require 'package)
(require 'ert)
(setq package-user-dir (make-temp-file "openplanet-installed-" t))
(package-initialize)
(unwind-protect
    (progn
      (package-install-file (expand-file-name "openplanet.el"))
      (should (package-installed-p 'openplanet '(0 1 0)))
      (should (autoloadp (symbol-function 'openplanet-angelscript-mode)))
      (with-temp-buffer
        (setq buffer-file-name "/tmp/install-example.as")
        (set-auto-mode)
        (should (eq major-mode 'openplanet-angelscript-mode)))
      (openplanet-setup)
      (should (featurep 'eglot))
      (princ (format "PASS: package-install-file and generated autoloads (%s)\n" emacs-version)))
  (delete-directory package-user-dir t))
;;; install.el ends here
