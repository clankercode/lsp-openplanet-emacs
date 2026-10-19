;;; openplanet-test.el --- Openplanet unit tests -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: Unlicense OR CC0-1.0
(require 'ert)
(require 'openplanet)
(require 'eglot)

(ert-deftest openplanet-source-association-and-editing ()
  (dolist (name '("Main.as" "/tmp/Main.as" "/tmp/a b/test.as"))
    (with-temp-buffer
      (setq buffer-file-name name)
      (set-auto-mode)
      (should (eq major-mode 'openplanet-angelscript-mode))
      (insert "void Main() {\nprint(\"hello\");\n}\n")
      (indent-region (point-min) (point-max))
      (should (string-match-p "\n    print" (buffer-string)))
      (should (equal comment-start "// ")))))

(ert-deftest openplanet-selective-manifest-association ()
  (let ((auto-mode-alist (copy-tree auto-mode-alist)))
    (openplanet-enable-manifests)
    (openplanet-enable-manifests)
    (dolist (name '("info.toml" "/tmp/info.toml" "C:\\Plugin\\info.toml"))
      (with-temp-buffer
        (setq buffer-file-name name)
        (set-auto-mode)
        (should (eq major-mode 'openplanet-info-mode))
        (should (derived-mode-p 'conf-toml-mode))))
    ;; Emacs intentionally strips backup suffixes and folds filename case.
    (dolist (name '("settings.toml" "myinfo.toml" "info.toml.txt"))
      (with-temp-buffer
        (setq buffer-file-name name)
        (set-auto-mode)
        (should-not (eq major-mode 'openplanet-info-mode))))
    (openplanet-disable-manifests)
    (with-temp-buffer
      (setq buffer-file-name "/tmp/info.toml")
      (set-auto-mode)
      (should-not (eq major-mode 'openplanet-info-mode)))))

(ert-deftest openplanet-safe-executable-resolution ()
  (let* ((dir (make-temp-file "openplanet executable " t))
         (exe (expand-file-name "server with spaces" dir)))
    (unwind-protect
        (progn
          (write-region "#!/bin/sh\nexit 0\n" nil exe nil 'silent)
          (set-file-modes exe #o700)
          (let ((openplanet-server-executable exe))
            (should (equal (openplanet--command) (list exe "--lsp"))))
          (let ((exec-path (cons dir exec-path))
                (openplanet-server-executable "server with spaces"))
            (should (equal (openplanet--command) (list exe "--lsp"))))
          (dolist (bad (list "" "missing-openplanet-server" "./server"
                             "openplanet-lsp --lsp" "$(touch pwned)"
                             "/missing/openplanet-lsp" dir nil))
            (let ((openplanet-server-executable bad))
              (should-error (openplanet--command) :type 'user-error)))
          (set-file-modes exe #o600)
          (let ((openplanet-server-executable exe))
            (should-error (openplanet--command) :type 'user-error)))
      (delete-directory dir t)))
  (should (get 'openplanet-server-executable 'risky-local-variable))
  (should-not (get 'openplanet-server-executable 'safe-local-variable)))

(ert-deftest openplanet-rejects-remote-before-looking-up-executable ()
  (let ((default-directory "/ssh:example.invalid:/tmp/"))
    (should-error (openplanet--command) :type 'user-error)))

(ert-deftest openplanet-project-markers-and-nearest-root ()
  (let* ((dir (file-name-as-directory (make-temp-file "openplanet-root" t)))
         (plugin (expand-file-name "plugin/" dir))
         (src (expand-file-name "src/" plugin)))
    (unwind-protect
        (progn
          (make-directory src t)
          (write-region "" nil (expand-file-name ".openplanet-lsp.toml" dir))
          (with-temp-buffer
            (openplanet-angelscript-mode)
            (should (equal (project-root (openplanet--project-find src)) dir))
            (write-region "" nil (expand-file-name "info.toml" plugin))
            (should (equal (project-root (openplanet--project-find src)) plugin))
            (should-not (openplanet--project-find "/ssh:invalid:/tmp/")))
          (with-temp-buffer
            (conf-toml-mode)
            (should-not (openplanet--project-find src))))
      (delete-directory dir t))))

(ert-deftest openplanet-project-single-file-fallback ()
  (let ((dir (file-name-as-directory (make-temp-file "openplanet-single" t))))
    (unwind-protect
        (with-temp-buffer
          (openplanet-angelscript-mode)
          (should (equal (project-root (openplanet--project-find dir)) dir)))
      (delete-directory dir t))))

(ert-deftest openplanet-setup-is-idempotent-and-leaves-toml-alone ()
  (let ((eglot-server-programs (copy-tree eglot-server-programs))
        (project-find-functions (copy-sequence project-find-functions)))
    (let ((toml (cdr (assoc '(toml-ts-mode conf-toml-mode) eglot-server-programs))))
      (dotimes (_ 3) (openplanet-setup))
      (should (= 1 (cl-count openplanet--eglot-entry eglot-server-programs :test #'equal)))
      (should (= 1 (cl-count #'openplanet--project-find project-find-functions)))
      (should (equal toml (cdr (assoc '(toml-ts-mode conf-toml-mode) eglot-server-programs))))
      (dolist (pair '((openplanet-angelscript-mode . "angelscript")
                      (openplanet-info-mode . "toml")))
        (let ((entry (eglot--lookup-mode (car pair))))
          (should (equal (cdr (assoc (car pair) (car entry))) (cdr pair)))
          (should (eq (cdr entry) 'openplanet--eglot-contact)))))))

(ert-deftest openplanet-commands-reject-unrelated-buffers ()
  (with-temp-buffer
    (text-mode)
    (should-error (openplanet-eglot) :type 'user-error)
    (should-error (openplanet-lsp) :type 'user-error)))

(provide 'openplanet-test)
;;; openplanet-test.el ends here
