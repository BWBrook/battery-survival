testthat::test_that("normal quadrature integrates standard normal moments", {
  q <- cam_normal_quadrature(30)
  testthat::expect_equal(sum(q$weights), 1, tolerance = 1e-14)
  testthat::expect_equal(sum(q$weights * q$nodes), 0, tolerance = 1e-14)
  testthat::expect_equal(sum(q$weights * q$nodes^2), 1, tolerance = 1e-12)
})

testthat::test_that("camera survival agrees with the no-random-effect laws", {
  t <- c(1, 100, 300)
  testthat::expect_equal(
    cam_survival(t, log(150), 0.8, 0, "weibull"),
    stats::pweibull(t, shape = 1 / 0.8, scale = exp(log(150)), lower.tail = FALSE),
    tolerance = 1e-12
  )
  testthat::expect_equal(
    cam_survival(t, log(150), 0.8, 0, "loglogistic"),
    stats::plogis((log(150) - log(t)) / 0.8),
    tolerance = 1e-12
  )
  testthat::expect_equal(cam_survival(0, log(150), 0.8, 0, "weibull"), 1)
  testthat::expect_equal(cam_survival(t, log(150), 0.8, 0, "weibull", 30),
    cam_survival(t, log(150), 0.8, 0, "weibull", 60), tolerance = 1e-12)
  draws <- cam_survival(180, c(log(120), log(180)), c(0.6, 0.9),
    c(0, 0.2), "weibull")
  testthat::expect_length(draws, 2)
  testthat::expect_length(cam_survival(c(120, 180), log(150), 0.8, 0, "weibull"), 2)
  testthat::expect_error(cam_survival(c(1, 2, 3), c(log(100), log(120)),
    0.8, 0, "weibull"), "one value per draw")
})

testthat::test_that("camera moments satisfy the survival integral identity", {
  mu <- log(150)
  sigma <- 0.65
  T <- 180
  active <- stats::integrate(
    function(x) cam_survival(x, mu, sigma, 0, "weibull"), 0, T
  )$value
  expected <- active - T * cam_survival(T, mu, sigma, 0, "weibull")
  testthat::expect_equal(cam_partial_moment(T, mu, sigma, 0, "weibull"), expected,
    tolerance = 1e-7)
  testthat::expect_equal(
    cam_partial_moment(T, mu, sigma, 0, "weibull"),
    exp(mu) * gamma(1 + sigma) *
      stats::pgamma(exp((log(T) - mu) / sigma), 1 + sigma),
    tolerance = 1e-12
  )
  mixed_active <- stats::integrate(
    function(x) cam_survival(x, mu, sigma, 0.35, "weibull"), 0, T
  )$value
  mixed_h <- mixed_active - T * cam_survival(T, mu, sigma, 0.35, "weibull")
  testthat::expect_equal(
    cam_partial_moment(T, mu, sigma, 0.35, "weibull"), mixed_h,
    tolerance = 2e-6
  )
})

testthat::test_that("random-effect quadrature changes the mean as expected", {
  mu <- log(150)
  sigma <- 0.8
  tau <- 0.35
  expected <- exp(mu) * gamma(1 + sigma) * exp(tau^2 / 2)
  testthat::expect_equal(cam_mean(mu, sigma, tau, "weibull"), expected,
    tolerance = 1e-12)
  testthat::expect_equal(cam_survival(180, mu, sigma, 0, "weibull"),
    cam_survival(180, mu, sigma, 0, "weibull", 60), tolerance = 1e-12)
  testthat::expect_equal(cam_survival(180, mu, sigma, tau, "weibull", 30),
    cam_survival(180, mu, sigma, tau, "weibull", 60), tolerance = 2e-8)
})

testthat::test_that("log-logistic finite and infinite means are handled", {
  mu <- log(150)
  sigma <- 0.7
  expected <- exp(mu) * pi * sigma / sin(pi * sigma)
  testthat::expect_equal(cam_mean(mu, sigma, 0, "loglogistic"), expected,
    tolerance = 1e-12)
  testthat::expect_true(is.infinite(cam_mean(mu, 1, 0, "loglogistic")))
  p <- stats::plogis((log(180) - mu) / sigma)
  testthat::expect_equal(
    cam_partial_moment(180, mu, sigma, 0, "loglogistic"),
    expected * stats::pbeta(p, 1 + sigma, 1 - sigma), tolerance = 1e-12
  )
  testthat::expect_true(is.finite(cam_partial_moment(180, mu, 1.2, 0, "loglogistic")))
})

testthat::test_that("camera optimum handles finite, infinite, and invalid roots", {
  mu <- log(220)
  sigma <- 0.8
  mean_life <- cam_mean(mu, sigma, 0, "weibull")
  root <- cam_optimum(100, mu, sigma, 0, "weibull")
  testthat::expect_true(is.finite(root))
  known_h <- function(T) {
    stats::integrate(
      function(x) stats::pweibull(x, shape = 1 / sigma,
        scale = exp(mu), lower.tail = FALSE), 0, T
    )$value - T * stats::pweibull(T, shape = 1 / sigma,
      scale = exp(mu), lower.tail = FALSE)
  }
  known_root <- stats::uniroot(function(T) known_h(T) - 100, c(1, 1e4))$root
  testthat::expect_equal(root, known_root, tolerance = 1e-4)
  testthat::expect_equal(cam_partial_moment(root, mu, sigma, 0, "weibull"),
    100, tolerance = 1e-4)
  testthat::expect_equal(known_h(root), 100, tolerance = 1e-4)
  testthat::expect_equal(cam_optimum(mean_life, mu, sigma, 0, "weibull"), Inf)
  testthat::expect_true(is.finite(cam_optimum(200, mu, 1.2, 0, "loglogistic")))
  testthat::expect_true(is.na(cam_optimum(1e8, mu, 1.2, 0, "loglogistic")))
  testthat::expect_error(cam_optimum(-1, mu, sigma, 0, "weibull"), "non-negative")
})
