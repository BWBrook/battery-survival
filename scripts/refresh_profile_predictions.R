#!/usr/bin/env Rscript
# Rebuild profile-dependent sensitivity summaries from the sealed 17 Sep fits.
# This is a derived refresh only: it never calls cmdstanr sampling or survreg.

args <- commandArgs(trailingOnly = TRUE)
input <- if (length(args) >= 1L) args[[1L]] else "outputs/sensitivity/2026-09-17"
out <- if (length(args) >= 2L) args[[2L]] else "outputs/management/2026-09-19"

source("R/config.R")
source("R/derived_output_guard.R")
source("R/sensitivity_camera_fit.R")
source("R/sensitivity_camera_predict.R")
source("R/profile_support.R")
source("R/profile_revision.R")
source("R/economics_core.R")
if (file.exists("R/sensitivity_aft.R")) source("R/sensitivity_aft.R")
assert_derived_output_destination(input, out)

required_file <- function(path) {
  if (!file.exists(path)) stop("required sealed input missing: ", path, call. = FALSE)
  normalizePath(path, mustWork = TRUE)
}
input <- normalizePath(input, mustWork = TRUE)
design_path <- required_file(file.path(input, "design.rds"))
design <- readRDS(design_path)
if (!is.list(design) || !is.data.frame(design$train))
  stop("sealed design.rds does not contain train data", call. = FALSE)

families <- c("weibull", "loglogistic")
model_ids <- as.vector(rbind(paste0(families, "_independent"),
                             paste0(families, "_camera")))
missing_models <- model_ids[!file.exists(file.path(input, "models", model_ids, "fit.rds"))]
if (length(missing_models)) stop("sealed camera fits missing: ", paste(missing_models, collapse = ", "), call. = FALSE)

dir.create(file.path(out, "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(out, "models"), recursive = TRUE, showWarnings = FALSE)

profiles <- rebuild_profile_revision(design, file.path(out, "tables"))
write.csv(profiles, file.path(out, "profiles.csv"), row.names = FALSE)
saveRDS(list(train = design$train, profiles = profiles),
        file.path(out, "profile_revision.rds"))

ratios <- c(20, 50, 100, 200)
thin_intervals <- 20L
thin_cameras <- 10L
decision_rows <- list()
draw_rows <- list()
heterogeneity_rows <- list()

profile_workload <- function(p) {
  data.frame(profile_seas = as.character(p$seas), profile_reg = as.character(p$reg),
             profile_log_fi_pd = as.numeric(p$log_fi_pd),
             profile_log_day_pd = as.numeric(p$log_day_pd),
             profile_cell_rows = as.integer(p$profile_cell_rows),
             profile_cell_cameras = as.integer(p$profile_cell_cameras),
             profile_cell_events = as.integer(p$profile_cell_events),
             stringsAsFactors = FALSE)
}

safe_max <- function(x) if (length(x) && any(is.finite(x))) max(x, na.rm = TRUE) else NA_real_
interval <- function(x) cam_interval(x)

for (id in model_ids) {
  family <- sub("_(independent|camera)$", "", id)
  camera_model <- grepl("_camera$", id)
  fit <- readRDS(required_file(file.path(input, "models", id, "fit.rds")))
  draws <- cam_extract_draws(fit, design, 1000L)
  if (length(draws$alpha) != 1000L) stop("retained draw count changed for ", id)
  X <- cam_new_design(design, profiles)
  parameter <- fit$summary()
  tau <- draws$tau
  heterogeneity_rows[[id]] <- do.call(rbind, lapply(seq_along(design$brands), function(b) {
    residual <- draws$sigma[, b]^2 * if (family == "weibull") pi^2 / 6 else pi^2 / 3
    fraction <- tau^2 / (tau^2 + residual)
    data.frame(model_id = id, bb = design$brands[b],
               fraction_low = interval(fraction)[[1L]],
               fraction_median = interval(fraction)[[2L]],
               fraction_high = interval(fraction)[[3L]],
               stringsAsFactors = FALSE)
  }))
  for (j in seq_len(nrow(profiles))) {
    p <- profiles[j, , drop = FALSE]
    b <- match(as.character(p$bb), design$brands)
    mu <- draws$alpha + as.numeric(draws$beta %*% X[j, ])
    sigma <- draws$sigma[, b]
    for (r in ratios) {
      roots <- cam_optimum(r, mu, sigma, draws$tau, family, 30L)
      if (anyNA(roots)) stop("camera optimum failed for ", id, " profile ", p$profile_id)
      finite <- is.finite(roots)
      finite_n <- sum(finite)
      q <- interval(roots)
      md <- q[[2L]]
      support <- if (is.finite(md)) profile_support_summary(md, p, design$train,
                                                               thin_intervals, thin_cameras) else NULL
      ss <- profile_revision_draw_support(roots, p, design$train,
                                          thin_intervals, thin_cameras, md)
      draw_rows[[length(draw_rows) + 1L]] <- data.frame(
        model_id = id, family = family, camera_effect = camera_model,
        profile_id = as.character(p$profile_id), bb = as.character(p$bb),
        ft = as.character(p$ft), reg = as.character(p$reg), seas = as.character(p$seas),
        r = r, draw = seq_along(roots), T = roots, stringsAsFactors = FALSE)
      row <- cbind(
        data.frame(model_id = id, family = family, camera_effect = camera_model,
                   profile_id = as.character(p$profile_id), bb = as.character(p$bb),
                   ft = as.character(p$ft), reg = as.character(p$reg),
                   seas = as.character(p$seas), r = r,
                   low = q[[1L]], median = q[[2L]], high = q[[3L]],
                   probability_no_finite_optimum = mean(!finite),
                   pooled_probability_beyond_followup_given_finite = ss$pooled_probability_beyond_followup_given_finite,
                   pooled_probability_thin_support_given_finite = ss$pooled_probability_thin_support_given_finite,
                   region_probability_beyond_followup_given_finite = ss$regional_probability_beyond_followup_given_finite,
                   region_probability_thin_support_given_finite = ss$regional_probability_thin_support_given_finite,
                   profile_probability_beyond_followup_given_finite = ss$profile_probability_beyond_followup_given_finite,
                   profile_probability_thin_intervals_given_finite = ss$profile_probability_thin_intervals_given_finite,
                   profile_probability_thin_cameras_given_finite = ss$profile_probability_thin_cameras_given_finite,
                   profile_probability_thin_support_given_finite = ss$profile_probability_thin_support_given_finite,
                   pooled_n_at_risk_at_median = ss$pooled_intervals_at_risk,
                   pooled_n_cameras_risk_at_median = ss$pooled_cameras_at_risk,
                   region_n_at_risk_at_median = ss$regional_intervals_at_risk,
                   region_n_cameras_risk_at_median = ss$regional_cameras_at_risk,
                   profile_n_at_risk_at_median = ss$profile_intervals_at_risk,
                   profile_n_cameras_risk_at_median = ss$profile_cameras_at_risk,
                   pooled_max_followup = ss$pooled_max_followup,
                   region_max_followup = ss$regional_max_followup,
                   profile_max_followup = ss$profile_max_followup,
                   pooled_intervals = nrow(profile_support_subset(design$train, p, c("bb", "ft"))),
                   pooled_cameras = length(unique(profile_support_subset(design$train, p, c("bb", "ft"))$camera)),
                   regional_intervals = nrow(profile_support_subset(design$train, p, c("bb", "ft", "reg"))),
                   regional_cameras = length(unique(profile_support_subset(design$train, p, c("bb", "ft", "reg"))$camera)),
                   profile_intervals = nrow(profile_support_subset(design$train, p)),
                   profile_cameras = length(unique(profile_support_subset(design$train, p)$camera)),
                   profile_support = if (is.null(support)) "no_finite_optimum" else support$support,
                   profile_workload_supported = if (is.null(support)) NA else support$workload_supported,
                   stringsAsFactors = FALSE),
        profile_workload(p)
      )
      decision_rows[[length(decision_rows) + 1L]] <- row
    }
  }
  rm(fit, draws, X, parameter)
  gc()
}

decisions <- do.call(rbind, decision_rows)
draws <- do.call(rbind, draw_rows)
write.csv(decisions, file.path(out, "tables", "camera_decisions.csv"), row.names = FALSE)
saveRDS(draws, file.path(out, "models", "camera_decision_draws.rds"))
write.csv(do.call(rbind, heterogeneity_rows),
          file.path(out, "tables", "camera_heterogeneity.csv"), row.names = FALSE)

# A compact comparison table for manuscript synthesis.  A comparison is
# admitted only when both medians are finite, within the joint-cell follow-up,
# and neither model has >50% posterior probability of thin joint support.
comparison <- list()
add_comparison <- function(kind, baseline_id, contrast_id, family, profile_id, r) {
  a <- decisions[decisions$model_id == baseline_id & decisions$profile_id == profile_id & decisions$r == r, , drop = FALSE]
  b <- decisions[decisions$model_id == contrast_id & decisions$profile_id == profile_id & decisions$r == r, , drop = FALSE]
  stopifnot(nrow(a) == 1L, nrow(b) == 1L)
  include <- is.finite(a$median) && is.finite(b$median) &&
    a$profile_support != "unobserved_profile" && b$profile_support != "unobserved_profile" &&
    a$profile_probability_thin_support_given_finite <= .5 &&
    b$profile_probability_thin_support_given_finite <= .5 &&
    a$median <= a$profile_max_followup && b$median <= b$profile_max_followup
  reason <- if (include) "included" else if (!is.finite(a$median) || !is.finite(b$median)) "non_finite_median" else if (a$profile_probability_thin_support_given_finite > .5 || b$profile_probability_thin_support_given_finite > .5) "thin_joint_support" else "beyond_joint_followup"
  data.frame(comparison_type = kind, family = family, profile_id = profile_id,
             bb = a$bb, ft = a$ft, reg = a$reg, seas = a$seas, r = r,
             baseline_model = baseline_id, contrast_model = contrast_id,
             included = include, exclusion_reason = reason,
             baseline_median = a$median, contrast_median = b$median,
             median_shift_days = b$median - a$median,
             baseline_ci_width = a$high - a$low,
             contrast_ci_width = b$high - b$low,
             ci_width_ratio = (b$high - b$low) / (a$high - a$low),
             stringsAsFactors = FALSE)
}
for (family in families) for (j in seq_len(nrow(profiles))) for (r in ratios) {
  pid <- as.character(profiles$profile_id[[j]])
  comparison[[length(comparison) + 1L]] <- add_comparison(
    "camera_effect", paste0(family, "_independent"), paste0(family, "_camera"), family, pid, r)
  if (family == "weibull") {
    comparison[[length(comparison) + 1L]] <- add_comparison(
      "family_shift_independent", "weibull_independent", "loglogistic_independent", "independent", pid, r)
    comparison[[length(comparison) + 1L]] <- add_comparison(
      "family_shift_camera", "weibull_camera", "loglogistic_camera", "camera", pid, r)
  }
}
comparison <- do.call(rbind, comparison)
write.csv(comparison, file.path(out, "tables", "camera_sensitivity_comparison.csv"), row.names = FALSE)

# Recompute the frequentist decisions from the sealed AFT fit grid when it is
# available.  This is a deterministic prediction step, not a refit.
aft_grid_path <- file.path(input, "models", "aft_grid.rds")
if (file.exists(aft_grid_path) && exists("sa_decision_for_profile", mode = "function")) {
  grid <- readRDS(aft_grid_path)
  aft_rows <- list()
  for (id in names(grid$fits)) {
    fit <- grid$fits[[id]]
    if (is.null(fit)) next
    for (j in seq_len(nrow(profiles))) {
      p <- profiles[j, , drop = FALSE]
      g <- profile_support_subset(design$train, p, c("bb", "ft"))
      v <- sa_decision_for_profile(fit, p, ratios, max(g$rd), support_data = design$train)
      aft_rows[[length(aft_rows) + 1L]] <- cbind(model_id = id,
                                                  profile_id = p$profile_id,
                                                  bb = as.character(p$bb), ft = as.character(p$ft),
                                                  reg = as.character(p$reg), seas = as.character(p$seas), v)
    }
  }
  if (length(aft_rows)) write.csv(do.call(rbind, aft_rows),
                                  file.path(out, "tables", "aft_decisions.csv"), row.names = FALSE)
}

input_files <- c(design_path, file.path(input, "models", model_ids, "fit.rds"),
                 if (file.exists(aft_grid_path)) aft_grid_path else character())
source_files <- c("R/config.R", "R/derived_output_guard.R", "R/economics_core.R", "R/sensitivity_camera_fit.R", "R/sensitivity_camera_predict.R",
                  "R/profile_support.R", "R/profile_revision.R", "R/sensitivity_aft.R",
                  "scripts/refresh_profile_predictions.R")
writeLines(system2("sha256sum", input_files, stdout = TRUE), file.path(out, "input-sha256.txt"))
writeLines(system2("sha256sum", source_files[file.exists(source_files)], stdout = TRUE),
           file.path(out, "source-sha256.txt"))
writeLines(capture.output(sessionInfo()), file.path(out, "session-refresh-profiles.txt"))
cat(format(Sys.time()), "COMPLETED profile prediction refresh; no model fitting performed\n")
