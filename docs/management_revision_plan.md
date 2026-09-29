# Management synthesis following Fable review, 18 September 2026

Barry authorised the detailed revision after correspondence thread 42. Costs
remain **illustrative cost units**, as he confirmed in Codex chat. Venue remains
open, with a camera-trapping practice audience. This is a derived analysis of
the archived camera fits, not a new fit or a replacement of the original pipeline.

Before computing the new results, the comparison is defined as follows:

* Retain all eight existing brand/flash profiles and their covariates, battery
  costs from `config/battery_costs.csv`, service costs 80/450/900 and lost-day
  values 1/3/10. Analyse Weibull and loglogistic camera models separately.
* Minimise posterior expected loss per calendar day,
  `L(T) = K/T + cd*(1 - Eposterior[A(T)]/T)`, integrating new-camera effects.
  Use the same 1,000 balanced posterior draws and 30-node quadrature as the SA.
  Solve `Eposterior[A(T)-T*S(T)] = K/cd` analytically/numerically. Do not use
  quantile-truncated curves, a finite grid endpoint, or a median of draw-wise
  optima as the management decision.
* Where `K/cd >= Eposterior[X]`, report no finite optimum and infimum `cd`;
  distinguish that from a finite optimum beyond observed follow-up. Compare
  profile minima within each scenario, retaining ties at the no-service limit.
* Report support at the selected interval (matching profile region as well as
  whole brand/flash group). No ranking proves a transferable causal brand or
  flash effect: profile workloads, seasons and regions differ; sparse strata
  and extrapolated alternatives limit decision claims.
* Include a common 120-day comparison (below every profile's maximum follow-up,
  but still with risk counts) to separate interval choice from profile ranking.
  Calculate downtime at 150 days to check the proposed ecological example;
  flag its extrapolation for any profile with shorter follow-up.
* With `cd=0`, cost per calendar day tends to zero for every profile as visits
  are delayed. Do not claim an alkaline optimum by importing conclusions from
  the different cost-per-active-day objective.

Main prose will emphasise field effects, management trade-offs and ecological
effort. Detailed model specification, diagnostics and comparisons move to a
separate supplementary source. Remove the obsolete quantile-truncated cost
figures from the publication; preserve their archived files for provenance.

## Focused review amendment

Before manuscript acceptance, the independent check identified intervals within
pooled brand/flash follow-up but beyond the maximum in the profile's region.
The output now distinguishes `beyond_region_followup` from `thin`, retaining
both regional and pooled maxima. This does not change any joint optimum.
After this support check, a 90-day fixed-interval benchmark was added alongside
120 and 150 days; it is exploratory and gives an earlier comparison for sparse
Procell/infrared data. Neither benchmark is a new optimisation constraint.

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

## Authorised focused revision after message 226

Barry agreed to the following replacement framing before his own draft read.
This supersedes the joint optimisation as the main management display, while
preserving its code, outputs and qualifications above for provenance.

- Compare the four cheaper white-flash profiles with Energizer/white at 90 and
  120 days, preserving the saved camera fits, profile covariates and costs.
- Use the lost-day value equating posterior expected losses as the point
  estimate: battery-price saving divided by the posterior mean additional
  downtime days. A common service cost cancels at a fixed interval.
- Pair profile predictions within posterior draws to describe threshold
  uncertainty. Preserve draws with nonpositive downtime differences as no
  positive crossing (infinite switch value); report their mass and do not
  condition credible limits silently on a positive difference.
- Supply regional interval/camera risk counts for both alternatives and
  Energizer; flag Procell's thin 120-day support. Avoid unsupported 150-day
  comparisons and any blanket claim about all intervals beyond 120 days.
- Remove the nine-scenario table and unrestricted-optimum argument from the
  publication. Do not substitute a claim that the survey horizon necessarily
  sets the visit interval: a finite survey needs its own visit/replacement and
  retrieval assumptions.
- Anchor the abstract and management prose on white flash. Use the verified
  Wildlife Research structured abstract as a working format, without implying
  a submission commitment. Retain the two main sensitivity diagnostic figures
  and shorten Fig. 4's caption, with definitions in the supplement.
- Cite Barlow, Hunter and Proschan (1963) as an inspection-scheduling antecedent,
  not an identical objective: their detection-checking problem differs from
  replacement at every scheduled visit in this analysis.

This is a saved-draw derivation and editorial synthesis, with no new fits,
prior changes, raw-data edits, public release or new universal downtime value.


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
