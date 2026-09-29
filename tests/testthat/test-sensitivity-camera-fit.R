testthat::test_that("centred camera design preserves the survreg linear predictor and likelihood", {
  set.seed(20260917)
  n <- 240
  d <- data.frame(camera = rep(paste0("c", 1:40), each = 6),
    bb = factor(rep(c("A", "B"), n/2)), ft = factor(sample(c("i", "w"), n, TRUE)),
    seas = factor(sample(c("winter", "summer"), n, TRUE)),
    reg = factor(sample(c("ct", "nw"), n, TRUE)),
    log_fi_pd = runif(n), log_day_pd = runif(n))
  life <- rweibull(n, 3, 170)
  d$rd <- pmin(life, 190)
  d$event <- as.integer(life <= 190)
  design <- cam_design(d)
  for (family in c("weibull", "loglogistic")) {
    fit <- survival::survreg(sa_aft_formula(TRUE, "brand"), data = d, dist = family)
    b <- fit$coefficients[design$columns]
    alpha <- unname(fit$coefficients["(Intercept)"] + sum(b * design$centres))
    eta <- alpha + as.numeric(cam_new_design(design, d) %*% b)
    testthat::expect_equal(eta, unname(predict(fit, d, type = "lp")), tolerance = 1e-12)
    sigma <- unname(fit$scale[as.character(d$bb)])
    testthat::expect_equal(cam_loglik(eta, sigma, d$rd, d$event, family),
                           as.numeric(logLik(fit)), tolerance = 1e-9)
  }
  bad <- d[1, ]
  bad$reg <- "sw"
  testthat::expect_error(cam_new_design(design, bad), "unsupported factor")
})

testthat::test_that("decision intervals preserve infinite posterior mass", {
  testthat::expect_equal(unname(cam_interval(c(rep(150, 90), rep(Inf, 10)))), c(150, 150, Inf))
})

testthat::test_that("support probabilities do not conflate absent and extrapolated optima", {
  d <- data.frame(rd = c(100, 150, 200), camera = c("a", "b", "c"))
  p <- cam_root_support(c(50, 250, Inf), d, min_intervals = 2, min_cameras = 2)
  testthat::expect_equal(unname(p), c(.5, .5))
  testthat::expect_true(all(is.na(cam_root_support(c(Inf, Inf), d))))
})

testthat::test_that("posterior extraction yields scalar vectors and coefficient matrices", {
  testthat::skip_if_not_installed("posterior")
  vars <- c("alpha", "beta[1]", "beta[2]", "sigma[1]", "tau[1]")
  a <- array(seq_len(20 * 4 * length(vars)), dim = c(20, 4, length(vars)),
             dimnames = list(iteration = NULL, chain = NULL, variable = vars))
  fake <- list(draws = function(...) posterior::as_draws_array(a))
  x <- cam_extract_draws(fake, list(columns = c("a", "b"), brands = "A"), n = 8)
  testthat::expect_null(dim(x$alpha))
  testthat::expect_null(dim(x$tau))
  testthat::expect_equal(dim(x$beta), c(8L, 2L))
  testthat::expect_equal(dim(x$sigma), c(8L, 1L))
  testthat::expect_equal(dim(x$beta %*% matrix(1, 2, 3) + x$alpha), c(8L, 3L))
})
