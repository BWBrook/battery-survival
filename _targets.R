library(targets)

tar_option_set(
  packages = c(
    "broom",
    "dplyr",
    "fs",
    "ggplot2",
    "purrr",
    "readr",
    "stringr",
    "survival",
    "tibble",
    "tidyr",
    "yaml"
  ),
  format = "rds"
)

tar_source("R")

list(
  tar_target(profile_name, Sys.getenv("ANALYSIS_PROFILE", "dev"), cue = tar_cue(mode = "always")),
  tar_target(config_file, "config/analysis.yml", format = "file"),
  tar_target(cfg, read_analysis_config(profile = profile_name, path = config_file)),
  tar_target(output_dirs_ready, ensure_output_dirs(cfg)),
  tar_target(raw_data_file, cfg$data_file, format = "file"),
  tar_target(raw_data, read_analysis_data(raw_data_file)),
  tar_target(valid_data, validate_analysis_data(raw_data)),
  tar_target(feature_data, derive_features(valid_data)),
  tar_target(analysis_input, apply_profile_sample(feature_data, cfg)),
  tar_target(exclusion_file, cfg$exclusions_file, format = "file"),
  tar_target(cost_scenarios_file, cfg$cost_scenarios_file, format = "file"),
  tar_target(battery_costs_file, cfg$battery_costs_file, format = "file"),
  tar_target(exclusions_tbl, read_exclusions(exclusion_file)),
  tar_target(cost_scenarios, read_cost_scenarios(cost_scenarios_file)),
  tar_target(battery_costs, read_battery_costs(battery_costs_file)),
  tar_target(exclusion_result, apply_exclusions(analysis_input, exclusions_tbl)),
  tar_target(analysis_data, exclusion_result$data),
  tar_target(exclusion_log, exclusion_result$log),
  tar_target(qc_summary, build_qc_summary(analysis_input, analysis_data, exclusions_tbl, exclusion_log, cfg)),
  tar_target(qc_files, write_qc_tables(qc_summary, cfg), format = "file"),
  tar_target(km_fit, fit_km(analysis_data)),
  tar_target(cox_fit, fit_cox_model(analysis_data, cfg)),
  tar_target(aft_models, fit_aft_models(analysis_data, cfg)),
  tar_target(cox_diag, run_cox_diagnostics(cox_fit)),
  tar_target(cox_diag_tbl, tidy_cox_diagnostics(cox_diag)),
  tar_target(model_comparison, summarize_model_comparison(cox_fit, aft_models)),
  tar_target(cox_terms, tidy_cox_coefficients(cox_fit)),
  tar_target(aft_terms, tidy_aft_coefficients(aft_models)),
  tar_target(prediction_profiles, build_prediction_profiles(analysis_data)),
  tar_target(best_aft, choose_best_aft_model(aft_models, model_comparison)),
  tar_target(
    econ_grid,
    compute_service_interval_economics(
      aft_fit = best_aft$model,
      aft_name = best_aft$name,
      prediction_profiles = prediction_profiles,
      cost_scenarios = cost_scenarios,
      battery_costs = battery_costs,
      interval_min = cfg$economics$interval_min,
      interval_max = cfg$economics$interval_max,
      interval_by = cfg$economics$interval_by
    )
  ),
  tar_target(econ_optima, summarize_economic_optima(econ_grid)),
  tar_target(km_medians, extract_km_medians(km_fit)),
  tar_target(data_overview, summarize_data_overview(analysis_data)),
  tar_target(region_summary, summarize_region_event_rates(analysis_data)),
  tar_target(model_object_files, save_model_objects(km_fit, cox_fit, aft_models, cox_diag, cfg), format = "file"),
  tar_target(fig_km, plot_km_curves(km_fit, cfg), format = "file"),
  tar_target(fig_cox, plot_cox_hazard_ratios(cox_fit, cfg), format = "file"),
  tar_target(fig_aic, plot_model_aic(model_comparison, cfg), format = "file"),
  tar_target(fig_region_events, plot_region_event_rates(region_summary, cfg), format = "file"),
  tar_target(fig_econ_cost, plot_cost_per_active_day(econ_grid, cfg), format = "file"),
  tar_target(fig_econ_down, plot_downtime_fraction(econ_grid, cfg), format = "file"),
  tar_target(fig_econ_opt, plot_optimal_intervals(econ_optima, cfg), format = "file"),
  tar_target(model_table_files, write_model_tables(model_comparison, cox_terms, aft_terms, cfg), format = "file"),
  tar_target(
    analysis_table_files,
    write_analysis_tables(data_overview, region_summary, km_medians, cox_diag_tbl, cfg),
    format = "file"
  ),
  tar_target(econ_table_files, write_economics_tables(econ_grid, econ_optima, cfg), format = "file"),
  tar_target(
    artifact_manifest,
    write_artifact_manifest(
      cfg,
      artifact_files = c(
        qc_files,
        model_object_files,
        fig_km,
        fig_cox,
        fig_aic,
        fig_region_events,
        fig_econ_cost,
        fig_econ_down,
        fig_econ_opt,
        model_table_files,
        analysis_table_files,
        econ_table_files
      )
    ),
    format = "file"
  ),
  tar_target(
    render_manuscript,
    render_manuscript_qmd(
      cfg,
      artifact_files = c(
        qc_files,
        fig_km,
        fig_cox,
        fig_aic,
        fig_region_events,
        fig_econ_cost,
        fig_econ_down,
        fig_econ_opt,
        model_table_files,
        analysis_table_files,
        econ_table_files,
        artifact_manifest
      )
    ),
    format = "file"
  )
)
