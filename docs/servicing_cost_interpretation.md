# Servicing cost: interpretation adopted 12 September 2026

**17 September extension:** Barry subsequently authorised the bounded model
and camera-dependence sensitivity analysis described in
`docs/sensitivity_analysis_plan.md`. That separate analysis evaluates the
explicitly valued-downtime objective `J(T) = (K/c_d)/T + 1 - A(T)/T` across
assumed `K/c_d` values. It does not alter the monotonicity result below or turn
the original cost-per-active-day curve into an interior optimum. Its outputs
retain the minimum-confirmed-runtime endpoint, uncertainty and support limits.

**18 September synthesis:** the publication draft now includes both the original
cost/downtime interpretation and the separately valued-downtime sensitivity.
Camera dependence has been assessed; its results do not remove the endpoint or
regional-transfer limitations. The historical decision below applies to the
original cost-per-active-day model.

## Decision (12 September)

Retain the existing survival, expected active-day, downtime and cost-per-active-day curves as conditional scenarios. Retire the unconstrained service-interval minima and their bar chart from the active pipeline and manuscript. The user authorised settling this interpretation before adding the Makedoc backbone.

No new monetary penalty, downtime tolerance, field schedule or model fit is introduced. Numerical construction of the retained grid is unchanged.

## Why the previous optimum is not identified

For one battery/flash/workload profile, let survival be S(t), interval T > 0, and positive fixed cycle cost K = service cost + replacement battery-set cost. Assume the camera starts operational; it is serviced and receives a new set at T; after failure there is no rescue visit or restart during the cycle.

Expected active days are A(T) = integral from 0 to T of S(t). Cost per expected active day is C(T) = K/A(T), and expected downtime fraction is D(T) = 1 - A(T)/T.

Since A'(T) = S(T) >= 0,

    C'(T) = -K S(T) / A(T)^2 <= 0.

For a non-increasing survival curve, A(T) >= T S(T), hence

    D'(T) = [A(T) - T S(T)] / T^2 >= 0.

Cost therefore decreases or stays flat while downtime fraction increases or stays flat. Changing K rescales a profile's cost curve but cannot alter its minimising interval. This is a structural property, not a data-specific estimate. It does not imply that changing costs can never change the preferred battery: costs can affect comparisons between battery options.

The current interpolation uses quantiles 0.001 to 0.999 and sets survival to zero beyond the largest predicted quantile. That creates exact plateaus in A(T) and C(T). The former `summarize_economic_optima()` selected the first grid row attaining the minimum. Apparent interior optima could therefore mark a numerical plateau, while 359 days was the last grid point, not an inferred optimum. Direct analytic survival would remove the artificial cutoff but would not remove the monotonicity of the cost objective.

## What a decision can legitimately use

For a stated maximum expected downtime fraction d, compare evaluated intervals satisfying D(T) <= d. Within one profile and fixed positive cycle cost, the longest feasible evaluated interval has minimum cost under this criterion (possibly tied). Alternatively constrain failure probability 1-S(T). These are different management requirements; neither is a confidence bound or a guarantee for an individual camera.

A monetary value for missed observations could enter a different objective, but is not identified by these data. The backbone explains these options without adopting a value or computing new recommended intervals. Curve comparisons are conditional on their battery-specific workload profiles, not standardised causal comparisons.

## Empirical limits

- The event-time input is last confirmed operation for non-functioning cameras. Missing service-date upper bounds prevent an identified interval-censored refit; modelled downtime is not directly measured downtime.
- Workload is realised during the deployment and uses duration in its denominator. Conditional fit is not evidence of forecast performance using information available at installation.
- Supported SW predictions cover 183 of 589 intervals, all Varta/white flash. At 180 days observed survival is 0.601 versus predicted 0.289, and at 270 days 0.158 versus 0.0013. A zero error at 365 days does not establish satisfactory calibration.
- The original AFT outputs do not account for recurring cameras. The September 17 matched sensitivity now does; it is reported separately and does not retrospectively change the baseline curves.
- Service and battery costs are scenarios. Currency, price date, components and allocation across cameras sharing a trip need author confirmation.

## Implementation and evidence

The active DAG no longer produces `service_interval_optima.csv` or `optimal_service_interval.png`; the Quarto report and Makedoc figure list no longer consume them. Older copies under ignored `outputs/` and dated historical evidence remain provenance and are not current products. Do not manually edit or reinterpret them as corrected outputs.

Tests exercise the retained grid and the monotonic cost/downtime relationship. The draft's existing numerical results are taken from the Mac mini's saved full-data tables, not inferred from older development-profile baseline CSVs. See `docs/log/2026-09-12.md` for checks and source provenance.

The work leaves quantile interpolation, costs, profile construction, fitted models and the raw CSV unchanged. Any later direct-survival implementation or constrained recommendation should be evaluated as a separate scientific change with appropriate numerical comparison.

## September 18 management synthesis after review

The separately authorised joint comparison now uses the saved camera fits and
analytic survival, with service costs 80/450/900 and lost-day values 1/3/10.
Barry confirmed these remain illustrative units. `R/management_policy.R`
minimises posterior expected loss, not the median of draw-wise optima.
Six scenarios select Energizer/infrared under both families. Two have no finite
optimum for any profile; at 900/3 the finite loglogistic answer is 1,151 days,
beyond follow-up, whereas Weibull has no finite answer. A capped grid would
conceal this distinction. See `docs/management_revision_plan.md`.

The old cost/downtime figures are removed from the publication, while archived
outputs and the canonical baseline report remain unchanged. New cost outputs
also distinguish regional follow-up limits from the pooled brand/flash maximum.

### Posterior-tail qualification at final review

All new numerical no-finite-optimum classifications refer to the empirical
predictive mixture of the 1,000 retained posterior draws. The unbounded scale
priors can give infinite exact posterior predictive means even when retained
parameter draws have finite means (loglogistic conditional means can themselves
be infinite; Weibull conditional means grow extremely rapidly with scale).
A finite simulation cannot settle an unrestricted optimum in those remote
posterior tails. The manuscript therefore describes the practical outcome as
no supported finite solution, with the numerical convention explicit in Table2
and the supplement. Finite-time costs and the six consensus numerical minima
are unchanged; no new fits or posterior truncations were introduced.

### Focused manuscript revision following Fable message 226

The current publication replaces the nine-scenario joint optimum table with
white-flash break-even values at fixed 90/120-day revisit intervals. A common
service cost cancels; the threshold is the battery-cost saving divided by
additional expected lost days. Paired saved posterior draws quantify its
uncertainty. The unrestricted-optimum calculations and tail qualifications
above remain historical evidence, not the current management headline.
The current results do not claim an optimal finite-survey servicing schedule.


## 19 September profile-support correction

The authorised correction in `docs/profile_support_revision_plan.md` supersedes
the marginal-mode profile construction and region-only support matching used
above. Current scenarios use an observed joint region/season cell and observed
workload pair for each brand/flash group. Risk counts and follow-up limits match
all four categorical variables. New results are derived from unchanged saved
fits in `outputs/management/2026-09-19/`; the 17/18 September archives remain
sealed. The manuscript's downtime, effort ratios and break-even values are
conditional on last-image-as-failure and retrospective workload scenarios, not
validated prospective schedules or measured physical inactivity.
