make_model_test_data <- function(n = 200, seed = 123) {
  set.seed(seed)

  tibble::tibble(
    camera = paste0("cam", rep(seq_len(n / 2), each = 2)),
    rd = round(stats::runif(n, min = 30, max = 365), 1),
    event = stats::rbinom(n, size = 1, prob = 0.55),
    bb = factor(sample(c("Varta", "Procell", "Energizer"), n, replace = TRUE)),
    ft = factor(sample(c("w", "i"), n, replace = TRUE)),
    seas = factor(sample(c("summer", "autumn", "winter", "spring"), n, replace = TRUE)),
    reg = factor(sample(c("sw", "ne", "ct", "nw"), n, replace = TRUE)),
    log_fi_pd = stats::runif(n, 0, 2),
    log_day_pd = stats::runif(n, 0, 2)
  )
}

testthat::test_that("model comparison includes delta_aic ranking", {
  dat <- make_model_test_data()

  cfg <- list(
    model = list(
      cox_formula = "Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd",
      aft_formula = "Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd",
      aft_distributions = c("weibull", "lognormal")
    )
  )

  cox_fit <- fit_cox_model(dat, cfg)
  aft_fits <- fit_aft_models(dat, cfg)
  cmp <- summarize_model_comparison(cox_fit, aft_fits)

  testthat::expect_true(all(c("delta_aic", "rank") %in% names(cmp)))
  testthat::expect_equal(min(cmp$delta_aic, na.rm = TRUE), 0)
})

testthat::test_that("cox diagnostics tidier returns expected columns", {
  dat <- make_model_test_data()

  cfg <- list(
    model = list(
      cox_formula = "Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd"
    )
  )

  cox_fit <- fit_cox_model(dat, cfg)
  zph <- run_cox_diagnostics(cox_fit)
  tbl <- tidy_cox_diagnostics(zph)

  testthat::expect_true(all(c("term", "chisq", "df", "p_value") %in% names(tbl)))
  testthat::expect_true(nrow(tbl) >= 1)
})
