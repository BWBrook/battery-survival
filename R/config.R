`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

read_analysis_config <- function(
  profile = Sys.getenv("ANALYSIS_PROFILE", "dev"),
  path = "config/analysis.yml"
) {
  if (!file.exists(path)) {
    stop("Config file not found: ", path, call. = FALSE)
  }

  cfg_all <- yaml::read_yaml(path)
  if (is.null(cfg_all$default)) {
    stop("Config file must include a `default` section.", call. = FALSE)
  }

  if (!profile %in% names(cfg_all)) {
    stop(
      "Unknown analysis profile `", profile, "` in ", path,
      ". Available profiles: ", paste(setdiff(names(cfg_all), "default"), collapse = ", "),
      call. = FALSE
    )
  }

  cfg <- utils::modifyList(cfg_all$default, cfg_all[[profile]])
  cfg$profile <- profile
  cfg
}

review_paths <- function(cfg) {
  review <- cfg$review %||% list()
  review_root <- review$output_dir %||% fs::path(cfg$outputs_dir, "review")
  snapshot_dir <- review$bayesian_snapshot_dir %||% fs::path(review_root, "bayesian_snapshot")
  path_norm <- function(path) fs::path_norm(path)

  list(
    output_dir = path_norm(review_root),
    bayesian_snapshot_dir = path_norm(snapshot_dir),
    bayesian_tables_dir = path_norm(review$bayesian_tables_dir %||% fs::path(snapshot_dir, "tables")),
    bayesian_figures_dir = path_norm(review$bayesian_figures_dir %||% fs::path(snapshot_dir, "figures")),
    bayesian_models_dir = path_norm(review$bayesian_models_dir %||% fs::path(snapshot_dir, "models")),
    bayesian_manifest_path = path_norm(review$bayesian_manifest_path %||% fs::path(snapshot_dir, "manifest.csv")),
    manuscript_output_dir = path_norm(review$manuscript_output_dir %||% fs::path(review_root, "manuscript"))
  )
}

ensure_output_dirs <- function(cfg) {
  review <- review_paths(cfg)
  dirs <- c(
    cfg$outputs_dir,
    cfg$figures_dir,
    cfg$tables_dir,
    cfg$qc_dir,
    cfg$models_dir,
    cfg$manuscript_output_dir,
    review$output_dir,
    review$bayesian_snapshot_dir,
    review$bayesian_tables_dir,
    review$bayesian_figures_dir,
    review$bayesian_models_dir,
    review$manuscript_output_dir
  )
  fs::dir_create(dirs)
  invisible(dirs)
}
