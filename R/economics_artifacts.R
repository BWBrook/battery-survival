write_economics_tables <- function(econ_grid, cfg) {
  ensure_output_dirs(cfg)

  grid_path <- fs::path(cfg$tables_dir, "service_interval_economics.csv")

  readr::write_csv(econ_grid, grid_path)

  grid_path
}

plot_cost_per_active_day <- function(econ_grid, cfg) {
  ensure_output_dirs(cfg)
  out_path <- fs::path(cfg$figures_dir, "cost_per_active_day_vs_interval.png")

  p <- ggplot2::ggplot(
    econ_grid,
    ggplot2::aes(x = interval_days, y = cost_per_active_day, color = bb)
  ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::facet_grid(ft ~ scenario_label, scales = "free_y") +
    ggplot2::labs(
      title = "Cost per Expected Active Day vs Service Interval",
      x = "Service interval (days)",
      y = "Cost per active camera-day",
      color = "Battery brand"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  ggplot2::ggsave(out_path, p, width = 12, height = 6.5, dpi = 300)
  out_path
}

plot_downtime_fraction <- function(econ_grid, cfg) {
  ensure_output_dirs(cfg)
  out_path <- fs::path(cfg$figures_dir, "downtime_fraction_vs_interval.png")

  p <- ggplot2::ggplot(
    econ_grid,
    ggplot2::aes(x = interval_days, y = downtime_fraction, color = bb)
  ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::facet_grid(ft ~ scenario_label) +
    ggplot2::scale_y_continuous(labels = scales::label_percent(accuracy = 1)) +
    ggplot2::labs(
      title = "Expected Downtime Fraction vs Service Interval",
      x = "Service interval (days)",
      y = "Expected downtime fraction",
      color = "Battery brand"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  ggplot2::ggsave(out_path, p, width = 12, height = 6.5, dpi = 300)
  out_path
}
