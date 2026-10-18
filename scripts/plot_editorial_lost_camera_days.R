#!/usr/bin/env Rscript
# Editorial figure from the saved 19 September paired comparisons; no fitting.
args <- commandArgs(trailingOnly = TRUE)
input <- if (length(args)) args[1L] else
  "outputs/management/2026-09-19/break_even/break_even_estimates.csv"
out <- if (length(args) > 1L) args[2L] else
  "outputs/management/2026-10-18/editorial"
source("R/derived_output_guard.R")
source("R/editorial_lost_camera_days.R")
write_editorial_lost_camera_days(input, out)
