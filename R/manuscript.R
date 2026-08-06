manuscript_relative_path <- function(path, cfg) {
  fs::path_rel(path, start = fs::path_dir(cfg$manuscript_qmd))
}

review_manuscript_env <- function(cfg) {
  review <- review_paths(cfg)
  c(
    MANUSCRIPT_BAYES_TABLES_DIR = manuscript_relative_path(review$bayesian_tables_dir, cfg),
    MANUSCRIPT_BAYES_FIGURES_DIR = manuscript_relative_path(review$bayesian_figures_dir, cfg)
  )
}

quarto_project_render_args <- function(format, output_dir) {
  c(
    "render",
    "--to", format,
    "--output-dir", output_dir,
    "--no-clean"
  )
}

render_manuscript_qmd <- function(
  cfg,
  manuscript_source = cfg$manuscript_qmd,
  artifact_files = character(),
  output_dir = cfg$manuscript_output_dir,
  extra_env = character()
) {
  ensure_output_dirs(cfg)
  fs::dir_create(output_dir)
  skip_path <- fs::path(output_dir, "manuscript_skipped.txt")

  if (!isTRUE(cfg$render_manuscript)) {
    msg <- paste(
      "Manuscript rendering skipped for profile:",
      cfg$profile,
      "\nArtifacts available:",
      length(artifact_files)
    )
    writeLines(msg, con = skip_path)
    return(skip_path)
  }

  if (!file.exists(manuscript_source)) {
    stop("Manuscript source not found: ", manuscript_source, call. = FALSE)
  }
  if (file.exists(skip_path)) {
    unlink(skip_path)
  }

  if (length(extra_env) > 0) {
    old_env <- stats::setNames(
      as.list(Sys.getenv(names(extra_env), unset = NA_character_)),
      names(extra_env)
    )

    do.call(Sys.setenv, as.list(extra_env))
    on.exit({
      for (nm in names(old_env)) {
        if (is.na(old_env[[nm]])) {
          Sys.unsetenv(nm)
        } else {
          do.call(Sys.setenv, stats::setNames(list(old_env[[nm]]), nm))
        }
      }
    }, add = TRUE)
  }

  formats <- unlist(cfg$render_formats, use.names = FALSE)
  outputs <- character()

  for (fmt in formats) {
    output_name <- paste0(fs::path_ext_remove(fs::path_file(manuscript_source)), ".", fmt)
    project_output_dir <- fs::path_dir(output_dir)
    cmd <- quarto_project_render_args(fmt, project_output_dir)
    out <- system2("quarto", args = cmd, stdout = TRUE, stderr = TRUE)
    rc <- attr(out, "status")
    if (is.null(rc)) {
      rc <- 0L
    }

    if (rc != 0L) {
      stop("Quarto render failed for format `", fmt, "`.\n", paste(out, collapse = "\n"), call. = FALSE)
    }

    out_file <- fs::path(output_dir, output_name)
    outputs <- c(outputs, out_file)
  }

  outputs
}

render_review_manuscript_qmd <- function(cfg, review_snapshot_files, artifact_files = character()) {
  review <- review_paths(cfg)

  render_manuscript_qmd(
    cfg = cfg,
    artifact_files = c(artifact_files, review_snapshot_files),
    output_dir = review$manuscript_output_dir,
    extra_env = review_manuscript_env(cfg)
  )
}
