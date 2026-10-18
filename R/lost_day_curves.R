# Expected lost camera-days per service cycle as a continuous function of the
# revisit interval, from the saved camera-effect fits. No fitting occurs: the
# same balanced 1,000 posterior draws and new-camera quadrature used for the
# 90- and 120-day break-even values are evaluated on a grid of intervals.

# Base-R equivalent of cam_extract_draws() for saved CmdStan fit objects, so
# the curves can be rebuilt where cmdstanr and posterior are not installed.
lost_day_draws <- function(fit_path, design, n = 1000L) {
  a <- readRDS(fit_path)$.__enclos_env__$private$draws_
  if (is.null(a) || length(dim(a)) != 3L) stop("fit object has no embedded draws_ array", call. = FALSE)
  each <- max(1L, floor(n / dim(a)[2]))
  ix <- unique(round(seq(1, dim(a)[1], length.out = min(each, dim(a)[1]))))
  a <- unclass(a)[ix, , , drop = FALSE]
  take <- function(v) as.numeric(a[, , v])
  pick <- function(names) vapply(names, take, numeric(length(ix) * dim(a)[2]))
  vars <- dimnames(a)[[3]]
  list(alpha = take("alpha"),
       beta = pick(paste0("beta[", seq_along(design$columns), "]")),
       sigma = pick(paste0("sigma[", seq_along(design$brands), "]")),
       tau = if ("tau[1]" %in% vars) take("tau[1]") else rep(0, length(ix) * dim(a)[2]))
}

lost_day_matrix <- function(draws, x_row, brand, design, family, intervals) {
  mu <- draws$alpha + as.numeric(draws$beta %*% x_row)
  sigma <- draws$sigma[, match(brand, design$brands)]
  vapply(intervals, function(T) {
    T * management_loss(T, 1, 1, mu, sigma, draws$tau, family)$downtime
  }, numeric(length(mu)))
}

lost_day_summary <- function(m, intervals) {
  data.frame(interval = intervals,
             mean = colMeans(m),
             low = apply(m, 2, stats::quantile, 0.025, names = FALSE, type = 1),
             high = apply(m, 2, stats::quantile, 0.975, names = FALSE, type = 1))
}

# Longest revisit interval keeping expected downtime fraction below a tolerance,
# per posterior draw: the first grid interval at which D(T) reaches the
# tolerance, linearly interpolated. NA when the tolerance is not reached within
# the evaluated intervals. This is right-censoring at the grid endpoint, not
# an infinite crossing or a draw to discard from uncertainty summaries.
tolerance_interval <- function(lost_days, intervals, tolerance) {
  frac <- sweep(lost_days, 2, intervals, "/")
  apply(frac, 1, function(d) {
    k <- which(d >= tolerance)[1L]
    if (is.na(k)) return(NA_real_)
    if (k == 1L) return(intervals[1L])
    x0 <- intervals[k - 1L]; x1 <- intervals[k]; y0 <- d[k - 1L]; y1 <- d[k]
    x0 + (tolerance - y0) * (x1 - x0) / (y1 - y0)
  })
}

# Preserve right-censored draws in the percentile ranks. An unavailable bound
# is returned as NA with an explicit censoring flag, rather than as infinity.
# The finite values are identified because all censored crossings exceed the
# largest evaluated interval. No extrapolation is needed for those ranks.
tolerance_summary <- function(lost_days, intervals, tolerance) {
  crossings <- tolerance_interval(lost_days, intervals, tolerance)
  censored <- is.na(crossings)
  ranked <- crossings
  ranked[censored] <- Inf
  bounds <- stats::quantile(ranked, c(.025, .975), names = FALSE, type = 1)
  beyond <- is.infinite(bounds)
  bounds[beyond] <- NA_real_
  point <- tolerance_interval(matrix(colMeans(lost_days), nrow = 1),
                              intervals, tolerance)
  data.frame(interval_at_mean_downtime = point,
             draw_low = bounds[1L], draw_high = bounds[2L],
             mean_beyond_followup = is.na(point),
             draw_low_beyond_followup = beyond[1L],
             draw_high_beyond_followup = beyond[2L],
             share_beyond_followup = mean(censored),
             evaluated_followup = max(intervals))
}

# Use the same joint categorical support screen as the fixed-interval results.
# Missing times arise from crossings censored at the evaluated follow-up limit;
# they must not inherit the shared helper's unrelated no-finite-optimum label.
lost_day_support <- function(intervals, profile, train) {
  do.call(rbind, lapply(intervals, function(T) {
    s <- profile_support_summary(T, profile, train)
    data.frame(profile_intervals_at_risk = if (is.finite(T)) nrow(s$profile_risk) else NA_integer_,
               profile_cameras_at_risk = if (is.finite(T)) length(unique(s$profile_risk$camera)) else NA_integer_,
               profile_max_followup = s$profile_max_followup,
               profile_workload_supported = s$workload_supported,
               support = if (is.finite(T)) s$support else "beyond_evaluated_followup")
  }))
}
