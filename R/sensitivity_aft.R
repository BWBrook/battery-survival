# Bounded frequentist sensitivity analyses for the AFT models.
#
# These functions deliberately take an already prepared analysis data set.  In
# particular, they do not re-derive features or alter factor levels: the
# sensitivity fit must be comparable with the canonical training cohort.

sa_require_columns <- function(dat, required, context = "data") {
  missing <- setdiff(required, names(dat))
  if (length(missing) > 0) {
    stop(context, " is missing required columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  invisible(dat)
}

sa_aft_formula <- function(with_region = FALSE, scale_spec = "common") {
  rhs <- c("bb", "ft", "seas", "log_fi_pd", "log_day_pd")
  if (isTRUE(with_region)) rhs <- c(rhs, "reg")
  if (identical(scale_spec, "brand")) rhs <- c(rhs, "strata(bb)")
  stats::as.formula(paste("Surv(rd, event) ~", paste(rhs, collapse = " + ")))
}

sa_tidy_aft_fit <- function(fit, model_id) {
  p <- length(fit$coefficients)
  location <- tibble::tibble(
    model_id = model_id,
    component = "location",
    term = names(fit$coefficients),
    estimate = as.numeric(fit$coefficients),
    std.error = sqrt(pmax(0, diag(fit$var)[seq_len(p)]))
  )
  location <- location |>
    dplyr::mutate(
      conf.low = estimate - stats::qnorm(0.975) * std.error,
      conf.high = estimate + stats::qnorm(0.975) * std.error
    )

  scale_n <- length(fit$scale)
  if (scale_n == 0) return(location)
  scale_var <- diag(fit$var)[p + seq_len(scale_n)]
  scale_names <- names(fit$scale)
  if (is.null(scale_names) || any(!nzchar(scale_names))) {
    scale_names <- rep("common", scale_n)
  }
  scale_est <- log(as.numeric(fit$scale))
  scale_tbl <- tibble::tibble(
    model_id = model_id,
    component = "log_scale",
    term = scale_names,
    estimate = scale_est,
    std.error = sqrt(pmax(0, scale_var))
  ) |>
    dplyr::mutate(
      conf.low = estimate - stats::qnorm(0.975) * std.error,
      conf.high = estimate + stats::qnorm(0.975) * std.error
    )
  dplyr::bind_rows(location, scale_tbl)
}

sa_fit_aft_sensitivity <- function(
  dat,
  families = c("weibull", "lognormal", "loglogistic"),
  scale_specs = c("common", "brand"),
  with_region = c(FALSE, TRUE)
) {
  sa_require_columns(
    dat,
    c("rd", "event", "bb", "ft", "seas", "log_fi_pd", "log_day_pd", "reg"),
    "sensitivity data"
  )
  families <- as.character(families)
  scale_specs <- as.character(scale_specs)
  with_region <- as.logical(with_region)
  if (!all(families %in% c("weibull", "lognormal", "loglogistic"))) {
    stop("families must be weibull, lognormal, or loglogistic", call. = FALSE)
  }
  if (!all(scale_specs %in% c("common", "brand"))) {
    stop("scale_specs must be common or brand", call. = FALSE)
  }

  specs <- tidyr::expand_grid(
    family = families,
    scale = scale_specs,
    region = with_region
  ) |>
    dplyr::mutate(
      model_id = paste(family, scale, ifelse(region, "region", "noregion"), sep = "__")
    )

  fits <- vector("list", nrow(specs))
  diagnostics <- vector("list", nrow(specs))
  coefficients <- vector("list", nrow(specs))

  for (i in seq_len(nrow(specs))) {
    spec <- specs[i, ]
    warning_text <- character()
    fit <- tryCatch(
      withCallingHandlers(
        survival::survreg(
          formula = sa_aft_formula(spec$region[[1]], spec$scale[[1]]),
          data = dat,
          dist = spec$family[[1]],
          model = TRUE,
          x = TRUE
        ),
        warning = function(w) {
          warning_text <<- c(warning_text, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) e
    )
    if (inherits(fit, "error")) {
      fits[i] <- list(NULL)
      diagnostics[[i]] <- tibble::tibble(
        model_id = spec$model_id[[1]], family = spec$family[[1]],
        scale = spec$scale[[1]], region = spec$region[[1]],
        converged = FALSE, convergence = NA_integer_, iterations = NA_integer_,
        warnings = paste(warning_text, collapse = " | "),
        error = conditionMessage(fit)
      )
      coefficients[[i]] <- tibble::tibble()
    } else {
      fits[[i]] <- fit
      convergence <- if (is.null(fit$convergence)) 0L else as.integer(fit$convergence)
      diagnostics[[i]] <- tibble::tibble(
        model_id = spec$model_id[[1]], family = spec$family[[1]],
        scale = spec$scale[[1]], region = spec$region[[1]],
        # survreg does not expose a separate convergence code on all R
        # versions; a returned fit with no error is its successful status.
        converged = isTRUE(convergence == 0),
        convergence = convergence,
        iterations = as.integer(fit$iter %||% NA_integer_),
        warnings = paste(unique(warning_text), collapse = " | "), error = NA_character_
      )
      coefficients[[i]] <- sa_tidy_aft_fit(fit, spec$model_id[[1]])
    }
  }
  names(fits) <- specs$model_id

  diagnostics <- dplyr::bind_rows(diagnostics)
  coefficients <- dplyr::bind_rows(coefficients)
  comparison <- purrr::map_dfr(
    seq_len(nrow(specs)),
    function(i) {
      fit <- fits[[i]]
      if (is.null(fit)) {
        return(tibble::tibble(
          model_id = specs$model_id[[i]], family = specs$family[[i]],
          scale = specs$scale[[i]], region = specs$region[[i]],
          aic = NA_real_, loglik = NA_real_, n = NA_integer_,
          df = NA_real_, parameter_count = NA_real_
        ))
      }
      tibble::tibble(
        model_id = specs$model_id[[i]], family = specs$family[[i]],
        scale = specs$scale[[i]], region = specs$region[[i]],
        aic = as.numeric(stats::AIC(fit)),
        loglik = as.numeric(stats::logLik(fit)), n = stats::nobs(fit),
        df = as.numeric(fit$df), parameter_count = as.numeric(fit$df)
      )
    }
  ) |>
    dplyr::mutate(delta_aic = aic - min(aic, na.rm = TRUE)) |>
    dplyr::arrange(aic)

  list(
    fits = fits,
    specifications = specs,
    comparison = comparison,
    diagnostics = diagnostics,
    coefficients = coefficients
  )
}

sa_model_scale <- function(fit, newdata_row) {
  scales <- as.numeric(fit$scale)
  if (length(scales) == 1L) return(scales[[1]])
  if (!"bb" %in% names(newdata_row)) {
    stop("brand-specific scale requires a bb column in newdata", call. = FALSE)
  }
  scale_names <- names(fit$scale)
  if (is.null(scale_names) || any(!nzchar(scale_names))) {
    stop("brand-specific survreg scale has no named brand mapping", call. = FALSE)
  }
  brand <- as.character(newdata_row$bb[[1]])
  idx <- match(brand, scale_names)
  if (is.na(idx)) stop("newdata brand has no fitted scale: ", brand, call. = FALSE)
  scales[[idx]]
}

sa_predict_row_survival <- function(fit, newdata_row, times) {
  required <- c("bb", "ft", "seas", "log_fi_pd", "log_day_pd")
  if ("reg" %in% names(fit$xlevels)) required <- c(required, "reg")
  sa_require_columns(
    newdata_row,
    required,
    "newdata row"
  )
  times <- as.numeric(times)
  if (any(!is.finite(times)) || any(times < 0)) stop("times must be finite and non-negative", call. = FALSE)
  scale <- sa_model_scale(fit, newdata_row)
  eta <- as.numeric(stats::predict(fit, newdata = newdata_row, type = "lp"))[[1]]
  sa_survival_from_eta(fit$dist, eta, scale, times)
}

sa_survival_from_eta <- function(family, eta, scale, times) {
  eta <- as.numeric(eta)
  scale <- as.numeric(scale)
  times <- as.numeric(times)
  if (length(eta) > 1L && length(times) > 1L) {
    stop("sa_survival_from_eta accepts one time or one linear predictor vector", call. = FALSE)
  }
  if (length(scale) == 1L && length(eta) > 1L) scale <- rep(scale, length(eta))
  result_n <- max(length(eta), length(times))
  if (any(!is.finite(eta)) || any(!is.finite(scale)) || any(scale <= 0)) return(rep(NA_real_, result_n))
  if (length(eta) == 1L) {
    z <- rep(0, length(times))
    positive <- times > 0
    z[positive] <- (log(times[positive]) - eta) / scale
  } else {
    z <- rep(0, length(eta))
    positive <- times[[1]] > 0
    if (positive) z <- (log(times[[1]]) - eta) / scale
  }
  if (identical(family, "weibull")) {
    # survreg's Weibull error is extreme-value, so this is exp(-exp(z)).
    # Computing on the log scale avoids overflow in the upper tail.
    out <- exp(-exp(pmin(z, 700)))
  } else if (identical(family, "loglogistic")) {
    out <- stats::plogis(-z)
  } else {
    out <- stats::pnorm(z, lower.tail = FALSE)
  }
  if (length(eta) == 1L) out[!positive] <- 1
  if (length(times) == 1L && !positive) out[] <- 1
  pmax(0, pmin(1, out))
}

sa_km_summary <- function(dat, times) {
  max_followup <- max(dat$rd, na.rm = TRUE)
  sf <- survival::survfit(survival::Surv(rd, event) ~ 1, data = dat)
  out <- lapply(times, function(tt) {
    if (tt > max_followup) {
      return(tibble::tibble(
        observed_survival = NA_real_, km_low = NA_real_, km_high = NA_real_,
        n_at_risk = 0L,
        n_cameras_risk = if ("camera" %in% names(dat)) 0L else NA_integer_
      ))
    }
    if (tt == 0) {
      return(tibble::tibble(
        observed_survival = 1, km_low = 1, km_high = 1,
        n_at_risk = sum(dat$rd >= tt),
        n_cameras_risk = if ("camera" %in% names(dat)) dplyr::n_distinct(dat$camera[dat$rd >= tt]) else NA_integer_
      ))
    }
    ss <- summary(sf, times = tt, extend = TRUE)
    tibble::tibble(
      observed_survival = as.numeric(ss$surv[[1]]),
      km_low = as.numeric(ss$lower[[1]]), km_high = as.numeric(ss$upper[[1]]),
      n_at_risk = sum(dat$rd >= tt, na.rm = TRUE),
      n_cameras_risk = if ("camera" %in% names(dat)) dplyr::n_distinct(dat$camera[dat$rd >= tt]) else NA_integer_
    )
  })
  dplyr::bind_rows(out)
}

sa_calibrate_fit <- function(
  fit, dat, horizons = seq(90, 270, by = 30),
  group_vars = c("bb", "ft"), model_id = NA_character_
) {
  sa_require_columns(dat, c("rd", "event", group_vars, "bb", "ft", "seas", "log_fi_pd", "log_day_pd"), "calibration data")
  if (length(group_vars) == 0) group_vars <- character()
  group_key <- if (length(group_vars)) interaction(dat[group_vars], drop = TRUE, sep = "|") else factor(rep("all", nrow(dat)))
  groups <- split(dat, group_key, drop = TRUE)
  out <- purrr::map_dfr(groups, function(g) {
    # Predictions are row-averaged within the group, matching the validation
    # estimand rather than prediction at a synthetic modal covariate row.
    required <- c("bb", "ft", "seas", "log_fi_pd", "log_day_pd")
    if ("reg" %in% names(fit$xlevels)) required <- c(required, "reg")
    newdat <- g[, required, drop = FALSE]
    eta <- as.numeric(stats::predict(fit, newdata = newdat, type = "lp"))
    scales <- if (length(fit$scale) == 1L) {
      rep(as.numeric(fit$scale), nrow(g))
    } else {
      scale_names <- names(fit$scale)
      if (is.null(scale_names) || any(!nzchar(scale_names))) {
        stop("brand-specific survreg scale has no named brand mapping", call. = FALSE)
      }
      idx <- match(as.character(g$bb), scale_names)
      if (anyNA(idx)) stop("calibration data contains a brand with no fitted scale", call. = FALSE)
      as.numeric(fit$scale)[idx]
    }
    pred <- vapply(horizons, function(h) {
      mean(sa_survival_from_eta(fit$dist, eta, scales, h))
    }, numeric(1))
    km <- sa_km_summary(g, horizons)
    labels <- if (length(group_vars)) purrr::map(group_vars, ~as.character(g[[.x]][[1]])) else list()
    label_tbl <- if (length(labels)) tibble::as_tibble(setNames(labels, group_vars)) else tibble::tibble()
    dplyr::bind_cols(
      label_tbl,
      tibble::tibble(
        model_id = model_id, horizon_days = as.numeric(horizons),
        predicted_survival = pred, n_obs_rows = nrow(g),
        events = sum(g$event == 1, na.rm = TRUE),
        max_followup = max(g$rd, na.rm = TRUE)
      ), km
    ) |>
      dplyr::mutate(
        calibration_error = predicted_survival - observed_survival,
        thin_support = (is.finite(n_at_risk) & n_at_risk < 20) |
          (is.finite(n_cameras_risk) & n_cameras_risk < 10)
      )
  })
  out
}

sa_calibrate_sensitivity <- function(model_grid, dat, horizons = seq(90, 270, by = 30), group_vars = c("bb", "ft")) {
  fits <- model_grid$fits %||% model_grid
  ids <- names(fits)
  if (is.null(ids)) ids <- paste0("model_", seq_along(fits))
  purrr::map_dfr(seq_along(fits), function(i) {
    id <- ids[[i]]
    fit <- fits[[i]]
    if (is.null(fit)) return(tibble::tibble())
    sa_calibrate_fit(fit, dat, horizons, group_vars, id)
  })
}

sa_mean_lifetime <- function(fit, newdata_row) {
  eta <- as.numeric(stats::predict(fit, newdata = newdata_row, type = "lp"))[[1]]
  scale <- sa_model_scale(fit, newdata_row)
  if (identical(fit$dist, "weibull")) return(exp(eta) * gamma(1 + scale))
  if (identical(fit$dist, "lognormal")) return(exp(eta + scale ^ 2 / 2))
  if (scale >= 1) return(Inf)
  exp(eta) * pi * scale / sin(pi * scale)
}

sa_expected_active_days <- function(fit, newdata_row, interval_days) {
  interval_days <- as.numeric(interval_days)
  if (length(interval_days) != 1L || !is.finite(interval_days) || interval_days < 0) {
    stop("interval_days must be one finite non-negative value", call. = FALSE)
  }
  if (interval_days == 0) return(0)
  eta <- as.numeric(stats::predict(fit, newdata = newdata_row, type = "lp"))[[1]]
  scale <- sa_model_scale(fit, newdata_row)
  if (identical(fit$dist, "weibull")) {
    y <- exp((log(interval_days) - eta) / scale)
    return(exp(eta) * scale * gamma(scale) * stats::pgamma(y, shape = scale))
  }
  if (identical(fit$dist, "lognormal")) {
    z <- (log(interval_days) - eta) / scale
    upper <- stats::pnorm(z, lower.tail = FALSE)
    return(exp(eta + scale ^ 2 / 2) * stats::pnorm((log(interval_days) - eta - scale ^ 2) / scale) + interval_days * upper)
  }
  stats::integrate(
    function(x) sa_predict_row_survival(fit, newdata_row, x),
    lower = 0, upper = interval_days, rel.tol = 1e-7
  )$value
}

sa_decision_for_profile <- function(
  fit, profile, ratios, max_followup, integration_tol = 1e-7,
  support_data = NULL
) {
  if (!is.finite(max_followup) || max_followup <= 0) stop("max_followup must be positive", call. = FALSE)
  if (any(!is.finite(ratios)) || any(ratios <= 0)) stop("ratios must be finite and positive", call. = FALSE)
  H <- function(T) {
    sa_expected_active_days(fit, profile, T) -
      T * sa_predict_row_survival(fit, profile, T)
  }
  support_base <- if (is.null(support_data)) NULL else
    profile_support_summary(0, profile, support_data, 0L, 0L)
  pooled_support <- if (is.null(support_base)) NULL else support_base$pooled
  regional_support <- if (is.null(support_base)) NULL else support_base$regional
  profile_support <- if (is.null(support_base)) NULL else support_base$profile
  model_support <- if (!is.null(support_base) && "reg" %in% names(fit$xlevels))
    regional_support else pooled_support
  support_count <- function(T) {
    if (!is.finite(T) || is.null(model_support) || !"rd" %in% names(model_support)) return(NA_integer_)
    as.integer(sum(model_support$rd >= T, na.rm = TRUE))
  }
  camera_count <- function(T) {
    if (!is.finite(T) || is.null(model_support) || !all(c("rd", "camera") %in% names(model_support))) return(NA_integer_)
    as.integer(dplyr::n_distinct(model_support$camera[model_support$rd >= T]))
  }
  data_support_count <- function(dat, T) {
    if (!is.finite(T) || is.null(dat) || !"rd" %in% names(dat)) return(NA_integer_)
    as.integer(sum(dat$rd >= T, na.rm = TRUE))
  }
  data_camera_count <- function(dat, T) {
    if (!is.finite(T) || is.null(dat) || !all(c("rd", "camera") %in% names(dat))) return(NA_integer_)
    as.integer(dplyr::n_distinct(dat$camera[dat$rd >= T]))
  }
  pooled_support_count <- function(T) {
    if (!is.finite(T) || is.null(pooled_support) || !"rd" %in% names(pooled_support)) return(NA_integer_)
    as.integer(sum(pooled_support$rd >= T, na.rm = TRUE))
  }
  pooled_camera_count <- function(T) {
    if (!is.finite(T) || is.null(pooled_support) || !all(c("rd", "camera") %in% names(pooled_support))) return(NA_integer_)
    as.integer(dplyr::n_distinct(pooled_support$camera[pooled_support$rd >= T]))
  }
  support_for_root <- function(T) {
    if (is.null(support_data)) return(NA_character_)
    profile_support_summary(T, profile, support_data)$support
  }
  mean_life <- sa_mean_lifetime(fit, profile)
  h_supported <- H(max_followup)
  rows <- purrr::map_dfr(ratios, function(r) {
    if (is.finite(mean_life) && r >= mean_life) {
      status <- "no_finite_optimum"
      root <- NA_real_
    } else {
      upper <- max(max_followup, 365)
      bracketed <- FALSE
      while (upper < 1e7) {
        if (is.finite(H(upper)) && H(upper) >= r) {
          bracketed <- TRUE
          break
        }
        upper <- min(1e7, upper * 2)
      }
      if (!bracketed && is.finite(H(upper)) && H(upper) >= r) bracketed <- TRUE
      if (bracketed) {
        root <- tryCatch(
          stats::uniroot(function(x) H(x) - r, interval = c(0, upper))$root,
          error = function(e) NA_real_
        )
        if (is.finite(root)) {
          status <- if (root <= max_followup) "finite_within_followup" else "finite_beyond_followup"
        } else {
          status <- "range_failed"
        }
      } else {
        root <- NA_real_
        status <- "range_failed"
      }
    }
    tibble::tibble(
      value_lost_camera_days = r, optimum_days = root, status = status,
      mean_lifetime_days = mean_life, h_at_max_followup = h_supported,
      h_search_limit = if (exists("upper")) upper else NA_real_,
      max_followup = max_followup,
      n_at_risk_at_optimum = support_count(root),
      n_cameras_risk_at_optimum = camera_count(root),
      region_n_at_risk_at_optimum = data_support_count(regional_support, root),
      region_n_cameras_risk_at_optimum = data_camera_count(regional_support, root),
      profile_n_at_risk_at_optimum = data_support_count(profile_support, root),
      profile_n_cameras_risk_at_optimum = data_camera_count(profile_support, root),
      n_at_risk_pooled_at_optimum = pooled_support_count(root),
      n_cameras_pooled_at_optimum = pooled_camera_count(root),
      profile_intervals = if (is.null(profile_support)) NA_integer_ else nrow(profile_support),
      profile_max_followup = if (is.null(support_base)) NA_real_ else support_base$profile_max_followup,
      profile_workload_supported = if (is.null(support_base)) NA else support_base$workload_supported,
      profile_support = support_for_root(root),
      unobserved_profile = identical(support_for_root(root), "unobserved_profile"),
      profile_thin_support = identical(support_for_root(root), "thin"),
      thin_support = is.finite(root) && (
        (is.finite(support_count(root)) && support_count(root) < 20) ||
          (is.finite(camera_count(root)) && camera_count(root) < 10)
      )
    )
  })
  rows
}

sa_decision_curves <- function(
  model_grid, prediction_profiles, ratios = c(20, 50, 100, 200),
  max_followup, integration_tol = 1e-7, support_data = NULL
) {
  fits <- model_grid$fits %||% model_grid
  if (!is.data.frame(prediction_profiles) || nrow(prediction_profiles) == 0) stop("prediction_profiles must be non-empty", call. = FALSE)
  ids <- names(fits)
  if (is.null(ids)) ids <- paste0("model_", seq_along(fits))
  out <- purrr::map_dfr(seq_along(fits), function(i) {
    id <- ids[[i]]
    fit <- fits[[i]]
    if (is.null(fit)) return(tibble::tibble())
    purrr::map_dfr(seq_len(nrow(prediction_profiles)), function(i) {
      prof <- prediction_profiles[i, , drop = FALSE]
      result <- sa_decision_for_profile(
        fit, prof, ratios, max_followup, integration_tol, support_data
      )
      result |> dplyr::mutate(model_id = id, profile_row = i, .before = 1)
    })
  })
  out
}
