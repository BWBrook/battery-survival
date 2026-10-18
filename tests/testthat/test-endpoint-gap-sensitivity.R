testthat::test_that("imputation counts accept positive integers and reject invalid CLI values", {
  testthat::expect_identical(gap_parse_imputations("200"), 200L)
  testthat::expect_identical(gap_parse_imputations(1), 1L)
  for (value in list("0", "-1", "1.5", "Inf", "NaN", "", "abc", NA_real_,
                     numeric(), c(1, 2), as.double(.Machine$integer.max) + 1)) {
    testthat::expect_error(gap_parse_imputations(value), "positive integer")
  }
})

testthat::test_that("gap imputation shifts only failed intervals and respects the cap", {
  set.seed(1)
  dat <- data.frame(rd = c(100, 100, 50), event = c(1L, 0L, 1L), ti = c(100, 5, 1))
  out <- gap_impute_failure_times(dat, clustering = 3, cap_days = 120)
  testthat::expect_true(all(gap_impute_failure_times(dat, 3)$rd >= dat$rd))
  testthat::expect_equal(out$rd[2], 100)
  testthat::expect_true(all(out$rd[c(1, 3)] > dat$rd[c(1, 3)]))
  testthat::expect_true(all(out$rd <= 120))
  testthat::expect_equal(out$gap_days, out$rd - dat$rd)
  testthat::expect_error(gap_impute_failure_times(dat, clustering = 0.5, cap_days = 120))
})

testthat::test_that("mean imputed gap scales with clustering over the image rate", {
  set.seed(2)
  dat <- data.frame(rd = rep(100, 20000), event = 1L, ti = rep(50, 20000))
  g1 <- mean(gap_impute_failure_times(dat, 1, 1e6)$gap_days)
  g10 <- mean(gap_impute_failure_times(dat, 10, 1e6)$gap_days)
  testthat::expect_equal(g1, 2, tolerance = 0.05)
  testthat::expect_equal(g10, 20, tolerance = 0.05)
})

testthat::test_that("break-even threshold divides saving by additional lost days", {
  testthat::expect_equal(gap_threshold(16, 120, 0.11, 0.02), 16 / (120 * 0.09))
  testthat::expect_identical(gap_threshold(4, 90, 0.01, 0.02), Inf)
})

testthat::test_that("pooled thresholds use expected loss and propagate its Monte Carlo SE", {
  out <- gap_pool_expected_loss(12, c(2, 4))
  testthat::expect_equal(out$extra_lost_days, 3)
  testthat::expect_equal(out$pooled_threshold, 4)
  testthat::expect_false(isTRUE(all.equal(out$pooled_threshold, mean(12 / c(2, 4)))))
  testthat::expect_equal(out$extra_lost_days_mcse, 1)
  testthat::expect_equal(out$pooled_threshold_mcse, 4 / 3)
  testthat::expect_equal(out$n_fits, 2L)
  testthat::expect_equal(out$n_imputations, 2L)
})

testthat::test_that("pooled MCSE is unavailable for one fit or a nonfinite threshold", {
  baseline <- gap_pool_expected_loss(12, 3, imputed = FALSE)
  testthat::expect_equal(baseline$pooled_threshold, 4)
  testthat::expect_equal(baseline$n_fits, 1L)
  testthat::expect_equal(baseline$n_imputations, 0L)
  testthat::expect_true(is.na(baseline$extra_lost_days_mcse))
  testthat::expect_true(is.na(baseline$pooled_threshold_mcse))
  testthat::expect_true(is.na(gap_pool_expected_loss(12, 3)$pooled_threshold_mcse))
  for (loss in list(c(-1, 1), c(-3, -1))) {
    out <- gap_pool_expected_loss(12, loss)
    testthat::expect_identical(out$pooled_threshold, Inf)
    testthat::expect_true(is.na(out$pooled_threshold_mcse))
  }
  for (loss in list(c(1, Inf), c(1, NA_real_), c(1, NaN))) {
    out <- gap_pool_expected_loss(12, loss)
    testthat::expect_true(is.na(out$pooled_threshold))
    testthat::expect_true(is.na(out$pooled_threshold_mcse))
  }
  testthat::expect_true(is.na(gap_pool_expected_loss(Inf, c(2, 4))$pooled_threshold_mcse))
  testthat::expect_error(gap_pool_expected_loss(12, numeric()))
})

testthat::test_that("fit diagnostics retain default convergence warnings and one successful retry", {
  limits <- integer()
  fitter <- function(dat, family, maxiter) {
    limits <<- c(limits, maxiter)
    if (maxiter == 30L) warning("Ran out of iterations and did not converge")
    list(coefficients = c(location = 1), scale = 0.5, loglik = c(-10, -8),
         var = diag(2), iter = if (maxiter == 30L) 30L else 44L)
  }
  out <- gap_fit_diagnosed(NULL, "weibull", fitter)
  testthat::expect_equal(limits, c(30L, 200L))
  testthat::expect_equal(out$diagnostics$iterations, c(30L, 44L))
  testthat::expect_equal(out$diagnostics$convergence_failure, c(TRUE, FALSE))
  testthat::expect_equal(out$diagnostics$accepted, c(FALSE, TRUE))
  testthat::expect_equal(out$diagnostics$final_attempt, c(FALSE, TRUE))
  testthat::expect_match(out$diagnostics$warnings[[1L]], "did not converge")
  testthat::expect_identical(out$diagnostics$warnings[[2L]], "")
})

testthat::test_that("fit diagnostics reject persistent failure and nonfinite parameters", {
  good <- list(coefficients = c(location = 1), scale = 0.5,
               loglik = c(-10, -8), var = diag(2), iter = 3L)
  failed <- gap_fit_diagnosed(NULL, "weibull", function(dat, family, maxiter) {
    warning("Ran out of iterations and did not converge")
    good
  })
  testthat::expect_equal(nrow(failed$diagnostics), 2L)
  testthat::expect_false(any(failed$diagnostics$accepted))
  nonfinite <- gap_fit_diagnosed(NULL, "weibull", function(dat, family, maxiter) {
    good$coefficients <- Inf
    good
  })
  testthat::expect_equal(nrow(nonfinite$diagnostics), 1L)
  testthat::expect_false(nonfinite$diagnostics$finite_parameters)
  testthat::expect_false(nonfinite$diagnostics$accepted)
  error <- gap_fit_diagnosed(NULL, "weibull", function(dat, family, maxiter) stop("fit failed"))
  testthat::expect_false(error$diagnostics$accepted)
  testthat::expect_identical(error$diagnostics$error, "fit failed")
})

testthat::test_that("other fit warnings are retained without an unrelated retry", {
  out <- gap_fit_diagnosed(NULL, "weibull", function(dat, family, maxiter) {
    warning("other diagnostic")
    list(coefficients = c(location = 1), scale = 0.5,
         loglik = c(-10, -8), var = diag(2), iter = 3L)
  })
  testthat::expect_equal(nrow(out$diagnostics), 1L)
  testthat::expect_true(out$diagnostics$accepted)
  testthat::expect_identical(out$diagnostics$warnings, "other diagnostic")
})

testthat::test_that("one failed imputation suppresses its whole scenario-family group", {
  diagnostics <- expand.grid(scenario = c("b1", "b10"),
                             family = c("weibull", "loglogistic"),
                             imputation = 1:3, stringsAsFactors = FALSE)
  diagnostics$final_attempt <- TRUE
  diagnostics$accepted <- TRUE
  diagnostics$convergence_failure <- FALSE
  failed <- with(diagnostics, scenario == "b10" & family == "weibull" & imputation == 2)
  diagnostics$accepted[failed] <- FALSE
  diagnostics$convergence_failure[failed] <- TRUE
  status <- gap_scenario_status(diagnostics, 3)
  withheld <- status[status$status == "withheld", ]
  testthat::expect_equal(nrow(withheld), 1L)
  testthat::expect_identical(withheld$scenario, "b10")
  testthat::expect_identical(withheld$family, "weibull")
  testthat::expect_true(withheld$complete)
  testthat::expect_equal(withheld$fits_accepted, 2L)
  testthat::expect_equal(withheld$fits_failed, 1L)
  testthat::expect_identical(withheld$failed_imputations, "2")
  testthat::expect_match(withheld$withheld_reason, "non-convergence")
  raw <- diagnostics[diagnostics$accepted, c("scenario", "family", "imputation")]
  raw$value <- seq_len(nrow(raw))
  tagged <- gap_attach_scenario_status(raw, status)
  reported <- tagged[tagged$status == "reported", ]
  testthat::expect_equal(nrow(reported), 9L)
  testthat::expect_false(any(reported$scenario == "b10" & reported$family == "weibull"))
  testthat::expect_equal(sum(tagged$status == "withheld"), 2L)
  # Retry attempts do not count as additional imputations.
  prior <- diagnostics[failed, ]
  prior$final_attempt <- FALSE
  testthat::expect_equal(gap_scenario_status(rbind(prior, diagnostics), 3), status)
})

testthat::test_that("status distinguishes incomplete coverage and the unshifted baseline", {
  diagnostics <- data.frame(scenario = c("observed", "b1", "b1"),
                            family = "weibull", imputation = c(0L, 1L, 2L),
                            final_attempt = TRUE, accepted = TRUE, convergence_failure = FALSE)
  status <- gap_scenario_status(diagnostics, 3)
  baseline <- status[status$scenario == "observed", ]
  incomplete <- status[status$scenario == "b1", ]
  testthat::expect_identical(baseline$status, "reported")
  testthat::expect_equal(baseline$fits_expected, 1L)
  testthat::expect_identical(incomplete$status, "withheld")
  testthat::expect_false(incomplete$complete)
  testthat::expect_match(incomplete$withheld_reason, "incomplete")
})

testthat::test_that("break-even savings use brand names, not factor codes", {
  set.seed(3)
  n <- 400
  dat <- data.frame(
    bb = factor(rep(c("Energizer", "Varta", "Wallaby"), length.out = n)),
    ft = factor("w", levels = c("i", "w")),
    seas = factor(rep(c("summer", "winter"), length.out = n)),
    reg = factor(rep(c("ct", "se"), each = n / 2)),
    log_fi_pd = runif(n), log_day_pd = runif(n))
  base <- c(Energizer = 5.3, Varta = 5.1, Wallaby = 4.7)[as.character(dat$bb)]
  life <- exp(base + 0.2 * log(-log(runif(n))))
  dat$rd <- pmin(life, 200); dat$event <- as.integer(life < 200)
  fit <- gap_fit(dat, "weibull")
  profiles <- dat[!duplicated(dat$bb), c("bb", "ft", "seas", "reg", "log_fi_pd", "log_day_pd")]
  costs <- data.frame(bb = c("Varta", "Ansmann", "Energizer", "Wallaby"), battery_cost = c(48, 40, 52, 36))
  be <- gap_break_even(fit, profiles, costs, intervals = 120)
  testthat::expect_equal(be$saving[be$alternative == "Varta"], 4)
  testthat::expect_equal(be$saving[be$alternative == "Wallaby"], 16)
})
