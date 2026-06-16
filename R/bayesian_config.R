default_bayesian_families <- function(cfg) {
  fams <- cfg$bayesian$families
  if (is.null(fams)) {
    return(c("weibull", "lognormal", "gamma"))
  }
  as.character(unlist(fams, use.names = FALSE))
}

bayesian_enabled <- function(cfg) {
  isTRUE(cfg$bayesian$enabled)
}

default_bayesian_gate <- function(cfg) {
  gate <- cfg$bayesian$gate
  if (is.null(gate)) {
    gate <- list()
  }

  list(
    rhat_max = as.numeric(gate$rhat_max %||% 1.01),
    bulk_ess_min = as.numeric(gate$bulk_ess_min %||% 400),
    max_divergences = as.integer(gate$max_divergences %||% 0L)
  )
}

resolve_bayesian_cores <- function(chains, cores_cfg = NA_integer_, available_cores = NULL) {
  chains <- max(1L, as.integer(chains %||% 1L))
  cores_cfg <- as.integer(cores_cfg %||% NA_integer_)
  available_cores <- as.integer(available_cores %||% parallel::detectCores(logical = FALSE))

  if (!is.finite(available_cores) || is.na(available_cores) || available_cores < 1L) {
    available_cores <- 1L
  }

  requested_cores <- if (!is.na(cores_cfg) && cores_cfg > 0L) cores_cfg else chains
  max(1L, min(chains, requested_cores, available_cores))
}

check_bayesian_dependencies <- function(cfg) {
  backend <- cfg$bayesian$backend %||% "cmdstanr"
  has_brms <- requireNamespace("brms", quietly = TRUE)
  has_cmdstanr <- requireNamespace("cmdstanr", quietly = TRUE)

  has_cmdstan <- FALSE
  if (has_cmdstanr) {
    has_cmdstan <- tryCatch({
      path <- cmdstanr::cmdstan_path()
      nzchar(path) && dir.exists(path)
    }, error = function(e) FALSE)
  }

  tibble::tibble(
    backend = backend,
    has_brms = has_brms,
    has_cmdstanr = has_cmdstanr,
    has_cmdstan = has_cmdstan
  )
}

make_bayesian_formula <- function(cfg) {
  formula_txt <- cfg$bayesian$formula
  if (is.null(formula_txt)) {
    formula_txt <- "rd | cens(cens) ~ bb + ft + seas + log_fi_pd + log_day_pd"
  }
  stats::as.formula(formula_txt)
}

prepare_bayesian_data <- function(dat) {
  dat %>%
    dplyr::mutate(cens = ifelse(event == 1, 0, 1))
}
