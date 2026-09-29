testthat::test_that("expected-loss policy has correct analytical boundary and stationary point", {
  # Exponential mean 100: H(T) = 100[1 - exp(-T/100)(1+T/100)].
  p <- management_policy(50, 1, log(100), 1, family = "weibull")
  testthat::expect_equal(100 * (1 - exp(-p$interval / 100) * (1 + p$interval / 100)), 50, tolerance = 1e-5)
  testthat::expect_equal(management_policy(100, 1, log(100), 1, family = "weibull")$interval, Inf)
  testthat::expect_equal(management_policy(50, 0, log(100), 1, family = "weibull")$loss, 0)
  for (t in p$interval + c(-10, 10))
    testthat::expect_gt(management_loss(t, 50, 1, log(100), 1, family = "weibull")$loss, p$loss)
})

testthat::test_that("regional extrapolation is distinct from pooled support and thinness", {
  d <- data.frame(bb = "brand", ft = "i", reg = c("a", "a", "b"),
    seas = c("summer", "summer", "winter"),
    rd = c(90, 105, 122), camera = c(1, 2, 3))
  p <- data.frame(bb = "brand", ft = "i", reg = "a", seas = "summer")
  testthat::expect_equal(management_support(90, p, d)$support, "thin")
  testthat::expect_equal(management_support(120, p, d)$support, "beyond_profile_followup")
  testthat::expect_equal(management_support(123, p, d)$support, "beyond_followup")
  testthat::expect_equal(management_support(Inf, p, d)$support, "no_finite_optimum")
  testthat::expect_equal(management_support(120, p, d)$region_max_followup, 105)
})

testthat::test_that("support distinguishes an unobserved joint profile", {
  d <- data.frame(bb = "brand", ft = "w", reg = c("West", "Central"),
                  seas = c("summer", "spring"), rd = c(150, 160),
                  camera = c(1, 2))
  p <- data.frame(bb = "brand", ft = "w", reg = "West", seas = "spring")
  s <- management_support(90, p, d)
  testthat::expect_equal(s$support, "unobserved_profile")
  testthat::expect_equal(s$profile_risk, 0)
  testthat::expect_true(is.na(s$profile_max_followup))
})

testthat::test_that("posterior uncertainty is averaged before optimising", {
  mu <- log(c(50, 150))
  p <- management_policy(40, 1, mu, 1, family = "weibull")
  numeric_min <- optimize(function(t) mean(management_loss(t, 40, 1, mu, 1, family = "weibull")$loss), c(1, 500))
  testthat::expect_equal(p$interval, numeric_min$minimum, tolerance = 1e-4)
  testthat::expect_equal(p$mean_life, 100)
  testthat::expect_gt(abs(p$interval - median(cam_optimum(40, mu, 1, family = "weibull"))), .01)
  testthat::expect_error(management_policy(-1, 1, mu, 1, family = "weibull"))
})
