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

bayes-gamma-check:
  ANALYSIS_PROFILE=bayes_gamma_check Rscript scripts/run_full.R

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

# Bounded SA; run model stages on deep-server under tmux.
# R --vanilla permits an explicitly provisioned, recorded project library.
sensitivity stage="all":
  Rscript --vanilla scripts/run_sensitivity.R {{stage}}

# Private integrated publication draft; saved model outputs must already exist.
publication:
  Rscript --vanilla scripts/plot_manuscript_sensitivity.R
  make -B -C "$HOME/work/makedoc" CONFIG="$PWD/settings/build.yaml" check
  python3 scripts/format_manuscript_docx.py outputs/publication/battery-survival-integrated.docx
  python3 "$HOME/work/makedoc/scripts/build_manifest.py" --config "$PWD/settings/build.yaml" --profile battery_survival_integrated --output outputs/publication/battery-survival-integrated_build_manifest.json --pdf outputs/publication/battery-survival-integrated.pdf --docx outputs/publication/battery-survival-integrated.docx
  make -B -C "$HOME/work/makedoc" CONFIG="$PWD/settings/build.yaml" PROFILE=battery_survival_supplement check
  python3 scripts/format_manuscript_docx.py outputs/publication/battery-survival-supplement.docx
  python3 "$HOME/work/makedoc/scripts/build_manifest.py" --config "$PWD/settings/build.yaml" --profile battery_survival_supplement --output outputs/publication/battery-survival-supplement_build_manifest.json --pdf outputs/publication/battery-survival-supplement.pdf --docx outputs/publication/battery-survival-supplement.docx

# Derived management results only; saved camera fits and their runtime required.
management:
  Rscript --vanilla scripts/summarise_management.R

# Refresh corrected operating profiles and conditional diagnostics from sealed fits.
refresh-profiles:
  Rscript --vanilla scripts/refresh_profile_predictions.R

# Current fixed-interval management comparison; run refresh-profiles first.
break-even:
  Rscript --vanilla scripts/summarise_break_even.R
