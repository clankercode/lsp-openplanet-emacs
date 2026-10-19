EMACS ?= emacs

.PHONY: test compile check integration lsp-test lsp-integration install-test
test:
	$(EMACS) -Q --batch -L . -l test/openplanet-test.el -f ert-run-tests-batch-and-exit

compile:
	$(EMACS) -Q --batch -L . --eval '(setq byte-compile-error-on-warn t)' -f batch-byte-compile openplanet.el

check: compile test

integration:
	$(EMACS) -Q --batch -L . -l test/integration.el

lsp-test:
	$(EMACS) -Q --batch -L . -l test/lsp-mode-test.el -f ert-run-tests-batch-and-exit

lsp-integration:
	$(EMACS) -Q --batch -L . -l test/lsp-integration.el -f ert-run-tests-batch-and-exit

install-test:
	$(EMACS) -Q --batch -l test/install.el
