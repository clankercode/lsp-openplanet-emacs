EMACS ?= emacs

.PHONY: test compile check integration lsp-test
test:
	$(EMACS) -Q --batch -L . -l test/openplanet-test.el -f ert-run-tests-batch-and-exit

compile:
	$(EMACS) -Q --batch -L . --eval '(setq byte-compile-error-on-warn t)' -f batch-byte-compile openplanet.el

check: compile test

integration:
	$(EMACS) -Q --batch -L . -l test/integration.el

lsp-test:
	$(EMACS) -Q --batch -L . -l test/lsp-mode-test.el -f ert-run-tests-batch-and-exit
