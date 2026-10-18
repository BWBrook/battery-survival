# Translate the saved paired-draw downtime gaps to camera-days.  This is a
# linear transformation of the archived summaries, with no model refitting.
editorial_lost_camera_days <- function(estimates) {
  required <- c(
    "family", "interval", "alternative", "alternative_ft", "alternative_reg",
    "alternative_seas", "reference", "reference_ft", "reference_reg",
    "reference_seas", "downtime_gap_mean", "downtime_gap_low", "downtime_gap_high",
    "alternative_support", "reference_support", "alternative_profile_max_followup",
    "reference_profile_max_followup", "alternative_profile_intervals_at_risk",
    "reference_profile_intervals_at_risk", "alternative_profile_workload_supported",
    "reference_profile_workload_supported"
  )
  missing <- setdiff(required, names(estimates))
  if (length(missing)) stop("Missing saved-estimate columns: ", paste(missing, collapse = ", "))
  x <- estimates[estimates$alternative_ft == "w" & estimates$reference_ft == "w" &
                   estimates$reference == "Energizer" & estimates$interval %in% c(90, 120) &
                   estimates$family %in% c("weibull", "loglogistic"), required]
  if (!nrow(x)) stop("No white-flash 90/120-day Energizer comparisons found")
  if (anyDuplicated(x[c("family", "interval", "alternative")])) {
    stop("Duplicate family/interval/alternative comparison")
  }
  numeric_columns <- c("interval", "downtime_gap_mean", "downtime_gap_low", "downtime_gap_high",
                       "alternative_profile_max_followup", "reference_profile_max_followup")
  if (any(!is.finite(as.matrix(x[numeric_columns])))) stop("Non-finite saved estimates")
  if (any(x$downtime_gap_low > x$downtime_gap_high)) stop("Reversed paired interval")
  supported_status <- c("within_followup", "thin")
  x$plotted <- x$alternative_support %in% supported_status &
    x$reference_support %in% supported_status &
    x$alternative_profile_workload_supported %in% TRUE &
    x$reference_profile_workload_supported %in% TRUE &
    x$interval <= x$alternative_profile_max_followup &
    x$interval <= x$reference_profile_max_followup
  x$lost_days_mean <- ifelse(x$plotted, x$interval * x$downtime_gap_mean, NA_real_)
  x$lost_days_low <- ifelse(x$plotted, x$interval * x$downtime_gap_low, NA_real_)
  x$lost_days_high <- ifelse(x$plotted, x$interval * x$downtime_gap_high, NA_real_)
  x$display_status <- ifelse(x$plotted, "shown", "withheld: outside profile support")
  x <- x[order(x$interval, x$alternative, match(x$family, c("weibull", "loglogistic"))), ]
  rownames(x) <- NULL
  x[, setdiff(names(x), c("downtime_gap_mean", "downtime_gap_low", "downtime_gap_high"))]
}

plot_editorial_lost_camera_days <- function(x) {
  brands <- sort(unique(x$alternative))
  families <- c("weibull", "loglogistic")
  family_labels <- c("Weibull", "Log-logistic")
  colors <- c("#0072B2", "#D55E00")
  shapes <- c(16, 15)
  reference <- unique(x[c("reference", "reference_reg", "reference_seas")])
  if (nrow(reference) != 1L) stop("The figure requires one reference scenario")
  labels <- vapply(brands, function(brand) {
    profile <- unique(x[x$alternative == brand, c("alternative_reg", "alternative_seas")])
    if (nrow(profile) != 1L) stop("The figure requires one scenario per alternative")
    paste0(brand, "\n", toupper(profile$alternative_reg), ", ", profile$alternative_seas)
  }, character(1))
  limits <- range(c(0, x$lost_days_low, x$lost_days_high), na.rm = TRUE)
  ticks <- pretty(limits, n = 4)
  limits <- range(ticks)
  old <- par(no.readonly = TRUE)
  on.exit(par(old))
  par(oma = c(5.1, 0.2, 4.2, 0.3), mgp = c(2, .6, 0),
      family = "sans", las = 1, xaxs = "i", yaxs = "i")
  # Allow more space for the left labels while keeping both data panels the
  # same physical width, so a camera-day has the same length in each panel.
  panel_width <- par("din")[1] - sum(par("omi")[c(2, 4)])
  margin_difference <- (7.3 - .9) * par("csi") * par("mex")
  layout(matrix(c(1, 2), nrow = 1),
         widths = c(panel_width + margin_difference, panel_width - margin_difference))
  for (i in seq_along(c(90, 120))) {
    horizon <- c(90, 120)[i]
    par(mar = c(2.6, if (i == 1L) 7.3 else 0.9, 2.5, .8))
    plot.new()
    plot.window(xlim = limits, ylim = c(.45, length(brands) + .55))
    abline(v = ticks, col = "grey91", lwd = .7)
    abline(v = 0, col = "grey60", lwd = .9)
    axis(1, at = ticks, cex.axis = .9, col = "grey60", col.ticks = "grey60")
    if (i == 1L) axis(2, at = rev(seq_along(brands)), labels = labels,
                      tick = FALSE, cex.axis = .85, line = .2)
    title(main = paste0(letters[i], "  ", horizon, "-day revisit"),
          adj = 0, line = 1, cex.main = 1.08)
    for (j in seq_along(brands)) {
      y <- length(brands) - j + 1
      d <- x[x$interval == horizon & x$alternative == brands[j], ]
      if (!any(d$plotted)) {
        rect(limits[1], y - .38, limits[2], y + .38, col = "grey96", border = NA)
        max_followup <- min(d$alternative_profile_max_followup,
                            d$reference_profile_max_followup)
        note <- if (horizon > max_followup) {
          paste0("Withheld: joint-cell follow-up\nends at ", max_followup, " days")
        } else "Withheld: outside profile support"
        text(mean(limits), y, note, cex = .77, col = "grey35")
      }
      for (k in seq_along(families)) {
        z <- d[d$family == families[k] & d$plotted, ]
        if (!nrow(z)) next
        yy <- y + c(.13, -.13)[k]
        segments(z$lost_days_low, yy, z$lost_days_high, yy, col = colors[k], lwd = 1.8)
        segments(c(z$lost_days_low, z$lost_days_high), yy - .045,
                 c(z$lost_days_low, z$lost_days_high), yy + .045,
                 col = colors[k], lwd = 1.2)
        points(z$lost_days_mean, yy, pch = shapes[k], col = colors[k], cex = .9)
      }
    }
  }
  mtext("Additional expected lost camera-days", side = 3, outer = TRUE,
        line = 2.5, adj = 0, cex = 1.18, font = 2)
  mtext(paste0("White-flash scenarios relative to Energizer (",
               toupper(reference$reference_reg), ", ", reference$reference_seas, ")"),
        side = 3, outer = TRUE, line = 1.15, adj = 0, cex = .87)
  mtext("Additional expected lost camera-days per deployment", side = 1,
        outer = TRUE, line = .15, cex = .9)
  par(fig = c(0, 1, .07, .13), mar = rep(0, 4), oma = rep(0, 4), new = TRUE)
  plot.new()
  legend("center", family_labels, col = colors, pch = shapes, lwd = 1.8,
         horiz = TRUE, bty = "n", cex = .88, x.intersp = .7)
  mtext("Points: posterior means; bars: paired-draw 95% intervals.",
        side = 1, line = -0.1, cex = .73)
  mtext("Modelled under the last-image endpoint convention; scenario inputs differ in region, season and workload.",
        side = 1, line = .95, cex = .73)
  invisible(x)
}

write_editorial_lost_camera_days <- function(input, out) {
  assert_derived_output_destination(dirname(input), out,
                                   protected = c("outputs/sensitivity",
                                                 "outputs/management/2026-09-17",
                                                 "outputs/management/2026-09-18",
                                                 "outputs/management/2026-09-19"))
  sha256 <- function(paths) {
    hashes <- system2("sha256sum", shQuote(paths), stdout = TRUE)
    if (length(hashes) != length(paths) || !is.null(attr(hashes, "status"))) {
      stop("Cannot record SHA-256 provenance")
    }
    hashes
  }
  original_hash <- sha256(input)
  x <- editorial_lost_camera_days(read.csv(input, stringsAsFactors = FALSE))
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  csv <- file.path(out, "additional_lost_camera_days.csv")
  write.csv(x, csv, row.names = FALSE, na = "")
  stem <- file.path(out, "additional_lost_camera_days")
  grDevices::cairo_pdf(paste0(stem, ".pdf"), width = 8.4, height = 5.4,
                      pointsize = 11, family = "sans")
  plot_editorial_lost_camera_days(x)
  dev.off()
  png(paste0(stem, ".png"), width = 2520, height = 1620, res = 300,
      pointsize = 11, type = "cairo", bg = "white")
  plot_editorial_lost_camera_days(x)
  dev.off()
  if (!identical(original_hash, sha256(input))) stop("Source changed during generation")
  source_files <- c(input, "R/editorial_lost_camera_days.R", "R/derived_output_guard.R",
                    "scripts/plot_editorial_lost_camera_days.R")
  writeLines(sha256(source_files), file.path(out, "source-sha256.txt"))
  writeLines(c(
    "# Additional expected lost camera-days: figure provenance", "",
    paste("Generated:", format(Sys.time(), tz = "Australia/Hobart", usetz = TRUE)),
    paste("Source:", input),
    "Source and rendering-code SHA-256 hashes: source-sha256.txt.", "",
    "For each supported row, mean = interval * downtime_gap_mean,",
    "lower = interval * downtime_gap_low, upper = interval * downtime_gap_high.",
    "The saved gaps already use paired posterior draws. Multiplication by the",
    "positive interval preserves their 2.5% and 97.5% quantiles. No draws are read",
    "and no fit is run. The figure retains the two AFT families separately.", "",
    "Intervals describe posterior parameter uncertainty in expected lost camera-days,",
    "not predictive variation in losses among individual cameras.", "",
    "Only supported white-flash comparisons to Energizer at 90/120 days are shown.",
    "Both profiles must have supported workloads and within_followup or thin status,",
    "and the interval must not exceed either joint-cell maximum follow-up.",
    "The 120-day Procell comparison is withheld: its joint-cell maximum is 117 days.",
    "Withheld rows have blank derived quantities in the CSV.", "",
    "These are modelled scenario contrasts under the last-image endpoint convention,",
    "not measurements of inactivity or causal brand effects. Scenario inputs differ",
    "in region, season and retrospective workload. Region labels retain source codes.",
    "Blue circles denote Weibull; orange squares denote log-logistic. Both panels",
    "share an axis, and all plotted interval limits are retained.", "",
    paste("Supported rows plotted:", sum(x$plotted)),
    paste("Rows withheld:", sum(!x$plotted)),
    "",
    "Reproduce from the repository root:",
    paste("Rscript --vanilla scripts/plot_editorial_lost_camera_days.R", input, out)
  ), file.path(out, "provenance.md"))
  capture.output(sessionInfo(), file = file.path(out, "session-info.txt"))
  artifacts <- file.path(out, c("additional_lost_camera_days.csv",
                                "additional_lost_camera_days.pdf",
                                "additional_lost_camera_days.png", "provenance.md",
                                "source-sha256.txt", "session-info.txt"))
  writeLines(sha256(artifacts), file.path(out, "artifact-sha256.txt"))
  invisible(x)
}
