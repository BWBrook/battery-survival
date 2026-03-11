make_review_cfg <- function(base_dir = tempdir(), profile = "bayes_prod") {
  list(
    profile = profile,
    outputs_dir = file.path(base_dir, "outputs"),
    figures_dir = file.path(base_dir, "outputs", "figures"),
    tables_dir = file.path(base_dir, "outputs", "tables"),
    qc_dir = file.path(base_dir, "outputs", "qc"),
    models_dir = file.path(base_dir, "outputs", "models"),
    manuscript_qmd = file.path(base_dir, "manuscript", "paper.qmd"),
    manuscript_output_dir = file.path(base_dir, "outputs", "manuscript"),
    render_manuscript = TRUE,
    render_formats = c("html", "pdf"),
    review = list(
      output_dir = file.path(base_dir, "outputs", "review"),
      bayesian_snapshot_dir = file.path(base_dir, "outputs", "review", "bayesian_snapshot"),
      bayesian_tables_dir = file.path(base_dir, "outputs", "review", "bayesian_snapshot", "tables"),
      bayesian_figures_dir = file.path(base_dir, "outputs", "review", "bayesian_snapshot", "figures"),
      bayesian_models_dir = file.path(base_dir, "outputs", "review", "bayesian_snapshot", "models"),
      bayesian_manifest_path = file.path(base_dir, "outputs", "review", "bayesian_snapshot", "manifest.csv"),
      manuscript_output_dir = file.path(base_dir, "outputs", "review", "manuscript")
    )
  )
}

testthat::test_that("snapshot_bayesian_review_artifacts copies production artifacts into review paths", {
  base_dir <- file.path(tempdir(), paste0("review-snapshot-", Sys.getpid()))
  cfg <- make_review_cfg(base_dir = base_dir, profile = "bayes_prod")
  ensure_output_dirs(cfg)
  fs::dir_create(dirname(cfg$manuscript_qmd))
  writeLines("qmd", cfg$manuscript_qmd)

  status_path <- file.path(cfg$tables_dir, "bayesian_status.csv")
  comp_path <- file.path(cfg$tables_dir, "bayesian_model_comparison.csv")
  coef_path <- file.path(cfg$tables_dir, "bayesian_coefficients.csv")
  gate_path <- file.path(cfg$tables_dir, "bayesian_gate_results.csv")
  fig_path <- file.path(cfg$figures_dir, "bayesian_time_ratios.png")
  status_rds <- file.path(cfg$models_dir, "bayesian_status.rds")
  fit_rds <- file.path(cfg$models_dir, "bayes_fit_weibull.rds")

  readr::write_csv(tibble::tibble(model_family = "weibull"), status_path)
  readr::write_csv(tibble::tibble(model_family = "weibull"), comp_path)
  readr::write_csv(tibble::tibble(model_family = "weibull"), coef_path)
  readr::write_csv(tibble::tibble(model_family = "weibull"), gate_path)
  writeBin(as.raw(c(1, 2, 3, 4)), fig_path)
  readr::write_rds(list(status = "ok"), status_rds)
  readr::write_rds(list(fit = "ok"), fit_rds)

  out <- snapshot_bayesian_review_artifacts(
    table_files = c(status_path, comp_path, coef_path, gate_path),
    figure_file = fig_path,
    model_files = c(status_rds, fit_rds),
    cfg = cfg
  )

  review <- review_paths(cfg)
  expected <- c(
    file.path(review$bayesian_tables_dir, "bayesian_status.csv"),
    file.path(review$bayesian_tables_dir, "bayesian_model_comparison.csv"),
    file.path(review$bayesian_tables_dir, "bayesian_coefficients.csv"),
    file.path(review$bayesian_tables_dir, "bayesian_gate_results.csv"),
    file.path(review$bayesian_figures_dir, "bayesian_time_ratios.png"),
    file.path(review$bayesian_models_dir, "bayesian_status.rds"),
    file.path(review$bayesian_models_dir, "bayes_fit_weibull.rds"),
    review$bayesian_manifest_path
  )

  testthat::expect_setequal(out, expected)
  testthat::expect_true(all(file.exists(expected)))
})

testthat::test_that("required_review_bayesian_snapshot_files validates manifest-backed snapshot", {
  base_dir <- file.path(tempdir(), paste0("review-required-", Sys.getpid()))
  cfg <- make_review_cfg(base_dir = base_dir, profile = "full")
  ensure_output_dirs(cfg)
  fs::dir_create(dirname(cfg$manuscript_qmd))
  writeLines("qmd", cfg$manuscript_qmd)

  review <- review_paths(cfg)
  fs::dir_create(c(review$bayesian_tables_dir, review$bayesian_figures_dir, review$bayesian_models_dir))

  files <- c(
    file.path(review$bayesian_tables_dir, "bayesian_status.csv"),
    file.path(review$bayesian_tables_dir, "bayesian_model_comparison.csv"),
    file.path(review$bayesian_tables_dir, "bayesian_coefficients.csv"),
    file.path(review$bayesian_tables_dir, "bayesian_gate_results.csv"),
    file.path(review$bayesian_figures_dir, "bayesian_time_ratios.png"),
    file.path(review$bayesian_models_dir, "bayesian_status.rds")
  )

  for (path in files[grepl("\\.csv$", files)]) {
    readr::write_csv(tibble::tibble(path = basename(path)), path)
  }
  writeBin(as.raw(c(1, 2, 3, 4)), files[grepl("\\.png$", files)])
  readr::write_rds(list(status = "ok"), files[grepl("\\.rds$", files)])

  readr::write_csv(
    tibble::tibble(source = files, path = files, exists = TRUE, bytes = 1, modified = "now"),
    review$bayesian_manifest_path
  )

  out <- required_review_bayesian_snapshot_files(cfg)
  testthat::expect_true(all(file.exists(out)))
  testthat::expect_true(review$bayesian_manifest_path %in% out)
})

testthat::test_that("review_manuscript_env resolves snapshot paths relative to the manuscript source", {
  base_dir <- file.path(tempdir(), paste0("review-env-", Sys.getpid()))
  cfg <- make_review_cfg(base_dir = base_dir, profile = "full")
  fs::dir_create(dirname(cfg$manuscript_qmd))
  writeLines("qmd", cfg$manuscript_qmd)

  env <- review_manuscript_env(cfg)

  testthat::expect_equal(
    unname(env[["MANUSCRIPT_BAYES_TABLES_DIR"]]),
    "../outputs/review/bayesian_snapshot/tables"
  )
  testthat::expect_equal(
    unname(env[["MANUSCRIPT_BAYES_FIGURES_DIR"]]),
    "../outputs/review/bayesian_snapshot/figures"
  )
})
