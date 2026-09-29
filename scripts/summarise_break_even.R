#!/usr/bin/env Rscript
# Fixed-interval white-flash break-even analysis from archived camera fits.
# No model fitting occurs in this script.

args <- commandArgs(trailingOnly = TRUE)
input <- if (length(args)) args[1L] else "outputs/sensitivity/2026-09-17"
out <- if (length(args) > 1L) args[2L] else
  "outputs/management/2026-09-19/break_even"
source("R/derived_output_guard.R")
assert_derived_output_destination(input, out)
dir.create(out, recursive = TRUE, showWarnings = FALSE)

source("R/sensitivity_camera_fit.R")
source("R/sensitivity_camera_predict.R")
source("R/profile_support.R")
source("R/management_policy.R")
source("R/management_break_even.R")

design <- readRDS(file.path(input, "design.rds"))
profiles_path <- if (length(args) > 2L) args[3L] else
  "outputs/management/2026-09-19/tables/profiles.csv"
if (!file.exists(profiles_path)) stop("Corrected profiles missing; run just refresh-profiles first")
profiles <- read.csv(profiles_path, stringsAsFactors = FALSE)
costs <- read.csv("config/battery_costs.csv", stringsAsFactors = FALSE)
white <- profiles[profiles$ft == "w", , drop = FALSE]
reference <- white[white$bb == "Energizer", , drop = FALSE]
alternatives <- white[white$bb != "Energizer", , drop = FALSE]
stopifnot(nrow(reference) == 1L, nrow(alternatives) == 4L)
X <- cam_new_design(design, white)
rownames(X) <- white$bb

prefix_names <- function(x, prefix) {
  names(x) <- paste0(prefix, names(x))
  x
}

fmt_number <- function(x, digits = 2L) {
  ifelse(is.infinite(x), "Inf", formatC(x, format = "f", digits = digits))
}

result <- list()
effort <- list()
for (family in c("weibull", "loglogistic")) {
  fit_path <- file.path(input, "models", paste0(family, "_camera"), "fit.rds")
  fit <- readRDS(fit_path)
  draws <- cam_extract_draws(fit, design, 1000L)

  profile_values <- list()
  for (j in seq_len(nrow(white))) {
    p <- white[j, , drop = FALSE]
    mu <- draws$alpha + as.numeric(draws$beta %*% X[p$bb, ])
    sigma <- draws$sigma[, match(p$bb, design$brands)]
    profile_values[[p$bb]] <- lapply(c(90, 120), function(T) {
      management_loss(T, 1, 1, mu, sigma, draws$tau, family)
    })
    names(profile_values[[p$bb]]) <- c("90", "120")

    v120 <- profile_values[[p$bb]][["120"]]
    ei_draw <- 120 / v120$active
    sp <- management_profile_support(120, p, design$train)
    effort[[length(effort) + 1L]] <- cbind(
      data.frame(family = family, bb = p$bb, ft = p$ft, reg = p$reg, seas = p$seas,
                 interval = 120,
                 expected_downtime = mean(v120$downtime),
                 downtime_low = cam_interval(v120$downtime)["low"],
                 downtime_high = cam_interval(v120$downtime)["high"],
                 effort_inflation = 120 / mean(v120$active),
                 effort_inflation_draw_mean = mean(ei_draw),
                 effort_inflation_low = cam_interval(ei_draw)["low"],
                 effort_inflation_median = cam_interval(ei_draw)["median"],
                 effort_inflation_high = cam_interval(ei_draw)["high"]),
      sp
    )
  }

  ref_cost <- costs$battery_cost[match("Energizer", costs$bb)]
  for (j in seq_len(nrow(alternatives))) {
    alt <- alternatives[j, , drop = FALSE]
    alt_cost <- costs$battery_cost[match(alt$bb, costs$bb)]
    for (T in c(90, 120)) {
      av <- profile_values[[alt$bb]][[as.character(T)]]
      rv <- profile_values[["Energizer"]][[as.character(T)]]
      be <- management_break_even(T, alt_cost, ref_cost,
                                  av$downtime, rv$downtime)
      asp <- prefix_names(management_profile_support(T, alt, design$train),
                          "alternative_")
      rsp <- prefix_names(management_profile_support(T, reference, design$train),
                          "reference_")
      result[[length(result) + 1L]] <- cbind(
        data.frame(
          family = family, interval = T,
          alternative = alt$bb, alternative_ft = alt$ft,
          alternative_reg = alt$reg, alternative_seas = alt$seas,
          alternative_log_fi_pd = alt$log_fi_pd, alternative_log_day_pd = alt$log_day_pd,
          reference = "Energizer", reference_ft = reference$ft,
          reference_reg = reference$reg, reference_seas = reference$seas,
          reference_log_fi_pd = reference$log_fi_pd, reference_log_day_pd = reference$log_day_pd,
          alternative_battery_cost = alt_cost,
          reference_battery_cost = ref_cost,
          battery_cost_saving = be$battery_cost_saving,
          alternative_expected_downtime = mean(av$downtime),
          alternative_downtime_low = cam_interval(av$downtime)["low"],
          alternative_downtime_high = cam_interval(av$downtime)["high"],
          reference_expected_downtime = mean(rv$downtime),
          reference_downtime_low = cam_interval(rv$downtime)["low"],
          reference_downtime_high = cam_interval(rv$downtime)["high"],
          downtime_gap_mean = be$downtime_gap_mean,
          downtime_gap_low = be$downtime_gap_low,
          downtime_gap_high = be$downtime_gap_high,
          break_even_lost_day_value = be$break_even,
          break_even_low = be$break_even_low,
          break_even_median = be$break_even_median,
          break_even_high = be$break_even_high,
          probability_positive_gap = be$probability_positive_gap,
          probability_no_finite_crossing = be$probability_no_finite_crossing,
          uncertainty = "paired posterior draws; +Inf retained when downtime gap <= 0",
          service_cost = "cancels at common interval"
        ), asp, rsp
      )
    }
  }
  rm(fit, draws, profile_values)
  gc()
}

result <- do.call(rbind, result)
effort <- do.call(rbind, effort)
result <- result[order(result$interval, result$alternative, result$family), ]
effort <- effort[order(effort$bb, effort$family), ]
write.csv(result, file.path(out, "break_even_estimates.csv"), row.names = FALSE)
write.csv(effort, file.path(out, "effort_inflation_120.csv"), row.names = FALSE)

# Preserve a labelled comparison with the prior target; equality is not expected
# because the operating profiles and support definition have changed.
previous_path <- "outputs/management/2026-09-18/break_even/break_even_estimates.csv"
if (file.exists(previous_path)) {
  old <- read.csv(previous_path, stringsAsFactors = FALSE)
  old <- old[, c("family", "interval", "alternative", "break_even_lost_day_value")]
  names(old)[4] <- "previous_profile_threshold"
  comparison <- merge(result[, c("family", "interval", "alternative", "break_even_lost_day_value")],
                      old, by = c("family", "interval", "alternative"), all.x = TRUE)
  comparison$change <- comparison$break_even_lost_day_value - comparison$previous_profile_threshold
  write.csv(comparison, file.path(out, "comparison_previous_profiles.csv"), row.names = FALSE)
}

# Compact manuscript candidate: point estimates are ratios of posterior mean
# downtimes.  Brackets are paired-draw 95% intervals and can contain Inf.
wide <- reshape(result[, c("interval", "alternative", "family",
                           "break_even_lost_day_value", "break_even_low",
                           "break_even_high", "probability_no_finite_crossing",
                           "alternative_profile_intervals_at_risk",
                           "reference_profile_intervals_at_risk")],
                idvar = c("interval", "alternative"), timevar = "family",
                direction = "wide")
wide <- wide[order(wide$interval, wide$alternative), ]
table_lines <- c(
  "| Replacement interval (days) | Cheaper white-flash set | Weibull break-even value | Log-logistic break-even value | Alternative profile intervals / cameras at risk |",
  "|---:|:---|---:|---:|---:|"
)
for (i in seq_len(nrow(wide))) {
  cell <- function(f) {
    support_status <- result$alternative_support[
      result$family == f & result$interval == wide$interval[i] &
        result$alternative == wide$alternative[i]]
    if (!support_status %in% c("within_followup", "thin")) return("—")
    point <- wide[[paste0("break_even_lost_day_value.", f)]][i]
    low <- wide[[paste0("break_even_low.", f)]][i]
    high <- wide[[paste0("break_even_high.", f)]][i]
    paste0(fmt_number(point), " [", fmt_number(low), ", ",
           fmt_number(high), "]")
  }
  table_lines <- c(table_lines, paste0(
    "| ", wide$interval[i], " | ", wide$alternative[i], " | ",
    cell("weibull"), " | ", cell("loglogistic"), " | ",
    wide$alternative_profile_intervals_at_risk.weibull[i], " / ",
    result$alternative_profile_cameras_at_risk[
      result$family == "weibull" & result$interval == wide$interval[i] &
        result$alternative == wide$alternative[i]
    ], " |"
  ))
}
writeLines(c(
  "Table 2. Lost-camera-day value at which a cheaper white-flash battery set ties Energizer at a fixed replacement interval.",
  "",
  table_lines,
  "",
  paste0(
    "An em dash withholds an unsupported extrapolation; numerical model extrapolations remain in the CSV. Point estimates use posterior mean downtime under the last-image endpoint convention. Brackets are 95% intervals from paired posterior draws; Inf is retained when the cheaper alternative has no finite crossing in a draw. Common servicing costs cancel. Energizer had ",
    unique(result$reference_profile_intervals_at_risk[result$interval == 90]),
    " intervals from ",
    unique(result$reference_profile_cameras_at_risk[result$interval == 90]),
    " cameras at risk at 90 days and ",
    unique(result$reference_profile_intervals_at_risk[result$interval == 120]),
    " intervals from ",
    unique(result$reference_profile_cameras_at_risk[result$interval == 120]),
    " cameras at 120 days. Procell at 120 days had ",
    unique(result$alternative_profile_intervals_at_risk[
      result$alternative == "Procell" & result$interval == 120]),
    " intervals from ",
    unique(result$alternative_profile_cameras_at_risk[
      result$alternative == "Procell" & result$interval == 120]),
    " cameras and was classified as ",
    unique(result$alternative_support[
      result$alternative == "Procell" & result$interval == 120]),
    ". Profiles use the most frequent observed region/season cell and its observed workload pair nearest the cell medians. Profile risk counts match brand, flash, region and season. Comparisons do not isolate causal battery-brand effects."
  )
), file.path(out, "table2_break_even.md"))

supp <- c(
  "## Fixed-interval break-even analysis",
  "",
  "For alternative battery set X and Energizer reference E at a common interval T, the common servicing cost cancels. The break-even value of a lost camera-day is `(C_E - C_X) / {T (D_X - D_E)}`. Point estimates use posterior mean downtime. Uncertainty pairs the same retained posterior draw across profiles and marginalises the new-camera effect separately for each profile using 30-node normal quadrature.",
  "",
  "A non-positive downtime gap means that the cheaper alternative is no worse on either cost component in that draw. Its switching value is recorded as `Inf`; the output reports this probability and the unconditional interval retains the infinite mass. Profiles differ in observed covariates, so comparisons are conditional operating-profile contrasts rather than causal battery-brand effects.",
  "",
  table_lines
)
writeLines(supp, file.path(out, "supplement_break_even.md"))

capture.output(sessionInfo(), file = file.path(out, "session-break-even.txt"))
input_files <- c(
  file.path(input, "design.rds"),
  profiles_path,
  file.path(input, "models", "weibull_camera", "fit.rds"),
  file.path(input, "models", "loglogistic_camera", "fit.rds"),
  "config/battery_costs.csv"
)
if (file.exists(previous_path)) input_files <- c(input_files, previous_path)
source_files <- c("R/derived_output_guard.R", "R/management_break_even.R", "R/management_policy.R",
                  "R/profile_support.R", "R/economics_core.R",
                  "R/sensitivity_camera_fit.R", "R/sensitivity_camera_predict.R",
                  "scripts/summarise_break_even.R",
                  "tests/testthat/test-management-break-even.R")
writeLines(system2("sha256sum", input_files, stdout = TRUE),
           file.path(out, "input-sha256.txt"))
writeLines(system2("sha256sum", source_files, stdout = TRUE),
           file.path(out, "source-sha256.txt"))
artifact_files <- list.files(out, full.names = TRUE)
artifact_files <- artifact_files[basename(artifact_files) != "artifact-sha256.txt"]
writeLines(system2("sha256sum", artifact_files, stdout = TRUE),
           file.path(out, "artifact-sha256.txt"))
cat("COMPLETED fixed-interval break-even analysis\n")
