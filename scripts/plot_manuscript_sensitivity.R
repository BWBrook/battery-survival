#!/usr/bin/env Rscript
# Publication-sized displays from the archived sensitivity tables; no fitting.
input <- "outputs/sensitivity/2026-09-17/tables"
out <- "outputs/publication/figures"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
cols <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7")

# Brand KM display.  This is generated from the archived training cohort,
# rather than from the older baseline PNG.  All KM steps are retained; once a
# brand has fewer than ten intervals at risk, its tail is drawn in grey to
# signal sparse support without hiding the evidence.
cohorts <- readRDS("outputs/sensitivity/2026-09-17/cohorts.rds")
train <- as.data.frame(cohorts$train)
# Brands in order of recorded endurance, with the same colours as main Fig. 2.
brands <- c("Energizer", "Varta", "Ansmann", "Wallaby", "Procell")
stopifnot(setequal(brands, unique(as.character(train$bb))))
brand_cols <- c(Energizer = "#000000", Varta = "#0072B2", Ansmann = "#009E73",
                Wallaby = "#E69F00", Procell = "#D55E00")
risk_times <- c(0, 90, 120, 180, 270, 360)
km_xlim <- c(-12, 380)
png(file.path(out, "km_by_brand.png"), width = 2300, height = 2300, res = 300, pointsize = 12)
layout(matrix(c(1, 2), nrow = 2), heights = c(4.8, 1.45))
par(mar = c(3.6, 5.6, 1, 1), mgp = c(2.4, .7, 0))
plot(NA, xlim = km_xlim, ylim = c(0, 1), xlab = "", ylab = "Recorded survival",
     xaxs = "i", las = 1)
abline(v = c(90, 120), lty = 3, col = "grey65")
for (brand in brands) {
  d <- train[as.character(train$bb) == brand, , drop = FALSE]
  fit <- survival::survfit(survival::Surv(rd, event) ~ 1, data = d)
  # First post-event risk set below ten. The grey full curve is drawn first,
  # then the supported segment is overlaid in the brand colour.
  lines(c(0, fit$time), c(1, fit$surv), type = "s", col = "grey72", lwd = 2)
  thin <- which(fit$n.risk < 10)[1]
  supported <- if (is.na(thin)) rep(TRUE, length(fit$time)) else seq_along(fit$time) < thin
  lines(c(0, fit$time[supported]), c(1, fit$surv[supported]), type = "s",
        col = brand_cols[[brand]], lwd = 2.3)
}
legend("topright", legend = c(brands, "Grey: n < 10 at risk"),
       col = c(unname(brand_cols[brands]), "grey72"), lwd = 2.3,
       bty = "n", title = "Battery brand", cex = .88)
mtext("Days since deployment", side = 1, line = 2.2, cex = .9)

# A compact at-risk table keeps the thin-tail cue tied to concrete support.
par(mar = c(0.4, 5.6, 0.2, 1), mgp = c(2.4, .7, 0))
plot.new()
plot.window(xlim = km_xlim, ylim = c(.4, length(brands) + 1.6), xaxs = "i", yaxs = "i")
par(xpd = NA)
text(km_xlim[1], length(brands) + 1.35, "Number at risk", adj = 0, cex = .78, font = 2)
axis(2, at = c(rev(seq_along(brands)), length(brands) + .8), labels = c(brands, "Day"),
     las = 1, tick = FALSE, cex.axis = .72, line = -0.4)
text(risk_times, length(brands) + .8, labels = risk_times, cex = .75, col = "grey25")
for (i in seq_along(brands)) {
  brand <- brands[[i]]
  d <- train[as.character(train$bb) == brand, , drop = FALSE]
  n_risk <- vapply(risk_times, function(t) sum(d$rd >= t), numeric(1))
  text(risk_times, length(brands) - i + 1, labels = n_risk, cex = .72,
       col = ifelse(n_risk < 10, "grey55", "black"))
}
dev.off()

# Held-region predictions from the saved six-model check. The grey envelope
# is variation across model specifications, not a confidence interval.
sw <- read.csv(file.path(input, "aft_sw_calibration.csv"))
sw_original <- sw[sw$model_id == "weibull__common__noregion", ]
sw_original <- sw_original[order(sw_original$horizon_days), ]
sw_times <- sort(unique(sw$horizon_days))
stopifnot(length(unique(sw$model_id)) == 6L,
          all(sw$bb == "Varta"), all(sw$ft == "w"),
          all(sw$n_obs_rows == 183L),
          all(vapply(split(sw, sw$horizon_days), function(d) {
            length(unique(d$observed_survival)) == 1L &&
              length(unique(d$km_low)) == 1L &&
              length(unique(d$km_high)) == 1L && nrow(d) == 6L
          }, logical(1))))
sw_min <- vapply(sw_times, function(t) min(sw$predicted_survival[sw$horizon_days == t]), numeric(1))
sw_max <- vapply(sw_times, function(t) max(sw$predicted_survival[sw$horizon_days == t]), numeric(1))
png(file.path(out, "sw_transfer.png"), width = 2300, height = 1900, res = 300, pointsize = 12)
par(mar = c(5.5, 4.5, 1, 1), mgp = c(2.5, .7, 0))
plot(NA, xlim = range(sw_times), ylim = c(0, 1),
     xlab = "Days since deployment", ylab = "Recorded survival", xaxt = "n", las = 1)
polygon(c(sw_times, rev(sw_times)), c(sw_min, rev(sw_max)),
        col = "grey86", border = NA)
for (id in unique(sw$model_id)) {
  g <- sw[sw$model_id == id, ]; g <- g[order(g$horizon_days), ]
  lines(g$horizon_days, g$predicted_survival, col = "grey65", lwd = 1)
}
with(sw_original, {
  lines(horizon_days, predicted_survival, col = "#0072B2", lwd = 2.3, lty = 2)
  arrows(horizon_days, km_low, horizon_days, km_high,
         length = .035, angle = 90, code = 3, col = "black")
  lines(horizon_days, observed_survival, col = "black", lwd = 2)
  points(horizon_days, observed_survival, col = "black", pch = 16, cex = .8)
})
axis(1, at = sw_times)
legend("bottomleft", inset = .025,
       legend = c("Observed KM (95% pointwise intervals)",
                  "Original Weibull specification", "Range of six no-region models"),
       col = c("black", "#0072B2", "grey65"), lty = c(1, 2, 1),
       lwd = c(2, 2.3, 7), pch = c(16, NA, NA), bty = "n", cex = .78)
mtext(paste("Intervals at risk:", paste(sw_original$n_at_risk, collapse = " / ")),
      side = 1, line = 4.1, cex = .8)
dev.off()

cal <- read.csv(file.path(input, "aft_calibration_bb.csv"))
ids <- c("weibull__common__noregion", "weibull__brand__region", "loglogistic__brand__region")
png(file.path(out, "aft_calibration.png"), width = 2100, height = 2400, res = 300, pointsize = 12)
par(mfrow = c(3, 2), mar = c(3.5, 3.8, 3, .5), oma = c(.4, 0, 0, 0), mgp = c(2.3, .7, 0))
for (brand in unique(cal$bb)) {
  g <- cal[cal$bb == brand, ]
  obs <- g[g$model_id == ids[1], ]
  plot(NA, xlim = c(85, 275), ylim = c(0, 1), xlab = "Days", ylab = "Survival", main = "")
  title(main = brand, line = 1.5)
  for (k in seq_along(ids)) {
    x <- g[g$model_id == ids[k], ]
    lines(x$horizon_days, x$predicted_survival, col = cols[k], lwd = 2, lty = k)
  }
  thin <- obs$n_at_risk < 10
  obs_col <- ifelse(thin, "grey70", "black")
  with(obs, arrows(horizon_days, km_low, horizon_days, km_high, length = .025, angle = 90, code = 3,
                   col = obs_col))
  points(obs$horizon_days, obs$observed_survival, pch = 16, cex = ifelse(thin, .62, .7), col = obs_col)
  mtext(paste("At risk:", paste(obs$n_at_risk, collapse = "/")), side = 3, line = .15, cex = .7)
}
plot.new()
legend("center", c("KM, n at risk ≥ 10", "KM, n at risk < 10", "Original Weibull", "Weibull: brand scale + region", "Loglogistic: brand scale + region"),
       col = c("black", "grey70", cols[1:3]), lty = c(NA, NA, 1, 2, 3), pch = c(16, 16, NA, NA, NA),
       lwd = 2, bty = "n", cex = .85, x.intersp = .65)
dev.off()

dec <- read.csv("outputs/management/2026-09-19/tables/camera_decisions.csv")
ids <- c("weibull_independent", "weibull_camera", "loglogistic_independent", "loglogistic_camera")
png(file.path(out, "camera_decisions.png"), width = 2100, height = 2850, res = 300, pointsize = 12)
par(mfrow = c(4, 2), mar = c(2.8, 3.8, 2, .5), oma = c(4.5, 0, 0, 0), mgp = c(2.3, .6, 0))
profiles <- unique(dec[c("bb", "ft")])
for (j in seq_len(nrow(profiles))) {
  brand <- profiles$bb[j]; flash <- profiles$ft[j]
  g <- dec[dec$bb == brand & dec$ft == flash, ]
  plot(NA, xlim = c(15, 205), ylim = c(50, 350), xlab = "", ylab = "Interval (days)",
       main = paste(brand, if (flash == "w") "white flash" else "infrared"))
  if (g$profile_max_followup[1] < 350) rect(15, g$profile_max_followup[1], 205, 350, col = "grey93", border = NA)
  abline(h = g$profile_max_followup[1], lty = 3, col = "grey40")
  for (k in seq_along(ids)) {
    x <- g[g$model_id == ids[k], ]; keep <- is.finite(x$median) & x$median <= 350
    xx <- x$r + (k - 2.5) * 1.5
    lines(xx[keep], x$median[keep], col = cols[k], lty = if (k %% 2) 2 else 1, lwd = 1.5)
    points(xx[keep], x$median[keep], col = cols[k], pch = ifelse(
      x$profile_probability_thin_support_given_finite[keep] > .5, 1, 16), cex = .75)
    arrows(xx[keep], pmax(50, x$low[keep]), xx[keep], pmin(350, x$high[keep]),
           length = .025, angle = 90, code = 3, col = cols[k])
  }
}
mtext(expression(K/c[d]~"(camera-days; common-ratio diagnostic)"), side = 1, outer = TRUE, line = .1)
par(fig = c(0, 1, 0, .055), oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
plot.new()
legend("center", c("Weibull: independent", "Weibull: camera", "Loglogistic: independent", "Loglogistic: camera"),
       col = cols, lty = c(2, 1, 2, 1), pch = 16, bty = "n", ncol = 2, cex = .9)
dev.off()

# Readable labels from the saved camera-cluster robust Cox estimates.
cox <- read.csv("outputs/management/2026-09-18/field_effects/cox_effects_saved_robust_ci.csv")
labels <- c(bbEnergizer = "Energizer vs Ansmann", bbProcell = "Procell vs Ansmann",
            bbVarta = "Varta vs Ansmann", bbWallaby = "Wallaby vs Ansmann",
            ftw = "White flash vs infrared", seasspring = "Spring vs autumn",
            seassummer = "Summer vs autumn", seaswinter = "Winter vs autumn",
            log_fi_pd = "Flash workload", log_day_pd = "Daylight workload")
stopifnot(all(cox$term %in% names(labels)))
png(file.path(out, "cox_hazard_ratios.png"), width = 2300, height = 1900, res = 300, pointsize = 12)
par(mar = c(4.8, 12.5, 2, 1), mgp = c(2.5, .7, 0))
y <- rev(seq_len(nrow(cox)))
plot(cox$hr, y, log = "x", xlim = c(.15, 11), ylim = c(.5, nrow(cox) + .5),
     axes = FALSE, xlab = "Hazard ratio (95% robust confidence interval)", ylab = "", pch = 16)
axis(1, at = c(.2, .5, 1, 2, 5, 10), labels = c("0.2", "0.5", "1", "2", "5", "10"))
axis(2, at = y, labels = unname(labels[cox$term]), las = 1, tick = FALSE, cex.axis = .85)
abline(v = 1, lty = 2, col = "grey50")
segments(cox$hr_low, y, cox$hr_high, y, lwd = 2, col = "#0072B2")
points(cox$hr, y, pch = 16, col = "#0072B2")
mtext("Workload effects: per unit of log(1 + images per recorded day)", side = 1, line = 3.5, cex = .78)
dev.off()
