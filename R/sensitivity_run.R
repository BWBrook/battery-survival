sa_write <- function(x, cfg, name) {
  utils::write.csv(x, file.path(cfg$output_dir, "tables", paste0(name, ".csv")), row.names = FALSE)
}

cam_root_support <- function(roots, dat, min_intervals = 20, min_cameras = 10) {
  finite <- is.finite(roots)
  if (nrow(dat) == 0L) {
    return(c(probability_beyond_followup_given_finite = NA_real_,
             probability_thin_support_given_finite = NA_real_))
  }
  nr <- vapply(roots[finite], function(t) sum(dat$rd >= t), integer(1))
  nc <- vapply(roots[finite], function(t) length(unique(dat$camera[dat$rd >= t])), integer(1))
  c(probability_beyond_followup_given_finite = if (any(finite)) mean(roots[finite] > max(dat$rd)) else NA_real_,
    probability_thin_support_given_finite = if (any(finite)) mean(nr < min_intervals | nc < min_cameras) else NA_real_)
}

run_sa_aft <- function(train, sw, profiles, cfg) {
  grid <- sa_fit_aft_sensitivity(train)
  saveRDS(grid, file.path(cfg$output_dir, "models", "aft_grid.rds"))
  sa_write(grid$comparison, cfg, "aft_comparison")
  sa_write(grid$diagnostics, cfg, "aft_diagnostics")
  sa_write(grid$coefficients, cfg, "aft_coefficients")
  baseline <- grid$comparison$aic[grid$comparison$model_id == "weibull__common__noregion"]
  stopifnot(abs(baseline - 18763.229210434703) < 1e-5)
  for (group in list("bb", c("bb", "ft"))) {
    v <- sa_calibrate_sensitivity(grid, train, cfg$horizons, group)
    sa_write(v, cfg, paste0("aft_calibration_", paste(group, collapse = "_")))
  }
  sw <- sw[as.character(sw$bb) == "Varta" & as.character(sw$ft) == "w", ]
  stopifnot(nrow(sw) == 183)
  supported <- grid$fits[grepl("__noregion$", names(grid$fits))]
  sa_write(sa_calibrate_sensitivity(supported, sw, cfg$horizons), cfg, "aft_sw_calibration")
  decisions <- lapply(names(grid$fits), function(id) {
    fit <- grid$fits[[id]]
    do.call(rbind, lapply(seq_len(nrow(profiles)), function(j) {
      p <- profiles[j, ]
      g <- train[train$bb == p$bb & train$ft == p$ft, ]
      v <- sa_decision_for_profile(fit, p, cfg$ratios, max(g$rd), support_data = train)
      cbind(model_id = id, bb = as.character(p$bb), ft = as.character(p$ft),
            reg = as.character(p$reg), seas = as.character(p$seas), v)
    }))
  })
  sa_write(do.call(rbind, decisions), cfg, "aft_decisions")
  overlap <- train |>
    dplyr::group_by(camera) |>
    dplyr::summarise(intervals = dplyr::n(), brands = dplyr::n_distinct(bb),
                     regions = dplyr::n_distinct(reg), .groups = "drop")
  sa_write(overlap, cfg, "camera_overlap")
  cat(format(Sys.time()), "AFT comparisons complete\n")
}

run_sa_camera_summary <- function(design, profiles, cfg) {
  out <- cfg$output_dir
  diagnostics <- utils::read.csv(file.path(out, "tables", "camera_diagnostics.csv"))
  if (!all(diagnostics$gate_pass)) stop("Camera fit failed diagnostic gate; inspect before interpretation")
  decisions <- survival <- calibration <- parameters <- quadrature <- list()
  root_draws <- list()
  train <- design$train
  for (id in diagnostics$model) {
    cat(format(Sys.time()), "SUMMARISING", id, "\n")
    family <- strsplit(id, "_", fixed = TRUE)[[1]][1]
    fit <- readRDS(file.path(out, "models", id, "fit.rds"))
    draws <- cam_extract_draws(fit, design, cfg$camera$prediction_draws)
    D <- length(draws$alpha)
    # Coefficient summaries use all posterior draws, with interpretable labels.
    ps <- fit$summary()
    ps$term <- ps$variable
    ps$term[ps$variable == "alpha"] <- "centred_training_intercept"
    for (j in seq_along(design$columns)) ps$term[ps$variable == paste0("beta[", j, "]")] <- design$columns[j]
    for (j in seq_along(design$brands)) ps$term[ps$variable == paste0("sigma[", j, "]")] <- paste0("AFT_scale_", design$brands[j])
    ps <- ps[grepl("^(alpha$|beta\\[|sigma\\[|tau\\[)", ps$variable), ]
    parameters[[id]] <- cbind(model_id = id, ps)
    hetero <- do.call(rbind, lapply(seq_along(design$brands), function(b) {
      residual <- draws$sigma[, b]^2 * if (family == "weibull") pi^2/6 else pi^2/3
      fraction <- draws$tau^2 / (draws$tau^2 + residual)
      data.frame(model_id = id, bb = design$brands[b], t(cam_interval(fraction)),
                 scale_tau_correlation = if (all(draws$tau == 0)) NA_real_ else cor(draws$sigma[, b], draws$tau),
                 infinite_mean_fraction = if (family == "loglogistic") mean(draws$sigma[, b] >= 1) else 0)
    }))
    sa_write(hetero, cfg, paste0(id, "_heterogeneity"))
    X <- cam_new_design(design, profiles)
    for (j in seq_len(nrow(profiles))) {
      p <- profiles[j, ]
      b <- match(as.character(p$bb), design$brands)
      mu <- draws$alpha + as.numeric(draws$beta %*% X[j, ])
      sig <- draws$sigma[, b]
      g <- train[train$bb == p$bb & train$ft == p$ft, ]
      gr <- g[g$reg == p$reg, ]
      gp <- profile_support_subset(train, p)
      profile_max <- if (nrow(gp)) max(gp$rd) else NA_real_
      label <- paste(id, p$bb, p$ft, sep = ":")
      for (h in cfg$horizons) {
        v <- cam_survival(h, mu, sig, draws$tau, family, cfg$camera$quadrature_nodes)
        typical <- cam_survival(h, mu, sig, 0, family, cfg$camera$quadrature_nodes)
        typical_q <- cam_interval(typical)
        difference_q <- cam_interval(v - typical)
        survival[[paste(label, h)]] <- data.frame(model_id = id, bb = as.character(p$bb),
          ft = as.character(p$ft), reg = as.character(p$reg), seas = as.character(p$seas),
          horizon_days = h,
          t(cam_interval(v)), typical_camera_low = typical_q[1], typical_camera_median = typical_q[2],
          typical_camera_high = typical_q[3], marginal_minus_typical_low = difference_q[1],
          marginal_minus_typical_median = difference_q[2], marginal_minus_typical_high = difference_q[3],
          n_at_risk = sum(g$rd >= h), n_cameras_risk = length(unique(g$camera[g$rd >= h])),
          region_n_at_risk = sum(gr$rd >= h),
          region_n_cameras_risk = length(unique(gr$camera[gr$rd >= h])),
          profile_n_at_risk = sum(gp$rd >= h),
          profile_n_cameras_risk = length(unique(gp$camera[gp$rd >= h])),
          max_followup = max(g$rd), region_max_followup = if (nrow(gr)) max(gr$rd) else NA_real_,
          profile_max_followup = profile_max,
          profile_observed = nrow(gp) > 0L)
      }
      ix <- unique(round(seq(1, D, length.out = 30)))
      q30 <- cam_survival(180, mu[ix], sig[ix], draws$tau[ix], family, 30)
      q60 <- cam_survival(180, mu[ix], sig[ix], draws$tau[ix], family, 60)
      for (r in cfg$ratios) {
        roots <- cam_optimum(r, mu, sig, draws$tau, family, cfg$camera$quadrature_nodes)
        if (anyNA(roots)) stop("Camera optimum failed to bracket for ", label)
        root60 <- cam_optimum(r, mu[ix], sig[ix], draws$tau[ix], family, 60)
        both_finite <- is.finite(root60) & is.finite(roots[ix])
        root_shift <- if (any(both_finite)) max(abs(root60[both_finite] - roots[ix][both_finite])) else 0
        disagreement <- sum(is.finite(root60) != is.finite(roots[ix]))
        quadrature[[paste(label, r)]] <- data.frame(model_id = id, bb = as.character(p$bb), ft = as.character(p$ft), r = r,
          max_survival_difference_30_60 = max(abs(q30 - q60)), max_root_difference_days_30_60 = root_shift,
          finite_status_disagreements = disagreement)
        if (anyNA(root60) || root_shift > .1 || disagreement > 0) stop("Quadrature needs refinement for ", label)
        root_draws[[paste(label, r)]] <- data.frame(model_id = id, bb = as.character(p$bb),
                                                 ft = as.character(p$ft), r = r, draw = seq_len(D), T = roots)
        support <- cam_root_support(roots, g, cfg$thin_intervals, cfg$thin_cameras)
        regional_support <- cam_root_support(roots, gr, cfg$thin_intervals, cfg$thin_cameras)
        profile_support <- cam_root_support(roots, gp, cfg$thin_intervals, cfg$thin_cameras)
        md <- median(roots)
        decisions[[paste(label, r)]] <- data.frame(model_id = id, bb = as.character(p$bb), ft = as.character(p$ft),
          reg = as.character(p$reg), seas = as.character(p$seas),
          r = r, t(cam_interval(roots)),
          probability_no_finite_optimum = mean(is.infinite(roots)),
          t(support), region_probability_beyond_followup_given_finite = regional_support[1],
          region_probability_thin_support_given_finite = regional_support[2],
          profile_probability_beyond_followup_given_finite = profile_support[1],
          profile_probability_thin_support_given_finite = profile_support[2],
          n_at_risk_at_median = sum(g$rd >= md), n_cameras_risk_at_median = length(unique(g$camera[g$rd >= md])),
          region_n_at_risk_at_median = sum(gr$rd >= md),
          region_n_cameras_risk_at_median = length(unique(gr$camera[gr$rd >= md])),
          profile_n_at_risk_at_median = sum(gp$rd >= md),
          profile_n_cameras_risk_at_median = length(unique(gp$camera[gp$rd >= md])),
          profile_intervals = nrow(gp),
          profile_cameras = length(unique(gp$camera)),
          profile_observed = nrow(gp) > 0L,
          max_followup = max(g$rd),
          region_max_followup = if (nrow(gr)) max(gr$rd) else NA_real_,
          profile_max_followup = profile_max)
      }
    }
    # Row-standardised new-camera predictions; no fitted individual effects.
    for (brand in design$brands) {
      g <- train[train$bb == brand, ]
      b <- match(brand, design$brands)
      mu <- draws$beta %*% t(cam_new_design(design, g)) + draws$alpha
      sig <- rep(draws$sigma[, b], nrow(g))
      tau <- rep(draws$tau, nrow(g))
      km <- sa_km_summary(g, cfg$horizons)
      for (k in seq_along(cfg$horizons)) {
        h <- cfg$horizons[k]
        v <- cam_survival(h, as.vector(mu), sig, tau, family, cfg$camera$quadrature_nodes)
        v <- rowMeans(matrix(v, nrow = D))
        calibration[[paste(id, brand, h)]] <- cbind(data.frame(model_id = id, bb = brand,
          horizon_days = h, t(cam_interval(v))), km[k, ])
      }
    }
  }
  sa_write(do.call(rbind, decisions), cfg, "camera_decisions")
  sa_write(do.call(rbind, survival), cfg, "camera_profile_survival")
  sa_write(do.call(rbind, calibration), cfg, "camera_calibration_bb")
  sa_write(do.call(rbind, parameters), cfg, "camera_population_parameters")
  sa_write(do.call(rbind, quadrature), cfg, "camera_quadrature_check")
  saveRDS(do.call(rbind, root_draws), file.path(out, "models", "camera_decision_draws.rds"))
}
