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

testthat::test_that("economics grid and optima are generated", {
  dat <- tibble::tibble(
    camera = paste0("cam", seq_len(240)),
    rd = stats::runif(240, 20, 365),
    event = stats::rbinom(240, 1, 0.55),
    bb = factor(sample(c("Varta", "Procell", "Energizer"), 240, replace = TRUE)),
    ft = factor(sample(c("w", "i"), 240, replace = TRUE)),
    seas = factor(sample(c("summer", "autumn", "winter", "spring"), 240, replace = TRUE)),
    reg = factor(sample(c("sw", "ne", "ct"), 240, replace = TRUE)),
    log_fi_pd = stats::runif(240, 0, 2),
    log_day_pd = stats::runif(240, 0, 2)
  )

  cfg <- list(
    model = list(
      aft_formula = "Surv(rd, event) ~ bb + ft + seas + log_fi_pd + log_day_pd + reg",
      aft_distributions = c("weibull", "lognormal")
    )
  )

  aft_models <- fit_aft_models(dat, cfg)

  model_comparison <- tibble::tibble(
    model = c("aft_weibull", "aft_lognormal"),
    family = c("weibull", "lognormal"),
    aic = c(100, 120)
  )

  best <- choose_best_aft_model(aft_models, model_comparison)
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

  opt <- summarize_economic_optima(grid)

  testthat::expect_true(nrow(grid) > 0)
  testthat::expect_true(all(c("cost_per_active_day", "downtime_fraction", "interval_days") %in% names(grid)))
  testthat::expect_true(nrow(opt) > 0)
})
