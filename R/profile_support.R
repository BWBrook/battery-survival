# Shared support helpers for the operating profiles used in management outputs.
# A profile is a joint brand/flash/region/season scenario. Continuous workload
# values are considered supported when they fall within the observed ranges in
# that categorical cell; prediction profiles constructed by
# build_prediction_profiles() use an actually observed workload pair.

profile_support_keys <- function() c("bb", "ft", "reg", "seas")

profile_support_subset <- function(dat, profile, keys = profile_support_keys()) {
  missing_data <- setdiff(keys, names(dat))
  missing_profile <- setdiff(keys, names(profile))
  if (length(missing_data) || length(missing_profile)) {
    missing <- unique(c(missing_data, missing_profile))
    stop("profile support missing required columns: ",
         paste(missing, collapse = ", "), call. = FALSE)
  }
  keep <- rep(TRUE, nrow(dat))
  for (key in keys) {
    keep <- keep & as.character(dat[[key]]) == as.character(profile[[key]][[1L]])
  }
  dat[keep, , drop = FALSE]
}

profile_workload_support <- function(dat, profile) {
  workload <- c("log_fi_pd", "log_day_pd")
  if (!all(workload %in% names(dat)) || !all(workload %in% names(profile)) ||
      nrow(dat) == 0L) {
    return(NA)
  }
  values <- vapply(workload, function(x) as.numeric(profile[[x]][[1L]]), numeric(1))
  if (any(!is.finite(values))) return(FALSE)
  ranges <- lapply(workload, function(x) range(dat[[x]], na.rm = TRUE))
  if (any(!vapply(ranges, function(x) length(x) == 2L && all(is.finite(x)), logical(1)))) {
    return(NA)
  }
  all(vapply(seq_along(workload), function(i) {
    values[[i]] >= ranges[[i]][[1L]] && values[[i]] <= ranges[[i]][[2L]]
  }, logical(1)))
}

profile_support_summary <- function(T, profile, train,
                                    min_intervals = 20L, min_cameras = 10L) {
  required <- c(profile_support_keys(), "rd", "camera")
  missing <- setdiff(required, names(train))
  if (length(missing)) {
    stop("support data missing required columns: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  pooled <- profile_support_subset(train, profile, c("bb", "ft"))
  regional <- profile_support_subset(train, profile, c("bb", "ft", "reg"))
  joint <- profile_support_subset(train, profile)

  safe_max <- function(x) if (length(x) && any(is.finite(x))) max(x, na.rm = TRUE) else NA_real_
  risk_rows <- function(x) {
    if (!is.finite(T) || nrow(x) == 0L) return(x[FALSE, , drop = FALSE])
    x[is.finite(x$rd) & x$rd >= T, , drop = FALSE]
  }
  pooled_risk <- risk_rows(pooled)
  regional_risk <- risk_rows(regional)
  profile_risk <- risk_rows(joint)
  pooled_max <- safe_max(pooled$rd)
  region_max <- safe_max(regional$rd)
  profile_max <- safe_max(joint$rd)
  workload_supported <- profile_workload_support(joint, profile)

  status <- if (!is.finite(T)) {
    "no_finite_optimum"
  } else if (nrow(joint) == 0L) {
    "unobserved_profile"
  } else if (identical(workload_supported, FALSE)) {
    "out_of_workload_support"
  } else if (is.finite(pooled_max) && T > pooled_max) {
    "beyond_followup"
  } else if (is.finite(profile_max) && T > profile_max) {
    "beyond_profile_followup"
  } else if (nrow(profile_risk) < min_intervals ||
             length(unique(profile_risk$camera)) < min_cameras) {
    "thin"
  } else {
    "within_followup"
  }

  list(
    pooled = pooled, regional = regional, profile = joint,
    pooled_risk = pooled_risk, regional_risk = regional_risk,
    profile_risk = profile_risk,
    pooled_max_followup = pooled_max,
    region_max_followup = region_max,
    profile_max_followup = profile_max,
    workload_supported = workload_supported,
    support = status
  )
}
