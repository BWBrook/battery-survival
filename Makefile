R = Rscript

.PHONY: restore dev full bayes bayes-check bayes-prod manuscript manuscript-prod-bayes review-prod-bayes test check lock

restore:
	$(R) --vanilla -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv', repos='https://cloud.r-project.org')"
	$(R) --vanilla -e "source('renv/activate.R'); renv::restore(prompt = FALSE)"

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

manuscript-prod-bayes:
	bash scripts/run_with_log.sh manuscript-prod-bayes env ANALYSIS_PROFILE=full $(R) scripts/render_paper_prod_bayes.R

review-prod-bayes:
	bash scripts/run_with_log.sh review-prod-bayes bash scripts/review_prod_bayes.sh

test:
	$(R) -e "testthat::test_dir('tests/testthat')"

check: test dev

lock:
	$(R) -e "renv::snapshot(prompt = FALSE)"
