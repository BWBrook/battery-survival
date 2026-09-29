#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(survival))
for (f in sort(list.files("R", pattern = "\\.R$", full.names = TRUE))) source(f)
cfg <- yaml::read_yaml("config/sensitivity.yml")
args <- commandArgs(trailingOnly = TRUE)
stage <- if (length(args)) args[1] else "all"
if (!stage %in% c("prepare", "aft", "camera", "summarise", "all")) stop("Unknown stage")
out <- cfg$output_dir
pipeline_cfg <- read_analysis_config("full")
raw <- read_analysis_data(pipeline_cfg$data_file)
dat <- derive_features(validate_analysis_data(raw))
dat <- apply_exclusions(dat, read_exclusions(pipeline_cfg$exclusions_file))$data
parts <- build_analysis_partitions(dat, pipeline_cfg)
train <- droplevels(parts$train)
stopifnot(nrow(train) == 3216L, length(unique(train$camera)) == 489L)
profiles <- build_prediction_profiles(train)
# Establish or validate the immutable run identity before any cohort, design,
# profile, Stan-data, or checkpoint-associated output can be overwritten.
design <- cam_design(train)
checkpoint_guard(design, cfg, out)
for (d in c("tables", "models", "figures")) dir.create(file.path(out, d), showWarnings = FALSE)
write.csv(parts$summary, file.path(out, "tables", "cohort.csv"), row.names = FALSE)
write.csv(profiles, file.path(out, "tables", "profiles.csv"), row.names = FALSE)
saveRDS(list(train = train, sw = parts$validation, profiles = profiles), file.path(out, "cohorts.rds"))
capture.output(sessionInfo(), file = file.path(out, paste0("session-", stage, ".txt")))
saveRDS(design, file.path(out, "design.rds"))
if (stage %in% c("prepare", "camera", "all")) {
  set.seed(cfg$seed)
  prior <- lapply(cfg$camera$families, function(family) {
    n <- 5000L
    x <- cam_new_design(design, profiles)
    b <- matrix(rnorm(n * ncol(x), 0, cfg$camera$beta_sd), nrow = n)
    mu <- rnorm(n, cfg$camera$intercept_mean, cfg$camera$intercept_sd) +
      rowSums(b * x[rep(seq_len(nrow(x)), length.out = n), , drop = FALSE])
    sig <- exp(rnorm(n, cfg$camera$log_scale_mean, cfg$camera$log_scale_sd))
    mu <- mu + abs(rnorm(n, 0, cfg$camera$camera_sd_scale)) * rnorm(n)
    u <- runif(n)
    y <- exp(mu + sig * if (family == "weibull") log(-log(u)) else qlogis(u))
    data.frame(family = family, t(cam_interval(y)), prob_below_1_day = mean(y < 1),
               prob_above_365_days = mean(y > 365))
  })
  write.csv(do.call(rbind, prior), file.path(out, "tables", "prior_predictive.csv"), row.names = FALSE)
}
if (stage %in% c("aft", "all")) run_sa_aft(train, parts$validation, profiles, cfg)
if (stage %in% c("camera", "all")) {
  fits <- cam_fit_models(design, cfg, file.path(out, "models"), checkpoint_root = out)
  diag <- lapply(names(fits), function(id) {
    v <- cam_diagnostics(fits[[id]], id, cfg$camera$max_treedepth)
    write.csv(v$parameters, file.path(out, "tables", paste0(id, "_parameters.csv")), row.names = FALSE)
    v$summary
  })
  write.csv(do.call(rbind, diag), file.path(out, "tables", "camera_diagnostics.csv"), row.names = FALSE)
}
if (stage %in% c("summarise", "all")) run_sa_camera_summary(design, profiles, cfg)
capture.output(sessionInfo(), file = file.path(out, paste0("session-", stage, ".txt")))
packages <- c("survival", "cmdstanr", "posterior", "dplyr", "readr", "tidyr", "purrr", "yaml", "testthat", "jsonlite", "data.table")
versions <- data.frame(package = packages, version = vapply(packages, function(p)
  if (requireNamespace(p, quietly = TRUE)) as.character(packageVersion(p)) else NA_character_, character(1)))
write.csv(versions, file.path(out, "runtime-package-versions.csv"), row.names = FALSE)
cat(format(Sys.time()), "COMPLETED", stage, "\n")
