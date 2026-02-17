derive_features <- function(dat) {
  dat %>%
    dplyr::mutate(
      ti = dplyr::coalesce(ti, 0),
      fi = dplyr::coalesce(fi, 0),
      event = as.integer(1 - bok),
      fi_pd = fi / rd,
      ti_pd = ti / rd,
      day_pd = pmax(ti - fi, 0) / rd,
      log_fi_pd = log1p(fi_pd),
      log_ti_pd = log1p(ti_pd),
      log_day_pd = log1p(day_pd),
      ft = factor(ft),
      bt = factor(stringr::str_to_lower(bt)),
      bb = factor(stringr::str_to_title(bb)),
      seas = factor(stringr::str_to_lower(seas)),
      reg = factor(stringr::str_to_lower(reg))
    )
}

apply_profile_sample <- function(dat, cfg) {
  sample_n <- cfg$sample_n %||% NULL
  if (is.null(sample_n) || nrow(dat) <= sample_n) {
    return(dat)
  }

  set.seed(cfg$seed)
  keep_idx <- sort(sample.int(nrow(dat), size = sample_n, replace = FALSE))
  dat[keep_idx, , drop = FALSE]
}
