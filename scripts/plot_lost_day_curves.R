#!/usr/bin/env Rscript
# Continuous expected lost camera-days per cycle for the white-flash scenarios,
# from the sealed 17 September camera fits and the corrected 19 September
# scenarios. No model fitting occurs.

input <- "outputs/sensitivity/2026-09-17"
profiles_path <- "outputs/management/2026-09-19/tables/profiles.csv"
support_path <- "outputs/management/2026-09-19/break_even/break_even_estimates.csv"
out <- "outputs/management/2026-10-18/lost_day_curves"

source("R/derived_output_guard.R")
assert_derived_output_destination(c(input, profiles_path, support_path), out)
dir.create(out, recursive = TRUE, showWarnings = FALSE)
source("R/sensitivity_camera_fit.R")
source("R/sensitivity_camera_predict.R")
source("R/management_policy.R")
source("R/profile_support.R")
source("R/lost_day_curves.R")

design <- readRDS(file.path(input, "design.rds"))
profiles <- read.csv(profiles_path, stringsAsFactors = FALSE)
white <- profiles[profiles$ft == "w", , drop = FALSE]
X <- cam_new_design(design, white)
rownames(X) <- white$bb
support <- read.csv(support_path, stringsAsFactors = FALSE)
max_follow <- c(Energizer = unique(support$reference_profile_max_followup),
                tapply(support$alternative_profile_max_followup, support$alternative, unique))
grid <- sort(unique(c(seq(30, max(max_follow), by = 3), unname(max_follow))))
profile_support <- lapply(white$bb, function(b)
  lost_day_support(grid, white[white$bb == b, , drop = FALSE], design$train))
names(profile_support) <- white$bb

curves <- list(); additional <- list()
for (family in c("weibull", "loglogistic")) {
  draws <- lost_day_draws(file.path(input, "models", paste0(family, "_camera"), "fit.rds"), design)
  mats <- lapply(white$bb, function(b) lost_day_matrix(draws, X[b, ], b, design, family, grid))
  names(mats) <- white$bb
  for (b in white$bb) {
    keep <- grid <= max_follow[[b]]
    curves[[length(curves) + 1L]] <- cbind(family = family, scenario = b,
      lost_day_summary(mats[[b]][, keep, drop = FALSE], grid[keep]),
      profile_support[[b]][keep, , drop = FALSE])
    if (b != "Energizer") {
      keep2 <- grid <= min(max_follow[[b]], max_follow[["Energizer"]])
      paired_support <- profile_support[[b]][keep2, , drop = FALSE]
      reference_support <- profile_support[["Energizer"]][keep2, , drop = FALSE]
      paired_support$comparison_support <- ifelse(paired_support$support != "within_followup",
        paired_support$support, reference_support$support)
      names(reference_support) <- paste0("reference_", names(reference_support))
      additional[[length(additional) + 1L]] <- cbind(family = family, scenario = b,
        lost_day_summary((mats[[b]] - mats[["Energizer"]])[, keep2, drop = FALSE], grid[keep2]),
        paired_support, reference_support)
    }
  }
  # Exact horizons for validation against the published break-even outputs.
  for (b in setdiff(white$bb, "Energizer")) for (T in c(90, 120)) {
    if (T > max_follow[[b]]) next
    d <- mean(lost_day_matrix(draws, X[b, ], b, design, family, T) -
              lost_day_matrix(draws, X["Energizer", ], "Energizer", design, family, T))
    pub <- support$downtime_gap_mean[support$family == family & support$interval == T &
                                     support$alternative == b] * T
    if (abs(d - pub) > 1e-6) stop("validation failed for ", family, " ", b, " ", T, ": ", d, " vs ", pub)
  }
}
curves <- do.call(rbind, curves); additional <- do.call(rbind, additional)
write.csv(curves, file.path(out, "lost_day_curves.csv"), row.names = FALSE)
write.csv(additional, file.path(out, "additional_lost_day_curves.csv"), row.names = FALSE)

cols <- c(Energizer = "#000000", Varta = "#0072B2", Ansmann = "#009E73",
          Wallaby = "#E69F00", Procell = "#D55E00")
labs <- c(Energizer = "Energizer (CT, summer)", Varta = "Varta (SE, summer)",
          Ansmann = "Ansmann (WT, summer)", Wallaby = "Wallaby (SE, autumn)",
          Procell = "Procell (CT, winter)")
adequate <- function(d) {
  status <- if ("comparison_support" %in% names(d)) d$comparison_support else d$support
  status == "within_followup"
}
band <- function(d, col) {
  ok <- adequate(d)
  for (i in seq_len(nrow(d) - 1L)) {
    j <- c(i, i + 1L)
    polygon(c(d$interval[j], rev(d$interval[j])), c(d$low[j], rev(d$high[j])),
      col = grDevices::adjustcolor(col, if (all(ok[j])) 0.18 else 0.055), border = NA)
  }
}
curve_line <- function(d, col, lwd, lty) {
  ok <- adequate(d)
  segment_ok <- head(ok, -1L) & tail(ok, -1L)
  runs <- cumsum(c(TRUE, diff(segment_ok) != 0))
  for (segment in split(seq_along(segment_ok), runs)) {
    j <- c(segment[1L], segment + 1L)
    lines(d$interval[j], d$mean[j], lwd = lwd, lty = lty,
          col = grDevices::adjustcolor(col, if (segment_ok[segment[1L]]) 1 else 0.35))
  }
}
draw_panel <- function(dat, order, ylab, letter, title, ylim, tolerances = numeric()) {
  plot(NA, xlim = c(30, 210), ylim = ylim, xlab = "Revisit interval (days)", ylab = ylab,
       las = 1, bty = "l", xaxs = "i")
  abline(v = c(90, 120), lty = 3, col = "grey45"); abline(h = 0, col = "grey80")
  # Lost days equal to a fixed share of the interval; crossings give Table 2.
  for (tol in tolerances) {
    abline(a = 0, b = tol, col = "grey60", lwd = 1)
    text(203, 203 * tol, paste0(100 * tol, "%"), pos = 1, offset = 0.35, col = "grey40", cex = 0.8)
  }
  for (b in order) {
    w <- dat[dat$family == "weibull" & dat$scenario == b, ]
    l <- dat[dat$family == "loglogistic" & dat$scenario == b, ]
    band(w, cols[[b]])
    curve_line(w, cols[[b]], lwd = 2.4, lty = 1)
    curve_line(l, cols[[b]], lwd = 1.2, lty = 2)
    points(tail(w$interval, 1), tail(w$mean, 1), pch = 21, bg = "white", col = cols[[b]], cex = 1.1)
  }
  mtext(paste0(letter, "  ", title), side = 3, adj = 0, line = 0.6, font = 2, cex = 1.05)
}
render <- function(device, file, ...) {
  device(file, ...)
  op <- par(mfrow = c(1, 2), mar = c(4.4, 4.6, 2.6, 0.8), oma = c(4.2, 0, 0, 0), cex = 0.95)
  ymax <- max(curves$high[curves$interval <= 170], additional$high) * 1.04
  draw_panel(curves, c("Energizer", "Varta", "Ansmann", "Wallaby", "Procell"),
             "Expected lost camera-days per cycle", "a", "Lost observation time", c(0, ymax),
             tolerances = c(0.05, 0.10))
  draw_panel(additional, c("Varta", "Ansmann", "Wallaby", "Procell"),
             "Additional lost camera-days vs Energizer", "b", "Additional loss by scenario", c(0, ymax))
  par(fig = c(0, 1, 0, 1), oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
  plot(0, 0, type = "n", bty = "n", xaxt = "n", yaxt = "n")
  legend("bottom", legend = labs, col = cols[names(labs)], lwd = 2.4, ncol = 3, bty = "n", cex = 0.85)
  legend("bottom", inset = c(0, 0.075), legend = c("Weibull camera model (95% band)", "Loglogistic camera model",
         "Loss of 5% or 10% of the interval (panel a)", "End of observed scenario follow-up",
         "Faded: fewer than 20 intervals or 10 cameras at risk"),
         lty = c(1, 2, 1, NA, 1), pch = c(NA, NA, NA, 21, NA), lwd = c(2.4, 1.2, 1, NA, 2.4),
         col = c("grey25", "grey25", "grey60", "grey25", "grey75"), ncol = 2, bty = "n", cex = 0.75)
  par(op); dev.off()
}
# Main-text figure: one panel, the Weibull camera model only, so the threshold
# shape and the tolerance crossings carry the display. The two-panel version
# with both families and paired differences is the supplementary figure.
cells <- c(Energizer = "Central, summer", Varta = "South East, summer",
           Ansmann = "West, summer", Wallaby = "South East, autumn",
           Procell = "Central, winter")
render_main <- function(device, file, ...) {
  device(file, ...)
  op <- par(mar = c(4.2, 4.6, 0.8, 0.8), cex = 0.95)
  plot(NA, xlim = c(30, 210), ylim = c(0, 55), xlab = "Revisit interval (days)",
       ylab = "Expected lost camera-days between visits", las = 1, bty = "l", xaxs = "i")
  abline(v = c(90, 120), lty = 3, col = "grey45"); abline(h = 0, col = "grey80")
  for (tol in c(0.05, 0.10)) {
    abline(a = 0, b = tol, col = "grey60", lwd = 1)
    text(203, 203 * tol, paste0(100 * tol, "%"), pos = 1, offset = 0.35, col = "grey40", cex = 0.8)
  }
  order <- c("Energizer", "Varta", "Ansmann", "Wallaby", "Procell")
  for (b in order) {
    w <- curves[curves$family == "weibull" & curves$scenario == b, ]
    band(w, cols[[b]])
    curve_line(w, cols[[b]], lwd = 2.6, lty = 1)
    points(tail(w$interval, 1), tail(w$mean, 1), pch = 21, bg = "white", col = cols[[b]], cex = 1.1)
  }
  legend("topleft", inset = c(0.01, 0), legend = c(paste0(order, " (", cells[order], ")"),
         "Loss of 5% or 10% of the interval", "End of observed follow-up", "Faded: thin support"),
         col = c(cols[order], "grey60", "grey25", "grey75"), lwd = c(rep(2.6, 5), 1, NA, 2.6),
         pch = c(rep(NA, 6), 21, NA), bty = "o", bg = "white", box.col = NA, cex = 0.78,
         y.intersp = 1.15)
  par(op); dev.off()
}
render_main(grDevices::png, file.path(out, "lost_day_curves.png"), width = 1950, height = 1380, res = 300)
render_main(grDevices::pdf, file.path(out, "lost_day_curves.pdf"), width = 6.5, height = 4.6)
render(grDevices::png, file.path(out, "lost_day_curves_detail.png"), width = 2700, height = 1380, res = 300)
render(grDevices::pdf, file.path(out, "lost_day_curves_detail.pdf"), width = 9, height = 4.6)
hashes <- tools::md5sum(c(file.path(input, "design.rds"), file.path(input, "cohorts.rds"),
                          file.path(input, "models", c("weibull_camera", "loglogistic_camera"), "fit.rds"),
                          profiles_path, support_path, "R/lost_day_curves.R",
                          "R/profile_support.R", "R/management_policy.R", "R/sensitivity_camera_predict.R",
                          "R/sensitivity_camera_fit.R", "scripts/plot_lost_day_curves.R"))
write.csv(data.frame(file = names(hashes), md5 = unname(hashes)), file.path(out, "input_md5.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out, "session.txt"))
cat("curves written; 90/120-day values match published break-even outputs\n")
