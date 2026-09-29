# Rebuild and audit the eight observed operating profiles used by the
# September 2026 derived management refresh.  This file deliberately contains
# no model fitting: profiles and all predictions are functions of a sealed
# design$train object and saved posterior fits.

profile_revision_required <- function() {
  c("bb", "ft", "seas", "reg", "log_fi_pd", "log_day_pd")
}

profile_revision_validate_train <- function(train) {
  missing <- setdiff(c(profile_revision_required(), "rd", "event", "camera"),
                     names(train))
  if (length(missing)) {
    stop("profile revision training data missing: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  if (!nrow(train)) stop("profile revision training data is empty", call. = FALSE)
  needed <- train[, profile_revision_required(), drop = FALSE]
  if (any(!stats::complete.cases(needed)) ||
      any(!is.finite(train$log_fi_pd)) || any(!is.finite(train$log_day_pd))) {
    stop("profile revision training data has incomplete or non-finite profile fields",
         call. = FALSE)
  }
  invisible(train)
}

profile_revision_metadata <- function(profiles, train) {
  profile_revision_validate_train(train)
  if (!is.data.frame(profiles) || nrow(profiles) == 0L) {
    stop("profiles must be a non-empty data frame", call. = FALSE)
  }
  missing <- setdiff(profile_revision_required(), names(profiles))
  if (length(missing)) {
    stop("profiles missing: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  # Work entirely from the selected categorical cell.  This prevents the
  # profile metadata from silently reverting to a pooled brand/flash range.
  out <- lapply(seq_len(nrow(profiles)), function(i) {
    p <- profiles[i, , drop = FALSE]
    cell <- train[as.character(train$bb) == as.character(p$bb) &
                    as.character(train$ft) == as.character(p$ft) &
                    as.character(train$reg) == as.character(p$reg) &
                    as.character(train$seas) == as.character(p$seas), , drop = FALSE]
    if (!nrow(cell)) {
      stop("profile has no observed joint region/season cell: ",
           paste(as.character(p$bb), as.character(p$ft), as.character(p$reg),
                 as.character(p$seas), sep = "/"), call. = FALSE)
    }
    workload <- c("log_fi_pd", "log_day_pd")
    ranges <- vapply(workload, function(v) range(cell[[v]], na.rm = TRUE),
                     numeric(2L))
    selected <- vapply(workload, function(v) as.numeric(p[[v]][[1L]]), numeric(1))
    if (any(!is.finite(selected))) stop("profile workload is not finite", call. = FALSE)
    if (any(selected < ranges[1L, ] | selected > ranges[2L, ])) {
      stop("profile workload is outside its observed joint-cell range", call. = FALSE)
    }
    data.frame(
      profile_id = paste(as.character(p$bb), as.character(p$ft),
                         as.character(p$reg), as.character(p$seas), sep = "__"),
      profile_cell_rows = nrow(cell),
      profile_cell_cameras = length(unique(cell$camera)),
      profile_cell_events = sum(cell$event, na.rm = TRUE),
      profile_cell_workload_fi_min = ranges[1L, "log_fi_pd"],
      profile_cell_workload_fi_max = ranges[2L, "log_fi_pd"],
      profile_cell_workload_day_min = ranges[1L, "log_day_pd"],
      profile_cell_workload_day_max = ranges[2L, "log_day_pd"],
      profile_selection_rule = "modal_joint_region_season_then_nearest_observed_workload_pair",
      stringsAsFactors = FALSE
    )
  })
  cbind(profiles, do.call(rbind, out), row.names = NULL)
}

rebuild_profile_revision <- function(design, out = NULL) {
  if (!is.list(design) || !is.data.frame(design$train)) {
    stop("design must contain a data.frame train component", call. = FALSE)
  }
  profile_revision_validate_train(design$train)
  profiles <- build_prediction_profiles(design$train)
  profiles <- profile_revision_metadata(profiles, design$train)
  if (nrow(profiles) != 8L) {
    stop("expected eight battery/flash profiles; got ", nrow(profiles), call. = FALSE)
  }
  if (anyDuplicated(profiles$profile_id)) stop("profile_id values are not unique")
  if (!is.null(out)) {
    dir.create(out, recursive = TRUE, showWarnings = FALSE)
    utils::write.csv(profiles, file.path(out, "profiles.csv"), row.names = FALSE)
  }
  profiles
}

profile_revision_draw_support <- function(roots, profile, train,
                                          min_intervals = 20L,
                                          min_cameras = 10L,
                                          at_risk_root = NULL) {
  profile_revision_validate_train(train)
  required <- c("profile_support_summary", "profile_support_subset")
  if (!all(vapply(required, exists, logical(1), mode = "function"))) {
    stop("source R/profile_support.R before calculating profile support", call. = FALSE)
  }
  joint <- profile_support_subset(train, profile)
  regional <- profile_support_subset(train, profile, c("bb", "ft", "reg"))
  pooled <- profile_support_subset(train, profile, c("bb", "ft"))
  finite <- is.finite(roots)
  denominator <- sum(finite)
  measure <- function(dat, key) {
    if (!denominator) return(NA_real_)
    m <- vapply(roots[finite], function(T) {
      risk <- dat[is.finite(dat$rd) & dat$rd >= T, , drop = FALSE]
      if (key == "intervals") nrow(risk) else length(unique(risk$camera))
    }, integer(1))
    mean(m < if (key == "intervals") min_intervals else min_cameras)
  }
  probability_beyond <- function(dat) {
    if (!denominator || !nrow(dat)) return(NA_real_)
    mean(roots[finite] > max(dat$rd, na.rm = TRUE))
  }
  probability <- function(dat) {
    risk_interval <- if (denominator) vapply(roots[finite], function(T)
      sum(is.finite(dat$rd) & dat$rd >= T), integer(1)) else integer()
    risk_camera <- if (denominator) vapply(roots[finite], function(T)
      length(unique(dat$camera[is.finite(dat$rd) & dat$rd >= T])), integer(1)) else integer()
    list(
      intervals = if (denominator) mean(risk_interval < min_intervals) else NA_real_,
      cameras = if (denominator) mean(risk_camera < min_cameras) else NA_real_,
      thin = if (denominator) mean(risk_interval < min_intervals |
                                    risk_camera < min_cameras) else NA_real_,
      beyond = probability_beyond(dat)
    )
  }
  p <- probability(joint); r <- probability(regional); g <- probability(pooled)
  max_value <- function(x) if (nrow(x)) max(x$rd, na.rm = TRUE) else NA_real_
  median_root <- if (is.null(at_risk_root)) {
    if (denominator) stats::median(roots[finite]) else NA_real_
  } else {
    as.numeric(at_risk_root)[[1L]]
  }
  at_risk <- function(dat, cameras = FALSE) {
    if (is.na(median_root)) return(NA_integer_)
    keep <- is.finite(dat$rd) & dat$rd >= median_root
    if (cameras) length(unique(dat$camera[keep])) else sum(keep)
  }
  data.frame(
    profile_intervals_at_risk = at_risk(joint),
    profile_cameras_at_risk = at_risk(joint, TRUE),
    regional_intervals_at_risk = at_risk(regional),
    regional_cameras_at_risk = at_risk(regional, TRUE),
    pooled_intervals_at_risk = at_risk(pooled),
    pooled_cameras_at_risk = at_risk(pooled, TRUE),
    profile_max_followup = max_value(joint),
    regional_max_followup = max_value(regional),
    pooled_max_followup = max_value(pooled),
    profile_probability_beyond_followup_given_finite = p$beyond,
    profile_probability_thin_intervals_given_finite = p$intervals,
    profile_probability_thin_cameras_given_finite = p$cameras,
    profile_probability_thin_support_given_finite = p$thin,
    regional_probability_beyond_followup_given_finite = r$beyond,
    regional_probability_thin_support_given_finite = r$thin,
    pooled_probability_beyond_followup_given_finite = g$beyond,
    pooled_probability_thin_support_given_finite = g$thin,
    stringsAsFactors = FALSE
  )
}
