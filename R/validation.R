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
          error = function(e) rep(NA_real_, length(horizons_days))
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

write_validation_tables <- function(validation_detail, validation_summary, cfg) {
  ensure_output_dirs(cfg)

  detail_path <- fs::path(cfg$tables_dir, "validation_survival_detail.csv")
  summary_path <- fs::path(cfg$tables_dir, "validation_survival_summary.csv")

  readr::write_csv(validation_detail, detail_path)
  readr::write_csv(validation_summary, summary_path)

  c(detail_path, summary_path)
}

plot_validation_observed_vs_predicted <- function(validation_detail, cfg) {
  ensure_output_dirs(cfg)
  out_path <- fs::path(cfg$figures_dir, "validation_observed_vs_predicted.png")

  if (nrow(validation_detail) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate(
        "text",
        x = 0.5,
        y = 0.5,
        label = "No SW validation rows available.",
        size = 4
      ) +
      ggplot2::xlim(0, 1) +
      ggplot2::ylim(0, 1) +
      ggplot2::theme_void()

    ggplot2::ggsave(out_path, p, width = 8, height = 4.5, dpi = 300)
    return(out_path)
  }

  plot_df <- validation_detail %>%
    dplyr::filter(
      is.finite(observed_survival),
      is.finite(predicted_survival)
    )

  if (nrow(plot_df) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate(
        "text",
        x = 0.5,
        y = 0.5,
        label = "No in-support SW validation predictions available.",
        size = 4
      ) +
      ggplot2::xlim(0, 1) +
      ggplot2::ylim(0, 1) +
      ggplot2::theme_void()

    ggplot2::ggsave(out_path, p, width = 8, height = 4.5, dpi = 300)
    return(out_path)
  }

  p <- ggplot2::ggplot(
    plot_df,
    ggplot2::aes(x = observed_survival, y = predicted_survival, color = bb, shape = ft)
  ) +
    ggplot2::geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "grey50") +
    ggplot2::geom_point(size = 2.3, alpha = 0.9) +
    ggplot2::facet_wrap(~horizon_days) +
    ggplot2::scale_x_continuous(labels = scales::label_percent(accuracy = 1), limits = c(0, 1)) +
    ggplot2::scale_y_continuous(labels = scales::label_percent(accuracy = 1), limits = c(0, 1)) +
    ggplot2::labs(
      title = "AFT Validation on SW: Observed vs Predicted Survival",
      x = "Observed survival probability",
      y = "Predicted survival probability",
      color = "Battery brand",
      shape = "Flash type"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  ggplot2::ggsave(out_path, p, width = 11, height = 5.5, dpi = 300)
  out_path
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

write_testbench_tables <- function(tb_summary, cfg) {
  ensure_output_dirs(cfg)
  out_path <- fs::path(cfg$tables_dir, "testbench_summary.csv")
  readr::write_csv(tb_summary, out_path)
  out_path
}

plot_testbench_km <- function(tb_km_fit, cfg) {
  ensure_output_dirs(cfg)
  out_path <- fs::path(cfg$figures_dir, "testbench_km_by_brand.png")

  if (is.null(tb_km_fit)) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate(
        "text",
        x = 0.5,
        y = 0.5,
        label = "No testbench rows available.",
        size = 4
      ) +
      ggplot2::xlim(0, 1) +
      ggplot2::ylim(0, 1) +
      ggplot2::theme_void()

    ggplot2::ggsave(out_path, p, width = 8, height = 4.5, dpi = 300)
    return(out_path)
  }

  km_df <- broom::tidy(tb_km_fit)
  if (!"strata" %in% names(km_df)) {
    km_df$strata <- "all"
  }
  km_df <- km_df %>%
    dplyr::mutate(strata = dplyr::coalesce(as.character(strata), "all"))

  p <- ggplot2::ggplot(km_df, ggplot2::aes(x = time, y = estimate, color = strata)) +
    ggplot2::geom_step(linewidth = 0.9) +
    ggplot2::labs(
      title = "Testbench Kaplan-Meier Curves",
      x = "Run duration (days)",
      y = "Survival probability",
      color = "Battery brand"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  ggplot2::ggsave(out_path, p, width = 9, height = 5, dpi = 300)
  out_path
}
