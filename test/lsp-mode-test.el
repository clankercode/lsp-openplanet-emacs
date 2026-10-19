;;; lsp-mode-test.el --- API tests -*- lexical-binding: t; no-byte-compile: t; -*-
;; SPDX-License-Identifier: Unlicense OR CC0-1.0
(require 'package)
(when (getenv "OPENPLANET_PACKAGE_DIR")
  (setq package-user-dir (getenv "OPENPLANET_PACKAGE_DIR")))
(package-initialize)
(require 'ert)
(require 'lsp-mode)
(require 'openplanet)

(ert-deftest openplanet-real-lsp-mode-registration ()
  (openplanet-setup)
  (let ((client (gethash 'openplanet lsp-clients)))
    (should client)
    (should (equal (lsp--client-major-modes client)
                   '(openplanet-angelscript-mode openplanet-info-mode)))
    (should-not (lsp--client-initialization-options client))
    (dolist (mode '(openplanet-angelscript-mode openplanet-info-mode))
      (with-temp-buffer
        (funcall mode)
        (setq buffer-file-name (if (eq mode 'openplanet-info-mode)
                                   "/tmp/info.toml" "/tmp/Main.as"))
        (should (lsp--supports-buffer? client))
        (should (equal (lsp-buffer-language)
                       (if (eq mode 'openplanet-info-mode) "toml" "angelscript")))))
    (dolist (mode '(conf-toml-mode c++-mode text-mode))
      (with-temp-buffer
        (funcall mode)
        (setq buffer-file-name "/tmp/settings.toml")
        (should-not (lsp--supports-buffer? client))))))

(ert-deftest openplanet-real-lsp-mode-command-is-dynamic ()
  (openplanet-setup)
  (let* ((client (gethash 'openplanet lsp-clients))
         (connection (lsp--client-new-connection client)))
    (should (funcall (plist-get connection :test?)))
    (let ((openplanet-server-executable "/missing/openplanet-lsp"))
      (should-error (funcall (plist-get connection :test?)) :type 'user-error))))
;;; lsp-mode-test.el ends here
