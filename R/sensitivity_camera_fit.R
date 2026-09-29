cam_design <- function(train) {
  train <- droplevels(train)
  form <- ~ bb + ft + seas + reg + log_fi_pd + log_day_pd
  mm <- stats::model.matrix(form, train)[, -1, drop = FALSE]
  centres <- colMeans(mm)
  list(formula = form, centres = centres,
       columns = colnames(mm), brands = levels(train$bb),
       cameras = sort(unique(train$camera)), train = train,
       X = sweep(mm, 2, centres, "-"))
}

cam_new_design <- function(design, nd) {
  for (v in c("bb", "ft", "seas", "reg"))
    nd[[v]] <- factor(as.character(nd[[v]]), levels = levels(design$train[[v]]))
  if (anyNA(nd[c("bb", "ft", "seas", "reg")]))
    stop("Camera prediction contains an unsupported factor level")
  mm <- stats::model.matrix(design$formula, nd)[, design$columns, drop = FALSE]
  sweep(mm, 2, design$centres, "-")
}

cam_stan_data <- function(design, cfg, family, use_camera) {
  d <- design$train
  c(list(N = nrow(d), P = ncol(design$X), B = length(design$brands),
         J = length(design$cameras), X = unname(design$X),
         log_time = log(d$rd), event = d$event,
         brand = match(as.character(d$bb), design$brands),
         camera = match(d$camera, design$cameras),
         family_id = match(family, c("weibull", "loglogistic")),
         use_camera = as.integer(use_camera)),
    cfg[c("intercept_mean", "intercept_sd", "beta_sd", "log_scale_mean",
          "log_scale_sd", "camera_sd_scale")])
}

# Independent R likelihood used to verify the Stan model at the MLE.
cam_loglik <- function(mu, sigma, time, event, family) {
  z <- (log(time) - mu) / sigma
  if (family == "weibull") {
    ld <- -log(sigma) + z - exp(z) - log(time)
    ls <- -exp(z)
  } else {
    ld <- stats::dlogis(log(time), mu, sigma, log = TRUE) - log(time)
    ls <- stats::plogis(log(time), mu, sigma, lower.tail = FALSE, log.p = TRUE)
  }
  sum(ifelse(event == 1, ld, ls))
}

cam_fit_models <- function(design, cfg, out, checkpoint_root = dirname(out),
                           model_path = "models/stan/camera_aft.stan") {
  # Validate the immutable run identity before compiling Stan, writing
  # data.json, checking likelihoods, or loading any completed fit.
  checkpoint_guard(design, cfg, checkpoint_root, model_path)
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  model <- cmdstanr::cmdstan_model(model_path)
  checks <- list()
  for (family in cfg$camera$families) {
    mle <- survival::survreg(sa_aft_formula(TRUE, "brand"), data = design$train, dist = family)
    b <- mle$coefficients[design$columns]
    init_mle <- list(alpha = unname(mle$coefficients["(Intercept)"] + sum(b * design$centres)),
                     beta = unname(b), log_sigma = log(unname(mle$scale[design$brands])),
                     z_camera = numeric(0), tau = numeric(0))
    v <- model$sample(data = cam_stan_data(design, cfg$camera, family, FALSE),
                      chains = 1, iter_warmup = 0, iter_sampling = 1,
                      fixed_param = TRUE, init = list(init_mle), seed = cfg$seed,
                      output_dir = out, sig_figs = 18, refresh = 0)
    ll <- as.numeric(v$draws("log_lik_total", format = "matrix"))
    checks[[family]] <- data.frame(family = family, survreg_loglik = as.numeric(logLik(mle)),
                                   stan_loglik = ll, difference = ll - as.numeric(logLik(mle)))
    stopifnot(abs(checks[[family]]$difference) < 1e-6)
  }
  write.csv(do.call(rbind, checks), file.path(dirname(out), "tables", "stan_likelihood_checks.csv"), row.names = FALSE)
  fits <- list()
  for (family in cfg$camera$families) for (re in c(FALSE, TRUE)) {
    id <- paste(family, if (re) "camera" else "independent", sep = "_")
    dest <- file.path(out, id)
    dir.create(dest, recursive = TRUE, showWarnings = FALSE)
    dat <- cam_stan_data(design, cfg$camera, family, re)
    cmdstanr::write_stan_json(dat, file.path(dest, "data.json"))
    # Each completed fit is a checkpoint. A new attempt must use a new output dir.
    checkpoint <- file.path(dest, "fit.rds")
    if (file.exists(checkpoint)) {
      cat(format(Sys.time()), "USING COMPLETED FIT", id, "\n")
      fits[[id]] <- readRDS(checkpoint)
      next
    }
    cat(format(Sys.time()), "SAMPLING", id, "\n")
    fit <- model$sample(
      data = dat, seed = cfg$seed, chains = cfg$camera$chains,
      parallel_chains = cfg$camera$parallel_chains,
      iter_warmup = cfg$camera$warmup, iter_sampling = cfg$camera$sampling,
      adapt_delta = cfg$camera$adapt_delta,
      max_treedepth = cfg$camera$max_treedepth,
      refresh = 250, output_dir = dest,
      init = function() list(alpha = cfg$camera$intercept_mean,
                            beta = rep(0, ncol(design$X)),
                            log_sigma = rep(log(.3), length(design$brands)),
                            z_camera = rep(0, as.integer(re) * length(design$cameras)),
                            tau = if (re) .15 else numeric(0)))
    fit$save_object(checkpoint)
    fits[[id]] <- fit
  }
  fits
}

cam_diagnostics <- function(fit, id, depth = 12) {
  all <- fit$summary()
  population <- all[grepl("^(alpha$|beta\\[|log_sigma\\[|tau\\[)", all$variable), ]
  sampler <- fit$diagnostic_summary()
  latent <- all[grepl("^z_camera\\[", all$variable), ]
  row <- data.frame(
    model = id, rhat_max = max(population$rhat),
    ess_bulk_min = min(population$ess_bulk), ess_tail_min = min(population$ess_tail),
    divergences = sum(sampler$num_divergent),
    treedepth_hits = sum(sampler$num_max_treedepth),
    ebfmi_min = min(sampler$ebfmi),
    latent_rhat_max = if (nrow(latent)) max(latent$rhat) else NA_real_,
    latent_ess_bulk_min = if (nrow(latent)) min(latent$ess_bulk) else NA_real_)
  row$gate_pass <- with(row, rhat_max <= 1.01 & ess_bulk_min >= 400 &
                         ess_tail_min >= 400 & divergences == 0 &
                         treedepth_hits == 0 & ebfmi_min >= .3)
  if (any(!is.finite(unlist(row[c("rhat_max", "ess_bulk_min", "ess_tail_min",
                                  "divergences", "treedepth_hits", "ebfmi_min")])))) row$gate_pass <- FALSE
  list(summary = row, parameters = all)
}

cam_extract_draws <- function(fit, design, n = 1000) {
  a <- fit$draws(inc_warmup = FALSE, format = "draws_array")
  # Balance retained derived-summary draws across chains.
  each <- max(1L, floor(n / dim(a)[2]))
  ix <- unique(round(seq(1, dim(a)[1], length.out = min(each, dim(a)[1]))))
  d <- unclass(as.matrix(posterior::as_draws_matrix(a[ix, , , drop = FALSE])))
  list(alpha = as.numeric(d[, "alpha"]),
       beta = d[, paste0("beta[", seq_along(design$columns), "]"), drop = FALSE],
       sigma = d[, paste0("sigma[", seq_along(design$brands), "]"), drop = FALSE],
       tau = if ("tau[1]" %in% colnames(d)) as.numeric(d[, "tau[1]"]) else rep(0, nrow(d)))
}

cam_interval <- function(x) {
  # Preserve Inf mass; type 1 avoids interpolation between finite and infinite draws.
  q <- stats::quantile(x, c(.025, .5, .975), na.rm = TRUE, type = 1, names = FALSE)
  c(low = q[1], median = q[2], high = q[3])
}
