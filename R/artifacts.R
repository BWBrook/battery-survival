save_model_objects <- function(km_fit, cox_fit, aft_models, cox_diag, cfg) {
  ensure_output_dirs(cfg)

  km_path <- fs::path(cfg$models_dir, "km_fit.rds")
  cox_path <- fs::path(cfg$models_dir, "cox_fit.rds")
  aft_path <- fs::path(cfg$models_dir, "aft_models.rds")
  zph_path <- fs::path(cfg$models_dir, "cox_zph.rds")

  readr::write_rds(km_fit, km_path)
  readr::write_rds(cox_fit, cox_path)
  readr::write_rds(aft_models, aft_path)
  readr::write_rds(cox_diag, zph_path)

  c(km_path, cox_path, aft_path, zph_path)
}

plot_km_curves <- function(km_fit, cfg) {
  ensure_output_dirs(cfg)

  km_df <- broom::tidy(km_fit)
  out_path <- fs::path(cfg$figures_dir, "km_by_brand.png")

  p <- ggplot2::ggplot(km_df, ggplot2::aes(x = time, y = estimate, color = strata)) +
    ggplot2::geom_step(linewidth = 0.9) +
    ggplot2::labs(
      title = "Kaplan-Meier Survival Curves by Battery Brand",
      x = "Run Duration (days)",
      y = "Survival Probability",
      color = "Brand"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  ggplot2::ggsave(out_path, plot = p, width = 9, height = 5, dpi = 300)
  out_path
}

plot_cox_hazard_ratios <- function(cox_fit, cfg) {
  ensure_output_dirs(cfg)

  coef_df <- tidy_cox_coefficients(cox_fit) %>%
    dplyr::filter(
      !stringr::str_detect(term, "strata\\("),
      is.finite(hr),
      is.finite(hr_low),
      is.finite(hr_high),
      hr > 0,
      hr_low > 0,
      hr_high > 0
    )

  out_path <- fs::path(cfg$figures_dir, "cox_hazard_ratios.png")

  p <- ggplot2::ggplot(
    coef_df,
    ggplot2::aes(x = stats::reorder(term, hr), y = hr, ymin = hr_low, ymax = hr_high)
  ) +
    ggplot2::geom_hline(yintercept = 1, linetype = "dashed", color = "grey50") +
    ggplot2::geom_pointrange() +
    ggplot2::coord_flip() +
    ggplot2::scale_y_log10() +
    ggplot2::labs(
      title = "Cox Model Hazard Ratios",
      x = "Term",
      y = "Hazard Ratio (log scale)"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  ggplot2::ggsave(out_path, plot = p, width = 9, height = 6, dpi = 300)
  out_path
}

plot_aft_model_aic <- function(aft_model_comparison, cfg) {
  ensure_output_dirs(cfg)

  out_path <- fs::path(cfg$figures_dir, "aft_model_aic_comparison.png")

  p <- ggplot2::ggplot(
    aft_model_comparison,
    ggplot2::aes(x = stats::reorder(model, aic), y = aic)
  ) +
    ggplot2::geom_col(fill = "#2C7FB8") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "AFT Distribution Comparison by AIC",
      x = "AFT distribution",
      y = "AIC"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  ggplot2::ggsave(out_path, plot = p, width = 8, height = 4.5, dpi = 300)
  out_path
}

write_model_tables <- function(aft_model_comparison, cox_terms, aft_terms, cfg) {
  ensure_output_dirs(cfg)

  model_path <- fs::path(cfg$tables_dir, "aft_model_comparison.csv")
  cox_path <- fs::path(cfg$tables_dir, "cox_coefficients.csv")
  aft_path <- fs::path(cfg$tables_dir, "aft_coefficients.csv")

  readr::write_csv(aft_model_comparison, model_path)
  readr::write_csv(cox_terms, cox_path)
  readr::write_csv(aft_terms, aft_path)

  c(model_path, cox_path, aft_path)
}

write_analysis_tables <- function(data_overview, region_summary, km_medians, cox_diag_tbl, cfg) {
  ensure_output_dirs(cfg)

  overview_path <- fs::path(cfg$tables_dir, "data_overview.csv")
  region_path <- fs::path(cfg$tables_dir, "region_event_summary.csv")
  km_med_path <- fs::path(cfg$tables_dir, "km_median_survival_by_brand.csv")
  cox_diag_path <- fs::path(cfg$tables_dir, "cox_ph_assumption.csv")

  readr::write_csv(data_overview, overview_path)
  readr::write_csv(region_summary, region_path)
  readr::write_csv(km_medians, km_med_path)
  readr::write_csv(cox_diag_tbl, cox_diag_path)

  c(overview_path, region_path, km_med_path, cox_diag_path)
}

plot_region_event_rates <- function(region_summary, cfg) {
  ensure_output_dirs(cfg)
  out_path <- fs::path(cfg$figures_dir, "event_rate_by_region.png")

  p <- ggplot2::ggplot(
    region_summary,
    ggplot2::aes(x = stats::reorder(reg, event_rate), y = event_rate)
  ) +
    ggplot2::geom_col(fill = "#1B9E77") +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(labels = scales::label_percent(accuracy = 1)) +
    ggplot2::labs(
      title = "Observed Failure Rate by Region",
      x = "Region",
      y = "Failure Rate (event proportion)"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  ggplot2::ggsave(out_path, plot = p, width = 8, height = 4.5, dpi = 300)
  out_path
}

write_artifact_manifest <- function(cfg, artifact_files) {
  ensure_output_dirs(cfg)

  manifest_path <- fs::path(cfg$outputs_dir, "artifact_manifest.csv")
  manifest <- tibble::tibble(path = artifact_files) %>%
    dplyr::mutate(
      exists = file.exists(path),
      bytes = ifelse(exists, fs::file_size(path), NA),
      modified = ifelse(exists, as.character(file.info(path)$mtime), NA)
    )

  readr::write_csv(manifest, manifest_path)
  manifest_path
}
