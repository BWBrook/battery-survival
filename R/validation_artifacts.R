write_validation_tables <- function(validation_detail, validation_summary, cfg) {
  ensure_output_dirs(cfg)

  detail_path <- fs::path(cfg$tables_dir, "validation_survival_detail.csv")
  summary_path <- fs::path(cfg$tables_dir, "validation_survival_summary.csv")

  readr::write_csv(validation_detail, detail_path)
  readr::write_csv(validation_summary, summary_path)

  c(detail_path, summary_path)
}

plot_validation_observed_vs_predicted <- function(validation_detail, cfg) {
  ensure_output_dirs(cfg)
  out_path <- fs::path(cfg$figures_dir, "validation_observed_vs_predicted.png")

  if (nrow(validation_detail) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate(
        "text",
        x = 0.5,
        y = 0.5,
        label = "No SW validation rows available.",
        size = 4
      ) +
      ggplot2::xlim(0, 1) +
      ggplot2::ylim(0, 1) +
      ggplot2::theme_void()

    ggplot2::ggsave(out_path, p, width = 8, height = 4.5, dpi = 300)
    return(out_path)
  }

  plot_df <- validation_detail %>%
    dplyr::filter(
      is.finite(observed_survival),
      is.finite(predicted_survival)
    )

  if (nrow(plot_df) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate(
        "text",
        x = 0.5,
        y = 0.5,
        label = "No in-support SW validation predictions available.",
        size = 4
      ) +
      ggplot2::xlim(0, 1) +
      ggplot2::ylim(0, 1) +
      ggplot2::theme_void()

    ggplot2::ggsave(out_path, p, width = 8, height = 4.5, dpi = 300)
    return(out_path)
  }

  p <- ggplot2::ggplot(
    plot_df,
    ggplot2::aes(x = observed_survival, y = predicted_survival, color = bb, shape = ft)
  ) +
    ggplot2::geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "grey50") +
    ggplot2::geom_point(size = 2.3, alpha = 0.9) +
    ggplot2::facet_wrap(~horizon_days) +
    ggplot2::scale_x_continuous(labels = scales::label_percent(accuracy = 1), limits = c(0, 1)) +
    ggplot2::scale_y_continuous(labels = scales::label_percent(accuracy = 1), limits = c(0, 1)) +
    ggplot2::labs(
      title = "AFT Validation on SW: Observed vs Predicted Survival",
      x = "Observed survival probability",
      y = "Predicted survival probability",
      color = "Battery brand",
      shape = "Flash type"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  ggplot2::ggsave(out_path, p, width = 11, height = 5.5, dpi = 300)
  out_path
}

write_testbench_tables <- function(tb_summary, cfg) {
  ensure_output_dirs(cfg)
  out_path <- fs::path(cfg$tables_dir, "testbench_summary.csv")
  readr::write_csv(tb_summary, out_path)
  out_path
}

plot_testbench_km <- function(tb_km_fit, cfg) {
  ensure_output_dirs(cfg)
  out_path <- fs::path(cfg$figures_dir, "testbench_km_by_brand.png")

  if (is.null(tb_km_fit)) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate(
        "text",
        x = 0.5,
        y = 0.5,
        label = "No testbench rows available.",
        size = 4
      ) +
      ggplot2::xlim(0, 1) +
      ggplot2::ylim(0, 1) +
      ggplot2::theme_void()

    ggplot2::ggsave(out_path, p, width = 8, height = 4.5, dpi = 300)
    return(out_path)
  }

  km_df <- broom::tidy(tb_km_fit)
  if (!"strata" %in% names(km_df)) {
    km_df$strata <- "all"
  }
  km_df <- km_df %>%
    dplyr::mutate(strata = dplyr::coalesce(as.character(strata), "all"))

  p <- ggplot2::ggplot(km_df, ggplot2::aes(x = time, y = estimate, color = strata)) +
    ggplot2::geom_step(linewidth = 0.9) +
    ggplot2::labs(
      title = "Testbench Kaplan-Meier Curves",
      x = "Run duration (days)",
      y = "Survival probability",
      color = "Battery brand"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  ggplot2::ggsave(out_path, p, width = 9, height = 5, dpi = 300)
  out_path
}
