fit_bayesian_models <- function(dat, cfg, dependency_status = NULL) {
  dep <- dependency_status %||% check_bayesian_dependencies(cfg)
  families <- default_bayesian_families(cfg)
  backend <- dep$backend[[1]]

  if (!bayesian_enabled(cfg)) {
    return(list(
      status = tibble::tibble(
        model_family = families,
        fit_status = "disabled",
        message = "Bayesian fitting disabled in config.",
        backend = backend
      ),
      dependency_status = dep,
      fits = list()
    ))
  }

  if (!dep$has_brms[[1]]) {
    return(list(
      status = tibble::tibble(
        model_family = families,
        fit_status = "missing_brms",
        message = "Package `brms` is not installed.",
        backend = backend
      ),
      dependency_status = dep,
      fits = list()
    ))
  }

  if (backend == "cmdstanr" && (!dep$has_cmdstanr[[1]] || !dep$has_cmdstan[[1]])) {
    return(list(
      status = tibble::tibble(
        model_family = families,
        fit_status = "missing_cmdstan",
        message = "cmdstanr backend requested, but cmdstanr/cmdstan is unavailable.",
        backend = backend
      ),
      dependency_status = dep,
      fits = list()
    ))
  }

  if (nrow(dat) == 0) {
    return(list(
      status = tibble::tibble(
        model_family = families,
        fit_status = "no_data",
        message = "Training data has zero rows.",
        backend = backend
      ),
      dependency_status = dep,
      fits = list()
    ))
  }

  chains <- as.integer(cfg$bayesian$chains %||% 4L)
  cores_cfg <- as.integer(cfg$bayesian$cores %||% NA_integer_)
  threads_per_chain <- as.integer(cfg$bayesian$threads_per_chain %||% 1L)
  iter_warmup <- as.integer(cfg$bayesian$iter_warmup %||% 1000L)
  iter_sampling <- as.integer(cfg$bayesian$iter_sampling %||% 1000L)
  iter_total <- iter_warmup + iter_sampling
  adapt_delta <- as.numeric(cfg$bayesian$adapt_delta %||% 0.95)
  max_treedepth <- as.integer(cfg$bayesian$max_treedepth %||% 12L)
  seed <- as.integer(cfg$bayesian$seed %||% cfg$seed %||% 20260217L)
  refresh <- as.integer(cfg$bayesian$refresh %||% 0L)
  init <- cfg$bayesian$init %||% 0
  cores <- resolve_bayesian_cores(chains, cores_cfg)
  threads_per_chain <- max(1L, threads_per_chain)

  fit_data <- prepare_bayesian_data(dat)
  fit_formula <- make_bayesian_formula(cfg)

  fit_rows <- purrr::map(
    families,
    function(fam_name) {
      fam_obj <- tryCatch(brms::brmsfamily(fam_name), error = function(e) e)
      if (inherits(fam_obj, "error")) {
        return(list(
          family = fam_name,
          status = "bad_family",
          message = conditionMessage(fam_obj),
          fit = NULL
        ))
      }

      fit_obj <- tryCatch({
        fit_args <- list(
          formula = fit_formula,
          data = fit_data,
          family = fam_obj,
          backend = backend,
          chains = chains,
          iter = iter_total,
          warmup = iter_warmup,
          cores = cores,
          seed = seed,
          refresh = refresh,
          init = init,
          control = list(adapt_delta = adapt_delta, max_treedepth = max_treedepth)
        )
        if (threads_per_chain > 1L) {
          fit_args$threads <- brms::threading(threads = threads_per_chain)
        }
        do.call(brms::brm, fit_args)
      }, error = function(e) e)

      if (inherits(fit_obj, "error")) {
        list(
          family = fam_name,
          status = "fit_error",
          message = conditionMessage(fit_obj),
          fit = NULL
        )
      } else {
        list(
          family = fam_name,
          status = "ok",
          message = "fit completed",
          fit = fit_obj
        )
      }
    }
  )

  status_tbl <- purrr::map_dfr(
    fit_rows,
    ~tibble::tibble(
      model_family = .x$family,
      fit_status = .x$status,
      message = .x$message,
      backend = backend
    )
  )

  fits <- purrr::map(fit_rows, "fit")
  names(fits) <- purrr::map_chr(fit_rows, "family")
  fits <- purrr::compact(fits)

  list(
    status = status_tbl,
    dependency_status = dep,
    fits = fits
  )
}
