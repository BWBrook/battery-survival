read_cost_scenarios <- function(path) {
  if (!file.exists(path)) {
    stop("Cost scenarios file not found: ", path, call. = FALSE)
  }

  dat <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  required <- c("scenario_id", "scenario_label", "service_cost")
  missing <- setdiff(required, names(dat))
  if (length(missing) > 0) {
    stop("Cost scenarios missing required columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  dat %>%
    dplyr::transmute(
      scenario_id = as.character(scenario_id),
      scenario_label = as.character(scenario_label),
      service_cost = as.numeric(service_cost),
      notes = as.character(.data$notes %||% NA_character_)
    )
}

read_battery_costs <- function(path) {
  if (!file.exists(path)) {
    stop("Battery costs file not found: ", path, call. = FALSE)
  }

  dat <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  required <- c("bb", "battery_cost")
  missing <- setdiff(required, names(dat))
  if (length(missing) > 0) {
    stop("Battery costs missing required columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  dat %>%
    dplyr::transmute(
      bb = stringr::str_to_title(as.character(bb)),
      battery_cost = as.numeric(battery_cost),
      notes = as.character(.data$notes %||% NA_character_)
    )
}

build_prediction_profiles <- function(dat) {
  mode_chr <- function(x) {
    tx <- table(as.character(x))
    names(tx)[which.max(tx)]
  }

  out <- dat %>%
    dplyr::group_by(bb, ft) %>%
    dplyr::summarise(
      seas = mode_chr(seas),
      reg = mode_chr(reg),
      log_fi_pd = stats::median(log_fi_pd, na.rm = TRUE),
      log_day_pd = stats::median(log_day_pd, na.rm = TRUE),
      n_rows = dplyr::n(),
      .groups = "drop"
    )

  out %>%
    dplyr::mutate(
      bb = factor(as.character(bb), levels = levels(dat$bb)),
      ft = factor(as.character(ft), levels = levels(dat$ft)),
      seas = factor(as.character(seas), levels = levels(dat$seas)),
      reg = factor(as.character(reg), levels = levels(dat$reg))
    )
}

choose_best_aft_model <- function(aft_models, model_comparison) {
  best <- model_comparison %>%
    dplyr::filter(stringr::str_starts(model, "aft_")) %>%
    dplyr::arrange(aic) %>%
    dplyr::slice(1)

  if (nrow(best) == 0) {
    stop("No AFT models found in model comparison.", call. = FALSE)
  }

  aft_name <- stringr::str_remove(best$model[[1]], "^aft_")
  if (!aft_name %in% names(aft_models)) {
    stop("Best AFT model not found in aft model list: ", aft_name, call. = FALSE)
  }

  list(name = aft_name, model = aft_models[[aft_name]])
}

predict_survival_from_aft <- function(aft_fit, newdata_row, times) {
  p_grid <- seq(0.001, 0.999, by = 0.001)
  q <- as.numeric(predict(aft_fit, newdata = newdata_row, type = "quantile", p = p_grid))
  keep_finite <- is.finite(q)
  q <- q[keep_finite]
  p <- p_grid[keep_finite]

  if (length(q) < 2) {
    surv <- rep(NA_real_, length(times))
    return(surv)
  }

  q <- pmax(q, 1e-6)
  ord <- order(q)
  q <- q[ord]
  p <- p[ord]

  keep <- !duplicated(q)
  q <- q[keep]
  p <- p[keep]

  if (length(q) < 2) {
    surv <- rep(NA_real_, length(times))
    return(surv)
  }

  cdf <- stats::approx(x = q, y = p, xout = times, rule = 2, ties = "ordered")$y
  cdf[times <= min(q)] <- 0
  cdf[times >= max(q)] <- 1
  pmax(0, pmin(1, 1 - cdf))
}

trapz_integral <- function(x, y) {
  if (length(x) < 2) {
    return(0)
  }
  sum(diff(x) * (head(y, -1) + tail(y, -1)) / 2)
}

expected_active_days <- function(times, surv, interval_days) {
  if (interval_days <= 0) {
    return(0)
  }
  if (sum(is.finite(surv)) < 2) {
    return(NA_real_)
  }

  idx <- which(times < interval_days)
  x <- c(times[idx], interval_days)
  y_base <- c(surv[idx], stats::approx(times, surv, xout = interval_days, rule = 2)$y)
  trapz_integral(x, y_base)
}

survival_at_interval <- function(times, surv, interval_days) {
  if (sum(is.finite(surv)) < 2) {
    return(NA_real_)
  }
  stats::approx(times, surv, xout = interval_days, rule = 2)$y
}

compute_service_interval_economics <- function(
  aft_fit,
  aft_name,
  prediction_profiles,
  cost_scenarios,
  battery_costs,
  interval_min,
  interval_max,
  interval_by
) {
  intervals <- seq(interval_min, interval_max, by = interval_by)
  time_grid <- seq(0, interval_max, by = 1)

  profile_costs <- prediction_profiles %>%
    dplyr::mutate(bb_chr = as.character(bb)) %>%
    dplyr::left_join(battery_costs, by = c("bb_chr" = "bb"))

  if (anyNA(profile_costs$battery_cost)) {
    missing <- profile_costs %>%
      dplyr::filter(is.na(battery_cost)) %>%
      dplyr::distinct(bb_chr) %>%
      dplyr::pull(bb_chr)
    stop("Missing battery costs for brands: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  out <- purrr::map_dfr(
    seq_len(nrow(profile_costs)),
    function(i) {
      prof <- profile_costs[i, ]
      newdat <- prof %>%
        dplyr::select(bb, ft, seas, reg, log_fi_pd, log_day_pd)
      surv <- predict_survival_from_aft(aft_fit, newdat, time_grid)

      purrr::map_dfr(
        seq_len(nrow(cost_scenarios)),
        function(j) {
          sc <- cost_scenarios[j, ]
          tibble::tibble(interval_days = intervals) %>%
            dplyr::rowwise() %>%
            dplyr::mutate(
              expected_active_days = expected_active_days(time_grid, surv, interval_days),
              expected_downtime_days = interval_days - expected_active_days,
              downtime_fraction = ifelse(interval_days > 0, expected_downtime_days / interval_days, NA_real_),
              survival_at_service = survival_at_interval(time_grid, surv, interval_days),
              fail_before_service = 1 - survival_at_service,
              service_cost = sc$service_cost[[1]],
              battery_cost = prof$battery_cost[[1]],
              total_cycle_cost = service_cost + battery_cost,
              cost_per_active_day = total_cycle_cost / pmax(expected_active_days, 1e-8),
              scenario_id = sc$scenario_id[[1]],
              scenario_label = sc$scenario_label[[1]],
              bb = as.character(prof$bb[[1]]),
              ft = as.character(prof$ft[[1]]),
              seas = as.character(prof$seas[[1]]),
              reg = as.character(prof$reg[[1]]),
              aft_model = aft_name
            ) %>%
            dplyr::ungroup()
        }
      )
    }
  )

  out %>%
    dplyr::filter(
      is.finite(expected_active_days),
      expected_active_days > 0,
      is.finite(expected_downtime_days),
      is.finite(downtime_fraction),
      is.finite(cost_per_active_day),
      is.finite(fail_before_service)
    )
}

summarize_economic_optima <- function(econ_grid) {
  econ_grid %>%
    dplyr::group_by(aft_model, scenario_id, scenario_label, bb, ft) %>%
    dplyr::arrange(cost_per_active_day, .by_group = TRUE) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup() %>%
    dplyr::select(
      aft_model, scenario_id, scenario_label, bb, ft,
      interval_days, expected_active_days, expected_downtime_days,
      downtime_fraction, cost_per_active_day, total_cycle_cost
    )
}
