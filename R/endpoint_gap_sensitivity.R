# Sensitivity of recorded lifetimes and break-even values to the unobserved gap
# between a failed camera's last image and its shutdown.
#
# Assumed-gap stress test motivated by Poisson sighting-record logic. We assume
# an exponential gap law with rate lambda equal to each failed interval's
# images per recorded day divided by a rate divisor b >= 1. This empirical-rate
# proxy and its divisors do not identify the conditional shutdown distribution
# or establish actual burst sizes. Workloads and scenario covariates are held
# fixed, so this is a controlled perturbation of the response only.

gap_parse_imputations <- function(value) {
  count <- suppressWarnings(as.numeric(value))
  if (length(count) != 1L || !is.finite(count) || count < 1 ||
      count != floor(count) || count > .Machine$integer.max) {
    stop("imputation count must be a positive integer", call. = FALSE)
  }
  as.integer(count)
}

gap_impute_failure_times <- function(dat, clustering, cap_days = Inf) {
  stopifnot(all(c("rd", "event", "ti") %in% names(dat)),
            length(clustering) == 1L, is.finite(clustering), clustering >= 1,
            length(cap_days) == 1L, !is.na(cap_days))
  failed <- dat$event == 1L
  if (any(!is.finite(dat$ti[failed]) | dat$ti[failed] <= 0)) {
    stop("failed intervals need a positive image count", call. = FALSE)
  }
  rate <- dat$ti[failed] / dat$rd[failed] / clustering
  gap <- stats::rexp(sum(failed), rate)
  shifted <- pmin(dat$rd[failed] + gap, pmax(cap_days, dat$rd[failed]))
  out <- dat
  out$gap_days <- 0
  out$gap_days[failed] <- shifted - dat$rd[failed]
  out$gap_capped <- FALSE
  out$gap_capped[failed] <- dat$rd[failed] + gap > cap_days
  out$rd[failed] <- shifted
  out
}

gap_fit <- function(dat, family, maxiter = survival::survreg.control()$maxiter) {
  survival::survreg(sa_aft_formula(with_region = TRUE, scale_spec = "brand"),
                    data = dat, dist = family,
                    control = survival::survreg.control(maxiter = maxiter))
}

# Record every attempt. Only a reported convergence failure triggers a retry;
# other errors or nonfinite results are returned as unaccepted for the runner
# to stop on. The higher iteration limit changes numerical effort, not the model.
gap_fit_diagnosed <- function(dat, family, fitter = gap_fit) {
  attempt <- function(maxiter, number) {
    warnings <- character()
    error <- ""
    fit <- tryCatch(
      withCallingHandlers(
        fitter(dat, family, maxiter = maxiter),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) {
        error <<- conditionMessage(e)
        NULL
      }
    )
    convergence_code <- if (is.null(fit$convergence)) NA_integer_ else as.integer(fit$convergence)
    convergence_failure <- any(grepl("did not converge|ran out of iterations|failed to converge",
                                    warnings, ignore.case = TRUE)) ||
      (!is.na(convergence_code) && convergence_code != 0L)
    finite_parameters <- length(fit$coefficients) > 0L && all(is.finite(fit$coefficients)) &&
      length(fit$scale) > 0L && all(is.finite(fit$scale) & fit$scale > 0)
    finite_loglik <- length(fit$loglik) > 0L && all(is.finite(fit$loglik))
    finite_covariance <- length(fit$var) > 0L && all(is.finite(fit$var))
    accepted <- !nzchar(error) && !convergence_failure &&
      finite_parameters && finite_loglik && finite_covariance
    list(fit = fit, diagnostics = data.frame(
      attempt = number, maxiter = maxiter,
      iterations = if (is.null(fit$iter)) NA_integer_ else as.integer(fit$iter),
      convergence_code = convergence_code, convergence_failure = convergence_failure,
      finite_parameters = finite_parameters, finite_loglik = finite_loglik,
      finite_covariance = finite_covariance,
      warnings = paste(warnings, collapse = " | "), error = error,
      accepted = accepted
    ))
  }
  first <- attempt(survival::survreg.control()$maxiter, 1L)
  attempts <- list(first$diagnostics)
  final <- first
  if (first$diagnostics$convergence_failure) {
    final <- attempt(200L, 2L)
    attempts[[2L]] <- final$diagnostics
  }
  diagnostics <- do.call(rbind, attempts)
  diagnostics$final_attempt <- seq_len(nrow(diagnostics)) == nrow(diagnostics)
  list(fit = final$fit, diagnostics = diagnostics)
}

# Every expected imputation must pass before a scenario-family group can be
# summarised. A failed fit withholds the whole group, including its other fits.
gap_scenario_status <- function(diagnostics, imputations) {
  imputations <- gap_parse_imputations(imputations)
  stopifnot(all(c("scenario", "family", "imputation", "final_attempt",
                  "accepted", "convergence_failure") %in% names(diagnostics)))
  final <- diagnostics[diagnostics$final_attempt, , drop = FALSE]
  groups <- split(final, final[c("scenario", "family")], drop = TRUE)
  do.call(rbind, lapply(groups, function(g) {
    expected <- if (g$scenario[[1L]] == "observed") 0L else seq_len(imputations)
    complete <- !anyDuplicated(g$imputation) && setequal(g$imputation, expected)
    accepted <- !is.na(g$accepted) & g$accepted
    reasons <- character()
    if (!complete) reasons <- c(reasons, "incomplete or duplicate fit coverage")
    if (any(!accepted)) {
      reasons <- c(reasons, if (any(g$convergence_failure[!accepted], na.rm = TRUE)) {
        "non-convergence after permitted retry"
      } else "failed fit diagnostics")
    }
    data.frame(scenario = g$scenario[[1L]], family = g$family[[1L]],
      complete = complete, fits_expected = length(expected), fits_attempted = nrow(g),
      fits_accepted = sum(accepted), fits_failed = sum(!accepted),
      status = if (complete && all(accepted)) "reported" else "withheld",
      withheld_reason = paste(reasons, collapse = "; "),
      failed_imputations = paste(sort(g$imputation[!accepted]), collapse = ";"))
  }))
}

gap_attach_scenario_status <- function(dat, status) {
  key <- function(x) paste(x$scenario, x$family, sep = "\r")
  stopifnot(!anyDuplicated(key(status)))
  idx <- match(key(dat), key(status))
  stopifnot(!anyNA(idx))
  cbind(dat, status[idx, c("status", "withheld_reason"), drop = FALSE])
}

gap_downtime <- function(fit, profile, interval_days) {
  1 - sa_expected_active_days(fit, profile, interval_days) / interval_days
}

gap_threshold <- function(saving, interval_days, downtime_alt, downtime_ref) {
  gap <- interval_days * (downtime_alt - downtime_ref)
  ifelse(gap > 0, saving / gap, Inf)
}

# Pool expected additional losses before taking the ratio. The delta-method
# MCSE describes finite simulation of the assumed gaps, not sampling or
# posterior uncertainty. A single unshifted fit has no imputation MCSE.
gap_pool_expected_loss <- function(saving, extra_lost_days, imputed = TRUE) {
  stopifnot(is.numeric(saving), length(saving) == 1L,
            is.numeric(extra_lost_days), length(extra_lost_days) >= 1L,
            is.logical(imputed), length(imputed) == 1L, !is.na(imputed),
            imputed || length(extra_lost_days) == 1L)
  n <- length(extra_lost_days)
  mean_loss <- mean(extra_lost_days)
  finite_input <- is.finite(saving) && all(is.finite(extra_lost_days))
  threshold <- if (!finite_input) NA_real_ else if (mean_loss > 0) saving / mean_loss else Inf
  loss_mcse <- if (finite_input && imputed && n >= 2L) {
    stats::sd(extra_lost_days) / sqrt(n)
  } else NA_real_
  threshold_mcse <- if (is.finite(threshold) && is.finite(loss_mcse)) {
    abs(saving) * loss_mcse / mean_loss ^ 2
  } else NA_real_
  data.frame(saving = saving, extra_lost_days = mean_loss,
             pooled_threshold = threshold, n_fits = n,
             n_imputations = if (imputed) n else 0L,
             extra_lost_days_mcse = loss_mcse,
             pooled_threshold_mcse = threshold_mcse)
}

gap_break_even <- function(fit, profiles, costs, intervals = c(90, 120)) {
  white <- profiles[as.character(profiles$ft) == "w", , drop = FALSE]
  ref <- white[as.character(white$bb) == "Energizer", , drop = FALSE]
  alt <- white[as.character(white$bb) != "Energizer", , drop = FALSE]
  stopifnot(nrow(ref) == 1L, nrow(alt) >= 1L)
  price <- stats::setNames(costs$battery_cost, costs$bb)
  rows <- list()
  for (days in intervals) {
    d_ref <- gap_downtime(fit, ref, days)
    for (i in seq_len(nrow(alt))) {
      d_alt <- gap_downtime(fit, alt[i, , drop = FALSE], days)
      brand <- as.character(alt$bb[[i]])
      saving <- price[["Energizer"]] - price[[brand]]
      rows[[length(rows) + 1L]] <- data.frame(
        interval = days, alternative = brand, saving = saving,
        extra_lost_days = days * (d_alt - d_ref),
        threshold = gap_threshold(saving, days, d_alt, d_ref))
    }
  }
  do.call(rbind, rows)
}

gap_profile_frame <- function(profiles, train) {
  out <- profiles[, c("bb", "ft", "seas", "reg", "log_fi_pd", "log_day_pd")]
  for (v in c("bb", "ft", "seas", "reg")) {
    out[[v]] <- factor(out[[v]], levels = levels(train[[v]]))
  }
  out
}

gap_km_medians <- function(dat) {
  km <- survival::survfit(survival::Surv(rd, event) ~ bb, data = dat)
  tab <- summary(km)$table
  data.frame(bb = sub("^bb=", "", rownames(tab)), median = unname(tab[, "median"]))
}
