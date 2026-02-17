exclusion_schema <- function() {
  c("scope", "id", "reason_code", "reason_detail", "active", "source")
}

read_exclusions <- function(path) {
  if (!file.exists(path)) {
    return(
      tibble::tibble(
        scope = character(),
        id = character(),
        reason_code = character(),
        reason_detail = character(),
        active = logical(),
        source = character()
      )
    )
  }

  ex <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  missing_cols <- setdiff(exclusion_schema(), names(ex))
  if (length(missing_cols) > 0) {
    stop(
      "Exclusions file is missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  ex %>%
    dplyr::select(dplyr::all_of(exclusion_schema())) %>%
    dplyr::mutate(
      scope = stringr::str_to_lower(as.character(scope)),
      id = as.character(id),
      reason_code = as.character(reason_code),
      reason_detail = as.character(reason_detail),
      active = as.logical(active),
      source = as.character(source)
    )
}

apply_exclusions <- function(dat, exclusions_tbl) {
  active_rules <- exclusions_tbl %>%
    dplyr::filter(active %in% TRUE) %>%
    dplyr::filter(scope %in% c("camera", "record"), !is.na(id), id != "")

  if (nrow(active_rules) == 0) {
    return(
      list(
        data = dat,
        log = tibble::tibble(
          run_id = integer(),
          camera = character(),
          scope = character(),
          id = character(),
          reason_code = character(),
          reason_detail = character(),
          source = character()
        )
      )
    )
  }

  exclusion_log <- purrr::map_dfr(
    seq_len(nrow(active_rules)),
    function(i) {
      rule <- active_rules[i, ]

      if (rule$scope[[1]] == "camera") {
        matched <- dat %>% dplyr::filter(camera %in% rule$id)
      } else {
        matched <- dat %>% dplyr::filter(run_id %in% suppressWarnings(as.integer(rule$id)))
      }

      if (nrow(matched) == 0) {
        return(tibble::tibble())
      }

      matched %>%
        dplyr::transmute(
          run_id = run_id,
          camera = camera,
          scope = rule$scope[[1]],
          id = rule$id[[1]],
          reason_code = rule$reason_code[[1]],
          reason_detail = rule$reason_detail[[1]],
          source = rule$source[[1]]
        )
    }
  ) %>%
    dplyr::distinct(run_id, .keep_all = TRUE)

  filtered <- dat %>% dplyr::anti_join(exclusion_log, by = "run_id")

  list(data = filtered, log = exclusion_log)
}
