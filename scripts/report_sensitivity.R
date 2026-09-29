#!/usr/bin/env Rscript
# Assemble an auditable numerical report from saved analysis tables.
cfg <- yaml::read_yaml("config/sensitivity.yml")
root <- cfg$output_dir
read_table <- function(name) read.csv(file.path(root, "tables", paste0(name, ".csv")), check.names = FALSE)
fmt <- function(x, digits = 2) ifelse(is.na(x), "—", ifelse(is.infinite(x), "Inf", formatC(x, digits = digits, format = "f")))
md_table <- function(x) {
  x[] <- lapply(x, as.character)
  names(x) <- gsub("|", "given", names(x), fixed = TRUE)
  c(paste0("| ", paste(names(x), collapse = " | "), " |"),
    paste0("| ", paste(rep("---", ncol(x)), collapse = " | "), " |"),
    apply(x, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |")), "")
}
comp <- read_table("aft_comparison")
diag <- read_table("camera_diagnostics")
dec <- read_table("camera_decisions")
ps <- read_table("camera_population_parameters")
quad <- read_table("camera_quadrature_check")
sw <- read_table("aft_sw_calibration")
cohorts <- readRDS(file.path(root, "cohorts.rds"))
profile_evidence <- do.call(rbind, lapply(seq_len(nrow(cohorts$profiles)), function(j) {
  p <- cohorts$profiles[j, ]
  g <- cohorts$train[cohorts$train$bb == p$bb & cohorts$train$ft == p$ft, ]
  data.frame(Brand = as.character(p$bb), Flash = if (p$ft == "w") "white" else "infrared",
             Intervals = nrow(g), Events = sum(g$event), Cameras = length(unique(g$camera)),
             `Maximum follow-up` = max(g$rd), `Profile region` = as.character(p$reg), check.names = FALSE)
}))
write.csv(profile_evidence, file.path(root, "tables", "profile_evidence.csv"), row.names = FALSE)
lines <- c("# Battery survival: bounded sensitivity results", "", "Generated from the saved 17 September 2026 sensitivity outputs.", "",
  "## What this analysis can establish", "",
  "The analysis tests model and camera-dependence sensitivity under the existing observation convention. For cameras found inactive, the last dated image is minimum confirmed runtime and is used as an event-time proxy. Actual shutdown could be later. Service dates are unavailable; no failure gap is imputed. Realised workload covariates make these retrospective conditional estimates, not verified forecasts at installation.", "",
  "Training: 3,216 intervals, 489 camera identifiers, 1,735 events and 1,481 right-censored records. The previously examined SW region remains outside fitting; only its 183 Varta/white-flash records have the required brand/flash overlap.", "",
  "Evidence available for each profile (events use the last-confirmed-runtime convention):", "", md_table(profile_evidence),
  "## Frequentist distribution sensitivity", "",
  "AIC below uses the independent-row likelihood. It describes the 12-model comparison and does not resolve dependence between deployments from the same camera.", "",
  md_table(data.frame(Model = comp$model_id, Parameters = comp$parameter_count,
                       AIC = fmt(comp$aic, 1), Delta = fmt(comp$delta_aic, 1))),
  "![Training calibration](figures/aft_calibration.png)", "",
  "The curves average predictions over the same brand's observed covariates. KM confidence intervals are pointwise and do not adjust for recurring cameras. Risk counts must accompany interpretation of the late tails.", "",
  "## Camera dependence", "",
  "Four matched Bayesian models use brand-specific AFT scale and region effects. Within each family, the camera model adds one normal random intercept on log runtime. All other priors and covariates are held fixed. Population-marginal predictions integrate over the distribution for a new camera; they do not average the estimated effects of existing cameras. These are fitted-data checks, not new-camera cross-validation.", "")
lines <- c(lines, "Credible intervals condition on each model and its priors. They exclude model-selection uncertainty and the unknown gap between the last image and shutdown. Intervals for the population-level mathematical optimum are not prediction intervals for an individual battery's runtime.", "")
tau <- ps[ps$variable == "tau[1]", ]
lines <- c(lines, md_table(data.frame(Model = tau$model_id, `Camera log-time SD (median)` = fmt(tau$median, 3),
                                     `5th percentile` = fmt(tau$q5, 3), `95th percentile` = fmt(tau$q95, 3), check.names = FALSE)))
for (id in c("weibull_camera", "loglogistic_camera")) {
  v <- read_table(paste0(id, "_heterogeneity"))
  lines <- c(lines, paste0("### ", id), "", "Camera share of latent log-runtime variance; 95% credible intervals:", "",
    md_table(data.frame(Brand = v$bb, Median = fmt(v$median, 3), Low = fmt(v$low, 3), High = fmt(v$high, 3),
      `Scale–camera SD correlation` = fmt(v$scale_tau_correlation, 3),
      `Infinite-mean draw fraction` = fmt(v$infinite_mean_fraction, 3), check.names = FALSE)))
}
lines <- c(lines, "## Conditional inspection-policy sensitivity", "",
  "For scheduled replacement at T, a functioning start and no rescue between visits, the illustrative objective is J(T) = r/T + 1 − A(T)/T, where r = K/c_d is assumed visit-plus-battery cost divided by the value of a lost camera-day. No downtime value is estimated. This differs from the original monotone cost-per-active-day objective. Profiles use brand/flash-specific modal season and region and median realised workloads; they are not standardised causal brand contrasts.", "",
  "The following profiles show medians and 95% credible intervals for the mathematical optimum. Inf denotes posterior mass at no finite optimum; a finite interval beyond observed follow-up is a distinct extrapolation. Probabilities of beyond-follow-up and thin support are conditional on a finite optimum. Thin support means fewer than 20 intervals or 10 distinct cameras at risk, a descriptive flag rather than a validated adequacy threshold. The Energizer/infrared and Procell/infrared cohorts contain only 25 and 30 intervals respectively; risk counts alone do not establish precise within-stratum identification.", "",
  "![Camera dependence and conditional decisions](figures/camera_decisions.png)", "")
profiles <- unique(dec[c("bb", "ft")])
for (j in seq_len(nrow(profiles))) {
  brand <- profiles$bb[j]
  flash <- profiles$ft[j]
  v <- dec[dec$bb == brand & dec$ft == flash, ]
  if (!nrow(v)) next
  lines <- c(lines, paste0("### ", brand, ": ", if (flash == "w") "white flash" else "infrared"), "",
    md_table(data.frame(Model = v$model_id, r = v$r,
      `Days: median [95% interval]` = paste0(fmt(v$median, 1), " [", fmt(v$low, 1), ", ", fmt(v$high, 1), "]"),
      `P(no finite optimum)` = fmt(v$probability_no_finite_optimum),
      `P(beyond follow-up | finite)` = fmt(v$probability_beyond_followup_given_finite),
      `P(thin regional support | finite)` = fmt(v$region_probability_thin_support_given_finite),
      `Regional intervals at median` = v$region_n_at_risk_at_median, check.names = FALSE)))
}
lines <- c(lines, "## Held-region assessment", "",
  "SW has an unseen region level. Only no-region frequentist fits are evaluated; no arbitrary SW coefficient or average training-region effect is assigned. New camera models therefore do not constitute a fresh SW validation. Camera age, drier conditions and other proposed explanations remain hypotheses.", "")
v <- sw[sw$horizon_days == 180, ]
lines <- c(lines, md_table(data.frame(Model = v$model_id, `Predicted survival at 180 days` = fmt(v$predicted_survival, 3),
  `Observed KM` = fmt(v$observed_survival, 3), `At risk` = v$n_at_risk, check.names = FALSE)),
  "## Verification", "",
  md_table(data.frame(Model = diag$model, `Max R-hat` = fmt(diag$rhat_max, 4),
    `Min bulk ESS` = fmt(diag$ess_bulk_min, 0), `Min tail ESS` = fmt(diag$ess_tail_min, 0),
    Divergences = diag$divergences, `Tree-depth hits` = diag$treedepth_hits,
    `Min E-BFMI` = fmt(diag$ebfmi_min, 3), Pass = diag$gate_pass, check.names = FALSE)),
  sprintf("Across representative profile/draw checks, doubling quadrature from 30 to 60 nodes changed survival at 180 days by at most %.3g and optimum time by at most %.4f days; finite-optimum classifications disagreed %d times.",
          max(quad$max_survival_difference_30_60), max(quad$max_root_difference_days_30_60), sum(quad$finite_status_disagreements)), "",
  "Population coefficients and scales define the diagnostic gate; latent-camera diagnostics are also saved. Decision intervals use 1,000 draws balanced across four chains. Numerical quadrature precision is distinct from posterior Monte Carlo uncertainty.", "",
  "The Stan event/censoring likelihood reproduces the matched survreg likelihoods at their maximum-likelihood coefficients; see tables/stan_likelihood_checks.csv. The full project test result is in tests.log. The actual runtime and package versions are recorded in session-*.txt and runtime-package-versions.csv. This isolated R library is not an exact restoration of the original project lockfile.", "",
  "Raw data, exclusions, the canonical production fits and the manuscript backbone were not replaced. Full tables, model draws, source snapshots and logs accompany this report. See docs/sensitivity_analysis_plan.md for the frozen comparison and docs/log/2026-09-17.md for the scientific interpretation and run provenance.")
writeLines(lines, file.path(root, "report.md"))
