;;; lsp-integration.el --- Live lsp-mode test -*- lexical-binding: t; no-byte-compile: t; -*-
;; SPDX-License-Identifier: Unlicense OR CC0-1.0
(require 'package)
(when (getenv "OPENPLANET_PACKAGE_DIR")
  (setq package-user-dir (getenv "OPENPLANET_PACKAGE_DIR")))
(package-initialize)
(require 'ert)
(require 'lsp-mode)
(require 'lsp-completion)
(require 'lsp-diagnostics)
(require 'flymake)
(require 'openplanet)
(defvar trusted-content)

(defun openplanet-lsp-test-wait (predicate description)
  "Wait up to 30 seconds for PREDICATE, or fail with DESCRIPTION."
  (let ((deadline (+ (float-time) 30)))
    (while (and (not (funcall predicate)) (< (float-time) deadline))
      (accept-process-output nil 0.1))
    (unless (funcall predicate) (ert-fail (concat "Timed out: " description)))))

(defun openplanet-lsp-test-messages ()
  "Return the current buffer's Flymake diagnostic messages."
  (mapcar #'flymake-diagnostic-text (flymake-diagnostics)))

(ert-deftest openplanet-live-lsp-mode ()
  (let* ((dir (make-temp-file "openplanet-lsp-mode-" t))
         (default-directory (file-name-as-directory dir))
         (user-emacs-directory (expand-file-name "emacs/" dir))
         (process-environment (copy-sequence process-environment))
         (trusted-content (list (abbreviate-file-name default-directory)))
         (lsp-session-file (expand-file-name "session" user-emacs-directory))
         (lsp-auto-guess-root t)
         (lsp-enable-file-watchers nil)
         (lsp-enable-snippet nil)
         (lsp-enable-on-type-formatting nil)
         (lsp-diagnostics-provider :flymake)
         ;; Keep old diagnostics until a real server publication replaces them.
         (lsp-diagnostic-clean-after-change nil)
         (lsp-log-io t)
         (lsp-io-messages-max t)
         (lsp-response-timeout 15)
         (lsp-restart 'ignore)
         source manifest workspace process events)
    (unwind-protect
        (progn
          ;; Isolate server user config while retaining real type DB discovery.
          (setenv "XDG_CONFIG_HOME" (expand-file-name "config" dir))
          (write-region "[meta]\nname = \"lsp-mode test\"\nauthor = \"clankercode\"\nversion = \"0.1.0\"\n"
                        nil (expand-file-name "info.toml" dir) nil 'silent)
          (write-region "string Greeting(const string &in name) { return name; }\nvoid Main() {\n    int value = MissingName;\n}\nvoid Complete() {\n    Gre\n}\n"
                        nil (expand-file-name "Main.as" dir) nil 'silent)
          (openplanet-enable-manifests)
          (setq source (find-file-noselect (expand-file-name "Main.as" dir)))
          (with-current-buffer source
            (should (eq major-mode 'openplanet-angelscript-mode))
            ;; The inherited C compiler backend cannot check AngelScript.
            (remove-hook 'flymake-diagnostic-functions #'flymake-cc t)
            (openplanet-lsp)
            ;; Retain the process even if initialization subsequently times out.
            (setq workspace (car (lsp-workspaces)))
            (should workspace)
            (setq process (lsp--workspace-proc workspace)
                  events (ewoc-buffer (lsp--workspace-ewoc workspace)))
            (openplanet-lsp-test-wait
             (lambda () (and (bound-and-true-p lsp-managed-mode)
                             (lsp-workspaces))) "lsp-mode initialization")
            (should (process-live-p process))
            (should (eq (lsp--workspace-status workspace) 'initialized))
            (should (equal (file-truename (lsp-workspace-root))
                           (directory-file-name (file-truename dir))))
            (princ (format "INITIALIZED: root=%s, process=%S\n"
                           (lsp-workspace-root) (process-command process)))
            (flymake-start)
            (openplanet-lsp-test-wait
             (lambda () (cl-some (lambda (text) (string-match-p "MissingName" text))
                                (openplanet-lsp-test-messages)))
             "source undefined-identifier diagnostic")
            (princ (format "ANGELSCRIPT DIAGNOSTICS: %S\n"
                           (openplanet-lsp-test-messages)))
            (should (memq #'lsp-completion-at-point completion-at-point-functions))
            (goto-char (point-min))
            (search-forward "    Gre")
            (let* ((capf (lsp-completion-at-point))
                   (completions (mapcar #'substring-no-properties
                                        (all-completions "Gre" (nth 2 capf)))))
              (should (member "Greeting" completions))
              (princ (format "LSP CAPF COMPLETIONS: %S\n" completions)))
            ;; Repair both invalid expressions, then prove stale diagnostics clear.
            (goto-char (point-min))
            (search-forward "MissingName")
            (replace-match "1" t t)
            (search-forward "    Gre")
            (replace-match "    Greeting(\"world\");" t t)
            (save-buffer)
            (openplanet-lsp-test-wait
             (lambda () (let ((messages (openplanet-lsp-test-messages)))
                          (and (cl-some (lambda (text)
                                          (string-match-p "local variable `value`" text))
                                        messages)
                               (not (cl-some (lambda (text)
                                               (string-match-p "MissingName" text))
                                             messages)))))
             "source diagnostic clearing after repair")
            (princ "SOURCE REPAIR: MissingName diagnostic cleared\n"))
          (setq manifest (find-file-noselect (expand-file-name "info.toml" dir)))
          (with-current-buffer manifest
            (should (eq major-mode 'openplanet-info-mode))
            (should (derived-mode-p 'conf-toml-mode))
            (openplanet-lsp)
            (openplanet-lsp-test-wait
             (lambda () (bound-and-true-p lsp-managed-mode)) "manifest attachment")
            (should (equal (lsp-workspaces) (list workspace)))
            (goto-char (point-max))
            (insert "\n[script]\ntimeout = \"not-a-number\"\n")
            (save-buffer)
            (flymake-start)
            (openplanet-lsp-test-wait
             (lambda () (cl-some (lambda (text) (string-match-p "timeout" text))
                                (openplanet-lsp-test-messages)))
             "manifest timeout diagnostic")
            (princ (format "TOML DIAGNOSTICS (same workspace): %S\n"
                           (openplanet-lsp-test-messages)))
            (goto-char (point-min))
            (search-forward "\"not-a-number\"")
            (replace-match "1000" t t)
            (save-buffer)
            (openplanet-lsp-test-wait
             (lambda () (not (cl-some (lambda (text) (string-match-p "timeout" text))
                                     (openplanet-lsp-test-messages))))
             "manifest diagnostic clearing after repair")
            (princ "MANIFEST REPAIR: timeout diagnostic cleared\n"))
          (with-current-buffer events
            (let ((log (buffer-string)))
              (should (string-match-p "Received response 'initialize" log))
              (should (string-match-p "\"languageId\": \"angelscript\"" log))
              (should (string-match-p "\"languageId\": \"toml\"" log))
              (should-not (string-match-p "\"initializationOptions\"" log))))
          (princ (format "PASS: Emacs %s; lsp-mode %s; live initialization, source diagnostics, CAPF, manifest routing, repairs; no initializationOptions\n"
                         emacs-version (lsp-version))))
      ;; Save the actual protocol trace even when an assertion fails.
      (when (buffer-live-p events)
        (with-current-buffer events
          (write-region (point-min) (point-max)
                        (or (getenv "OPENPLANET_LSP_EVENTS")
                            "/tmp/openplanet-lsp-mode-events.log") nil 'silent)))
      (when workspace (ignore-errors (lsp-workspace-shutdown workspace)))
      (when (and process (process-live-p process))
        (princ "CLEANUP: server still alive after lsp-mode shutdown; terminating test-owned process\n")
        (delete-process process))
      (dolist (buf (list source manifest))
        (when (buffer-live-p buf)
          (with-current-buffer buf (set-buffer-modified-p nil))
          (kill-buffer buf)))
      (delete-directory dir t))))
;;; lsp-integration.el ends here
