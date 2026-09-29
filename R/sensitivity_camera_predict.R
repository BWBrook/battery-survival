# Analytic and quadrature predictions for the camera-level AFT sensitivity.
#
# The AFT location is on log lifetime.  A camera effect is a normal additive
# shift on that scale, with standard deviation tau.  These helpers use only
# base R so that posterior-draw summaries do not require a modelling package.

cam_validate_family <- function(family) {
  if (length(family) != 1L || is.na(family)) {
    stop("family must be one scalar value", call. = FALSE)
  }
  family <- tolower(as.character(family))
  if (!family %in% c("weibull", "loglogistic")) {
    stop("family must be weibull or loglogistic", call. = FALSE)
  }
  family
}

cam_recycle <- function(...) {
  values <- list(...)
  lengths <- vapply(values, length, integer(1))
  if (any(lengths == 0L)) stop("prediction inputs cannot be empty", call. = FALSE)
  n <- max(lengths)
  if (any(!lengths %in% c(1L, n))) {
    stop("prediction vectors must have a common length or be scalar", call. = FALSE)
  }
  lapply(values, rep, length.out = n)
}

cam_check_draws <- function(mu, sigma, tau) {
  draws <- cam_recycle(mu, sigma, tau)
  names(draws) <- c("mu", "sigma", "tau")
  if (any(!is.finite(unlist(draws)))) {
    stop("mu, sigma, and tau must be finite", call. = FALSE)
  }
  if (any(draws$sigma <= 0)) {
    stop("sigma must be positive", call. = FALSE)
  }
  if (any(draws$tau < 0)) {
    stop("tau must be non-negative", call. = FALSE)
  }
  draws
}

cam_check_times <- function(x, label) {
  if (length(x) == 0L || any(!is.finite(x)) || any(x < 0)) {
    stop(label, " must be finite and non-negative", call. = FALSE)
  }
  as.numeric(x)
}

cam_prepare_prediction <- function(x, mu, sigma, tau, label) {
  draws <- cam_check_draws(mu, sigma, tau)
  x <- cam_check_times(x, label)
  n_draw <- length(draws$mu)
  if (length(x) != 1L && n_draw != 1L && length(x) != n_draw) {
    stop(label, " must be scalar or have one value per draw", call. = FALSE)
  }
  n <- max(length(x), n_draw)
  list(
    x = rep(x, length.out = n),
    mu = rep(draws$mu, length.out = n),
    sigma = rep(draws$sigma, length.out = n),
    tau = rep(draws$tau, length.out = n)
  )
}

# Nodes and weights for expectations under a standard normal distribution.
cam_normal_quadrature <- function(n = 30L) {
  if (length(n) != 1L || !is.finite(n) || n < 1 || n != as.integer(n)) {
    stop("n must be a positive integer", call. = FALSE)
  }
  n <- as.integer(n)
  jacobi <- matrix(0, nrow = n, ncol = n)
  if (n > 1L) {
    offdiag <- sqrt(seq_len(n - 1L))
    jacobi[cbind(seq_len(n - 1L), seq_len(n - 1L) + 1L)] <- offdiag
    jacobi[cbind(seq_len(n - 1L) + 1L, seq_len(n - 1L))] <- offdiag
  }
  eig <- eigen(jacobi, symmetric = TRUE)
  ord <- order(eig$values)
  list(nodes = as.numeric(eig$values[ord]), weights = eig$vectors[1L, ord]^2)
}

cam_conditional_survival <- function(t, eta, sigma, family) {
  values <- cam_recycle(as.numeric(t), as.numeric(eta), as.numeric(sigma))
  t <- values[[1]]
  eta <- values[[2]]
  sigma <- values[[3]]
  z <- (log(t) - eta) / sigma
  if (identical(family, "weibull")) return(exp(-exp(pmin(z, 700))))
  stats::plogis(-z)
}

cam_conditional_partial <- function(T, eta, sigma, family) {
  values <- cam_recycle(as.numeric(T), as.numeric(eta), as.numeric(sigma))
  T <- values[[1]]
  eta <- values[[2]]
  sigma <- values[[3]]
  z <- (log(T) - eta) / sigma
  out <- numeric(length(T))
  if (identical(family, "weibull")) {
    # For very large z, exp(z) is unnecessary because the gamma CDF is one.
    x <- exp(pmin(z, log(.Machine$double.xmax)))
    return(exp(eta) * gamma(1 + sigma) * stats::pgamma(x, 1 + sigma))
  }
  finite <- sigma < 1 & T > 0
  if (any(finite)) {
    p <- stats::plogis(z[finite])
    out[finite] <- exp(eta[finite]) * pi * sigma[finite] / sin(pi * sigma[finite]) *
      stats::pbeta(p, 1 + sigma[finite], 1 - sigma[finite])
  }
  # The log-logistic mean is infinite here, but its finite-T partial moment is
  # well-defined.  Integrate on log time to avoid the singular lower endpoint.
  numeric <- which(sigma >= 1 & T > 0)
  for (i in numeric) {
    active <- stats::integrate(
      function(log_t) exp(log_t) * cam_conditional_survival(
        exp(log_t), eta[i], sigma[i], family
      ), lower = -Inf, upper = log(T[i]), rel.tol = 1e-8
    )$value
    out[i] <- active - T[i] * cam_conditional_survival(T[i], eta[i], sigma[i], family)
  }
  out
}

cam_survival_values <- function(t, mu, sigma, tau, family, quad) {
  out <- numeric(length(mu))
  no_effect <- tau == 0
  if (any(no_effect)) {
    out[no_effect] <- cam_conditional_survival(
      t[no_effect], mu[no_effect], sigma[no_effect], family
    )
  }
  mixed <- which(!no_effect)
  if (length(mixed)) {
    out[mixed] <- 0
    for (j in seq_along(quad$nodes)) {
      out[mixed] <- out[mixed] + quad$weights[j] * cam_conditional_survival(
        t[mixed], mu[mixed] + tau[mixed] * quad$nodes[j], sigma[mixed], family
      )
    }
  }
  out
}

cam_partial_values <- function(T, mu, sigma, tau, family, quad) {
  out <- numeric(length(mu))
  no_effect <- tau == 0
  if (any(no_effect)) {
    out[no_effect] <- cam_conditional_partial(
      T[no_effect], mu[no_effect], sigma[no_effect], family
    )
  }
  mixed <- which(!no_effect)
  if (length(mixed)) {
    out[mixed] <- 0
    for (j in seq_along(quad$nodes)) {
      out[mixed] <- out[mixed] + quad$weights[j] * cam_conditional_partial(
        T[mixed], mu[mixed] + tau[mixed] * quad$nodes[j], sigma[mixed], family
      )
    }
  }
  out
}

cam_survival <- function(t, mu, sigma, tau = 0, family, nodes = 30L) {
  family <- cam_validate_family(family)
  input <- cam_prepare_prediction(t, mu, sigma, tau, "t")
  quad <- cam_normal_quadrature(nodes)
  cam_survival_values(input$x, input$mu, input$sigma, input$tau, family, quad)
}

cam_partial_moment <- function(T, mu, sigma, tau = 0, family, nodes = 30L) {
  family <- cam_validate_family(family)
  input <- cam_prepare_prediction(T, mu, sigma, tau, "T")
  quad <- cam_normal_quadrature(nodes)
  cam_partial_values(input$x, input$mu, input$sigma, input$tau, family, quad)
}

cam_mean_values <- function(mu, sigma, tau, family) {
  if (identical(family, "weibull")) {
    out <- exp(mu) * gamma(1 + sigma)
  } else {
    finite <- sigma < 1
    out <- rep(Inf, length(mu))
    out[finite] <- exp(mu[finite]) * pi * sigma[finite] / sin(pi * sigma[finite])
  }
  finite <- is.finite(out)
  out[finite] <- out[finite] * exp(tau[finite]^2 / 2)
  out
}

cam_mean <- function(mu, sigma, tau = 0, family) {
  family <- cam_validate_family(family)
  draws <- cam_check_draws(mu, sigma, tau)
  cam_mean_values(draws$mu, draws$sigma, draws$tau, family)
}

cam_optimum <- function(r, mu, sigma, tau = 0, family, nodes = 30L) {
  family <- cam_validate_family(family)
  input <- cam_prepare_prediction(r, mu, sigma, tau, "r")
  r <- input$x
  quad <- cam_normal_quadrature(nodes)
  means <- cam_mean_values(input$mu, input$sigma, input$tau, family)
  roots <- rep(NA_real_, length(r))
  roots[r == 0] <- 0
  active <- r > 0 & !(is.finite(means) & r >= means)
  roots[!active & r > 0 & is.finite(means) & r >= means] <- Inf
  if (!any(active)) return(roots)

  h_value <- function(x) {
    cam_partial_values(x, input$mu, input$sigma, input$tau, family, quad)
  }
  lo <- rep(0, length(r))
  hi <- rep(1, length(r))
  h_hi <- h_value(hi)
  repeat {
    needs_bracket <- active & is.finite(h_hi) & h_hi < r & hi < 1e7
    if (!any(needs_bracket)) break
    hi[needs_bracket] <- pmin(2 * hi[needs_bracket], 1e7)
    h_hi <- h_value(hi)
  }
  failed <- active & (!is.finite(h_hi) | h_hi < r)
  roots[failed] <- NA_real_
  active <- active & !failed
  if (!any(active)) return(roots)

  for (iter in seq_len(60L)) {
    mid <- (lo + hi) / 2
    h_mid <- h_value(mid)
    move_lo <- active & h_mid < r
    lo[move_lo] <- mid[move_lo]
    hi[active & !move_lo] <- mid[active & !move_lo]
    if (max(hi[active] - lo[active]) <= 1e-5) break
  }
  roots[active] <- (lo[active] + hi[active]) / 2
  roots
}
