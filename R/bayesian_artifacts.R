save_bayesian_objects <- function(bayesian_result, cfg) {
  ensure_output_dirs(cfg)

  status_path <- fs::path(cfg$models_dir, "bayesian_status.rds")
  readr::write_rds(
    list(
      status = bayesian_result$status,
      dependency_status = bayesian_result$dependency_status
    ),
    status_path
  )

  fit_paths <- purrr::imap_chr(
    bayesian_result$fits,
    function(fit_obj, fam_name) {
      out_path <- fs::path(cfg$models_dir, paste0("bayes_fit_", fam_name, ".rds"))
      readr::write_rds(fit_obj, out_path)
      out_path
    }
  )

  c(status_path, fit_paths)
}

snapshot_bayesian_review_artifacts <- function(table_files, figure_file, model_files, cfg) {
  if (!identical(cfg$profile, "bayes_prod")) {
    return(character())
  }

  ensure_output_dirs(cfg)
  review <- review_paths(cfg)

  src_files <- c(table_files, figure_file, model_files)
  if (length(src_files) == 0) {
    return(character())
  }

  missing <- src_files[!file.exists(src_files)]
  if (length(missing) > 0) {
    stop(
      "Cannot snapshot Bayesian production artifacts because source files are missing: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  dest_files <- vapply(
    src_files,
    function(src) {
      ext <- tolower(fs::path_ext(src))
      dir_out <- if (ext == "png") {
        review$bayesian_figures_dir
      } else if (ext == "rds") {
        review$bayesian_models_dir
      } else {
        review$bayesian_tables_dir
      }
      fs::path(dir_out, fs::path_file(src))
    },
    character(1)
  )

  fs::file_copy(src_files, dest_files, overwrite = TRUE)

  manifest <- tibble::tibble(
    source = src_files,
    path = dest_files
  ) %>%
    dplyr::mutate(
      exists = file.exists(path),
      bytes = ifelse(exists, fs::file_size(path), NA),
      modified = ifelse(exists, as.character(file.info(path)$mtime), NA)
    )

  readr::write_csv(manifest, review$bayesian_manifest_path)
  c(dest_files, review$bayesian_manifest_path)
}

required_review_bayesian_snapshot_files <- function(cfg) {
  review <- review_paths(cfg)
  manifest_path <- review$bayesian_manifest_path

  if (!file.exists(manifest_path)) {
    stop(
      "Production Bayesian review snapshot manifest not found at `",
      manifest_path,
      "`. Run `just bayes-prod` first.",
      call. = FALSE
    )
  }

  manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
  if (!all(c("path", "exists") %in% names(manifest))) {
    stop("Review snapshot manifest is missing required columns.", call. = FALSE)
  }

  required_basenames <- c(
    "bayesian_status.csv",
    "bayesian_model_comparison.csv",
    "bayesian_coefficients.csv",
    "bayesian_gate_results.csv",
    "bayesian_time_ratios.png"
  )
  missing_named <- setdiff(required_basenames, fs::path_file(manifest$path))
  if (length(missing_named) > 0) {
    stop(
      "Production Bayesian review snapshot is incomplete. Missing: ",
      paste(missing_named, collapse = ", "),
      call. = FALSE
    )
  }

  missing_paths <- manifest$path[!file.exists(manifest$path)]
  if (length(missing_paths) > 0) {
    stop(
      "Production Bayesian review snapshot paths are missing: ",
      paste(missing_paths, collapse = ", "),
      call. = FALSE
    )
  }

  c(manifest$path, manifest_path)
}

write_bayesian_tables <- function(status_tbl, comparison_tbl, coef_tbl, gate_tbl, cfg) {
  ensure_output_dirs(cfg)

  status_path <- fs::path(cfg$tables_dir, "bayesian_status.csv")
  comp_path <- fs::path(cfg$tables_dir, "bayesian_model_comparison.csv")
  coef_path <- fs::path(cfg$tables_dir, "bayesian_coefficients.csv")
  gate_path <- fs::path(cfg$tables_dir, "bayesian_gate_results.csv")

  readr::write_csv(status_tbl, status_path)
  readr::write_csv(comparison_tbl, comp_path)
  readr::write_csv(coef_tbl, coef_path)
  readr::write_csv(gate_tbl, gate_path)

  c(status_path, comp_path, coef_path, gate_path)
}

plot_bayesian_coefficients <- function(coef_tbl, cfg) {
  ensure_output_dirs(cfg)
  out_path <- fs::path(cfg$figures_dir, "bayesian_time_ratios.png")

  if (nrow(coef_tbl) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate(
        "text",
        x = 0.5,
        y = 0.5,
        label = "Bayesian models not fitted in this run.",
        size = 4
      ) +
      ggplot2::xlim(0, 1) +
      ggplot2::ylim(0, 1) +
      ggplot2::theme_void()

    ggplot2::ggsave(out_path, p, width = 8, height = 4.5, dpi = 300)
    return(out_path)
  }

  plot_df <- coef_tbl %>%
    dplyr::filter(term != "Intercept") %>%
    dplyr::mutate(term = stringr::str_replace(term, "^b_", ""))

  p <- ggplot2::ggplot(
    plot_df,
    ggplot2::aes(
      x = stats::reorder(term, time_ratio),
      y = time_ratio,
      ymin = time_ratio_low,
      ymax = time_ratio_high,
      color = model_family
    )
  ) +
    ggplot2::geom_hline(yintercept = 1, linetype = "dashed", color = "grey50") +
    ggplot2::geom_pointrange(position = ggplot2::position_dodge(width = 0.5)) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_log10() +
    ggplot2::labs(
      title = "Bayesian AFT Time Ratios",
      x = "Term",
      y = "Time ratio (log scale)",
      color = "Model family"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  ggplot2::ggsave(out_path, p, width = 10, height = 6, dpi = 300)
  out_path
}
