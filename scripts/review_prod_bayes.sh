#!/usr/bin/env bash
set -euo pipefail

ANALYSIS_PROFILE=bayes_prod Rscript scripts/run_full.R
ANALYSIS_PROFILE=full Rscript scripts/run_full.R
ANALYSIS_PROFILE=full Rscript scripts/render_paper_prod_bayes.R
