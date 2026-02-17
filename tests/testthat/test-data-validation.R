testthat::test_that("validate_analysis_data enforces required columns", {
  bad <- tibble::tibble(camera = "a")
  testthat::expect_error(validate_analysis_data(bad), "Missing required columns")
})

testthat::test_that("derive_features creates survival-ready covariates", {
  dat <- tibble::tibble(
    camera = c("cam1", "cam2"),
    rd = c(10, 20),
    bok = c(1L, 0L),
    ti = c(100, 200),
    fi = c(40, 90),
    ft = c("w", "i"),
    bt = c("lithium", "alkaline"),
    bb = c("varta", "procell"),
    seas = c("summer", "winter"),
    reg = c("sw", "ne")
  )

  clean <- dat %>% validate_analysis_data() %>% derive_features()
  testthat::expect_equal(clean$event, c(0L, 1L))
  testthat::expect_true(all(c("fi_pd", "ti_pd", "day_pd", "log_fi_pd", "log_ti_pd", "log_day_pd") %in% names(clean)))
  testthat::expect_true(all(clean$fi_pd > 0))
})
