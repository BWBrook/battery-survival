render_manuscript_qmd <- function(cfg, artifact_files = character()) {
  ensure_output_dirs(cfg)
  skip_path <- fs::path(cfg$manuscript_output_dir, "manuscript_skipped.txt")

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

  if (!file.exists(cfg$manuscript_qmd)) {
    stop("Manuscript source not found: ", cfg$manuscript_qmd, call. = FALSE)
  }
  if (file.exists(skip_path)) {
    unlink(skip_path)
  }

  formats <- unlist(cfg$render_formats, use.names = FALSE)
  outputs <- character()

  for (fmt in formats) {
    output_name <- paste0(fs::path_ext_remove(fs::path_file(cfg$manuscript_qmd)), ".", fmt)
    cmd <- c(
      "render",
      cfg$manuscript_qmd,
      "--to", fmt,
      "--output-dir", cfg$manuscript_output_dir,
      "--output", output_name
    )
    out <- system2("quarto", args = cmd, stdout = TRUE, stderr = TRUE)
    rc <- attr(out, "status")
    if (is.null(rc)) {
      rc <- 0L
    }

    if (rc != 0L) {
      stop("Quarto render failed for format `", fmt, "`.\n", paste(out, collapse = "\n"), call. = FALSE)
    }

    out_file <- fs::path(cfg$manuscript_output_dir, output_name)
    outputs <- c(outputs, out_file)
  }

  outputs
}
