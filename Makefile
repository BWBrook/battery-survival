R = Rscript

.PHONY: restore dev full bayes bayes-check bayes-prod manuscript test check lock

restore:
	$(R) -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv', repos='https://cloud.r-project.org')"
	$(R) -e "renv::restore(prompt = FALSE)"

dev:
	ANALYSIS_PROFILE=dev $(R) scripts/run_dev.R

full:
	ANALYSIS_PROFILE=full $(R) scripts/run_full.R

bayes:
	ANALYSIS_PROFILE=bayes $(R) scripts/run_full.R

bayes-check:
	ANALYSIS_PROFILE=bayes_check $(R) scripts/run_full.R

bayes-prod:
	ANALYSIS_PROFILE=bayes_prod $(R) scripts/run_full.R

manuscript:
	ANALYSIS_PROFILE=full $(R) scripts/render_paper.R

test:
	$(R) -e "testthat::test_dir('tests/testthat')"

check: test dev

lock:
	$(R) -e "renv::snapshot(prompt = FALSE)"
