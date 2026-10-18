#!/usr/bin/env Rscript
# Longest revisit interval at which expected downtime stays below 5% or 10% of
# the interval, for each white-flash scenario, from the sealed camera fits.
input <- "outputs/sensitivity/2026-09-17"
profiles_path <- "outputs/management/2026-09-19/tables/profiles.csv"
support_path <- "outputs/management/2026-09-19/break_even/break_even_estimates.csv"
out <- "outputs/management/2026-10-18/lost_day_curves"
source("R/derived_output_guard.R")
assert_derived_output_destination(c(input, profiles_path, support_path), out)
dir.create(out, recursive = TRUE, showWarnings = FALSE)
source("R/sensitivity_camera_fit.R"); source("R/sensitivity_camera_predict.R")
source("R/management_policy.R"); source("R/profile_support.R"); source("R/lost_day_curves.R")
design <- readRDS(file.path(input, "design.rds"))
white <- read.csv(profiles_path, stringsAsFactors = FALSE); white <- white[white$ft == "w", ]
X <- cam_new_design(design, white); rownames(X) <- white$bb
support <- read.csv(support_path, stringsAsFactors = FALSE)
max_follow <- c(Energizer = unique(support$reference_profile_max_followup),
                tapply(support$alternative_profile_max_followup, support$alternative, unique))
rows <- list()
for (family in c("weibull", "loglogistic")) {
  draws <- lost_day_draws(file.path(input, "models", paste0(family, "_camera"), "fit.rds"), design)
  for (b in white$bb) {
    grid <- seq(30, max_follow[[b]], by = 1)
    m <- lost_day_matrix(draws, X[b, ], b, design, family, grid)
    for (tol in c(0.05, 0.10)) {
      summary <- tolerance_summary(m, grid, tol)
      profile <- white[white$bb == b, , drop = FALSE]
      support_rows <- lapply(c(mean = "interval_at_mean_downtime", low = "draw_low", high = "draw_high"),
        function(column) lost_day_support(summary[[column]], profile, design$train))
      support_columns <- do.call(cbind, lapply(names(support_rows), function(label) {
        x <- support_rows[[label]]
        names(x) <- paste0(label, "_", names(x))
        x
      }))
      rows[[length(rows) + 1L]] <- cbind(data.frame(family = family, scenario = b, tolerance = tol),
        summary, max_followup = max_follow[[b]], support_columns)
    }
  }
}
res <- do.call(rbind, rows)
write.csv(res, file.path(out, "tolerance_intervals.csv"), row.names = FALSE)
hashes <- tools::md5sum(c(file.path(input, "design.rds"), file.path(input, "cohorts.rds"),
  file.path(input, "models", c("weibull_camera", "loglogistic_camera"), "fit.rds"),
  profiles_path, support_path, "R/lost_day_curves.R", "R/profile_support.R",
  "R/management_policy.R", "R/sensitivity_camera_predict.R", "R/sensitivity_camera_fit.R",
  "scripts/summarise_tolerance_intervals.R"))
write.csv(data.frame(file = names(hashes), md5 = unname(hashes)),
          file.path(out, "tolerance_input_md5.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out, "tolerance_session.txt"))
res[, 4:6] <- round(res[, 4:6], 1)
print(res[c("family", "scenario", "tolerance", "interval_at_mean_downtime", "draw_low", "draw_high",
            "share_beyond_followup", "mean_profile_intervals_at_risk", "mean_profile_cameras_at_risk",
            "mean_support")], row.names = FALSE)
