# Decisions use the empirical mixture of retained draws before minimisation.
# No-finite statuses describe that mixture, not unresolved exact posterior tails.
# These are not
# medians of draw-wise optima, which assume knowledge of the true parameters.
management_policy <- function(K, cd, mu, sigma, tau = 0, family, nodes = 30L) {
  stopifnot(length(K) == 1L, is.finite(K), K > 0,
            length(cd) == 1L, is.finite(cd), cd >= 0)
  family <- cam_validate_family(family)
  d <- cam_check_draws(mu, sigma, tau)
  quad <- cam_normal_quadrature(nodes)
  h <- function(t) mean(cam_partial_values(rep(t, length(d$mu)),
    d$mu, d$sigma, d$tau, family, quad))
  mean_life <- mean(cam_mean_values(d$mu, d$sigma, d$tau, family))
  # Guard the finite-mean boundary against roundoff (e.g. exp(log(100))).
  if (cd == 0 || (is.finite(mean_life) && K / cd >= mean_life * (1 - 1e-12)))
    return(list(interval = Inf, loss = cd, mean_life = mean_life,
                status = "no_finite_optimum"))
  hi <- 1
  while (h(hi) < K / cd && hi < 1e7) hi <- hi * 2
  if (h(hi) < K / cd) stop("Could not bracket expected-loss optimum")
  T <- uniroot(function(t) h(t) - K / cd, c(0, hi), tol = 1e-6)$root
  values <- management_loss(T, K, cd, mu, sigma, tau, family, nodes)
  list(interval = T, loss = mean(values$loss), mean_life = mean_life,
       status = "finite_optimum")
}

management_loss <- function(T, K, cd, mu, sigma, tau = 0, family, nodes = 30L) {
  stopifnot(length(T) == 1L, is.finite(T), T > 0, K > 0, cd >= 0)
  S <- cam_survival(T, mu, sigma, tau, family, nodes)
  A <- cam_partial_moment(T, mu, sigma, tau, family, nodes) + T * S
  D <- 1 - A / T
  list(active = A, downtime = D, loss = K / T + cd * D,
       effort_inflation = T / A)
}

management_support <- function(T, profile, train,
                               min_intervals = 20L, min_cameras = 10L) {
  x <- profile_support_summary(T, profile, train, min_intervals, min_cameras)
  data.frame(
    max_followup = x$pooled_max_followup,
    region_max_followup = x$region_max_followup,
    profile_max_followup = x$profile_max_followup,
    group_risk = nrow(x$pooled_risk),
    region_risk = nrow(x$regional_risk),
    region_cameras = length(unique(x$regional_risk$camera)),
    profile_risk = nrow(x$profile_risk),
    profile_cameras = length(unique(x$profile_risk$camera)),
    profile_intervals = nrow(x$profile),
    profile_workload_supported = x$workload_supported,
    support = x$support
  )
}
