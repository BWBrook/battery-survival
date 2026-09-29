make_economics_test_data <- function(n = 240, seed = 99) {
  set.seed(seed)
  tibble::tibble(
    camera = paste0("cam", seq_len(n)),
    rd = stats::runif(n, 20, 365),
    event = stats::rbinom(n, 1, 0.55),
    bb = factor(sample(c("Varta", "Procell", "Energizer"), n, replace = TRUE)),
    ft = factor(sample(c("w", "i"), n, replace = TRUE)),
    seas = factor(sample(c("summer", "autumn", "winter", "spring"), n, replace = TRUE)),
    reg = factor(sample(c("sw", "ne", "ct"), n, replace = TRUE)),
    log_fi_pd = stats::runif(n, 0, 2),
    log_day_pd = stats::runif(n, 0, 2)
  )
}

testthat::test_that("prediction profiles preserve expected covariate columns", {
  dat <- tibble::tibble(
    bb = factor(rep(c("Varta", "Procell"), each = 3)),
    ft = factor(rep(c("w", "i", "w"), 2)),
    seas = factor(c("summer", "winter", "summer", "spring", "winter", "spring")),
    reg = factor(c("sw", "ne", "sw", "ct", "ct", "ne")),
    log_fi_pd = c(0.2, 0.4, 0.3, 0.1, 0.7, 0.6),
    log_day_pd = c(0.5, 0.3, 0.2, 0.8, 0.6, 0.4)
  )

  prof <- build_prediction_profiles(dat)
  testthat::expect_true(all(c("bb", "ft", "seas", "reg", "log_fi_pd", "log_day_pd", "n_rows") %in% names(prof)))
  testthat::expect_true(nrow(prof) >= 2)
})

testthat::test_that("prediction profiles use a joint cell and an observed workload pair", {
  dat <- tibble::tibble(
    bb = factor(c("Varta", "Varta", "Varta", "Varta", "Procell", "Procell")),
    ft = factor(c("w", "w", "w", "i", "w", "w")),
    seas = factor(c("summer", "summer", "winter", "spring", "autumn", "autumn")),
    reg = factor(c("ct", "ct", "sw", "ne", "sw", "sw")),
    log_fi_pd = c(0.1, 0.3, 0.9, 0.5, 0.2, 0.4),
    log_day_pd = c(0.2, 0.6, 0.8, 0.7, 0.3, 0.9)
  )

  prof <- build_prediction_profiles(dat)
  varta_w <- dplyr::filter(prof, as.character(bb) == "Varta", as.character(ft) == "w")

  testthat::expect_equal(as.character(varta_w$seas), "summer")
  testthat::expect_equal(as.character(varta_w$reg), "ct")
  testthat::expect_equal(varta_w$log_fi_pd, 0.3)
  testthat::expect_equal(varta_w$log_day_pd, 0.6)
  testthat::expect_equal(varta_w$n_rows, 3)
  testthat::expect_equal(varta_w$n_profile_rows, 2)
  testthat::expect_equal(varta_w$profile_log_fi_median, 0.2)
  testthat::expect_true(any(
    dat$log_fi_pd == varta_w$log_fi_pd &
      dat$log_day_pd == varta_w$log_day_pd &
      as.character(dat$reg) == as.character(varta_w$reg) &
      as.character(dat$seas) == as.character(varta_w$seas)
  ))
})

testthat::test_that("joint profile selection cannot combine unobserved marginal modes", {
  dat <- tibble::tibble(
    bb = factor(rep("A", 7)), ft = factor(rep("w", 7)),
    reg = factor(c(rep("West", 3), rep("Central", 2), rep("North", 2))),
    seas = factor(c(rep("summer", 3), rep("spring", 4))),
    log_fi_pd = c(1, 2, 3, 4, 5, 6, 7),
    log_day_pd = c(7, 6, 5, 4, 3, 2, 1)
  )
  prof <- build_prediction_profiles(dat)
  testthat::expect_equal(as.character(prof$reg), "West")
  testthat::expect_equal(as.character(prof$seas), "summer")
  testthat::expect_equal(prof$n_profile_rows, 3)
})

testthat::test_that("joint profile ties are deterministic", {
  dat <- tibble::tibble(
    bb = factor(rep("A", 4)), ft = factor(rep("w", 4)),
    reg = factor(c("b", "b", "a", "a")),
    seas = factor(c("summer", "summer", "winter", "winter")),
    log_fi_pd = c(1, 2, 4, 6), log_day_pd = c(1, 2, 8, 10)
  )
  prof <- build_prediction_profiles(dat)
  testthat::expect_equal(as.character(prof$reg), "a")
  testthat::expect_equal(as.character(prof$seas), "winter")
  # Both observed pairs are equidistant from the medians; lexical workloads win.
  testthat::expect_equal(prof$log_fi_pd, 4)
  testthat::expect_equal(prof$log_day_pd, 8)
})

testthat::test_that("exact workload minimum beats a nearby lexical candidate", {
  dat <- tibble::tibble(
    bb = factor(rep("A", 3)), ft = factor(rep("w", 3)),
    reg = factor(rep("a", 3)), seas = factor(rep("summer", 3)),
    log_fi_pd = c(1 - 1e-5, 1, 2),
    log_day_pd = c(1 - 1e-5, 1, 2)
  )
  prof <- build_prediction_profiles(dat)
  testthat::expect_equal(prof$profile_log_fi_median, 1)
  testthat::expect_equal(prof$profile_log_day_median, 1)
  testthat::expect_equal(prof$log_fi_pd, 1)
  testthat::expect_equal(prof$log_day_pd, 1)
})

testthat::test_that("AFT survival interpolation stays bounded and non-increasing", {
  dat <- make_economics_test_data()

  fit <- survival::survreg(
    survival::Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd + reg,
    data = dat,
    dist = "weibull"
  )

  times <- seq(0, 360, by = 30)
  surv <- predict_survival_from_aft(
    aft_fit = fit,
    newdata_row = dat[1, c("bb", "ft", "seas", "reg", "log_fi_pd", "log_day_pd")],
    times = times
  )

  testthat::expect_true(all(is.finite(surv)))
  testthat::expect_true(all(surv >= 0 & surv <= 1))
  testthat::expect_true(all(diff(surv) <= 1e-8))
})

testthat::test_that("active-day helpers respect interval bounds", {
  times <- c(0, 10, 20, 30)
  surv <- c(1, 0.8, 0.5, 0.2)
  interval_days <- 15

  active_days <- expected_active_days(times, surv, interval_days)
  surv_at_interval <- survival_at_interval(times, surv, interval_days)

  testthat::expect_gte(active_days, 0)
  testthat::expect_lte(active_days, interval_days)
  testthat::expect_equal(surv_at_interval, 0.65)
})

testthat::test_that("interval metrics integrate survival independently of costs", {
  metrics <- compute_interval_metrics(
    times = c(0, 10, 20),
    surv = c(1, 0.5, 0),
    intervals = c(10, 20)
  )

  testthat::expect_equal(metrics$expected_active_days, c(7.5, 10))
  testthat::expect_equal(metrics$expected_downtime_days, c(2.5, 10))
  testthat::expect_equal(metrics$downtime_fraction, c(0.25, 0.5))
  testthat::expect_equal(metrics$survival_at_service, c(0.5, 0))
  testthat::expect_equal(metrics$fail_before_service, c(0.5, 1))
})

testthat::test_that("fixed-cycle economics have no interior cost optimum", {
  metrics <- compute_interval_metrics(
    times = c(0, 10, 20, 30),
    surv = c(1, 0.8, 0.5, 0.2),
    intervals = c(10, 20, 30)
  )

  battery_cost <- 40
  cost_per_active_day <- (100 + battery_cost) / metrics$expected_active_days
  scaled_cost_per_active_day <- (1000 + battery_cost) / metrics$expected_active_days

  testthat::expect_true(all(diff(cost_per_active_day) <= 1e-12))
  testthat::expect_true(all(diff(metrics$expected_downtime_days) >= -1e-12))
  testthat::expect_true(all(diff(metrics$downtime_fraction) >= -1e-12))
  testthat::expect_identical(
    which.min(cost_per_active_day),
    which.min(scaled_cost_per_active_day)
  )
})

testthat::test_that("economics grid is generated and remains valid", {
  dat <- make_economics_test_data()

  cfg <- list(
    model = list(
      aft_formula = "Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd + reg",
      aft_distributions = c("weibull", "lognormal")
    )
  )

  aft_models <- fit_aft_models(dat, cfg)

  aft_model_comparison <- tibble::tibble(
    model = c("aft_weibull", "aft_lognormal"),
    family = c("weibull", "lognormal"),
    aic = c(100, 120)
  )

  best <- choose_best_aft_model(aft_models, aft_model_comparison)
  prof <- build_prediction_profiles(dat)
  costs <- tibble::tibble(
    scenario_id = c("a", "b"),
    scenario_label = c("A", "B"),
    service_cost = c(100, 200)
  )
  batt <- tibble::tibble(
    bb = c("Varta", "Procell", "Energizer"),
    battery_cost = c(40, 20, 45)
  )

  grid <- compute_service_interval_economics(
    aft_fit = best$model,
    aft_name = best$name,
    prediction_profiles = prof,
    cost_scenarios = costs,
    battery_costs = batt,
    interval_min = 30,
    interval_max = 60,
    interval_by = 15
  )

  testthat::expect_true(nrow(grid) > 0)
  testthat::expect_true(all(c("cost_per_active_day", "downtime_fraction", "interval_days") %in% names(grid)))
  testthat::expect_true(all(grid$expected_active_days <= grid$interval_days))
  testthat::expect_true(all(grid$expected_active_days >= 0))
  testthat::expect_true(all(grid$downtime_fraction >= 0 & grid$downtime_fraction <= 1))
})

testthat::test_that("economics grid errors when battery costs are missing", {
  dat <- make_economics_test_data()

  fit <- survival::survreg(
    survival::Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd + reg,
    data = dat,
    dist = "weibull"
  )

  prof <- build_prediction_profiles(dat)
  costs <- tibble::tibble(
    scenario_id = "a",
    scenario_label = "A",
    service_cost = 100
  )
  batt <- tibble::tibble(
    bb = c("Varta", "Procell"),
    battery_cost = c(40, 20)
  )

  testthat::expect_error(
    compute_service_interval_economics(
      aft_fit = fit,
      aft_name = "weibull",
      prediction_profiles = prof,
      cost_scenarios = costs,
      battery_costs = batt,
      interval_min = 30,
      interval_max = 60,
      interval_by = 15
    ),
    "Missing battery costs"
  )
})
