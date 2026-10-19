;;; openplanet.el --- AngelScript and Openplanet language tools -*- lexical-binding: t; -*-

;; Author: Max Kaye <m@xk.io>
;; Assisted-by: Codex:ocx/gpt-6.1-sol
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: languages, tools
;; URL: https://github.com/clankercode/lsp-openplanet-emacs
;; SPDX-License-Identifier: Unlicense OR CC0-1.0

;; This is free and unencumbered software released into the public domain.
;; You may choose the Unlicense or CC0 1.0 Universal; see UNLICENSE and
;; LICENSE-CC0 for the full texts.

;;; Commentary:

;; AngelScript editing with optional Eglot and lsp-mode integrations.
;; Install openplanet-lsp separately, then call `openplanet-setup' and
;; choose one LSP client.  No configuration overrides are sent by default.
;; Call `openplanet-enable-manifests' for TOML-based info.toml editing.

;;; Code:

(require 'cc-mode)
(require 'conf-mode)
(require 'project)
(require 'cl-lib)

(defgroup openplanet nil
  "AngelScript and Openplanet language tools."
  :group 'languages
  :prefix "openplanet-")

(defcustom openplanet-server-executable "openplanet-lsp"
  "Executable name on PATH or absolute path to openplanet-lsp.
This is one executable, not a shell command.  Arguments and shell expansion
are not supported.  Paths containing spaces are supported.  An explicit
missing path fails visibly and never falls back to PATH.
Set this in trusted Emacs configuration, not project local variables."
  :type 'string
  :risky t
  :group 'openplanet)

(defconst openplanet--eglot-entry
  '(((openplanet-angelscript-mode :language-id "angelscript")
     (openplanet-info-mode :language-id "toml"))
    . openplanet--eglot-contact)
  "Eglot registration for only the Openplanet major modes.")

(defvar eglot-server-programs)
(defvar lsp-language-id-configuration)
(declare-function eglot-ensure "eglot")
(declare-function lsp "lsp-mode")
(declare-function lsp-register-client "lsp-mode")
(declare-function make-lsp-client "lsp-mode")
(declare-function lsp-stdio-connection "lsp-mode")

(defun openplanet--command ()
  "Return the validated stdio command, without shell interpretation."
  (when (file-remote-p default-directory)
    (user-error "Openplanet currently supports local buffers only"))
  (let* ((value openplanet-server-executable)
         (path (and (stringp value)
                    (> (length value) 0)
                    (if (file-name-absolute-p value)
                        value
                      (unless (file-name-directory value)
                        (executable-find value))))))
    (unless (and path (file-executable-p path) (not (file-directory-p path)))
      (user-error "Openplanet executable unavailable: %S; install openplanet-lsp or customize openplanet-server-executable" value))
    (list path "--lsp")))

(defun openplanet--eglot-contact (&rest _ignored)
  "Compute Eglot's command at connection time."
  (openplanet--command))

;;;###autoload
(define-derived-mode openplanet-angelscript-mode c++-mode "AngelScript"
  "Edit Openplanet AngelScript using C-family indentation and comments.
The language server supplies semantic completion, diagnostics and navigation."
  (setq-local c-basic-offset 4)
  (font-lock-add-keywords
   nil `((,(regexp-opt '("array" "dictionary" "string" "uint" "uint8"
                         "uint16" "uint64" "int8" "int16" "int64") 'symbols)
          . font-lock-type-face)
         (,(regexp-opt '("funcdef" "import" "in" "out" "inout" "is"
                         "mixin" "shared" "cast") 'symbols)
          . font-lock-keyword-face))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.as\\'" . openplanet-angelscript-mode))

;;;###autoload
(define-derived-mode openplanet-info-mode conf-toml-mode "Openplanet TOML"
  "Edit an Openplanet info.toml with TOML syntax and Openplanet LSP support.
Enable the association with `openplanet-enable-manifests'.  Ordinary TOML
files retain their existing major mode and server.")

;;;###autoload
(defun openplanet-enable-manifests ()
  "Associate only files named info.toml with `openplanet-info-mode'.
This is opt-in because other applications also use this filename.
Existing buffers are unchanged; revisit them or select the mode explicitly."
  (interactive)
  (add-to-list 'auto-mode-alist
               '("\\(?:\\`\\|[/\\\\]\\)info\\.toml\\'" . openplanet-info-mode)))

;;;###autoload
(defun openplanet-disable-manifests ()
  "Remove the optional info.toml association for future file visits."
  (interactive)
  (setq auto-mode-alist
        (delete '("\\(?:\\`\\|[/\\\\]\\)info\\.toml\\'" . openplanet-info-mode)
                auto-mode-alist)))

(defun openplanet--project-find (directory)
  "Find an Openplanet project containing DIRECTORY in an Openplanet buffer.
Prefer the nearest info.toml or .openplanet-lsp.toml marker.  With no marker,
use DIRECTORY as a single-file project.  Do not affect other editing modes."
  (when (and (derived-mode-p 'openplanet-angelscript-mode 'openplanet-info-mode)
             (not (file-remote-p directory)))
    (cons 'openplanet
          (file-name-as-directory
           (expand-file-name
            (or (locate-dominating-file
                 directory
                 (lambda (dir)
                   (or (file-exists-p (expand-file-name "info.toml" dir))
                       (file-exists-p (expand-file-name ".openplanet-lsp.toml" dir)))))
                directory))))))

(cl-defmethod project-root ((project (head openplanet)))
  "Return the root of an Openplanet PROJECT."
  (cdr project))

(defun openplanet--register-eglot ()
  "Register Openplanet's modes with Eglot idempotently."
  ;; Eglot bundled with Emacs 29 has one language ID per server.  Separate
  ;; entries keep manifests as TOML instead of sending AngelScript's ID.
  (if (fboundp 'eglot--language-ids)
      (add-to-list 'eglot-server-programs openplanet--eglot-entry)
    (dolist (entry '(((openplanet-angelscript-mode :language-id "angelscript")
                     . openplanet--eglot-contact)
                    ((openplanet-info-mode :language-id "toml")
                     . openplanet--eglot-contact)))
      (add-to-list 'eglot-server-programs entry))))

(defun openplanet--register-lsp-mode ()
  "Register Openplanet's modes with lsp-mode."
  (add-to-list 'lsp-language-id-configuration
               '(openplanet-angelscript-mode . "angelscript"))
  (add-to-list 'lsp-language-id-configuration '(openplanet-info-mode . "toml"))
  (lsp-register-client
   (make-lsp-client :new-connection (lsp-stdio-connection #'openplanet--command)
                    :major-modes '(openplanet-angelscript-mode openplanet-info-mode)
                    :priority 1
                    :server-id 'openplanet)))

;;;###autoload
(defun openplanet-setup ()
  "Register project discovery, Eglot and lsp-mode integrations.
This loads built-in Eglot but never starts a server.  If lsp-mode is already
loaded, also register its client.  Otherwise use `openplanet-lsp' or call
this again after loading lsp-mode.  It is safe to call repeatedly.
Choose Eglot OR lsp-mode for a buffer, not both."
  (interactive)
  (add-hook 'project-find-functions #'openplanet--project-find)
  (require 'eglot)
  (openplanet--register-eglot)
  (when (featurep 'lsp-mode)
    (openplanet--register-lsp-mode)))

;;;###autoload
(defun openplanet-eglot ()
  "Start Eglot for the current Openplanet source or manifest buffer."
  (interactive)
  (unless (derived-mode-p 'openplanet-angelscript-mode 'openplanet-info-mode)
    (user-error "Select an Openplanet major mode first"))
  (openplanet--command)
  (openplanet-setup)
  (require 'eglot)
  (eglot-ensure))

;;;###autoload
(defun openplanet-lsp ()
  "Start lsp-mode for the current Openplanet source or manifest buffer."
  (interactive)
  (unless (derived-mode-p 'openplanet-angelscript-mode 'openplanet-info-mode)
    (user-error "Select an Openplanet major mode first"))
  (openplanet--command)
  (unless (require 'lsp-mode nil t)
    (user-error "Install the optional lsp-mode package first"))
  (openplanet-setup)
  (lsp))

(provide 'openplanet)
;;; openplanet.el ends here
