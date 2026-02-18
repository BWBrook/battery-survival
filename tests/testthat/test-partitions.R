testthat::test_that("build_analysis_partitions assigns expected cohorts", {
  dat <- tibble::tibble(
    camera = paste0("cam", seq_len(8)),
    rd = c(100, 110, 120, 130, 140, 150, 160, 170),
    event = c(1L, 0L, 1L, 0L, 1L, 1L, 0L, 1L),
    reg = factor(c("ct", "se", "sw", "ne", "tb", "wt", "nw", "xx"))
  )

  cfg <- list()
  part <- build_analysis_partitions(dat, cfg)

  testthat::expect_equal(nrow(part$train), 4)
  testthat::expect_equal(nrow(part$validation), 1)
  testthat::expect_equal(nrow(part$descriptive), 1)
  testthat::expect_equal(nrow(part$testbench), 1)
  testthat::expect_equal(sum(part$all$partition == "excluded"), 1)
})

testthat::test_that("custom partition config overrides defaults", {
  dat <- tibble::tibble(
    camera = paste0("cam", seq_len(4)),
    rd = c(100, 110, 120, 130),
    event = c(1L, 0L, 1L, 0L),
    reg = factor(c("a", "b", "c", "d"))
  )

  cfg <- list(
    partitions = list(
      train_regions = c("a", "b"),
      validation_regions = c("c"),
      descriptive_regions = character(),
      testbench_regions = c("d")
    )
  )

  part <- build_analysis_partitions(dat, cfg)

  testthat::expect_equal(nrow(part$train), 2)
  testthat::expect_equal(nrow(part$validation), 1)
  testthat::expect_equal(nrow(part$testbench), 1)
})
