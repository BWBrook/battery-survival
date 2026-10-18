# Supporting information: How long can a camera trap be left? Battery survival, revisit intervals and lost observation time

Private working supplement, 18 October 2026. This document contains the model-family and camera-dependence sensitivity analysis, its empirical support, and the reproducible management calculations. It accompanies the main manuscript and is not an independent validation report.

## S1. Analysis populations

Table S1. Analysis populations and camera state at service, from the saved partition summary. A non-functioning camera is assigned its last-image time as the event time; an operational camera is right-censored at service.

| Population | Deployment intervals | Camera identifiers | Non-functioning | Operational |
|---|---:|---:|---:|---:|
| TAS-CAM training | 3,216 | 489 | 1,735 | 1,481 |
| SW held region | 589 | 262 | 426 | 163 |
| NE descriptive | 564 | 201 | 103 | 461 |
| Testbench | 63 | 63 | 63 | 0 |

## S2. Model specification and computation


AFT models express covariate differences on the lifetime scale [@Wei1992]. The initial comparison fitted Weibull, lognormal and loglogistic distributions with a common AFT error scale and no region effect. We then examined all 12 combinations of these families, common or brand-specific error scales, and presence or absence of fixed regional effects. Every model retained brand, flash type, season and the two workload variables and used the same training intervals. AIC compares their full likelihoods; the Cox partial likelihood is excluded. Because these AFT likelihoods treat rows as independent, their AIC ranking does not account for repeated cameras. The expanded candidate set followed exploratory model criticism, so this is a sensitivity analysis rather than a new confirmatory selection exercise.

To assess camera dependence, we fitted four matched Bayesian models: Weibull and loglogistic, each with and without a normal camera random intercept on log runtime. All four included brand-specific AFT error scales and fixed regional effects. Within each family, the fixed-effect structure and priors were identical. The model is

$$
\log X_{ij}=\alpha+\mathbf{x}_{ij}^{\mathsf T}\boldsymbol\beta+u_j+\sigma_{b(i)}\epsilon_{ij},
\qquad u_j\sim N(0,\tau^2),
$$

where $i$ indexes an interval, $j$ its recorded camera identifier, and $b(i)$ its battery brand. The error distribution is standard minimum extreme-value for Weibull or standard logistic for loglogistic; $u_j=0$ in the independent models. Non-intercept design columns were centred on their training means. Priors were $\alpha\sim N(\log 150,1^2)$, $\beta_k\sim N(0,0.5^2)$, $\log\sigma_b\sim N(\log 0.3,0.75^2)$ and $\tau\sim\mathrm{half\text{-}Normal}(0,0.5^2)$. The camera term represents persistent heterogeneity associated with the recorded identifier, without attributing it to hardware, age or location.

The censored likelihoods were implemented directly in Stan and checked against the corresponding frequentist likelihoods at their maximum-likelihood estimates. Four chains per model used 1,500 warmup and 1,500 retained iterations each. We required population-parameter $\widehat R\leq1.01$, bulk and tail effective sample sizes of at least 400, no divergences or maximum-tree-depth hits, and adequate chain energy behaviour. Latent-camera diagnostics were also inspected. Derived summaries used 1,000 draws balanced across chains. Predictions for a new camera integrated over its random-effect distribution using 30-node normal quadrature, checked against 60 nodes. Credible intervals condition on each model and its priors; they exclude model-selection and endpoint-gap uncertainty. Fitting used R 4.6.1 and CmdStan 2.38.0 in a separately provisioned library, not an exact restoration of the original project lockfile; package versions and session records accompany the saved sensitivity outputs.

Training calibration compares survival predictions averaged over each brand's observed covariates with Kaplan-Meier estimates at 30-day intervals from 90 to 270 days. Pointwise Kaplan-Meier intervals are descriptive and do not adjust for recurring cameras. These comparisons are fitted-data checks, not cross-validation on unseen cameras.

SW remains a support-limited held-region check from the same project. Only 183 Varta/white-flash intervals have the brand and flash levels represented in training. For this subset, we compared averaged predictions from the six no-region AFT models with Kaplan-Meier survival. Region-adjusted models were not assigned an arbitrary coefficient for the unseen SW level. The held region had already been examined during earlier analysis; this comparison is neither a new independent validation nor a test of transfer to other camera systems.

## S3. Model comparison and camera dependence


The original three-model comparison favoured Weibull, with AIC 18,763.23 versus 18,812.69 for loglogistic and 18,898.22 for lognormal. This preference changed when dispersion and regional effects were allowed to vary. The expanded comparison favoured loglogistic with brand-specific scale and region effects, with AIC 18,718.73: 11.25 lower than the equivalent Weibull and 44.50 lower than the original Weibull (Table S2). Brand-specific scales and regional effects each improved AIC within every family. The original distribution ranking therefore depended on its common-scale, no-region specification. Training calibration is shown in Fig. S2; the Cox associations are in Fig. S1.

Table S2. Expanded AFT comparison on the same 3,216 intervals. Scale refers to the error scale on log time; all models include brand, flash type, season and both workload variables. Delta AIC is relative to the lowest value. These independent-row likelihoods do not correct for camera dependence.

| Family | Scale | Region | AIC | Delta AIC |
|---|---|---|---:|---:|
| Loglogistic | Brand-specific | Yes | 18,718.73 | 0.00 |
| Weibull | Brand-specific | Yes | 18,729.97 | 11.25 |
| Loglogistic | Brand-specific | No | 18,731.64 | 12.91 |
| Weibull | Common | Yes | 18,746.43 | 27.70 |
| Weibull | Brand-specific | No | 18,747.86 | 29.14 |
| Weibull | Common | No | 18,763.23 | 44.50 |
| Lognormal | Brand-specific | Yes | 18,775.91 | 57.19 |
| Lognormal | Brand-specific | No | 18,783.55 | 64.82 |
| Loglogistic | Common | Yes | 18,801.45 | 82.72 |
| Loglogistic | Common | No | 18,812.69 | 93.97 |
| Lognormal | Common | Yes | 18,892.65 | 173.92 |
| Lognormal | Common | No | 18,898.22 | 179.50 |

In the matched Bayesian comparison, median camera log-time standard deviations were 0.131 under Weibull and 0.130 under loglogistic. Brand-specific median camera shares of latent log-runtime variance ranged from 11% to 26% across the two families. All four models passed the sampling checks, with population-parameter maximum $\widehat R<1.003$, minimum bulk effective sample size above 2,285, and no divergences or tree-depth hits. Camera identity is not interchangeable with site: 99 identifiers occurred in more than one region, and 428 were observed with more than one battery brand.

## S4. Conditional intervals and empirical support

The original sensitivity compared cycle-cost/lost-day-value ratios of 20, 50, 100 and 200 camera-days. These ratios isolate distributional and camera-dependence sensitivity within each profile. They are not a joint battery-cost comparison: equal ratios imply different lost-day values when battery-set prices differ. Figure S3 retains this diagnostic purpose. Open points in that figure indicate greater than 50% posterior probability of fewer than 20 intervals or 10 cameras remaining at risk in the matching brand/flash/region/season cell, conditional on a finite optimum. Grey shading exceeds that joint cell's maximum follow-up; medians above 350 days or infinite medians are omitted, and intervals are clipped to the plotted range. These display conventions do not establish reliable prediction in small strata.

We retained 20 of the 64 independent-versus-camera comparisons with finite posterior medians within joint-cell follow-up and no more than 50% probability of thin joint-cell support in either model. The largest median shift was 1.7 days (Ansmann/white, Weibull, ratio 50). Across white-flash scenarios at ratios 20 and 50, adding camera effects changed 95% credible-interval widths by factors of 0.99 to 1.23; that width comparison includes thin and extrapolated scenarios and does not establish their support. Model family made larger differences: Energizer/infrared at ratio 50 differed by 8.3 days within joint-cell follow-up, with 20 joint-cell intervals remaining at either median. Its entire stratum contained only 25 intervals and eight events.

Table S3. Illustrative conditional optima from the camera models. Values are posterior medians and 95% credible intervals in days, integrating new-camera effects. Risk counts match brand, flash, region and season at the Weibull/loglogistic median respectively. † Both Varta medians exceed the selected cell's 175-day maximum; these extrapolations illustrate a diagnostic limitation and are not supported field schedules. All values are conditional on the stated cost ratio $r$.

| Brand / flash | $r$ | Weibull | Loglogistic | At risk (W/L) |
|---|---:|---:|---:|---:|
| Ansmann / white | 50 | 129.0 (124.4-133.8) | 127.5 (122.8-132.0) | 31 / 32 |
| Energizer / white | 50 | 179.2 (173.5-184.7) | 178.0 (172.5-184.0) | 95 / 98 |
| Energizer / infrared | 50 | 245.3 (233.1-259.3) | 237.1 (223.7-251.1) | 20 / 20 |
| Varta / white† | 100 | 191.6 (185.4-198.2) | 199.2 (192.8-206.6) | 0 / 0 |

Long extrapolations could change qualitatively. For Energizer/white flash at $r=200$, adding camera effects changed the Weibull posterior probability of no finite optimum from 0.558 to 0.217. The corresponding median changed from infinity to 360.4 days, beyond the 204-day joint-cell maximum follow-up for this profile. This distinction matters mathematically but does not support a field schedule. More generally, a finite model-derived answer can remain poorly supported by the observations.

## S5. Fixed-interval break-even calculations

The management comparison reuses the archived Weibull and loglogistic camera fits, analysed separately, without new sampling. The five white-flash profiles use observed joint region–season cells and observed workload pairs selected by the uniform rule in Section S6. Their differences therefore combine battery and operating conditions; they are not common-covariate treatment contrasts. Infrared profiles remain in the model-sensitivity diagnostic in Section S4, but do not anchor the management claim.

At a fixed revisit interval $T$, let $D_{b,\theta}(T)$ be the expected downtime fraction for profile $b$, integrated over a new camera's random effect, conditional on model parameters $\theta$. Its posterior mean is $\overline{D}_b(T)$. For battery cost $C_b$, common service cost $C_s$, and lost-day value $c_d$, posterior expected cost per calendar day is

$$
\overline{L}_b(T)=\frac{C_s+C_b}{T}+c_d\overline{D}_b(T).
$$

For a cheaper alternative $X$ and Energizer $E$, subtracting these losses eliminates the common service cost. Their equality gives

$$
c_d^{\star}(T)=\frac{C_{b,E}-C_{b,X}}{T[\overline{D}_X(T)-\overline{D}_E(T)]}.
$$

This is the threshold for choosing between profiles on posterior expected loss. It is a ratio formed after averaging downtime, not a posterior mean or median of draw-wise ratios. The battery-set costs are 24, 36, 40, 48 and 52 illustrative units for Procell, Wallaby, Ansmann, Varta and Energizer respectively. Changing the common service cost cannot change their ranking at fixed $T$. Costs that differ between alternatives would not cancel.

To describe parameter uncertainty, each retained posterior draw supplies predictions for all profiles together. We calculate the threshold within each paired draw, keeping their shared coefficients and camera-variation parameters paired; 2.5th and 97.5th percentiles describe this parameter-conditional distribution. If the cheaper profile has no greater downtime in a draw, it has lower loss at every nonnegative lost-day value: its switch threshold is recorded as infinity rather than discarded. The machine-readable output reports the frequency of these draws, and uncertainty bounds retain them. The expected-loss threshold and the bounds thus summarise different aspects of the same posterior, not interchangeable point estimators. All 1,000 retained draws had positive downtime differences in all 16 calculated comparisons (including the unsupported Procell 120-day extrapolations retained only in the machine-readable output); this establishes zero sampled mass at infinity, not an exact zero posterior probability.

Predictions use direct distributional survival and partial first moments with 30-node normal quadrature for new-camera effects and 1,000 posterior draws balanced across chains. Uncertainty excludes model-family, price, profile-construction and last-image-gap uncertainty; the bounds are not individual-camera prediction intervals. Figure S4 multiplies each saved paired downtime-gap mean and its interval limits by the positive revisit interval, yielding additional expected lost camera-days. This linear transformation preserves the paired uncertainty; unsupported rows are withheld. The continuous paired differences in Fig. S5b use the same draws and calculation over a grid of intervals (Section S9). Neither requires new fitting or posterior sampling. The two families are reported separately. At-risk counts match brand, flash, region and season jointly; pooled brand/flash and region-only counts are retained separately in machine-readable outputs. Fewer than 20 joint-cell intervals or 10 cameras is flagged as thin support. Empty categorical cells, workloads outside that cell's observed ranges, and horizons beyond its maximum follow-up have separate support flags. A supported workload pair and adequate risk count do not establish prospective validity.

The 90- and 120-day horizons were selected during exploratory manuscript development after inspection of the existing support summaries. They are fixed comparisons, not optimised schedules or a test of prospectively specified policies. The corrected profile rule selects Central/winter for Procell/white, whose maximum follow-up is 117 days. Its 120-day numerical extrapolations are retained in the machine-readable output but withheld from the manuscript tables; even 120 days exceeds this scenario's support, despite a pooled brand/flash maximum of 148 days. The earlier nine-scenario joint optimisation and its distant-tail qualifications are retained in the project archive and decision log, but are not evidence for the fixed-interval management claim.

Source: `R/management_break_even.R` and `scripts/summarise_break_even.R`. Corrected profile-dependent results are saved in `outputs/management/2026-09-19/`, with fixed-interval calculations in its `break_even/` subdirectory. The 18 September results retain the former marginal-mode profiles for provenance and are superseded here. The correction reuses the same 1,000 posterior draws and 30-node quadrature; it changes prediction scenarios and support matching, not fitted models. Raw data, fitted models and the sealed sensitivity outputs are unchanged.

## S6. Downtime, effort and profile support

Table S4. Modelled downtime and nominal-to-active-effort ratios at 120 days under the last-image convention. W / LL denotes Weibull / loglogistic. All intervals / events are pooled within brand and flash; risk counts match the joint brand/flash/region/season cell. Effort inflation divides nominal time by posterior mean active time. The unsupported Procell extrapolation is withheld.

| Brand | All intervals / events | Downtime W / LL (%) | Effort inflation W / LL | Joint risk | Support |
|---|---:|---:|---:|---:|---|
| Ansmann | 206 / 157 | 7.8 / 7.4 | 1.08 / 1.08 | 38 / 38 | Within follow-up |
| Energizer | 1156 / 440 | 1.7 / 1.4 | 1.02 / 1.01 | 222 / 97 | Within follow-up |
| Procell | 731 / 596 | — | — | 0 / 0 | Beyond cell follow-up |
| Varta | 501 / 230 | 3.8 / 3.5 | 1.04 / 1.04 | 85 / 85 | Within follow-up |
| Wallaby | 226 / 219 | 11.0 / 11.1 | 1.12 / 1.12 | 35 / 35 | Within follow-up |

For a common interval, effort inflation is $T/\overline{A}(T)=1/[1-\overline{D}(T)]$: nominal deployed days divided by posterior mean active days. It is not the posterior mean of the draw-wise inflation factors. These are scenario quantities under the last-image-as-failure convention, not measurements of physically inactive days; an unobserved period of continued operation would reduce actual downtime. The factor describes the expected-effort denominator; it is not a universal multiplier for bias in an ecological estimator. The full white-flash strata contain substantially more observations than the sparse infrared groups, but late follow-up remains limited for some brands.


For each brand/flash group, the profile uses the most frequent observed region–season combination. Ties are resolved lexically by region then season. Within that cell, we select the observed pair of log-one-plus flash and daylight rates minimising squared Euclidean distance from the two cell medians, resolving exact ties lexically by flash then daylight rate. Selection does not use event status or follow-up duration separately from the already defined workload rates. Thus both the categorical combination and the workload pair occurred in the data. Scenario differences still combine brand with region, season and realised workload; they are not standardised brand contrasts. Table S5 makes the scenarios explicit.

Table S5. Observed operating scenarios used in the corrected predictions. W and IR denote white and infrared flash. Counts are joint-cell intervals / camera identifiers / events. Workloads are the selected log-one-plus images per recorded day, followed by the joint-cell minimum–maximum in brackets. The maximum follow-up is for that categorical cell, not the entire brand/flash group. The machine-readable profiles CSV retains full precision.

| Profile and region/season | Counts | Flash workload [range] | Daylight workload [range] | Max days |
|---|---:|---:|---:|---:|
| Ansmann / W; West / summer | 68 / 68 / 49 | 0.288 [0.000–1.290] | 0.405 [0.028–3.138] | 164 |
| Energizer / IR; Central / spring | 24 / 24 / 8 | 0.405 [0.112–0.816] | 0.173 [0.107–0.447] | 366 |
| Energizer / W; Central / summer | 251 / 101 / 107 | 0.439 [0.008–1.178] | 0.414 [0.016–3.982] | 204 |
| Procell / IR; West / summer | 12 / 12 / 0 | 0.603 [0.259–0.988] | 1.636 [0.797–2.549] | 105 |
| Procell / W; Central / winter | 91 / 91 / 46 | 0.304 [0.000–0.981] | 0.230 [0.000–1.523] | 117 |
| Varta / IR; North West / spring | 50 / 28 / 8 | 0.775 [0.155–2.483] | 0.699 [0.153–3.753] | 170 |
| Varta / W; South East / summer | 95 / 95 / 25 | 0.613 [0.046–1.668] | 0.602 [0.054–4.346] | 175 |
| Wallaby / W; South East / autumn | 106 / 106 / 105 | 0.481 [0.007–1.926] | 0.272 [0.008–1.506] | 168 |

## S7. Held-region and late-tail checks

At 180 days, SW Varta/white Kaplan–Meier survival was 0.601 (112 at risk), versus 0.289 under the original Weibull specification and a highest prediction of 0.400 across six no-region models (main-text Fig. 3). The 406 other SW intervals had unsupported battery levels. These independent-row fits did not resolve the transfer failure. The region-adjusted camera models were not evaluated in SW, so this check does not test whether camera dependence explains the regional difference.

In training, Energizer survival at 270 days was 0.405 by Kaplan-Meier, versus row-averaged camera predictions of 0.120 (Weibull) and 0.185 (loglogistic), with only 19 intervals still at risk. These are fitted-data diagnostics, not out-of-sample forecast checks.

## S8. Exploratory sensitivity to assumed last-image gaps

The last image cannot identify when a camera stopped operating. We perturbed recorded endpoints under explicit assumptions to explore sensitivity; these gaps are not estimated shutdown times.

Each of the 1,735 failed training intervals received an exponential gap at its recorded images-per-day rate divided by $b$ = 1, 3 or 10. Poisson observation logic motivates the waiting-time scale but cannot establish this conditional gap law. The divisors do not estimate bursts or temporal clustering, and recorded rates depend on the observation window and image protocol. All failed intervals had positive counts; 22 had ten images or fewer. Censored durations, workload covariates and scenarios stayed fixed: only failed-row durations changed.

Shifted lifetimes were uncapped. A paired variant of $b$ = 10 used the same simulated gaps but capped shifted lifetimes at 366 days, the longest recorded duration in the cohort. This is an illustrative cap, not an upper bound on any failed camera's shutdown. For each setting, 200 sets of gaps were drawn and the brand-scale, region-adjusted Weibull and loglogistic AFT models were refitted as independent-row models. Expected additional lost days were averaged across imputations before dividing the battery-set saving. Original support flags were retained, so Procell at 120 days remains withheld: simulated extensions do not create observed follow-up.

Fits required convergence and finite parameters, likelihood, covariance and expected losses. Non-convergence triggered one retry at a higher iteration limit; any persistent failure withheld the entire setting/family group. Uncapped $b$ = 10 Weibull failed, including a targeted check from two alternative starting points. None of that group enters model summaries. Gap and Kaplan–Meier summaries do not depend on these fits.

The unshifted frequentist fits provide a separate baseline from the main camera models: their Weibull Ansmann threshold is about 10% lower at 120 days. Imputation variation and Monte Carlo error do not represent sampling or posterior uncertainty.

Table S6. Supported 120-day break-even values under assumed gaps, in illustrative units per additional lost camera-day. Values divide the saving by expected losses averaged across 200 imputations, rather than averaging thresholds. The unshifted baseline uses one fit. — The whole setting is withheld for numerical failures. Monte Carlo precision is reported below and in the accompanying CSV.

| Family | Alternative | Unshifted | $b$ = 1 | $b$ = 3 | $b$ = 10 | $b$ = 10, capped |
|---|---|---:|---:|---:|---:|---:|
| Weibull | Ansmann | 1.48 | 1.58 | 1.71 | — | 2.06 |
| Weibull | Varta | 1.56 | 1.56 | 1.47 | — | 1.36 |
| Weibull | Wallaby | 1.41 | 1.51 | 1.52 | — | 1.41 |
| Loglogistic | Ansmann | 1.64 | 1.79 | 2.07 | 3.07 | 3.09 |
| Loglogistic | Varta | 1.55 | 1.58 | 1.65 | 1.97 | 1.97 |
| Loglogistic | Wallaby | 1.38 | 1.48 | 1.67 | 2.20 | 2.20 |

The largest uncapped setting had a median assumed gap of 6.2 days, a mean of about 15 days, and an average within-imputation 99th percentile of about 135 days. Shifted maximum lifetimes ranged from 386 to 1,858 days across imputations. Capping affected only 6.1 failed intervals on average, yet removed the Weibull convergence failures. The small fraction capped therefore does not establish that the extreme tail is unimportant.

All reported 120-day thresholds had relative Monte Carlo standard errors below 0.9%, meeting the 5% numerical criterion set before the expanded run; the largest absolute Monte Carlo standard error was 0.019 units. This measures finite simulation error under the assumed gaps, not the credibility of those assumptions. The original 20-imputation pilot, failed attempts and withheld setting remain in the analysis archive.

The daylight coefficient on log time changed from 0.042 in the unshifted loglogistic fit to a median of −0.013 under uncapped $b$ = 10. In the capped Weibull setting it changed from 0.041 to −0.033. The construction gives longer extensions to lower-rate records while holding rates fixed as predictors. These changes show sensitivity to that construction, not that endpoint gaps caused the original association. Main Table 2 tolerance crossings were not recomputed.

Code: `R/endpoint_gap_sensitivity.R` and `scripts/run_endpoint_gap_sensitivity.R`; outputs, input hashes, numerical status and Monte Carlo summaries: `outputs/endpoint_gap/2026-10-18/`.

## S9. Observation-time curves and tolerance crossings

Expected lost time is $T-A(T)=\int_0^T[1-S(t)]\,dt$. For each posterior draw, the curves integrate over the fitted population distribution of camera effects. Main Fig. 2 (Weibull) and Fig. S5 (both families, with paired differences from Energizer) use 1,000 balanced draws from each saved model and evaluate revisits on a three-day grid augmented with the exact joint-cell maximum follow-up. The same draws are paired when subtracting the Energizer scenario. Bands describe uncertainty in expected time, not variation in the losses of individual cameras. Agreement between the two lifetime families does not assess endpoint error or uncertainty in scenario construction.

Main Table 2 inverts the posterior mean downtime fraction on a one-day grid, with linear interpolation between adjacent values. Its point estimate is not the mean or median of draw-wise crossings. The 2.5th and 97.5th percentiles of draw-wise crossings describe parameter uncertainty. Crossings beyond the observed cell maximum remain right-censored in this summary; their mass is retained in the percentile denominator rather than discarded. For the Energizer 10% tolerance, 0.5% of Weibull draws and 0.6% of loglogistic draws did not cross within 204 days. Both reported percentile limits remain inside follow-up.

Support is evaluated in the exact brand, flash, region and season cell, with the same descriptive screen used elsewhere: fewer than 20 deployment intervals or 10 cameras at risk is thin support. Varta's 10% mean crossings have only one interval and one camera at risk. The other mean crossings meet this screen, although parts of the plotted late tails and some parameter intervals do not. Maximum follow-up alone is not evidence of reliable prediction. The machine-readable curve and tolerance tables retain joint-cell counts and support classifications, including those at the uncertainty limits: `outputs/management/2026-10-18/lost_day_curves/`.

## References
