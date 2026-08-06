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
