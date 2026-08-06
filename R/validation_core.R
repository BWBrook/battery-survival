default_validation_horizons <- function(cfg) {
  horizons <- cfg$validation$horizons_days
  if (is.null(horizons)) {
    return(c(90, 180, 270, 365))
  }
  as.integer(unlist(horizons, use.names = FALSE))
}

predict_group_survival <- function(aft_fit, dat, horizons_days) {
  required <- c("bb", "ft", "seas", "reg", "log_fi_pd", "log_day_pd")
  missing <- setdiff(required, names(dat))
  if (length(missing) > 0) {
    stop("Validation data missing required columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  xlevels <- aft_fit$xlevels

  pred_rows <- purrr::map_dfr(
    seq_len(nrow(dat)),
    function(i) {
      row_i <- dat[i, , drop = FALSE]
      newdat <- row_i[, required, drop = FALSE]
      supported <- TRUE
      for (nm in names(xlevels)) {
        if (nm %in% names(newdat)) {
          supported <- supported && as.character(newdat[[nm]][[1]]) %in% xlevels[[nm]]
        }
      }

      surv <- if (!supported) {
        rep(NA_real_, length(horizons_days))
      } else {
        tryCatch(
          predict_survival_from_aft(
            aft_fit = aft_fit,
            newdata_row = newdat,
            times = horizons_days
          ),
          error = function(e) {
            stop(
              "AFT prediction failed for supported validation row ", i,
              ": ", conditionMessage(e),
              call. = FALSE
            )
          }
        )
      }

      tibble::tibble(
        bb = as.character(row_i$bb[[1]]),
        ft = as.character(row_i$ft[[1]]),
        horizon_days = horizons_days,
        predicted_survival = surv,
        supported = supported
      )
    }
  )

  pred_rows %>%
    dplyr::group_by(bb, ft, horizon_days) %>%
    dplyr::summarise(
      predicted_survival = if (all(is.na(predicted_survival))) {
        NA_real_
      } else {
        mean(predicted_survival, na.rm = TRUE)
      },
      supported_rows = sum(supported, na.rm = TRUE),
      n_pred_rows = dplyr::n(),
      .groups = "drop"
    )
}

observed_group_survival <- function(dat, horizons_days) {
  dat %>%
    dplyr::mutate(
      bb_chr = as.character(bb),
      ft_chr = as.character(ft)
    ) %>%
    dplyr::group_by(bb_chr, ft_chr) %>%
    dplyr::group_modify(
      ~{
        sf <- survival::survfit(survival::Surv(rd, event) ~ 1, data = .x)
        surv <- summary(sf, times = horizons_days, extend = TRUE)$surv
        tibble::tibble(
          horizon_days = horizons_days,
          observed_survival = as.numeric(surv),
          n_obs_rows = nrow(.x),
          events = sum(.x$event == 1, na.rm = TRUE)
        )
      }
    ) %>%
    dplyr::ungroup() %>%
    dplyr::rename(bb = bb_chr, ft = ft_chr)
}

validate_aft_predictions <- function(aft_fit, validation_dat, cfg) {
  horizons_days <- default_validation_horizons(cfg)
  mean_or_na <- function(x) if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)
  rmse_or_na <- function(x) if (all(is.na(x))) NA_real_ else sqrt(mean(x, na.rm = TRUE))

  if (nrow(validation_dat) == 0) {
    empty_detail <- tibble::tibble(
      bb = character(),
      ft = character(),
      horizon_days = integer(),
      observed_survival = numeric(),
      predicted_survival = numeric(),
      abs_error = numeric(),
      sq_error = numeric(),
      n_obs_rows = integer(),
      supported_rows = integer(),
      n_pred_rows = integer()
    )
    empty_summary <- tibble::tibble(
      horizon_days = integer(),
      groups = integer(),
      mean_observed = numeric(),
      mean_predicted = numeric(),
      mae = numeric(),
      rmse = numeric(),
      supported_rows = integer(),
      total_rows = integer()
    )
    return(list(detail = empty_detail, summary = empty_summary))
  }

  obs <- observed_group_survival(validation_dat, horizons_days)
  pred <- predict_group_survival(aft_fit, validation_dat, horizons_days)

  detail <- obs %>%
    dplyr::left_join(pred, by = c("bb", "ft", "horizon_days")) %>%
    dplyr::mutate(
      abs_error = abs(predicted_survival - observed_survival),
      sq_error = (predicted_survival - observed_survival) ^ 2
    ) %>%
    dplyr::arrange(horizon_days, bb, ft)

  summary_tbl <- detail %>%
    dplyr::group_by(horizon_days) %>%
    dplyr::summarise(
      groups = dplyr::n(),
      mean_observed = mean_or_na(observed_survival),
      mean_predicted = mean_or_na(predicted_survival),
      mae = mean_or_na(abs_error),
      rmse = rmse_or_na(sq_error),
      supported_rows = sum(supported_rows, na.rm = TRUE),
      total_rows = sum(n_pred_rows, na.rm = TRUE),
      .groups = "drop"
    )

  list(detail = detail, summary = summary_tbl)
}

summarize_testbench_data <- function(tb_dat) {
  if (nrow(tb_dat) == 0) {
    return(tibble::tibble(
      rows = 0L,
      cameras = 0L,
      events = 0L,
      censored = 0L,
      event_rate = NA_real_,
      median_rd = NA_real_,
      q05_rd = NA_real_,
      q95_rd = NA_real_
    ))
  }

  tibble::tibble(
    rows = nrow(tb_dat),
    cameras = dplyr::n_distinct(tb_dat$camera),
    events = sum(tb_dat$event == 1, na.rm = TRUE),
    censored = sum(tb_dat$event == 0, na.rm = TRUE),
    event_rate = mean(tb_dat$event == 1, na.rm = TRUE),
    median_rd = stats::median(tb_dat$rd, na.rm = TRUE),
    q05_rd = stats::quantile(tb_dat$rd, 0.05, na.rm = TRUE),
    q95_rd = stats::quantile(tb_dat$rd, 0.95, na.rm = TRUE)
  )
}

fit_tb_km <- function(tb_dat) {
  if (nrow(tb_dat) == 0) {
    return(NULL)
  }

  survival::survfit(survival::Surv(rd, event) ~ bb, data = tb_dat)
}
