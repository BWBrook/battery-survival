testthat::test_that("break-even formula uses paired posterior draws", {
  alt <- c(.20, .30, .10)
  ref <- c(.10, .10, .15)
  x <- management_break_even(100, 40, 52, alt, ref)

  testthat::expect_equal(x$downtime_gap, c(.10, .20, -.05))
  testthat::expect_equal(x$break_even_draws, c(1.2, .6, Inf))
  testthat::expect_equal(x$break_even, 12 / (100 * mean(c(.10, .20, -.05))))
  testthat::expect_equal(x$probability_positive_gap, 2 / 3)
  testthat::expect_equal(x$probability_no_finite_crossing, 1 / 3)

  # The plug-in value equalises posterior expected loss; below it the cheaper
  # set wins, above it the less failure-prone reference wins.
  cd <- x$break_even
  da <- mean(alt)
  dr <- mean(ref)
  loss <- function(cost, downtime, value) (80 + cost) / 100 + value * downtime
  testthat::expect_equal(loss(40, da, cd), loss(52, dr, cd))
  testthat::expect_lt(loss(40, da, cd / 2), loss(52, dr, cd / 2))
  testthat::expect_gt(loss(40, da, cd * 2), loss(52, dr, cd * 2))
})

testthat::test_that("non-positive downtime gaps preserve infinite crossing mass", {
  x <- management_break_even(120, 24, 52,
                             c(.10, .20, .50, .40),
                             c(.20, .20, .10, .50))
  testthat::expect_equal(x$probability_no_finite_crossing, .75)
  testthat::expect_equal(x$break_even_median, Inf)
  testthat::expect_equal(x$break_even_high, Inf)
  testthat::expect_true(is.finite(x$break_even))

  dominant <- management_break_even(120, 24, 52, c(.1, .2), c(.2, .3))
  testthat::expect_equal(dominant$break_even, Inf)
  testthat::expect_equal(dominant$probability_no_finite_crossing, 1)
})

testthat::test_that("break-even rejects invalid costs and downtime", {
  testthat::expect_error(management_break_even(0, 40, 52, .2, .1))
  testthat::expect_error(management_break_even(120, 52, 40, .2, .1))
  testthat::expect_error(management_break_even(120, 40, 52, 1.2, .1),
                         "probabilities")
})

testthat::test_that("profile support reports full and at-risk denominators", {
  d <- data.frame(bb = c("x", "x", "x", "x"), ft = "w",
                  reg = c("a", "a", "b", "b"),
                  seas = c("summer", "winter", "summer", "summer"),
                  rd = c(80, 120, 130, 40), camera = c(1, 1, 2, 3),
                  event = c(1, 0, 1, 0))
  p <- data.frame(bb = "x", ft = "w", reg = "a", seas = "summer")
  s <- management_profile_support(90, p, d)
  testthat::expect_equal(s$intervals, 2)
  testthat::expect_equal(s$events, 1)
  testthat::expect_equal(s$cameras, 1)
  testthat::expect_equal(s$pooled_intervals, 4)
  testthat::expect_equal(s$pooled_events, 2)
  testthat::expect_equal(s$pooled_cameras, 3)
  testthat::expect_equal(s$intervals_at_risk, 1)
  testthat::expect_equal(s$pooled_intervals_at_risk, 2)
  testthat::expect_equal(s$profile_intervals, 1)
  testthat::expect_equal(s$profile_intervals_at_risk, 0)
  testthat::expect_equal(s$support, "beyond_profile_followup")
  testthat::expect_error(management_profile_support(90, p, d[, -7]),
                         "missing required columns")
})
