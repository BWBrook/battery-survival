#!/usr/bin/env Rscript

if (!requireNamespace("targets", quietly = TRUE)) {
  stop("Package `targets` is required. Run `just restore` first.", call. = FALSE)
}

Sys.setenv(ANALYSIS_PROFILE = "full")
targets::tar_make()
