build_qc_summary <- function(before_data, after_data, exclusions_tbl, exclusion_log, cfg) {
  counts <- tibble::tibble(
    profile = cfg$profile,
    rows_before = nrow(before_data),
    rows_after = nrow(after_data),
    rows_removed = nrow(before_data) - nrow(after_data),
    cameras_before = dplyr::n_distinct(before_data$camera),
    cameras_after = dplyr::n_distinct(after_data$camera),
    cameras_removed = dplyr::n_distinct(before_data$camera) - dplyr::n_distinct(after_data$camera)
  )

  configured_reasons <- exclusions_tbl %>%
    dplyr::filter(active %in% TRUE) %>%
    dplyr::count(reason_code, name = "configured_rules")

  applied_reasons <- exclusion_log %>%
    dplyr::count(reason_code, name = "rows_removed")

  reason_summary <- configured_reasons %>%
    dplyr::full_join(applied_reasons, by = "reason_code") %>%
    dplyr::mutate(
      configured_rules = tidyr::replace_na(configured_rules, 0L),
      rows_removed = tidyr::replace_na(rows_removed, 0L)
    ) %>%
    dplyr::arrange(dplyr::desc(rows_removed), reason_code)

  list(
    counts = counts,
    reason_summary = reason_summary,
    exclusion_log = exclusion_log
  )
}

write_qc_tables <- function(qc_summary, cfg) {
  ensure_output_dirs(cfg)

  counts_path <- fs::path(cfg$qc_dir, "qc_counts.csv")
  reason_path <- fs::path(cfg$qc_dir, "qc_reason_summary.csv")
  log_path <- fs::path(cfg$qc_dir, "qc_exclusion_log.csv")

  readr::write_csv(qc_summary$counts, counts_path)
  readr::write_csv(qc_summary$reason_summary, reason_path)
  readr::write_csv(qc_summary$exclusion_log, log_path)

  c(counts_path, reason_path, log_path)
}
