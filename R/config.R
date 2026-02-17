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

ensure_output_dirs <- function(cfg) {
  dirs <- c(
    cfg$outputs_dir,
    cfg$figures_dir,
    cfg$tables_dir,
    cfg$qc_dir,
    cfg$models_dir,
    cfg$manuscript_output_dir
  )
  fs::dir_create(dirs)
  invisible(dirs)
}
