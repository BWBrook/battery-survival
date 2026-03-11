set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

restore:
  Rscript --vanilla -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv', repos='https://cloud.r-project.org')"
  Rscript --vanilla -e "source('renv/activate.R'); renv::restore(prompt = FALSE)"

dev:
  ANALYSIS_PROFILE=dev Rscript scripts/run_dev.R

full:
  ANALYSIS_PROFILE=full Rscript scripts/run_full.R

bayes:
  ANALYSIS_PROFILE=bayes Rscript scripts/run_full.R

bayes-check:
  ANALYSIS_PROFILE=bayes_check Rscript scripts/run_full.R

bayes-prod:
  ANALYSIS_PROFILE=bayes_prod Rscript scripts/run_full.R

manuscript:
  ANALYSIS_PROFILE=full Rscript scripts/render_paper.R

manuscript-prod-bayes:
  bash scripts/run_with_log.sh manuscript-prod-bayes env ANALYSIS_PROFILE=full Rscript scripts/render_paper_prod_bayes.R

review-prod-bayes:
  bash scripts/run_with_log.sh review-prod-bayes bash scripts/review_prod_bayes.sh

test:
  Rscript -e "testthat::test_dir('tests/testthat')"

check:
  just test
  just dev

lock:
  Rscript -e "renv::snapshot(prompt = FALSE)"
