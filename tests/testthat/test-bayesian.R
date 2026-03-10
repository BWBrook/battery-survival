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

testthat::test_that("bayesian gate evaluation applies strict pass/fail thresholds", {
  cmp <- tibble::tibble(
    model_family = c("weibull", "lognormal"),
    fit_status = c("ok", "ok"),
    looic = c(100, 102),
    rhat_max = c(1.005, 1.02),
    bulk_ess_min = c(1200, 200),
    divergences = c(0L, 2L),
    treedepth_saturated = c(0L, 0L),
    bfmi_min = c(0.8, 0.7),
    elapsed_seconds = c(20, 22),
    message = c("fit completed", "fit completed")
  )

  cfg <- list(
    bayesian = list(
      gate = list(
        rhat_max = 1.01,
        bulk_ess_min = 400,
        max_divergences = 0
      )
    )
  )

  gate <- evaluate_bayesian_gate(cmp, cfg)

  testthat::expect_true(all(c(
    "gate_status", "fail_reasons", "all_families_pass",
    "criterion_rhat", "criterion_ess", "criterion_divergences"
  ) %in% names(gate)))
  testthat::expect_equal(gate$gate_status[gate$model_family == "weibull"], "pass")
  testthat::expect_equal(gate$gate_status[gate$model_family == "lognormal"], "fail")
  testthat::expect_false(any(gate$all_families_pass))
})

testthat::test_that("bayesian comparison with no fits includes diagnostics columns", {
  bayesian_result <- list(
    status = tibble::tibble(
      model_family = c("weibull", "lognormal"),
      fit_status = c("disabled", "disabled"),
      message = c("off", "off"),
      backend = c("cmdstanr", "cmdstanr")
    ),
    fits = list()
  )

  cfg <- list(bayesian = list(max_treedepth = 12L))
  out <- summarize_bayesian_model_comparison(bayesian_result, cfg)

  testthat::expect_true(all(c(
    "divergences", "treedepth_saturated", "bfmi_min", "elapsed_seconds"
  ) %in% names(out)))
  testthat::expect_true(all(is.na(out$divergences)))
})

testthat::test_that("missing backend Bayesian status produces stable comparison and gate outputs", {
  bayesian_result <- list(
    status = tibble::tibble(
      model_family = "weibull",
      fit_status = "missing_cmdstan",
      message = "cmdstanr backend requested, but cmdstanr/cmdstan is unavailable.",
      backend = "cmdstanr"
    ),
    fits = list()
  )

  cfg <- list(
    bayesian = list(
      max_treedepth = 12L,
      gate = list(
        rhat_max = 1.01,
        bulk_ess_min = 400,
        max_divergences = 0L
      )
    )
  )

  comparison <- summarize_bayesian_model_comparison(bayesian_result, cfg)
  gate <- evaluate_bayesian_gate(comparison, cfg)

  testthat::expect_equal(comparison$fit_status, "missing_cmdstan")
  testthat::expect_true(all(is.na(comparison$looic)))
  testthat::expect_true(all(is.na(comparison$divergences)))
  testthat::expect_equal(gate$gate_status, "fail")
  testthat::expect_match(gate$fail_reasons, "fit_status_not_ok")
  testthat::expect_false(gate$all_families_pass)
})
