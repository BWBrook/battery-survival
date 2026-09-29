#!/usr/bin/env Rscript
# Standalone scientific figures from the saved SA tables; no model refitting.
cfg <- yaml::read_yaml("config/sensitivity.yml")
root <- cfg$output_dir
read_table <- function(name) read.csv(file.path(root, "tables", paste0(name, ".csv")))
palette <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7")
start_plot <- function(name, width = 1700, height = 1050) {
  png(file.path(root, "figures", paste0(name, ".png")), width, height, res = 160)
}

cal <- read_table("aft_calibration_bb")
ids <- c("weibull__common__noregion", "weibull__brand__region", "loglogistic__brand__region")
start_plot("aft_calibration")
par(mfrow = c(2, 3), mar = c(4, 4, 3, 1), oma = c(3, 0, 2, 0))
for (brand in unique(cal$bb)) {
  g <- cal[cal$bb == brand, ]
  obs <- g[g$model_id == ids[1], ]
  plot(NA, xlim = c(85, 275), ylim = c(0, 1), xlab = "Days", ylab = "Survival", main = brand)
  for (k in seq_along(ids)) {
    x <- g[g$model_id == ids[k], ]
    lines(x$horizon_days, x$predicted_survival, col = palette[k], lwd = 2)
  }
  with(obs, arrows(horizon_days, km_low, horizon_days, km_high, length = .03, angle = 90, code = 3, col = "grey40"))
  points(obs$horizon_days, obs$observed_survival, pch = 16, cex = .8)
  mtext(paste("At risk:", paste(obs$n_at_risk, collapse = " / ")), side = 3, line = .15, cex = .64)
}
plot.new()
legend("center", c("KM and pointwise 95% intervals", "Original Weibull", "Weibull: brand scale + region",
                   "Loglogistic: brand scale + region"), col = c("black", palette[1:3]),
       lty = c(NA, 1, 1, 1), pch = c(16, NA, NA, NA), lwd = 2, bty = "n", cex = .8)
mtext("Training calibration: predictions averaged over the same brand's covariates", outer = TRUE, side = 3, cex = 1.1)
mtext("Risk counts correspond to 90, 120, 150, 180, 210, 240 and 270 days. KM intervals do not adjust for recurring cameras.",
      outer = TRUE, side = 1, cex = .75)
dev.off()

if (file.exists(file.path(root, "tables", "camera_decisions.csv"))) {
  dec <- read_table("camera_decisions")
  ids <- c("weibull_independent", "weibull_camera", "loglogistic_independent", "loglogistic_camera")
  start_plot("camera_decisions", height = 1550)
  par(mfrow = c(3, 3), mar = c(4, 4, 3, 1), oma = c(4, 0, 2, 0))
  profiles <- unique(dec[c("bb", "ft")])
  for (j in seq_len(nrow(profiles))) {
    brand <- profiles$bb[j]
    flash <- profiles$ft[j]
    g <- dec[dec$bb == brand & dec$ft == flash, ]
    if (!nrow(g)) next
    plot(NA, xlim = c(15, 205), ylim = c(50, 350), xlab = expression(K/c[d]~"(camera-days)"),
         ylab = "Illustrative interval (days)", main = paste(brand, if (flash == "w") "white flash" else "infrared"))
    if (g$max_followup[1] < 350) rect(15, g$max_followup[1], 205, 350, col = "grey93", border = NA)
    abline(h = g$max_followup[1], lty = 3, col = "grey40")
    for (k in seq_along(ids)) {
      x <- g[g$model_id == ids[k], ]
      finite <- is.finite(x$median) & x$median <= 350
      xx <- x$r + (k - 2.5) * 1.5
      lines(xx[finite], x$median[finite], col = palette[k], lty = if (k %% 2) 2 else 1)
      # Open circles warn of >50% probability of thin regional support, conditional on finite roots.
      points(xx[finite], x$median[finite], col = palette[k], pch = ifelse(
        x$region_probability_thin_support_given_finite[finite] > .5, 1, 16))
      arrows(xx[finite], pmax(50, x$low[finite]), xx[finite], pmin(350, x$high[finite]),
             length = .025, angle = 90, code = 3, col = palette[k])
    }
  }
  plot.new()
  legend("center", c("Weibull: independent rows", "Weibull: camera effect", "Loglogistic: independent rows",
                      "Loglogistic: camera effect", "Beyond maximum follow-up (grey)", "Thin regional support (open point)"),
         col = c(palette, "grey40", "black"), lty = c(2, 1, 2, 1, 3, NA),
         pch = c(16, 16, 16, 16, NA, 1), bty = "n", cex = .8)
  mtext("Camera dependence and illustrative servicing intervals", outer = TRUE, side = 3, cex = 1.1)
  mtext("Medians and 95% credible intervals; new-camera effects integrated out. All models include brand-specific scale and region.",
        outer = TRUE, side = 1, line = .7, cex = .72)
  mtext("Points above 350 days or with no finite median optimum are omitted; intervals clipped to plot. Full classifications and regional support are in the tables.",
        outer = TRUE, side = 1, line = 2, cex = .68)
  dev.off()
}
