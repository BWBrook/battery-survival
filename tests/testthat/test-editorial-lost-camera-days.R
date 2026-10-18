testthat::test_that("lost-day intervals preserve saved paired contrasts and signed limits", {
  x <- data.frame(
    family = c("weibull", "loglogistic"), interval = c(90, 120),
    alternative = "Ansmann", alternative_ft = "w", alternative_reg = "wt",
    alternative_seas = "summer", reference = "Energizer", reference_ft = "w",
    reference_reg = "ct", reference_seas = "summer",
    downtime_gap_mean = c(.02, .07), downtime_gap_low = c(-.01, .04),
    downtime_gap_high = c(.03, .09), alternative_support = "within_followup",
    reference_support = "within_followup", alternative_profile_max_followup = 150,
    reference_profile_max_followup = 200, alternative_profile_intervals_at_risk = 25,
    reference_profile_intervals_at_risk = 100,
    alternative_profile_workload_supported = TRUE, reference_profile_workload_supported = TRUE
  )
  d <- editorial_lost_camera_days(x)
  testthat::expect_equal(d$lost_days_mean, c(1.8, 8.4))
  testthat::expect_equal(d$lost_days_low, c(-.9, 4.8))
  testthat::expect_equal(d$lost_days_high, c(2.7, 10.8))
  testthat::expect_true(all(d$plotted))

  # The joint-cell bound overrides even a mistakenly permissive support label.
  x$alternative_profile_max_followup[2] <- 117
  d <- editorial_lost_camera_days(x)
  testthat::expect_equal(d$plotted, c(TRUE, FALSE))
  testthat::expect_true(all(is.na(d[2, c("lost_days_mean", "lost_days_low", "lost_days_high")])))

  # Reference support and workload support must also qualify the contrast.
  x$reference_support[1] <- "beyond_profile_followup"
  testthat::expect_false(any(editorial_lost_camera_days(x)$plotted))
  x$reference_support[1] <- "within_followup"
  x$reference_profile_workload_supported[1] <- FALSE
  testthat::expect_false(any(editorial_lost_camera_days(x)$plotted))
  testthat::expect_error(editorial_lost_camera_days(rbind(x, x[1, ])), "Duplicate")
})
