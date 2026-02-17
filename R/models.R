fit_km <- function(dat) {
  survival::survfit(survival::Surv(rd, event) ~ bb, data = dat)
}

fit_cox_model <- function(dat, cfg) {
  cox_formula <- stats::as.formula(cfg$model$cox_formula)

  survival::coxph(
    formula = cox_formula,
    data = dat,
    ties = "efron",
    robust = TRUE,
    cluster = dat$camera,
    model = TRUE,
    x = TRUE
  )
}

fit_aft_models <- function(dat, cfg) {
  aft_formula <- stats::as.formula(cfg$model$aft_formula)
  dists <- unlist(cfg$model$aft_distributions, use.names = FALSE)

  fits <- purrr::map(
    dists,
    ~survival::survreg(
      formula = aft_formula,
      data = dat,
      dist = .x,
      model = TRUE,
      x = TRUE
    )
  )
  names(fits) <- dists
  fits
}

run_cox_diagnostics <- function(cox_fit) {
  survival::cox.zph(cox_fit, transform = "km")
}

summarize_model_comparison <- function(cox_fit, aft_models) {
  cox_row <- tibble::tibble(
    model = "coxph",
    family = "coxph",
    aic = as.numeric(stats::AIC(cox_fit)),
    loglik = as.numeric(stats::logLik(cox_fit)),
    n = stats::nobs(cox_fit)
  )

  aft_rows <- purrr::imap_dfr(
    aft_models,
    ~tibble::tibble(
      model = paste0("aft_", .y),
      family = .y,
      aic = as.numeric(stats::AIC(.x)),
      loglik = as.numeric(stats::logLik(.x)),
      n = stats::nobs(.x)
    )
  )

  out <- dplyr::bind_rows(cox_row, aft_rows) %>%
    dplyr::arrange(aic) %>%
    dplyr::mutate(
      delta_aic = aic - min(aic, na.rm = TRUE),
      rank = dplyr::row_number()
    )

  out
}

tidy_cox_coefficients <- function(cox_fit) {
  broom::tidy(cox_fit, conf.int = TRUE, exponentiate = TRUE) %>%
    dplyr::mutate(
      hr = estimate,
      hr_low = conf.low,
      hr_high = conf.high
    )
}

tidy_aft_coefficients <- function(aft_models) {
  purrr::imap_dfr(
    aft_models,
    ~broom::tidy(.x, conf.int = TRUE) %>%
      dplyr::mutate(model = .y, .before = 1)
  )
}

extract_km_medians <- function(km_fit) {
  km_tidy <- broom::tidy(km_fit)

  km_tidy %>%
    dplyr::group_by(strata) %>%
    dplyr::arrange(time, .by_group = TRUE) %>%
    dplyr::summarise(
      median_survival_days = {
        idx <- which(estimate <= 0.5)
        if (length(idx) == 0) NA_real_ else time[min(idx)]
      },
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      bb = stringr::str_remove(strata, "^bb="),
      .before = 1
    )
}

summarize_data_overview <- function(dat) {
  tibble::tibble(
    rows = nrow(dat),
    cameras = dplyr::n_distinct(dat$camera),
    events = sum(dat$event == 1, na.rm = TRUE),
    censored = sum(dat$event == 0, na.rm = TRUE),
    event_rate = mean(dat$event == 1, na.rm = TRUE),
    median_rd = stats::median(dat$rd, na.rm = TRUE),
    q05_rd = stats::quantile(dat$rd, 0.05, na.rm = TRUE),
    q95_rd = stats::quantile(dat$rd, 0.95, na.rm = TRUE)
  )
}

summarize_region_event_rates <- function(dat) {
  dat %>%
    dplyr::group_by(reg) %>%
    dplyr::summarise(
      rows = dplyr::n(),
      cameras = dplyr::n_distinct(camera),
      events = sum(event == 1, na.rm = TRUE),
      event_rate = mean(event == 1, na.rm = TRUE),
      mean_rd = mean(rd, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::arrange(dplyr::desc(event_rate))
}

tidy_cox_diagnostics <- function(cox_diag) {
  out <- as.data.frame(cox_diag$table, stringsAsFactors = FALSE)
  out$term <- rownames(out)
  rownames(out) <- NULL

  tibble::as_tibble(out) %>%
    dplyr::rename(chisq = chisq, p_value = `p`) %>%
    dplyr::select(term, chisq, df, p_value)
}
