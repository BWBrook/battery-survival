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
