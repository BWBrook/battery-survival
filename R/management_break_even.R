# Fixed-interval break-even comparisons from paired posterior draws.
#
# At a common replacement interval T, common servicing costs cancel.  If the
# alternative battery set costs less than the reference set, its expected loss
# equals the reference when
#
#   lost_day_value = (C_reference - C_alternative) /
#                    {T (D_alternative - D_reference)}.
#
# Draws are paired by posterior draw number.  A non-positive downtime gap means
# that the cheaper alternative is no worse on either component, so its crossing
# value is +Inf rather than a discarded or conditionally summarised draw.

management_break_even <- function(T, alternative_cost, reference_cost,
                                  alternative_downtime, reference_downtime) {
  stopifnot(length(T) == 1L, is.finite(T), T > 0,
            length(alternative_cost) == 1L, is.finite(alternative_cost),
            length(reference_cost) == 1L, is.finite(reference_cost),
            reference_cost > alternative_cost)
  d <- cam_recycle(as.numeric(alternative_downtime),
                   as.numeric(reference_downtime))
  alternative_downtime <- d[[1L]]
  reference_downtime <- d[[2L]]
  if (any(!is.finite(alternative_downtime)) ||
      any(!is.finite(reference_downtime)) ||
      any(alternative_downtime < 0 | alternative_downtime > 1) ||
      any(reference_downtime < 0 | reference_downtime > 1)) {
    stop("downtime draws must be finite probabilities", call. = FALSE)
  }

  saving <- reference_cost - alternative_cost
  gap <- alternative_downtime - reference_downtime
  crossing <- rep(Inf, length(gap))
  crossing[gap > 0] <- saving / (T * gap[gap > 0])
  q <- stats::quantile(crossing, c(.025, .5, .975),
                       names = FALSE, type = 1)
  mean_gap <- mean(gap)

  list(
    battery_cost_saving = saving,
    downtime_gap = gap,
    downtime_gap_mean = mean_gap,
    downtime_gap_low = stats::quantile(gap, .025, names = FALSE, type = 1),
    downtime_gap_high = stats::quantile(gap, .975, names = FALSE, type = 1),
    break_even = if (mean_gap > 0) saving / (T * mean_gap) else Inf,
    break_even_draws = crossing,
    break_even_low = q[1L],
    break_even_median = q[2L],
    break_even_high = q[3L],
    probability_positive_gap = mean(gap > 0),
    probability_no_finite_crossing = mean(gap <= 0)
  )
}

management_profile_support <- function(T, profile, train) {
  required <- c("bb", "ft", "reg", "seas", "rd", "camera", "event")
  missing <- setdiff(required, names(train))
  if (length(missing)) {
    stop("support data missing required columns: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  x <- profile_support_summary(T, profile, train)
  event_count <- function(d) sum(d$event, na.rm = TRUE)
  camera_count <- function(d) length(unique(d$camera))
  data.frame(
    # Legacy unprefixed fields remain regional for existing readers.
    intervals = nrow(x$regional),
    events = event_count(x$regional),
    cameras = camera_count(x$regional),
    intervals_at_risk = nrow(x$regional_risk),
    cameras_at_risk = camera_count(x$regional_risk),
    max_followup = x$region_max_followup,
    region_intervals = nrow(x$regional),
    region_events = event_count(x$regional),
    region_cameras = camera_count(x$regional),
    region_intervals_at_risk = nrow(x$regional_risk),
    region_cameras_at_risk = camera_count(x$regional_risk),
    region_max_followup = x$region_max_followup,
    profile_intervals = nrow(x$profile),
    profile_events = event_count(x$profile),
    profile_cameras = camera_count(x$profile),
    profile_intervals_at_risk = nrow(x$profile_risk),
    profile_cameras_at_risk = camera_count(x$profile_risk),
    profile_max_followup = x$profile_max_followup,
    profile_workload_supported = x$workload_supported,
    pooled_intervals = nrow(x$pooled),
    pooled_events = event_count(x$pooled),
    pooled_cameras = camera_count(x$pooled),
    pooled_intervals_at_risk = nrow(x$pooled_risk),
    pooled_cameras_at_risk = camera_count(x$pooled_risk),
    pooled_max_followup = x$pooled_max_followup,
    support = x$support
  )
}
