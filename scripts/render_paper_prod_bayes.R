#!/usr/bin/env Rscript

r_files <- sort(list.files("R", pattern = "\\.R$", full.names = TRUE))
for (f in r_files) {
  source(f)
}

profile <- Sys.getenv("ANALYSIS_PROFILE", "full")
if (!nzchar(profile)) {
  profile <- "full"
}

cfg <- read_analysis_config(profile = profile, path = "config/analysis.yml")
snapshot_files <- required_review_bayesian_snapshot_files(cfg)
review <- review_paths(cfg)

message("Using production Bayesian snapshot manifest: ", review$bayesian_manifest_path)
message("Rendering review manuscript to: ", review$manuscript_output_dir)

outputs <- render_review_manuscript_qmd(cfg, review_snapshot_files = snapshot_files)
print(outputs)
