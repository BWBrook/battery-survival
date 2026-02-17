analysis_required_columns <- function() {
  c("camera", "rd", "bok", "ti", "fi", "ft", "bt", "bb", "seas", "reg")
}

read_analysis_data <- function(path) {
  if (!file.exists(path)) {
    stop("Input data file not found: ", path, call. = FALSE)
  }

  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

validate_analysis_data <- function(dat) {
  if (!inherits(dat, "data.frame")) {
    stop("Input must be a data.frame/tibble.", call. = FALSE)
  }

  required_cols <- analysis_required_columns()
  missing_cols <- setdiff(required_cols, names(dat))
  if (length(missing_cols) > 0) {
    stop(
      "Missing required columns: ", paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  out <- dplyr::as_tibble(dat) %>%
    dplyr::select(dplyr::all_of(required_cols)) %>%
    dplyr::mutate(
      run_id = dplyr::row_number(),
      camera = as.character(camera),
      rd = as.numeric(rd),
      bok = as.integer(bok),
      ti = as.numeric(ti),
      fi = as.numeric(fi),
      ft = as.character(ft),
      bt = as.character(bt),
      bb = as.character(bb),
      seas = as.character(seas),
      reg = as.character(reg)
    )

  if (nrow(out) == 0) {
    stop("Input data contains zero rows.", call. = FALSE)
  }
  if (anyNA(out$camera) || any(out$camera == "")) {
    stop("Column `camera` contains missing/empty values.", call. = FALSE)
  }
  if (anyNA(out$rd) || any(out$rd <= 0)) {
    stop("Column `rd` must be non-missing and > 0.", call. = FALSE)
  }
  if (anyNA(out$bok) || any(!out$bok %in% c(0L, 1L))) {
    stop("Column `bok` must contain only 0/1.", call. = FALSE)
  }
  if (any(out$ti < 0, na.rm = TRUE)) {
    stop("Column `ti` must be >= 0 when present.", call. = FALSE)
  }
  if (any(out$fi < 0, na.rm = TRUE)) {
    stop("Column `fi` must be >= 0 when present.", call. = FALSE)
  }
  if (any(out$fi > out$ti, na.rm = TRUE)) {
    stop("Detected rows where `fi > ti`, which violates expected data contract.", call. = FALSE)
  }

  out
}
