;;; integration.el --- Real Eglot/server smoke test -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: Unlicense OR CC0-1.0
(require 'openplanet)
(require 'eglot)
(require 'ert)
(require 'flymake)

(defun openplanet-test-wait (predicate seconds description)
  "Wait SECONDS for PREDICATE, otherwise error with DESCRIPTION."
  (let ((deadline (+ (float-time) seconds)))
    (while (and (not (funcall predicate)) (< (float-time) deadline))
      (accept-process-output nil 0.1))
    (unless (funcall predicate) (error "Timed out: %s" description))))

(let* ((dir (make-temp-file "openplanet-eglot-" t))
       (default-directory (file-name-as-directory dir))
       (eglot-sync-connect 15)
       (eglot-connect-timeout 20)
       (eglot-autoshutdown t)
       (eglot-events-buffer-config '(:size 200000 :format full))
       source manifest server manifest-server)
  (unwind-protect
      (progn
        (write-region "[meta]\nname = \"Eglot test\"\nauthor = \"clankercode\"\nversion = \"0.1.0\"\n"
                      nil (expand-file-name "info.toml" dir) nil 'silent)
        (write-region "string Greeting(const string &in name) { return name; }\nvoid Main() {\n    int value = MissingName;\n}\nvoid Complete() {\n    Gre\n}\n"
                      nil (expand-file-name "Main.as" dir) nil 'silent)
        (openplanet-setup)
        (openplanet-enable-manifests)
        (setq source (find-file-noselect (expand-file-name "Main.as" dir)))
        (with-current-buffer source
          (call-interactively #'eglot)
          (setq server (eglot-current-server))
          (should server)
          (flymake-start)
          (should (equal (project-root (project-current)) default-directory))
          (openplanet-test-wait
           (lambda () (flymake-diagnostics)) 30 "AngelScript diagnostics")
          (let ((messages (mapcar #'flymake-diagnostic-text (flymake-diagnostics))))
            (should (cl-some (lambda (text) (string-match-p "MissingName" text)) messages))
            (princ (format "ANGELSCRIPT DIAGNOSTICS: %S\n" messages)))
          (goto-char (point-min))
          (search-forward "    Gre")
          (let* ((capf (eglot-completion-at-point))
                 (completions (all-completions "Gre" (nth 2 capf))))
            (should (member "Greeting" completions))
            (princ (format "CAPF COMPLETIONS: %S\n"
                           (mapcar #'substring-no-properties completions))))
          (goto-char (point-min))
          (search-forward "Greeting")
          (backward-char 2)
          (let ((hover (jsonrpc-request server :textDocument/hover
                                       (eglot--TextDocumentPositionParams))))
            (should hover)
            (princ (format "HOVER: %S\n" hover))))
        (setq manifest (find-file-noselect (expand-file-name "info.toml" dir)))
        (with-current-buffer manifest
          (should (eq major-mode 'openplanet-info-mode))
          (unless (fboundp 'eglot--language-ids)
            (call-interactively #'eglot))
          (openplanet-test-wait (lambda () (eglot-managed-p)) 10 "manifest management")
          (setq manifest-server (eglot-current-server))
          (when (fboundp 'eglot--language-ids)
            (should (eq server manifest-server)))
          (goto-char (point-max))
          (insert "\n[script]\ntimeout = \"not-a-number\"\n")
          (save-buffer)
          (flymake-start)
          (openplanet-test-wait (lambda () (flymake-diagnostics)) 30 "manifest diagnostics")
          (princ (format "TOML DIAGNOSTICS: %S\n"
                         (mapcar #'flymake-diagnostic-text (flymake-diagnostics)))))
        (when-let* ((events (jsonrpc-events-buffer server)))
          (with-current-buffer events
            (let ((coding-system-for-write 'no-conversion))
            (write-region (point-min) (point-max)
                          (or (getenv "OPENPLANET_EVENTS") "/tmp/openplanet-eglot-events.log") nil 'silent))))
        (princ (format "PASS: Emacs %s, Eglot %s, command %S\n"
                       emacs-version (or (bound-and-true-p eglot-version) "bundled")
                       (openplanet--command))))
    (when (and manifest-server (not (eq server manifest-server)))
      (ignore-errors (eglot-shutdown manifest-server)))
    (when server
      (when-let* ((events (jsonrpc-events-buffer server)))
        (with-current-buffer events
          (let ((coding-system-for-write 'no-conversion))
          (write-region (point-min) (point-max)
                        (or (getenv "OPENPLANET_EVENTS") "/tmp/openplanet-eglot-events.log") nil 'silent))))
      (ignore-errors (eglot-shutdown server)))
    (dolist (buf (list source manifest))
      (when (buffer-live-p buf) (kill-buffer buf)))
    (delete-directory dir t)))
;;; integration.el ends here
