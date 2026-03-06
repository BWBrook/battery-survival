set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

restore:
  Rscript -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv', repos='https://cloud.r-project.org')"
  Rscript -e "renv::restore(prompt = FALSE)"

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

test:
  Rscript -e "testthat::test_dir('tests/testthat')"

check:
  just test
  just dev

lock:
  Rscript -e "renv::snapshot(prompt = FALSE)"
