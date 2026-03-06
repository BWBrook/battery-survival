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

safe_min <- function(x) {
  if (length(x) == 0 || all(is.na(x))) {
    return(NA_real_)
  }
  min(x, na.rm = TRUE)
}

safe_sum_int <- function(x) {
  if (length(x) == 0 || all(is.na(x))) {
    return(NA_integer_)
  }
  as.integer(round(sum(x, na.rm = TRUE)))
}

compute_chain_bfmi <- function(energy) {
  e <- as.numeric(energy)
  e <- e[is.finite(e)]
  if (length(e) < 2) {
    return(NA_real_)
  }

  e_var <- stats::var(e)
  if (!is.finite(e_var) || e_var <= 0) {
    return(NA_real_)
  }

  de <- diff(e)
  mean(de^2, na.rm = TRUE) / e_var
}

summarize_sampler_diagnostics <- function(fit_obj, max_treedepth_threshold = 12L) {
  out <- tibble::tibble(
    divergences = NA_integer_,
    treedepth_saturated = NA_integer_,
    bfmi_min = NA_real_,
    elapsed_seconds = NA_real_
  )

  if (is.null(fit_obj) || is.null(fit_obj$fit)) {
    return(out)
  }

  backend_fit <- fit_obj$fit

  if (inherits(backend_fit, "stanfit")) {
    if (!requireNamespace("rstan", quietly = TRUE)) {
      return(out)
    }

    sp <- tryCatch(
      rstan::get_sampler_params(backend_fit, inc_warmup = FALSE),
      error = function(e) NULL
    )

    if (!is.null(sp) && length(sp) > 0) {
      divergences <- vapply(
        sp,
        function(x) {
          if (!"divergent__" %in% colnames(x)) NA_real_ else sum(x[, "divergent__"], na.rm = TRUE)
        },
        numeric(1)
      )
      treedepth_saturated <- vapply(
        sp,
        function(x) {
          if (!"treedepth__" %in% colnames(x)) NA_real_ else {
            sum(x[, "treedepth__"] >= max_treedepth_threshold, na.rm = TRUE)
          }
        },
        numeric(1)
      )
      bfmi_chain <- vapply(
        sp,
        function(x) {
          if (!"energy__" %in% colnames(x)) NA_real_ else compute_chain_bfmi(x[, "energy__"])
        },
        numeric(1)
      )

      out$divergences <- safe_sum_int(divergences)
      out$treedepth_saturated <- safe_sum_int(treedepth_saturated)
      out$bfmi_min <- safe_min(bfmi_chain)
    }

    elapsed <- tryCatch(rstan::get_elapsed_time(backend_fit), error = function(e) NULL)
    if (!is.null(elapsed)) {
      elapsed_vals <- as.numeric(elapsed[, "warmup"] + elapsed[, "sample"])
      out$elapsed_seconds <- if (all(!is.finite(elapsed_vals))) NA_real_ else sum(elapsed_vals, na.rm = TRUE)
    }

    return(out)
  }

  if (inherits(backend_fit, "CmdStanMCMC")) {
    diag_arr <- tryCatch(
      posterior::as_draws_array(backend_fit$sampler_diagnostics()),
      error = function(e) NULL
    )

    if (!is.null(diag_arr)) {
      diag_vars <- posterior::variables(diag_arr)

      if ("divergent__" %in% diag_vars) {
        out$divergences <- safe_sum_int(as.numeric(diag_arr[, , "divergent__"]))
      }

      if ("treedepth__" %in% diag_vars) {
        out$treedepth_saturated <- safe_sum_int(as.numeric(diag_arr[, , "treedepth__"] >= max_treedepth_threshold))
      }

      if ("energy__" %in% diag_vars) {
        energy_arr <- diag_arr[, , "energy__", drop = FALSE]
        dim_energy <- dim(energy_arr)
        if (length(dim_energy) == 3 && dim_energy[2] > 0) {
          energy_mat <- matrix(as.numeric(energy_arr), nrow = dim_energy[1], ncol = dim_energy[2])
          bfmi_chain <- apply(energy_mat, 2, compute_chain_bfmi)
          out$bfmi_min <- safe_min(bfmi_chain)
        }
      }
    }

    elapsed <- tryCatch(backend_fit$time(), error = function(e) NULL)
    if (!is.null(elapsed)) {
      if (is.numeric(elapsed$total) && length(elapsed$total) == 1) {
        out$elapsed_seconds <- as.numeric(elapsed$total)
      } else if (is.data.frame(elapsed$chains) && "total" %in% names(elapsed$chains)) {
        out$elapsed_seconds <- sum(elapsed$chains$total, na.rm = TRUE)
      }
    }
  }

  out
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
  init <- cfg$bayesian$init %||% 0
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

summarize_bayesian_model_comparison <- function(bayesian_result, cfg) {
  max_treedepth <- as.integer(cfg$bayesian$max_treedepth %||% 12L)

  if (length(bayesian_result$fits) == 0) {
    return(bayesian_result$status %>%
      dplyr::transmute(
        model_family,
        fit_status,
        looic = NA_real_,
        rhat_max = NA_real_,
        bulk_ess_min = NA_real_,
        divergences = NA_integer_,
        treedepth_saturated = NA_integer_,
        bfmi_min = NA_real_,
        elapsed_seconds = NA_real_,
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
      sampler_diag <- summarize_sampler_diagnostics(
        fit_obj = fit_obj,
        max_treedepth_threshold = max_treedepth
      )

      tibble::tibble(
        model_family = fam_name,
        fit_status = "ok",
        looic = looic,
        rhat_max = rhat_max,
        bulk_ess_min = bulk_ess_min,
        divergences = sampler_diag$divergences,
        treedepth_saturated = sampler_diag$treedepth_saturated,
        bfmi_min = sampler_diag$bfmi_min,
        elapsed_seconds = sampler_diag$elapsed_seconds,
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
      divergences = NA_integer_,
      treedepth_saturated = NA_integer_,
      bfmi_min = NA_real_,
      elapsed_seconds = NA_real_,
      message
    )

  dplyr::bind_rows(by_fit, non_ok)
}

evaluate_bayesian_gate <- function(comparison_tbl, cfg) {
  gate <- default_bayesian_gate(cfg)

  out <- comparison_tbl %>%
    dplyr::mutate(
      gate_type = "strict",
      criterion_fit_ok = fit_status == "ok",
      criterion_rhat = is.finite(rhat_max) & rhat_max <= gate$rhat_max,
      criterion_ess = is.finite(bulk_ess_min) & bulk_ess_min >= gate$bulk_ess_min,
      criterion_divergences = is.finite(divergences) & divergences <= gate$max_divergences,
      gate_pass = criterion_fit_ok & criterion_rhat & criterion_ess & criterion_divergences,
      gate_status = ifelse(gate_pass, "pass", "fail"),
      warning_treedepth = is.finite(treedepth_saturated) & treedepth_saturated > 0,
      warning_bfmi = is.finite(bfmi_min) & bfmi_min < 0.3,
      fail_reasons = purrr::pmap_chr(
        list(criterion_fit_ok, criterion_rhat, criterion_ess, criterion_divergences),
        function(f_ok, r_ok, e_ok, d_ok) {
          reasons <- character(0)
          if (!isTRUE(f_ok)) reasons <- c(reasons, "fit_status_not_ok")
          if (!isTRUE(r_ok)) reasons <- c(reasons, "rhat_threshold")
          if (!isTRUE(e_ok)) reasons <- c(reasons, "bulk_ess_threshold")
          if (!isTRUE(d_ok)) reasons <- c(reasons, "divergence_threshold")
          if (length(reasons) == 0) "none" else paste(reasons, collapse = ";")
        }
      )
    ) %>%
    dplyr::arrange(gate_status, looic)

  all_pass <- nrow(out) > 0 && all(out$gate_pass, na.rm = TRUE)
  out %>%
    dplyr::mutate(all_families_pass = all_pass, .before = 1)
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

write_bayesian_tables <- function(status_tbl, comparison_tbl, coef_tbl, gate_tbl, cfg) {
  ensure_output_dirs(cfg)

  status_path <- fs::path(cfg$tables_dir, "bayesian_status.csv")
  comp_path <- fs::path(cfg$tables_dir, "bayesian_model_comparison.csv")
  coef_path <- fs::path(cfg$tables_dir, "bayesian_coefficients.csv")
  gate_path <- fs::path(cfg$tables_dir, "bayesian_gate_results.csv")

  readr::write_csv(status_tbl, status_path)
  readr::write_csv(comparison_tbl, comp_path)
  readr::write_csv(coef_tbl, coef_path)
  readr::write_csv(gate_tbl, gate_path)

  c(status_path, comp_path, coef_path, gate_path)
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
