# Bounded model and camera-dependence sensitivity analysis

Approved by Barry on 17 September 2026, following correspondence thread 23.
This specification records the comparisons before the new fits are inspected.
Fable's exploratory results have already informed the candidate set; this is
not an independently selected or confirmatory model-selection exercise.

## Scientific boundary

For cameras found inactive, `rd` is the time to the last dated image: minimum
confirmed runtime, used as an event-time proxy. For cameras still operating,
the existing right-censoring convention is retained. Service dates are treated
as unavailable. They could bound an unobserved gap but would not identify the
shutdown time. No endpoint is imputed and no source reconstruction is attempted.
The analysis estimates associations and conditional scenarios under this
observation convention, not verified physical battery exhaustion or measured
downtime. Realised image rates remain retrospective covariates.

Use the existing full-data feature/exclusion/partition functions, including
the documented missing-image-count replacement rule. Expect 3,216 TAS-CAM
intervals from 489 cameras. SW remains a previously examined held-region
assessment; NE and the bench cohort are not added to fitting. Suggested SW
differences in camera age, humidity and wind are unmeasured hypotheses.

## Comparisons

1. Fit the 12-model factorial grid: Weibull, lognormal and loglogistic;
   common or brand-specific log-time scale; with or without region effects.
   All retain brand, flash type, season and both log workload covariates.
   Check baseline likelihood against the saved pipeline results. Report AIC,
   likelihood, parameter count, coefficients and fit warnings, without treating
   the independent-row likelihood as a correction for camera dependence.
2. Compare fitted survival averaged over the observed covariates with KM for
   the same training brand and brand/flash groups at 90--270 days in 30-day
   steps. Report intervals and distinct cameras at risk, KM uncertainty and
   maximum follow-up. KM intervals are descriptive and are not cluster-adjusted.
   Assess SW Varta/white with no-region models only; an unseen fixed region
   level cannot be supplied to a region-adjusted fit.
3. Fit matched parametric models with and without a normal camera random
   intercept. Keep fixed effects, response family, scale structure and priors
   identical within each pair. Record the exact implementation and priors
   below before sampling. Assess camera variation, coefficient changes,
   population-marginal survival for a new camera and decision uncertainty.
   Population-marginal predictions integrate over camera effects; setting an
   effect to zero is a different prediction. This is a dependence sensitivity,
   not new-camera or new-region cross-validation.
4. Use analytic survival for the existing modal-season/median-workload
   brand/flash profiles. For region models use the profile's modal training
   region. These are conditional profiles, not standardised brand comparisons.
   Evaluate the illustrative inspection policy
   `J(T) = r/T + 1 - A(T)/T`, where `A(T) = integral_0^T S(t)dt` and
   `r = K/c_d` takes 20, 50, 100 and 200 camera-days. Solve
   `A(T) - T*S(T) = r`; distinguish no finite optimum from a finite optimum
   beyond observed follow-up. Assume a functioning start, scheduled replacement
   at T and no rescue before T. No monetary value is inferred from these data.

### Frozen camera comparison

Use four direct CmdStan fits: Weibull and loglogistic, each with brand-specific
AFT error scales and region effects, with/without a non-centred normal camera
intercept. This matches the informative flexible frequentist specifications.
The server's older R library is incompatible with its current R runtime;
direct CmdStan avoids installing the additional brms/rstan stack and also
allows an exact loglogistic comparison. `models/stan/camera_aft.stan` implements
the same censored log-time likelihood as `survreg`, including the event-density
Jacobian. This is an explicit implementation change, not a new scientific model.

Centre all non-intercept design columns using training means. Priors are:
intercept Normal(log(150), 1), slopes Normal(0, 0.5), brand log(AFT scale)
Normal(log(0.3), 0.75), and camera SD half-Normal(0, 0.5). The fixed parameters
have identical priors within each matched pair. Run four chains with 1,500
warmup and 1,500 retained iterations per chain, adapt_delta 0.99, tree depth 12.
Use 1,000 evenly spaced posterior draws for derived summaries and 30-node
normal Gauss--Hermite quadrature for new-camera marginalisation; check numerical
accuracy against doubled quadrature on representative posterior draws.
Report the fraction of loglogistic draws with infinite mean lifetime separately.
No MCMC comparison is interpreted as independent-row AIC or predictive CV.

## Support and acceptance

Maximum follow-up is an outer bound, not adequate support by itself. Carry
brand/flash risk counts into decision tables; flag fewer than 20 intervals or
10 cameras at risk as a descriptive thin-support warning, not a validated
threshold. Retain the actual counts so conclusions do not depend on this flag.
For region-conditioned profiles, also report the corresponding regional counts.
Report shifts in days and uncertainty, rather than declaring robustness from
family agreement or an arbitrary three-day rule.

Require likelihood/quantile checks for analytic survival, explicit checks of
finite-mean/root cases, and matched-camera marginalisation checks. Bayesian
results need four chains, R-hat <= 1.01, bulk and tail ESS >= 400 for monitored
population parameters (latent-camera diagnostics also reported), no divergences or maximum-treedepth hits, and adequate chain energy
behaviour. Any failed criterion is reported and investigated before scientific
interpretation. Preserve all attempted runs; do not tune to a preferred result.

Run on deep-server in a dated isolated snapshot under tmux; retain source/data
checksums, configuration, runtime versions, logs and model draws. Existing
pipeline and manuscript outputs remain the baseline. Deliver a reproducible
SA report and source, with implications for the next manuscript revision.
