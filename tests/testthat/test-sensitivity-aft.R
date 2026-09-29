make_sensitivity_test_data <- function(n = 420, seed = 901) {
  set.seed(seed)
  tibble::tibble(
    camera = paste0("camera", seq_len(n)),
    rd = round(stats::runif(n, 35, 365), 1),
    event = stats::rbinom(n, 1, 0.62),
    bb = factor(sample(c("Varta", "Procell", "Energizer"), n, TRUE)),
    ft = factor(sample(c("w", "i"), n, TRUE)),
    seas = factor(sample(c("summer", "autumn", "winter", "spring"), n, TRUE)),
    reg = factor(sample(c("ct", "se", "sw"), n, TRUE)),
    log_fi_pd = stats::runif(n, 0, 1.5),
    log_day_pd = stats::runif(n, 0, 1.5)
  )
}

testthat::test_that("sensitivity grid fits the prescribed 12 models", {
  dat <- make_sensitivity_test_data()
  out <- sa_fit_aft_sensitivity(dat)

  testthat::expect_length(out$fits, 12)
  testthat::expect_equal(nrow(out$specifications), 12)
  testthat::expect_equal(nrow(out$comparison), 12)
  testthat::expect_true(all(out$diagnostics$converged))
  testthat::expect_true(all(is.na(out$diagnostics$error)))
  testthat::expect_true(all(c("aic", "delta_aic", "family", "scale", "region") %in% names(out$comparison)))
  testthat::expect_true(all(c("component", "term", "estimate", "std.error") %in% names(out$coefficients)))
})

testthat::test_that("analytic row survival agrees with survreg quantiles", {
  dat <- make_sensitivity_test_data(n = 300)
  for (family in c("weibull", "lognormal", "loglogistic")) {
    fit <- survival::survreg(
      survival::Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd,
      data = dat, dist = family
    )
    row <- dat[1, , drop = FALSE]
    p <- c(0.2, 0.5, 0.8)
    q <- as.numeric(stats::predict(fit, newdata = row, type = "quantile", p = p))
    got <- sa_predict_row_survival(fit, row, q)
    testthat::expect_equal(got, 1 - p, tolerance = 1e-7)
    testthat::expect_equal(sa_predict_row_survival(fit, row, 0), 1)
  }
})

testthat::test_that("brand-specific scales use the fitted named mapping", {
  dat <- make_sensitivity_test_data()
  fit <- survival::survreg(
    survival::Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd + strata(bb),
    data = dat, dist = "weibull"
  )
  row <- dat[1, , drop = FALSE]
  expected <- (
    log(100) - as.numeric(stats::predict(fit, newdata = row, type = "lp"))
  ) / sa_model_scale(fit, row)
  testthat::expect_equal(
    sa_predict_row_survival(fit, row, 100), exp(-exp(expected)),
    tolerance = 1e-12
  )
  bad <- row
  bad$bb <- factor("unknown")
  testthat::expect_error(sa_predict_row_survival(fit, bad, 100), "no fitted scale")
})

testthat::test_that("analytic active-day formulas agree with numerical integration", {
  dat <- make_sensitivity_test_data(n = 300)
  row <- dat[1, , drop = FALSE]
  for (family in c("weibull", "lognormal")) {
    fit <- survival::survreg(
      survival::Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd,
      data = dat, dist = family
    )
    interval <- 180
    numerical <- stats::integrate(
      function(t) sa_predict_row_survival(fit, row, t),
      lower = 0, upper = interval, rel.tol = 1e-9
    )$value
    testthat::expect_equal(
      sa_expected_active_days(fit, row, interval), numerical,
      tolerance = 1e-5
    )
  }
})

testthat::test_that("calibration uses row averages and suppresses unsupported KM tails", {
  dat <- make_sensitivity_test_data(n = 260)
  fit <- survival::survreg(
    survival::Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd,
    data = dat, dist = "weibull"
  )
  out <- sa_calibrate_fit(fit, dat, horizons = c(90, 270, 400), group_vars = "bb", model_id = "m")
  testthat::expect_true(all(out$model_id == "m"))
  testthat::expect_true(all(is.na(out$observed_survival[out$horizon_days == 400])))
  testthat::expect_true(all(out$n_at_risk[out$horizon_days == 400] == 0))
  one <- dat[dat$bb == levels(dat$bb)[1], , drop = FALSE]
  expected <- mean(vapply(seq_len(nrow(one)), function(i) {
    sa_predict_row_survival(fit, one[i, , drop = FALSE], 90)
  }, numeric(1)))
  actual <- out$predicted_survival[out$bb == levels(dat$bb)[1] & out$horizon_days == 90]
  testthat::expect_equal(actual, expected, tolerance = 1e-10)
})

testthat::test_that("decision roots distinguish supported, beyond-support, and infinite cases", {
  dat <- make_sensitivity_test_data(n = 360)
  fit <- survival::survreg(
    survival::Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd,
    data = dat, dist = "weibull"
  )
  profile <- dat[1, c("bb", "ft", "seas", "reg", "log_fi_pd", "log_day_pd"), drop = FALSE]
  mean_life <- sa_mean_lifetime(fit, profile)
  out <- sa_decision_for_profile(
    fit, profile, ratios = c(20, mean_life), max_followup = max(dat$rd),
    support_data = dat
  )
  testthat::expect_equal(out$status[[2]], "no_finite_optimum")
  testthat::expect_equal(out$status[[1]], "finite_within_followup")
  testthat::expect_true(is.finite(out$optimum_days[[1]]))
  beyond <- sa_decision_for_profile(fit, profile, ratios = 20, max_followup = 1, support_data = dat)
  testthat::expect_equal(beyond$status, "finite_beyond_followup")
  testthat::expect_true(is.finite(beyond$optimum_days))
  # Counts use the actual joint profile cell, not the caller's artificial
  # model-support horizon.
  expected_beyond_risk <- sum(
    as.character(dat$bb) == as.character(profile$bb) &
      as.character(dat$ft) == as.character(profile$ft) &
      dat$rd >= beyond$optimum_days
  )
  testthat::expect_equal(beyond$n_at_risk_at_optimum, expected_beyond_risk)

  ll <- survival::survreg(
    survival::Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd,
    data = dat, dist = "loglogistic"
  )
  ll$scale <- 1
  infinite <- sa_decision_for_profile(ll, profile, ratios = 200, max_followup = max(dat$rd))
  testthat::expect_true(infinite$status %in% c("finite_within_followup", "finite_beyond_followup"))
  testthat::expect_true(is.finite(infinite$optimum_days))
  testthat::expect_true(is.na(out$optimum_days[[2]]))
})

testthat::test_that("decision support counts are based on matching profile strata", {
  dat <- make_sensitivity_test_data(n = 360)
  fit <- survival::survreg(
    survival::Surv(rd, event) ~ bb + ft + seas + reg,
    data = dat, dist = "weibull"
  )
  profile <- dat[1, c("bb", "ft", "seas", "reg", "log_fi_pd", "log_day_pd"), drop = FALSE]
  out <- sa_decision_for_profile(fit, profile, 20, max(dat$rd), support_data = dat)
  expected_profile <- sum(
    as.character(dat$bb) == as.character(profile$bb) &
      as.character(dat$ft) == as.character(profile$ft) &
      as.character(dat$reg) == as.character(profile$reg) &
      as.character(dat$seas) == as.character(profile$seas) &
      dat$rd >= out$optimum_days
  )
  expected_region <- sum(
    as.character(dat$bb) == as.character(profile$bb) &
      as.character(dat$ft) == as.character(profile$ft) &
      as.character(dat$reg) == as.character(profile$reg) &
      dat$rd >= out$optimum_days
  )
  testthat::expect_equal(out$n_at_risk_at_optimum, expected_region)
  testthat::expect_true("n_cameras_risk_at_optimum" %in% names(out))
  testthat::expect_equal(out$profile_n_at_risk_at_optimum, expected_profile)
})

testthat::test_that("AFT decision support reports empty categorical cells safely", {
  dat <- make_sensitivity_test_data(n = 360)
  fit <- survival::survreg(
    survival::Surv(rd, event) ~ bb + ft + seas + reg,
    data = dat, dist = "weibull"
  )
  profile <- dat[1, c("bb", "ft", "seas", "reg", "log_fi_pd", "log_day_pd"), drop = FALSE]
  support <- dat[!(
    as.character(dat$bb) == as.character(profile$bb) &
      as.character(dat$ft) == as.character(profile$ft) &
      as.character(dat$reg) == as.character(profile$reg) &
      as.character(dat$seas) == as.character(profile$seas)
  ), , drop = FALSE]
  out <- sa_decision_for_profile(fit, profile, 20, max(dat$rd), support_data = support)
  testthat::expect_equal(out$profile_support, "unobserved_profile")
  testthat::expect_equal(out$profile_n_at_risk_at_optimum, 0L)
  testthat::expect_true(is.na(out$profile_max_followup))
  testthat::expect_false(out$profile_thin_support)
})

testthat::test_that("camera root support handles an empty profile cell", {
  empty <- data.frame(rd = numeric(), camera = character())
  out <- cam_root_support(c(90, 120, Inf), empty)
  testthat::expect_named(out, c(
    "probability_beyond_followup_given_finite",
    "probability_thin_support_given_finite"
  ))
  testthat::expect_true(all(is.na(out)))
})
