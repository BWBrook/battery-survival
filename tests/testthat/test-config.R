testthat::test_that("read_analysis_config returns requested profile", {
  cfg <- read_analysis_config(profile = "dev", path = file.path(repo_root, "config", "analysis.yml"))
  testthat::expect_equal(cfg$profile, "dev")
  testthat::expect_true(is.numeric(cfg$seed))
  testthat::expect_true(file.exists(file.path(repo_root, cfg$data_file)))
})
