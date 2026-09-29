testthat::test_that("profile support excludes other seasons in the same region", {
  d <- data.frame(
    bb = "x", ft = "w", reg = "West",
    seas = c("summer", "summer", "spring"),
    log_fi_pd = c(1, 1.2, 1.1), log_day_pd = c(.5, .7, .6),
    rd = c(130, 80, 200), camera = c(1, 2, 3)
  )
  p <- data.frame(bb = "x", ft = "w", reg = "West", seas = "summer",
                  log_fi_pd = 1, log_day_pd = .5)
  x <- profile_support_summary(120, p, d)
  testthat::expect_equal(nrow(x$regional_risk), 2)
  testthat::expect_equal(nrow(x$profile_risk), 1)
  testthat::expect_equal(x$profile_max_followup, 130)
  testthat::expect_equal(x$support, "thin")
})

testthat::test_that("workload support uses ranges rather than exact-pair matching", {
  d <- data.frame(
    bb = "x", ft = "w", reg = "West", seas = "summer",
    log_fi_pd = c(1, 2), log_day_pd = c(3, 4),
    rd = c(100, 120), camera = 1:2
  )
  inside <- data.frame(bb = "x", ft = "w", reg = "West", seas = "summer",
                       log_fi_pd = 1.5, log_day_pd = 3.5)
  outside <- inside
  outside$log_fi_pd <- 2.5
  testthat::expect_true(profile_workload_support(d, inside))
  testthat::expect_equal(profile_support_summary(90, outside, d)$support,
                         "out_of_workload_support")
})
