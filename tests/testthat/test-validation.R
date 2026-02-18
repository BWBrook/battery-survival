make_validation_test_data <- function(n = 120, seed = 42) {
  set.seed(seed)
  tibble::tibble(
    camera = paste0("cam", seq_len(n)),
    rd = round(stats::runif(n, min = 30, max = 365), 1),
    event = stats::rbinom(n, size = 1, prob = 0.55),
    bb = factor(sample(c("Varta", "Procell", "Energizer"), n, replace = TRUE)),
    ft = factor(sample(c("w", "i"), n, replace = TRUE)),
    seas = factor(sample(c("summer", "autumn", "winter", "spring"), n, replace = TRUE)),
    reg = factor(sample(c("ct", "se", "sw", "wt"), n, replace = TRUE)),
    log_fi_pd = stats::runif(n, 0, 2),
    log_day_pd = stats::runif(n, 0, 2)
  )
}

testthat::test_that("validate_aft_predictions returns detail and summary tables", {
  dat <- make_validation_test_data()
  train <- dat[dat$reg != "sw", , drop = FALSE]
  val <- dat[dat$reg == "sw", , drop = FALSE]

  fit <- survival::survreg(
    survival::Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd,
    data = train,
    dist = "weibull"
  )

  cfg <- list(validation = list(horizons_days = c(90, 180, 270)))
  out <- validate_aft_predictions(fit, val, cfg)

  testthat::expect_true(all(c("detail", "summary") %in% names(out)))
  testthat::expect_true(all(
    c("horizon_days", "observed_survival", "predicted_survival", "abs_error") %in% names(out$detail)
  ))
  testthat::expect_true(all(c("horizon_days", "mae", "rmse") %in% names(out$summary)))
})

testthat::test_that("testbench summary handles empty inputs", {
  empty <- tibble::tibble(
    camera = character(),
    rd = numeric(),
    event = integer()
  )

  out <- summarize_testbench_data(empty)
  testthat::expect_equal(out$rows, 0)
  testthat::expect_true(is.na(out$event_rate))
})
