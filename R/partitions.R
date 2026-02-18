partition_defaults <- function() {
  list(
    train_regions = c("ct", "se", "nw", "wt"),
    validation_regions = c("sw"),
    descriptive_regions = c("ne"),
    testbench_regions = c("tb")
  )
}

get_partition_config <- function(cfg) {
  defaults <- partition_defaults()
  pcfg <- cfg$partitions

  if (is.null(pcfg)) {
    return(defaults)
  }

  out <- defaults
  for (nm in names(defaults)) {
    if (!is.null(pcfg[[nm]])) {
      out[[nm]] <- tolower(as.character(unlist(pcfg[[nm]], use.names = FALSE)))
    }
  }
  out
}

build_analysis_partitions <- function(dat, cfg) {
  if (!all(c("reg", "camera", "event", "rd") %in% names(dat))) {
    stop("Partitioning requires columns: reg, camera, event, rd", call. = FALSE)
  }

  pcfg <- get_partition_config(cfg)
  partition_levels <- c(
    "train_tascam",
    "validation_sw",
    "descriptive_ne",
    "testbench_tb",
    "excluded"
  )

  out <- dat %>%
    dplyr::mutate(
      reg_chr = tolower(as.character(reg)),
      partition = dplyr::case_when(
        reg_chr %in% pcfg$train_regions ~ "train_tascam",
        reg_chr %in% pcfg$validation_regions ~ "validation_sw",
        reg_chr %in% pcfg$descriptive_regions ~ "descriptive_ne",
        reg_chr %in% pcfg$testbench_regions ~ "testbench_tb",
        TRUE ~ "excluded"
      ),
      partition = factor(partition, levels = partition_levels)
    ) %>%
    dplyr::select(-reg_chr)

  summary_tbl <- out %>%
    dplyr::group_by(partition) %>%
    dplyr::summarise(
      rows = dplyr::n(),
      cameras = dplyr::n_distinct(camera),
      events = sum(event == 1, na.rm = TRUE),
      censored = sum(event == 0, na.rm = TRUE),
      event_rate = mean(event == 1, na.rm = TRUE),
      median_rd = stats::median(rd, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::arrange(partition)

  by_region_tbl <- out %>%
    dplyr::group_by(partition, reg) %>%
    dplyr::summarise(
      rows = dplyr::n(),
      cameras = dplyr::n_distinct(camera),
      events = sum(event == 1, na.rm = TRUE),
      censored = sum(event == 0, na.rm = TRUE),
      event_rate = mean(event == 1, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::arrange(partition, reg)

  definition_tbl <- tibble::tibble(
    partition = c(
      "train_tascam",
      "validation_sw",
      "descriptive_ne",
      "testbench_tb"
    ),
    regions = c(
      paste(pcfg$train_regions, collapse = ","),
      paste(pcfg$validation_regions, collapse = ","),
      paste(pcfg$descriptive_regions, collapse = ","),
      paste(pcfg$testbench_regions, collapse = ",")
    )
  )

  drop_factor_levels <- function(x) {
    if (nrow(x) == 0) {
      return(x)
    }
    x %>%
      dplyr::mutate(
        dplyr::across(
          .cols = dplyr::where(is.factor),
          .fns = droplevels
        )
      )
  }

  train <- dplyr::filter(out, partition == "train_tascam") %>% drop_factor_levels()
  validation <- dplyr::filter(out, partition == "validation_sw") %>% drop_factor_levels()
  descriptive <- dplyr::filter(out, partition == "descriptive_ne") %>% drop_factor_levels()
  testbench <- dplyr::filter(out, partition == "testbench_tb") %>% drop_factor_levels()
  field <- dplyr::filter(out, partition %in% c("train_tascam", "validation_sw", "descriptive_ne")) %>% drop_factor_levels()

  list(
    all = out,
    train = train,
    validation = validation,
    descriptive = descriptive,
    testbench = testbench,
    field = field,
    summary = summary_tbl,
    by_region = by_region_tbl,
    definition = definition_tbl
  )
}

write_partition_tables <- function(summary_tbl, by_region_tbl, definition_tbl, cfg) {
  ensure_output_dirs(cfg)

  summary_path <- fs::path(cfg$tables_dir, "partition_summary.csv")
  by_region_path <- fs::path(cfg$tables_dir, "partition_by_region.csv")
  definition_path <- fs::path(cfg$tables_dir, "partition_definition.csv")

  readr::write_csv(summary_tbl, summary_path)
  readr::write_csv(by_region_tbl, by_region_path)
  readr::write_csv(definition_tbl, definition_path)

  c(summary_path, by_region_path, definition_path)
}
