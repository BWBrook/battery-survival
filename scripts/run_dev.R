#!/usr/bin/env Rscript

if (!requireNamespace("targets", quietly = TRUE)) {
  stop("Package `targets` is required. Run `just restore` first.", call. = FALSE)
}

profile <- Sys.getenv("ANALYSIS_PROFILE", "dev")
if (!nzchar(profile)) {
  profile <- "dev"
}
Sys.setenv(ANALYSIS_PROFILE = profile)
targets::tar_make()
