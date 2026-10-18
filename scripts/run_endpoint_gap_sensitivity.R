#!/usr/bin/env Rscript
# Last-image gap sensitivity: impute shutdown after the last image from each
# failed interval's own image rate, refit the brand-scale region AFTs and
# recompute medians, workload coefficients and white-flash break-even values.
# Optional arguments: input directory, profiles CSV, output directory, imputations.

args <- commandArgs(trailingOnly = TRUE)
input <- if (length(args)) args[1L] else "outputs/sensitivity/2026-09-17"
profiles_path <- if (length(args) > 1L) args[2L] else "outputs/management/2026-09-19/tables/profiles.csv"
out <- if (length(args) > 2L) args[3L] else "outputs/endpoint_gap/2026-10-18"
support_path <- "outputs/management/2026-09-19/break_even/break_even_estimates.csv"
imputations_requested <- if (length(args) > 3L) args[4L] else 200L
clustering <- c(1, 3, 10)
families <- c("weibull", "loglogistic")

source("R/derived_output_guard.R")
assert_derived_output_destination(c(input, profiles_path, support_path), out)
suppressPackageStartupMessages(library(survival))
source("R/sensitivity_aft.R")
source("R/endpoint_gap_sensitivity.R")
imputations <- gap_parse_imputations(imputations_requested)
dir.create(out, recursive = TRUE, showWarnings = FALSE)

train <- readRDS(file.path(input, "cohorts.rds"))$train
stopifnot(nrow(train) == 3216L, sum(train$event) == 1735L)
profiles <- gap_profile_frame(read.csv(profiles_path, stringsAsFactors = FALSE), train)
costs <- read.csv("config/battery_costs.csv", stringsAsFactors = FALSE)
cap_variant <- max(train$rd)
support <- read.csv(support_path, stringsAsFactors = FALSE)
support <- unique(support[, c("interval", "alternative", "alternative_support")])
fit_diagnostics <- list()

run_one <- function(dat, scenario, imputation) {
  rows <- lapply(families, function(family) {
    checked <- gap_fit_diagnosed(dat, family)
    diagnostics <- cbind(scenario = scenario, imputation = imputation, family = family,
                         checked$diagnostics)
    diagnostics$finite_expected_losses <- NA
    index <- length(fit_diagnostics) + 1L
    fit_diagnostics[[index]] <<- diagnostics
    if (!tail(diagnostics$accepted, 1L)) {
      return(list(break_even = NULL, coefficients = NULL))
    }
    fit <- checked$fit
    prediction_error <- ""
    be <- tryCatch(gap_break_even(fit, profiles, costs), error = function(e) {
      prediction_error <<- conditionMessage(e)
      NULL
    })
    finite_losses <- !is.null(be) && all(is.finite(be$extra_lost_days)) && all(is.finite(be$saving))
    diagnostics$finite_expected_losses[nrow(diagnostics)] <- finite_losses
    diagnostics$accepted[nrow(diagnostics)] <- finite_losses
    if (nzchar(prediction_error)) diagnostics$error[nrow(diagnostics)] <- prediction_error
    fit_diagnostics[[index]] <<- diagnostics
    if (!finite_losses) {
      return(list(break_even = NULL, coefficients = NULL))
    }
    co <- coef(fit)[c("log_fi_pd", "log_day_pd", "ftw")]
    list(
      break_even = cbind(scenario = scenario, imputation = imputation, family = family, be),
      coefficients = data.frame(scenario = scenario, imputation = imputation, family = family,
                                term = names(co), estimate = unname(co))
    )
  })
  list(
    break_even = do.call(rbind, lapply(rows, `[[`, "break_even")),
    coefficients = do.call(rbind, lapply(rows, `[[`, "coefficients")),
    km = cbind(scenario = scenario, imputation = imputation, gap_km_medians(dat))
  )
}

results <- list(run_one(train, "observed", 0L))
gaps <- list()
scenarios <- rbind(data.frame(b = clustering, cap = Inf),
                   data.frame(b = max(clustering), cap = cap_variant))
for (k in seq_len(nrow(scenarios))) {
  b <- scenarios$b[[k]]; cap <- scenarios$cap[[k]]
  for (m in seq_len(imputations)) {
    set.seed(20261018L + 1000L * b + m)
    shifted <- gap_impute_failure_times(train, b, cap)
    scenario <- paste0("b", b, if (is.finite(cap)) paste0("_cap", cap) else "")
    results[[length(results) + 1L]] <- run_one(shifted, scenario, m)
    failed <- shifted$event == 1L
    gaps[[length(gaps) + 1L]] <- data.frame(
      scenario = scenario, imputation = m,
      gap_median = median(shifted$gap_days[failed]),
      gap_mean = mean(shifted$gap_days[failed]),
      gap_p90 = unname(quantile(shifted$gap_days[failed], 0.9)),
      gap_p99 = unname(quantile(shifted$gap_days[failed], 0.99)),
      gap_share_over_7 = mean(shifted$gap_days[failed] > 7),
      gap_share_over_90 = mean(shifted$gap_days[failed] > 90),
      max_gap = max(shifted$gap_days[failed]),
      max_shifted_lifetime = max(shifted$rd[failed]),
      capped = sum(shifted$gap_capped))
  }
}

bind <- function(name) do.call(rbind, lapply(results, `[[`, name))
break_even <- bind("break_even")
coefficients <- bind("coefficients")
km <- bind("km")
gap_draws <- do.call(rbind, gaps)
fit_diagnostics <- do.call(rbind, fit_diagnostics)
scenario_status <- gap_scenario_status(fit_diagnostics, imputations)
break_even <- gap_attach_scenario_status(break_even, scenario_status)
coefficients <- gap_attach_scenario_status(coefficients, scenario_status)
reported_break_even <- break_even[break_even$status == "reported", , drop = FALSE]
reported_coefficients <- coefficients[coefficients$status == "reported", , drop = FALSE]

q <- function(x, p) unname(quantile(x, p, na.rm = TRUE))
summarise_by <- function(df, keys, value) {
  groups <- split(df, df[keys], drop = TRUE)
  do.call(rbind, lapply(groups, function(g) {
    cbind(g[1L, keys, drop = FALSE],
          median = median(g[[value]]), low = q(g[[value]], 0.025), high = q(g[[value]], 0.975))
  }))
}
be_summary <- summarise_by(reported_break_even, c("scenario", "family", "interval", "alternative"), "threshold")
keys <- c("scenario", "family", "interval", "alternative")
pooled <- do.call(rbind, lapply(split(reported_break_even, reported_break_even[keys], drop = TRUE), function(g) {
  stopifnot(length(unique(g$saving)) == 1L)
  cbind(g[1L, keys, drop = FALSE],
        gap_pool_expected_loss(g$saving[[1L]], g$extra_lost_days,
                               imputed = g$scenario[[1L]] != "observed"))
}))
pooled <- merge(pooled, support, by = c("interval", "alternative"), all.x = TRUE)
pooled$reportable <- pooled$alternative_support == "within_followup"
mcse_rows <- pooled[pooled$reportable & pooled$interval == 120 & pooled$scenario != "observed", , drop = FALSE]
relative_mcse <- mcse_rows$pooled_threshold_mcse / abs(mcse_rows$pooled_threshold)
mcse_pass <- length(relative_mcse) > 0L && all(is.finite(relative_mcse)) && all(relative_mcse <= 0.05)
worst <- if (length(relative_mcse) && all(is.finite(relative_mcse))) which.max(relative_mcse) else NA_integer_
run_status <- if (!all(scenario_status$complete)) "incomplete" else if (any(scenario_status$status == "withheld")) {
  "complete_with_withheld_groups"
} else "complete_all_groups_reported"
analysis_status <- data.frame(run_status = run_status, imputations_per_setting = imputations,
  groups_reported = sum(scenario_status$status == "reported"),
  groups_withheld = sum(scenario_status$status == "withheld"),
  fits_expected = sum(scenario_status$fits_expected), fits_attempted = sum(scenario_status$fits_attempted),
  fits_accepted = sum(scenario_status$fits_accepted), fits_failed = sum(scenario_status$fits_failed),
  mcse_rule = "relative MCSE <= 0.05 for every reported, supported 120-day pooled threshold",
  mcse_pass = mcse_pass,
  max_relative_mcse = if (is.na(worst)) NA_real_ else relative_mcse[[worst]],
  worst_scenario = if (is.na(worst)) NA_character_ else mcse_rows$scenario[[worst]],
  worst_family = if (is.na(worst)) NA_character_ else mcse_rows$family[[worst]],
  worst_alternative = if (is.na(worst)) NA_character_ else mcse_rows$alternative[[worst]])
write.csv(pooled[order(pooled$family, pooled$interval, pooled$alternative, pooled$scenario), ],
          file.path(out, "break_even_pooled.csv"), row.names = FALSE)
lost_summary <- summarise_by(reported_break_even, c("scenario", "family", "interval", "alternative"), "extra_lost_days")
co_summary <- summarise_by(reported_coefficients, c("scenario", "family", "term"), "estimate")
km_summary <- summarise_by(km, c("scenario", "bb"), "median")
gap_summary <- summarise_by(gap_draws, "scenario", "gap_median")
gap_summary$share_over_7 <- tapply(gap_draws$gap_share_over_7, gap_draws$scenario, mean)[gap_summary$scenario]
gap_summary$capped_mean <- tapply(gap_draws$capped, gap_draws$scenario, mean)[gap_summary$scenario]
# Means of within-imputation summaries; maxima also retain their across-
# imputation range. These describe the assumed gaps, not uncertainty intervals.
for (column in c("gap_mean", "gap_p99", "gap_share_over_90", "max_gap", "max_shifted_lifetime")) {
  gap_summary[[paste0(column, "_mean")]] <- tapply(gap_draws[[column]], gap_draws$scenario, mean)[gap_summary$scenario]
}
for (column in c("max_gap", "max_shifted_lifetime")) {
  for (bound in c("min", "max")) {
    gap_summary[[paste0(column, "_", bound)]] <- tapply(gap_draws[[column]], gap_draws$scenario, match.fun(bound))[gap_summary$scenario]
  }
}

write.csv(break_even, file.path(out, "break_even_draws.csv"), row.names = FALSE)
write.csv(coefficients, file.path(out, "coefficient_draws.csv"), row.names = FALSE)
write.csv(be_summary, file.path(out, "break_even_summary.csv"), row.names = FALSE)
write.csv(lost_summary, file.path(out, "extra_lost_days_summary.csv"), row.names = FALSE)
write.csv(co_summary, file.path(out, "coefficient_summary.csv"), row.names = FALSE)
write.csv(km_summary, file.path(out, "km_median_summary.csv"), row.names = FALSE)
write.csv(gap_draws, file.path(out, "gap_draws.csv"), row.names = FALSE)
write.csv(gap_summary, file.path(out, "gap_summary.csv"), row.names = FALSE)
write.csv(fit_diagnostics, file.path(out, "fit_diagnostics.csv"), row.names = FALSE)
write.csv(scenario_status, file.path(out, "scenario_family_status.csv"), row.names = FALSE)
write.csv(analysis_status, file.path(out, "analysis_status.csv"), row.names = FALSE)
writeLines(c(capture.output(sessionInfo()),
             paste("cap variant (max recorded duration):", cap_variant), paste("imputations:", imputations),
             paste("run status:", run_status),
             "pooled_threshold_mcse: delta-method Monte Carlo SE over assumed-gap imputations; not sampling or posterior uncertainty",
             "observed: one unshifted fit, zero imputations, MCSE unavailable",
             "fit_diagnostics.csv records every default attempt and any convergence retry at maxiter=200",
             "Any failed fit withholds its entire scenario-family group; raw accepted-fit rows from withheld groups are labelled and excluded from every model-dependent summary",
             capture.output(print(scenario_status[scenario_status$status == "withheld", ], row.names = FALSE)),
             paste("reported supported 120-day relative-MCSE criterion passed:", mcse_pass),
             "gap_summary tail columns: means of within-imputation summaries; max_*_min/max give the range across imputations"),
           file.path(out, "session.txt"))
hashes <- tools::md5sum(c(file.path(input, "cohorts.rds"), profiles_path, support_path, "config/battery_costs.csv",
                          "R/endpoint_gap_sensitivity.R", "R/sensitivity_aft.R",
                          "scripts/run_endpoint_gap_sensitivity.R"))
write.csv(data.frame(file = names(hashes), md5 = unname(hashes)), file.path(out, "input_md5.csv"), row.names = FALSE)
cat(run_status, ":", analysis_status$groups_reported, "reported groups;",
    analysis_status$groups_withheld, "withheld groups;",
    analysis_status$fits_failed, "failed final fits; reported 120-day MCSE criterion:", mcse_pass, "\n")
