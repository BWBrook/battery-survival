default_bayesian_families <- function(cfg) {
  fams <- cfg$bayesian$families
  if (is.null(fams)) {
    return(c("weibull", "lognormal", "loglogistic"))
  }
  as.character(unlist(fams, use.names = FALSE))
}

bayesian_enabled <- function(cfg) {
  isTRUE(cfg$bayesian$enabled)
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

fit_bayesian_models <- function(dat, cfg) {
  dep <- check_bayesian_dependencies(cfg)
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
  auto_cores <- parallel::detectCores(logical = FALSE)
  if (!is.finite(auto_cores) || is.na(auto_cores)) {
    auto_cores <- 1L
  }
  cores <- if (!is.na(cores_cfg) && cores_cfg > 0L) {
    min(chains, cores_cfg)
  } else {
    max(1L, min(chains, auto_cores))
  }
  threads_per_chain <- max(1L, threads_per_chain)

  fit_data <- prepare_bayesian_data(dat)
  fit_formula <- make_bayesian_formula(cfg)

  fit_rows <- purrr::map(
    families,
    function(fam_name) {
      fam_fun <- tryCatch(get(fam_name, asNamespace("brms")), error = function(e) NULL)
      if (is.null(fam_fun)) {
        return(list(
          family = fam_name,
          status = "bad_family",
          message = paste0("Unknown brms family: ", fam_name),
          fit = NULL
        ))
      }

      fit_obj <- tryCatch({
        fit_args <- list(
          formula = fit_formula,
          data = fit_data,
          family = fam_fun(),
          backend = backend,
          chains = chains,
          iter = iter_total,
          warmup = iter_warmup,
          cores = cores,
          seed = seed,
          refresh = refresh,
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

summarize_bayesian_model_comparison <- function(bayesian_result) {
  if (length(bayesian_result$fits) == 0) {
    return(bayesian_result$status %>%
      dplyr::transmute(
        model_family,
        fit_status,
        looic = NA_real_,
        rhat_max = NA_real_,
        bulk_ess_min = NA_real_,
        message
      ))
  }

  by_fit <- purrr::imap_dfr(
    bayesian_result$fits,
    function(fit_obj, fam_name) {
      looic <- tryCatch({
        loo_tbl <- brms::loo(fit_obj)
        as.numeric(loo_tbl$estimates["looic", "Estimate"])
      }, error = function(e) NA_real_)

      draw_stats <- tryCatch({
        posterior::summarise_draws(
          brms::as_draws_array(fit_obj),
          rhat = posterior::rhat,
          ess_bulk = posterior::ess_bulk
        )
      }, error = function(e) NULL)
      rhat_max <- if (is.null(draw_stats) || !"rhat" %in% names(draw_stats)) {
        NA_real_
      } else {
        max(draw_stats$rhat, na.rm = TRUE)
      }
      bulk_ess_min <- if (is.null(draw_stats) || !"ess_bulk" %in% names(draw_stats)) {
        NA_real_
      } else {
        min(draw_stats$ess_bulk, na.rm = TRUE)
      }

      tibble::tibble(
        model_family = fam_name,
        fit_status = "ok",
        looic = looic,
        rhat_max = rhat_max,
        bulk_ess_min = bulk_ess_min,
        message = "fit completed"
      )
    }
  ) %>%
    dplyr::arrange(looic)

  non_ok <- bayesian_result$status %>%
    dplyr::filter(fit_status != "ok") %>%
    dplyr::transmute(
      model_family,
      fit_status,
      looic = NA_real_,
      rhat_max = NA_real_,
      bulk_ess_min = NA_real_,
      message
    )

  dplyr::bind_rows(by_fit, non_ok)
}

tidy_bayesian_coefficients <- function(bayesian_result) {
  if (length(bayesian_result$fits) == 0) {
    return(tibble::tibble(
      model_family = character(),
      term = character(),
      estimate = numeric(),
      std_error = numeric(),
      q2.5 = numeric(),
      q97.5 = numeric(),
      time_ratio = numeric(),
      time_ratio_low = numeric(),
      time_ratio_high = numeric()
    ))
  }

  purrr::imap_dfr(
    bayesian_result$fits,
    function(fit_obj, fam_name) {
      fx <- as.data.frame(brms::fixef(fit_obj, summary = TRUE))
      fx$term <- rownames(fx)
      rownames(fx) <- NULL

      tibble::as_tibble(fx) %>%
        dplyr::transmute(
          model_family = fam_name,
          term = term,
          estimate = Estimate,
          std_error = Est.Error,
          q2.5 = Q2.5,
          q97.5 = Q97.5,
          time_ratio = exp(Estimate),
          time_ratio_low = exp(Q2.5),
          time_ratio_high = exp(Q97.5)
        )
    }
  )
}

save_bayesian_objects <- function(bayesian_result, cfg) {
  ensure_output_dirs(cfg)

  status_path <- fs::path(cfg$models_dir, "bayesian_status.rds")
  readr::write_rds(
    list(
      status = bayesian_result$status,
      dependency_status = bayesian_result$dependency_status
    ),
    status_path
  )

  fit_paths <- purrr::imap_chr(
    bayesian_result$fits,
    function(fit_obj, fam_name) {
      out_path <- fs::path(cfg$models_dir, paste0("bayes_fit_", fam_name, ".rds"))
      readr::write_rds(fit_obj, out_path)
      out_path
    }
  )

  c(status_path, fit_paths)
}

write_bayesian_tables <- function(status_tbl, comparison_tbl, coef_tbl, cfg) {
  ensure_output_dirs(cfg)

  status_path <- fs::path(cfg$tables_dir, "bayesian_status.csv")
  comp_path <- fs::path(cfg$tables_dir, "bayesian_model_comparison.csv")
  coef_path <- fs::path(cfg$tables_dir, "bayesian_coefficients.csv")

  readr::write_csv(status_tbl, status_path)
  readr::write_csv(comparison_tbl, comp_path)
  readr::write_csv(coef_tbl, coef_path)

  c(status_path, comp_path, coef_path)
}

plot_bayesian_coefficients <- function(coef_tbl, cfg) {
  ensure_output_dirs(cfg)
  out_path <- fs::path(cfg$figures_dir, "bayesian_time_ratios.png")

  if (nrow(coef_tbl) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate(
        "text",
        x = 0.5,
        y = 0.5,
        label = "Bayesian models not fitted in this run.",
        size = 4
      ) +
      ggplot2::xlim(0, 1) +
      ggplot2::ylim(0, 1) +
      ggplot2::theme_void()

    ggplot2::ggsave(out_path, p, width = 8, height = 4.5, dpi = 300)
    return(out_path)
  }

  plot_df <- coef_tbl %>%
    dplyr::filter(term != "Intercept") %>%
    dplyr::mutate(term = stringr::str_replace(term, "^b_", ""))

  p <- ggplot2::ggplot(
    plot_df,
    ggplot2::aes(
      x = stats::reorder(term, time_ratio),
      y = time_ratio,
      ymin = time_ratio_low,
      ymax = time_ratio_high,
      color = model_family
    )
  ) +
    ggplot2::geom_hline(yintercept = 1, linetype = "dashed", color = "grey50") +
    ggplot2::geom_pointrange(position = ggplot2::position_dodge(width = 0.5)) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_log10() +
    ggplot2::labs(
      title = "Bayesian AFT Time Ratios",
      x = "Term",
      y = "Time ratio (log scale)",
      color = "Model family"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  ggplot2::ggsave(out_path, p, width = 10, height = 6, dpi = 300)
  out_path
}
