testthat::test_that("tolerance interval interpolates the first crossing per draw", {
  intervals <- c(50, 60, 70, 80)
  lost <- rbind(c(0, 1.2, 4.2, 8.0),   # fractions 0, 0.02, 0.06, 0.10
                c(0, 0.6, 1.4, 2.4))   # never reaches 5%
  out <- tolerance_interval(lost, intervals, 0.05)
  testthat::expect_equal(out[1], 60 + (0.05 - 0.02) * 10 / (0.06 - 0.02))
  testthat::expect_true(is.na(out[2]))
})

testthat::test_that("lost-day summary returns means and percentile limits by interval", {
  m <- matrix(c(1, 2, 3, 4, 10, 20, 30, 40), ncol = 2)
  s <- lost_day_summary(m, c(90, 120))
  testthat::expect_equal(s$mean, c(2.5, 25))
  testthat::expect_true(all(s$low <= s$mean & s$mean <= s$high))
})

testthat::test_that("right-censored crossings retain their percentile ranks", {
  intervals <- 1:100
  crossing <- c(seq(40, 90, length.out = 99), 200)
  # A monotone downtime fraction with a known 5% crossing for each draw.
  lost <- outer(.05 / crossing, intervals^2)
  s <- tolerance_summary(lost, intervals, .05)
  testthat::expect_equal(s$share_beyond_followup, .01)
  testthat::expect_equal(s$draw_high, unname(stats::quantile(crossing, .975, type = 1)))
  testthat::expect_false(s$draw_high_beyond_followup)

  crossing[98:100] <- 200
  s <- tolerance_summary(outer(.05 / crossing, intervals^2), intervals, .05)
  testthat::expect_equal(s$share_beyond_followup, .03)
  testthat::expect_true(is.na(s$draw_high))
  testthat::expect_true(s$draw_high_beyond_followup)
  testthat::expect_false(s$mean_beyond_followup)
})

testthat::test_that("mean downtime is inverted before summarising draw crossings", {
  intervals <- 1:100
  crossing <- c(20, 40, 80)
  s <- tolerance_summary(outer(.05 / crossing, intervals^2), intervals, .05)
  testthat::expect_equal(s$interval_at_mean_downtime, 1 / mean(1 / crossing))
  testthat::expect_false(isTRUE(all.equal(s$interval_at_mean_downtime, median(crossing))))
})

testthat::test_that("lost-day support distinguishes thin joint cells from follow-up limits", {
  d <- data.frame(bb = "Varta", ft = "w", reg = "se", seas = "summer",
                  log_fi_pd = 1, log_day_pd = 1,
                  rd = c(rep(149, 20), 175), camera = seq_len(21))
  other_season <- d
  other_season$seas <- "winter"
  other_season$rd <- 200
  other_season$camera <- other_season$camera + 21L
  profile <- d[1, c("bb", "ft", "reg", "seas", "log_fi_pd", "log_day_pd")]
  s <- lost_day_support(c(149, 156, 176, NA_real_), profile, rbind(d, other_season))
  testthat::expect_equal(s$profile_intervals_at_risk, c(21L, 1L, 0L, NA_integer_))
  testthat::expect_equal(s$profile_cameras_at_risk, c(21L, 1L, 0L, NA_integer_))
  testthat::expect_equal(s$profile_max_followup, rep(175, 4))
  testthat::expect_equal(s$support,
    c("within_followup", "thin", "beyond_profile_followup", "beyond_evaluated_followup"))
})
