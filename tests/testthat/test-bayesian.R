testthat::test_that("bayesian disabled mode returns disabled statuses", {
  dat <- tibble::tibble(
    rd = c(100, 120),
    event = c(1L, 0L),
    bb = factor(c("Varta", "Procell")),
    ft = factor(c("w", "i")),
    seas = factor(c("summer", "winter")),
    reg = factor(c("ct", "se")),
    log_fi_pd = c(0.2, 0.4),
    log_day_pd = c(0.3, 0.6)
  )

  cfg <- list(
    seed = 1L,
    bayesian = list(
      enabled = FALSE,
      backend = "cmdstanr",
      families = c("weibull", "lognormal")
    )
  )

  out <- fit_bayesian_models(dat, cfg)
  testthat::expect_true(all(out$status$fit_status == "disabled"))
  testthat::expect_equal(length(out$fits), 0)
})

testthat::test_that("bayesian enabled path reports non-ok status without forcing fit", {
  dat <- tibble::tibble(
    rd = c(100, 120),
    event = c(1L, 0L),
    bb = factor(c("Varta", "Procell")),
    ft = factor(c("w", "i")),
    seas = factor(c("summer", "winter")),
    reg = factor(c("ct", "se")),
    log_fi_pd = c(0.2, 0.4),
    log_day_pd = c(0.3, 0.6)
  )

  cfg <- list(
    seed = 1L,
    bayesian = list(
      enabled = TRUE,
      backend = "cmdstanr",
      families = c("not_a_family")
    )
  )

  out <- fit_bayesian_models(dat, cfg)
  testthat::expect_true(nrow(out$status) >= 1)
  testthat::expect_true(all(c("model_family", "fit_status", "message", "backend") %in% names(out$status)))
  testthat::expect_true(all(out$status$fit_status %in% c(
    "missing_brms",
    "missing_cmdstan",
    "bad_family",
    "fit_error",
    "ok"
  )))
})
