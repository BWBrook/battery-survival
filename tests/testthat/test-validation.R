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

testthat::test_that("unsupported validation rows are retained and counted explicitly", {
  dat <- make_validation_test_data(n = 400, seed = 7)
  train <- dat[dat$reg != "sw", , drop = FALSE] %>%
    dplyr::filter(bb != "Energizer") %>%
    dplyr::mutate(
      dplyr::across(
        .cols = dplyr::where(is.factor),
        .fns = droplevels
      )
    )
  validation <- dat[dat$reg == "sw", , drop = FALSE] %>%
    dplyr::slice(1:4) %>%
    dplyr::mutate(
      bb = factor(c("Varta", "Varta", "Energizer", "Energizer")),
      ft = factor(c("w", "w", "w", "w"))
    )

  fit <- survival::survreg(
    survival::Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd,
    data = train,
    dist = "weibull"
  )

  pred <- predict_group_survival(fit, validation, c(90, 180))
  unsupported <- dplyr::filter(pred, bb == "Energizer", ft == "w")
  supported <- dplyr::filter(pred, bb == "Varta", ft == "w")

  testthat::expect_true(all(is.na(unsupported$predicted_survival)))
  testthat::expect_true(all(unsupported$supported_rows == 0))
  testthat::expect_true(all(unsupported$n_pred_rows == 2))
  testthat::expect_true(all(supported$supported_rows == supported$n_pred_rows))

  out <- validate_aft_predictions(fit, validation, list(validation = list(horizons_days = c(90, 180))))
  unsupported_detail <- dplyr::filter(out$detail, bb == "Energizer", ft == "w")

  testthat::expect_equal(nrow(unsupported_detail), 2)
  testthat::expect_true(all(is.na(unsupported_detail$predicted_survival)))
  testthat::expect_true(all(unsupported_detail$supported_rows == 0))
})

testthat::test_that("validation summary keeps all observed strata but errors use finite predictions only", {
  dat <- make_validation_test_data(n = 400, seed = 7)
  train <- dat[dat$reg != "sw", , drop = FALSE] %>%
    dplyr::filter(bb != "Energizer") %>%
    dplyr::mutate(
      dplyr::across(
        .cols = dplyr::where(is.factor),
        .fns = droplevels
      )
    )
  validation <- dat[dat$reg == "sw", , drop = FALSE] %>%
    dplyr::slice(1:4) %>%
    dplyr::mutate(
      bb = factor(c("Varta", "Varta", "Energizer", "Energizer")),
      ft = factor(c("w", "w", "w", "w"))
    )

  fit <- survival::survreg(
    survival::Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd,
    data = train,
    dist = "weibull"
  )

  out <- validate_aft_predictions(fit, validation, list(validation = list(horizons_days = c(90, 180))))

  detail_90 <- dplyr::filter(out$detail, horizon_days == 90)
  summary_90 <- dplyr::filter(out$summary, horizon_days == 90)

  testthat::expect_equal(nrow(detail_90), 2)
  testthat::expect_equal(sum(is.finite(detail_90$predicted_survival)), 1)
  testthat::expect_equal(summary_90$groups, 2)
  testthat::expect_equal(summary_90$mean_observed, mean(detail_90$observed_survival))
  testthat::expect_equal(
    summary_90$mean_predicted,
    mean(detail_90$predicted_survival, na.rm = TRUE)
  )
  testthat::expect_equal(summary_90$mae, mean(detail_90$abs_error, na.rm = TRUE))
  testthat::expect_equal(
    summary_90$rmse,
    sqrt(mean(detail_90$sq_error, na.rm = TRUE))
  )
})

testthat::test_that("supported validation prediction errors are surfaced", {
  dat <- make_validation_test_data()
  train <- dat[dat$reg != "sw", , drop = FALSE]
  validation <- dat[dat$reg == "sw", , drop = FALSE] %>%
    dplyr::slice(1) %>%
    dplyr::mutate(log_fi_pd = "not numeric")

  fit <- survival::survreg(
    survival::Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd,
    data = train,
    dist = "weibull"
  )

  testthat::expect_error(
    predict_group_survival(fit, validation, c(90, 180)),
    "AFT prediction failed for supported validation row"
  )
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
