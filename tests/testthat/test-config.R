testthat::test_that("read_analysis_config returns requested profile", {
  cfg <- read_analysis_config(profile = "dev", path = file.path(repo_root, "config", "analysis.yml"))
  testthat::expect_equal(cfg$profile, "dev")
  testthat::expect_true(is.numeric(cfg$seed))
  testthat::expect_true(file.exists(file.path(repo_root, cfg$data_file)))
})

testthat::test_that("bayes_prod keeps the conservative production family set", {
  cfg <- read_analysis_config(profile = "bayes_prod", path = file.path(repo_root, "config", "analysis.yml"))
  testthat::expect_equal(cfg$profile, "bayes_prod")
  testthat::expect_equal(cfg$bayesian$families, c("weibull", "lognormal"))
})
