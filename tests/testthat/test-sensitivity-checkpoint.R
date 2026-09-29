checkpoint_test_design <- function() {
  n <- 12L
  d <- data.frame(
    camera = rep(paste0("c", seq_len(4L)), each = 3L),
    bb = factor(rep(c("A", "B"), length.out = n)),
    ft = factor(rep(c("i", "w"), length.out = n)),
    seas = factor(rep(c("winter", "summer"), length.out = n)),
    reg = factor(rep(c("ct", "nw"), length.out = n)),
    log_fi_pd = seq_len(n) / n,
    log_day_pd = rev(seq_len(n)) / n,
    rd = seq(30, 140, length.out = n),
    event = rep(c(1L, 0L, 1L), length.out = n)
  )
  cam_design(d)
}

checkpoint_test_config <- function(output_dir = "unused") {
  list(
    seed = 20260917L, output_dir = output_dir,
    ratios = c(20, 50), horizons = c(90, 120),
    camera = list(
      families = c("weibull", "loglogistic"), chains = 4L,
      parallel_chains = 4L, warmup = 10L, sampling = 10L,
      adapt_delta = .99, max_treedepth = 12L,
      prediction_draws = 20L, quadrature_nodes = 30L,
      intercept_mean = 5, intercept_sd = 1, beta_sd = .5,
      log_scale_mean = -1, log_scale_sd = .75, camera_sd_scale = .5
    )
  )
}

testthat::test_that("checkpoint guard permits unchanged reuse", {
  design <- checkpoint_test_design()
  cfg <- checkpoint_test_config()
  root <- tempfile("checkpoint-reuse-")
  model <- tempfile("camera-aft-", fileext = ".stan")
  file.copy(file.path(repo_root, "models/stan/camera_aft.stan"), model)
  on.exit(unlink(c(root, model), recursive = TRUE, force = TRUE), add = TRUE)

  testthat::expect_silent(checkpoint_guard(design, cfg, root, model))
  sentinel <- file.path(root, "sentinel.txt")
  writeLines("keep", sentinel)
  testthat::expect_silent(checkpoint_guard(design, cfg, root, model))
  testthat::expect_identical(readLines(sentinel), "keep")
})

testthat::test_that("changed observations with unchanged counts refuse reuse", {
  design <- checkpoint_test_design()
  cfg <- checkpoint_test_config()
  root <- tempfile("checkpoint-data-")
  model <- tempfile("camera-aft-", fileext = ".stan")
  file.copy(file.path(repo_root, "models/stan/camera_aft.stan"), model)
  on.exit(unlink(c(root, model), recursive = TRUE, force = TRUE), add = TRUE)
  checkpoint_guard(design, cfg, root, model)
  sentinel <- file.path(root, "sentinel.txt")
  writeLines("keep", sentinel)

  changed <- design
  changed$train$rd[1L] <- changed$train$rd[1L] + 1
  testthat::expect_error(
    checkpoint_guard(changed, cfg, root, model),
    "signature mismatch"
  )
  testthat::expect_identical(readLines(sentinel), "keep")
})

testthat::test_that("changed prior or Stan source refuses reuse", {
  design <- checkpoint_test_design()
  cfg <- checkpoint_test_config()
  root <- tempfile("checkpoint-settings-")
  model <- tempfile("camera-aft-", fileext = ".stan")
  file.copy(file.path(repo_root, "models/stan/camera_aft.stan"), model)
  on.exit(unlink(c(root, model), recursive = TRUE, force = TRUE), add = TRUE)
  checkpoint_guard(design, cfg, root, model)
  sentinel <- file.path(root, "sentinel.txt")
  writeLines("keep", sentinel)

  changed_cfg <- cfg
  changed_cfg$camera$beta_sd <- cfg$camera$beta_sd + .1
  testthat::expect_error(
    checkpoint_guard(design, changed_cfg, root, model),
    "signature mismatch"
  )
  write("model changed", model, append = TRUE)
  testthat::expect_error(
    checkpoint_guard(design, cfg, root, model),
    "signature mismatch"
  )
  testthat::expect_identical(readLines(sentinel), "keep")
})

testthat::test_that("changed Stan-data adapter body refuses reuse", {
  design <- checkpoint_test_design()
  cfg <- checkpoint_test_config()
  root <- tempfile("checkpoint-adapter-")
  model <- tempfile("camera-aft-", fileext = ".stan")
  file.copy(file.path(repo_root, "models/stan/camera_aft.stan"), model)
  on.exit(unlink(c(root, model), recursive = TRUE, force = TRUE), add = TRUE)
  checkpoint_guard(design, cfg, root, model)
  sentinel <- file.path(root, "sentinel.txt")
  writeLines("keep", sentinel)

  original <- get("cam_stan_data", envir = .GlobalEnv)
  on.exit(assign("cam_stan_data", original, envir = .GlobalEnv), add = TRUE)
  assign(
    "cam_stan_data",
    function(design, cfg, family, use_camera) {
      stop("test adapter mutation")
    },
    envir = .GlobalEnv
  )
  testthat::expect_error(
    checkpoint_guard(design, cfg, root, model),
    "signature mismatch"
  )
  testthat::expect_identical(readLines(sentinel), "keep")
})

testthat::test_that("legacy output without a signature is refused before fitting", {
  design <- checkpoint_test_design()
  cfg <- checkpoint_test_config()
  root <- tempfile("checkpoint-legacy-")
  dir.create(root, recursive = TRUE)
  sentinel <- file.path(root, "sentinel.txt")
  writeLines("keep", sentinel)
  on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)

  testthat::expect_error(
    cam_fit_models(
      design, cfg, file.path(root, "models"),
      model_path = file.path(repo_root, "models/stan/camera_aft.stan")
    ),
    "lacks checkpoint signature"
  )
  testthat::expect_false(file.exists(file.path(root, "models", "data.json")))
  testthat::expect_identical(readLines(sentinel), "keep")
})
