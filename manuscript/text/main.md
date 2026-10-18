# How long can a camera trap be left? Battery survival, revisit intervals and lost observation time

<div id="authors"></div>

> Private working draft, 18 October 2026. Illustrative costs; field protocol and author information await confirmation before circulation. Working target: Wildlife Research.

## Abstract

**Context.** Camera traps are often left for months between visits. If batteries fail meanwhile, nominal trap-days accumulate while nothing is recorded, so battery endurance and revisit schedule jointly determine how much observation a survey obtains.

**Aims.** We asked how long cameras in a Tasmanian network could be left before expected losses of observation time became substantial, and what longer-lasting batteries were worth at fixed revisit intervals.

**Methods.** We analysed 3,216 serviced deployments from 489 cameras as survival data, censoring cameras working at service and treating an inactive camera's last image as a minimum confirmed runtime. The area under each fitted survival curve up to a visit gave expected operating time, and the remainder expected lost camera-days, for five observed white-flash scenarios. A region held out of fitting tested transfer.

**Key results.** Median recorded endurance ranged from 85 days for Procell alkaline to 191 days for Energizer lithium. Expected lost time was negligible at short intervals, then rose steeply. A 5% tolerance for expected loss corresponded to revisits of about 72 days in a winter Procell scenario and 160 days in a summer Energizer scenario. Lengthening visits from 90 to 120 days multiplied the additional loss from cheaper lithium scenarios four- to six-fold, to about 2.5–12 camera-days per cycle. At 120 days their saving was offset once a lost day was worth over 1.37–1.65 illustrative units (about 3% of the Energizer set price), and counting deployed days as effort would overstate expected operating time by about 12%. Held-out Varta deployments outlasted predictions despite three times the training median flash workload.

**Conclusions.** Longer battery endurance bought little observation time while visits preceded most failures and substantially more once they did not, so a battery's worth depends on the schedule it is used with.

**Implications.** Surveys can set revisit intervals from a stated tolerance for lost observation, weigh battery costs against that loss, and count effort as expected operating time rather than deployed days. Because these estimates depend on last-image endpoints and local conditions, and did not transfer to the held-out region, each survey needs its own validated endurance curves.

## Keywords

camera trapping; battery life; survival analysis; survey effort; revisit interval; wildlife monitoring

## Introduction

A camera survey scheduled to run for four months does not necessarily deliver four months of observation. When batteries fail between visits, the camera stays in the field and its nominal trap-days keep accumulating, but nothing is recorded until someone returns, and the lost period cannot be recovered. Effort counted from deployment dates then overstates the opportunity to detect animals, which matters because inference from camera data depends on when cameras were able to record [@Burton2015]. As camera surveys grow into networks that are visited only periodically [@Steenweg2017], deciding how long cameras can be left, and what to power them with, becomes part of the sampling design rather than a logistical afterthought.

A battery's rated or median life answers neither question. What matters is the observation time a camera is expected to deliver before its next visit, and how that time changes as visits are spaced further apart. Both follow from a survival curve. The area under the curve up to the visit is the expected runtime in that interval, known in survival analysis as the restricted mean survival time [@RoystonParmar2013], and the rest of the interval is expected lost time. Failures early in an interval forfeit far more observation than failures just before service, which a probability of failure alone does not reveal. The shape of the curve determines how this loss grows. While nearly all batteries outlast the interval, longer endurance preserves little additional time; as failures become common before service, the observation time gained can increase substantially.

Field endurance can fall far short of expectation, particularly under winter and flash-heavy conditions [@Newey2015]. Translating endurance into a survey schedule requires more than knowing which battery lasts longest: it requires the expected loss before a visit and a stated tolerance for that loss. Servicing records can inform this calculation. A camera still working at service supplies a right-censored lifetime; a camera found inactive may supply the date of its last photograph. That photograph is a last sighting of a working camera. It confirms operation but does not date the shutdown, much as a species' last sighting does not date its extinction [@Solow2005].

We use 3,216 such records from 489 cameras in a Tasmanian monitoring network to ask three questions: how far recorded endurance differs among batteries and flash types, how long cameras can be left before expected losses become substantial, and what longer-lasting batteries buy at fixed revisit intervals. Testing the fitted relationships in a region held out of model fitting shows how far such estimates travel. The result is a way to read a survey's own servicing log as evidence about how much observation its cameras deliver.

## Methods

### Field records and the lifetime endpoint

The dataset contains 4,432 serviced deployment intervals from six Tasmanian regions and a testbench cohort. The primary analysis uses 3,216 intervals from 489 camera identifiers in the Central, South East, North West and West regions of the TAS-CAM network. The camera was non-functioning at service in 1,735 intervals and operating in 1,481. South West (SW; 589 intervals), monitored within the same project and protocol, was held out of fitting. North East (564 intervals, most still operating) and testbench records (63, all ending in failure) are described separately (Table S1).

> Field-methods input: confirm dates, hardware and settings, fresh-set and allocation practices, identifier continuity, season assignment, visit rules and failure classification (author checklist: `docs/field_methods_author_questions.md`). The original outline describes Cuddeback 1279 cameras with eight AA cells and interchangeable flash units; its applicability to the complete analytical dataset needs confirmation.

A camera operating at service is right-censored: its batteries lasted at least as long as the recorded interval. For a camera found non-functioning because of dead batteries or an internal power error, duration ends at the last dated image. The camera may have continued to operate without taking another photograph, so this endpoint is a minimum confirmed runtime, not an observed shutdown. Service dates for these records, which would bound the gap from above, are unavailable. We assign last-image times as event times without imputing the gap, so survival and downtime estimates refer to this operational-lifetime proxy. Any operation after the last image is counted as lost under this convention. The non-informative-censoring assumption additionally requires that visits were not timed in response to battery condition; this awaits confirmation of field practice.

Predictors were battery brand, flash type (white or infrared), season, region, and flash and daylight images per recorded day. Daylight images are total images minus flash images; one missing flash count was replaced by zero under the existing processing rule. Both rates enter as $\log(1+\mathrm{images/day})$. They accumulated during the interval being analysed and share its duration as their denominator, so their coefficients describe retrospective associations; they are not known when a camera is installed. Procell is the only alkaline brand in the training cohort and the other four are lithium, so brand and chemistry cannot be estimated as separate effects.

### Survival comparisons and regional transfer

Kaplan–Meier curves describe recorded survival by brand under the observed deployment mix [@KaplanMeier1958]. Their ordinary pointwise confidence intervals do not adjust for repeated cameras. A region-stratified Cox model related recorded lifetime to brand, flash, season and both workloads [@Cox1972]. Each region has its own baseline hazard, and camera-cluster robust standard errors account for repeated intervals. Proportional-hazards diagnostics assessed whether the estimated hazard ratios could be read as constant over follow-up.

For the observation-time calculations, we used parametric accelerated failure-time (AFT) models, which express covariate associations as multiplicative changes in lifetime [@Wei1992]. A sensitivity analysis compared Weibull, lognormal and loglogistic distributions, with common or brand-specific scales and with or without region effects. Matched Bayesian Weibull and loglogistic models, each with and without a normal camera random intercept, then assessed persistent differences among cameras, with covariates and priors matched within each family. Management predictions integrate over camera variation and refer to a new camera from the fitted population. Model specification, priors, computation and diagnostics are in Supplementary Sections S2–S4.

Training calibration compares predictions averaged over each brand's observed covariates with Kaplan–Meier estimates. In SW, only 183 Varta white-flash intervals share a brand/flash combination with training. The transfer check therefore uses the six AFT models without region effects, fitted with intervals treated as independent, because a model with region effects has no coefficient for a region it has not seen. It is a support-limited held-region check within the same project, not independent external validation, and it does not evaluate the camera-effect models.

### From endurance to lost observation time

Each modelled cycle starts with an operational camera and a replacement battery set. A scheduled visit at $T$ days installs another set, with no intervening rescue or restart. If $S(t)$ is the survival function, expected active time and the expected fraction lost are

$$
A(T)=\int_0^T S(t)\,dt,\qquad D(T)=1-\frac{A(T)}{T}.
$$

Thus $T D(T)$ is expected lost camera-days per cycle, that is, between consecutive visits. Unlike the probability of failure before service, $1-S(T)$, it accounts for how early failure occurs. It treats the last-image endpoint as failure, so unrecorded operation after that image counts as lost time; it is a modelled quantity under that convention, not a measurement of physical inactivity.

We compare the five white-flash brands using an observed operating scenario for each. The scenario uses the most frequent observed region–season cell and, within it, the observed workload pair nearest the cell's median transformed workloads (Table S5). This avoids combinations of region and season that never occurred with a brand. It does not standardise conditions across brands: each scenario combines a battery with its region, season and retrospective workload. For each scenario we evaluated $T D(T)$ on a grid of revisit intervals up to the maximum follow-up observed in its region–season cell, using the same 1,000 posterior draws as all other management summaries.

A survey can express its requirement as a tolerance: the largest expected fraction of each interval it can afford to lose. For illustrative tolerances of 5% and 10%, we found where the posterior mean $\overline{D}(T)$ reached the tolerance, and summarised parameter uncertainty by the same crossing in each posterior draw. This limits the expected fraction lost over deployments; it does not guarantee that an individual camera will lose less than that fraction. The calculation needs no price or value for a lost day. Section S9 gives the numerical procedure and treatment of crossings beyond follow-up.

### Valuing lost time

Lost days can also be valued explicitly. Let $C_s$ be the service cost, $C_b$ the battery-set cost and $c_d$ the value of a lost camera-day. Expected cost per calendar day is

$$
L(T)=\frac{C_s+C_b}{T}+c_d D(T).
$$

This connects periodic servicing to the losses incurred while a failed unit remains unattended [@Barlow1963], with battery replacement at every visit. Costs are illustrative units: 24 for Procell, 36 for Wallaby, 40 for Ansmann, 48 for Varta and 52 for Energizer. The value $c_d$ is a management input that battery records cannot identify. Cost per active day alone, $(C_s+C_b)/A(T)$, cannot select an interior optimum, because it never increases as $T$ grows.

At a common revisit interval, a cheaper scenario $X$ saves $C_{b,E}-C_{b,X}$ relative to Energizer $E$. With $\overline{D}$ denoting posterior mean expected downtime, their expected costs match at

$$
c_d^{\star}(T)=\frac{C_{b,E}-C_{b,X}}{T[\overline{D}_X(T)-\overline{D}_E(T)]}.
$$

The denominator is the additional expected lost camera-days under the cheaper scenario. When it is positive, lost-day values below the threshold favour the cheaper scenario and values above it favour Energizer; common service costs cancel. Paired posterior draws preserve shared parameters across scenarios in the uncertainty for additional lost days and thresholds. Section S5 distinguishes the ratio of expected quantities from its parameter-conditional uncertainty; the intervals exclude uncertainty about prices, the endpoint gap and scenario construction. We report 90 and 120 days as illustrative fixed policies, chosen after inspecting follow-up support, not as optimised schedules.

Support counts match brand, flash, region and season. Fewer than 20 intervals or 10 cameras at risk is flagged as thin support, a descriptive screen rather than a validated reliability threshold, and horizons beyond the matching cell's maximum follow-up are identified separately. These checks restrict extrapolation; they do not establish prospective validity for the retrospective scenarios.

### Stress test for the last-image gap

We explored the endpoint assumption by adding exponential gaps to failed-row durations, with rates set to recorded images per day divided by 1, 3 or 10 (Section S8). These rate choices are illustrative and do not estimate actual gaps or triggering patterns. Brand-scale, region-adjusted Weibull and loglogistic models were refitted for 200 imputations per setting, holding workloads and scenarios fixed. Fixed-interval cost comparisons were assessed against unshifted fits of the same independent-row models. A setting was withheld for a model family if any fit failed numerical checks. We report Monte Carlo error and tail sensitivity separately from the main posterior uncertainty.

## Results

### Endurance differed widely within the network

Recorded median lifetime ranged from 85 days for Procell to 191 days for Energizer (Table 1; Fig. [1](#fig-km-brand)). Lithium brands also differed substantially, with Wallaby and Ansmann well short of Varta and Energizer. At 120 days, estimated recorded survival was 0.897 for Energizer and 0.871 for Varta, compared with 0.345 for Wallaby and 0.070 for Procell. These curves describe each brand's observed deployment mix.

The differences persisted after adjustment for flash, season and workload within regions. Relative to Ansmann, Energizer had less than a quarter of the hazard, Varta less than half, Wallaby more than twice and Procell about seven and a half times (Table 1). White flash was associated with a hazard ratio of 3.75 relative to infrared (95% interval 2.95–4.77), and winter with 1.53 relative to autumn (1.33–1.77). Flash workload had a positive association (1.56; 1.30–1.88 per unit of log-one-plus rate), whereas daylight-image rate had a negative association (0.85; 0.74–0.96; Fig. S1). The global proportional-hazards test gave $p=0.011$, so these ratios summarise associations across follow-up.

Table 1. Recorded lifetime and adjusted brand associations in the training cohort. Medians and their ordinary pointwise 95% confidence intervals are Kaplan–Meier estimates, not adjusted for repeated cameras. Hazard ratios and 95% camera-cluster robust intervals come from the region-stratified Cox model, adjusted for flash type, season and realised workloads, with Ansmann as the reference brand. Chemistry is nested within brand.

| Brand | Chemistry | Intervals | Median days (95% CI) | Hazard ratio (95% CI) |
|---|---|---:|---:|---:|
| Ansmann | Lithium | 206 | 132 (127–140) | Reference |
| Energizer | Lithium | 1,181 | 191 (185–200) | 0.23 (0.19–0.28) |
| Procell | Alkaline | 761 | 85 (84–87) | 7.54 (6.02–9.43) |
| Varta | Lithium | 842 | 181 (174–187) | 0.42 (0.34–0.51) |
| Wallaby | Lithium | 226 | 108 (104–115) | 2.33 (1.89–2.88) |

Most cameras were used with more than one brand: 428 of 489 identifiers (87.5%), contributing 3,027 intervals. Adding camera effects to the matched AFT models left brand-coefficient directions unchanged and shifted them by less than 0.013 on the log-time scale, so under these models persistent camera heterogeneity did not account for the brand associations. This check does not remove confounding by allocation or operating conditions. Model-family and camera-dependence diagnostics are reported in Sections S3–S4 and Figs S2–S3.

### Lost time was negligible at short revisits, then rose steeply

Expected lost time was negligible for short revisit intervals and then rose steeply, at an interval that differed by scenario (Fig. [2](#fig-lost-day-curves)). At 60 days, every lithium scenario was expected to lose less than a third of a camera-day per cycle. At 120 days, the expected loss was about 2 days per cycle for Energizer, 4–5 for Varta, 9 for Ansmann and 13 for Wallaby; the Procell scenario had already lost about 12 days by 90 days. The two model families gave closely similar curves (Fig. S5).

The same curves show how long cameras could be left at a stated tolerance: the interval at which each curve crosses a diagonal line in Fig. [2](#fig-lost-day-curves) (Table 2). Keeping expected loss below 5% of each interval corresponded to revisits of up to about ten weeks (71–73 days) in the Procell scenario and about five months (158–161 days) in the Energizer scenario, with the other lithium scenarios between. The Energizer interval was more than twice Procell's and one to two months longer than those of the other lithium scenarios. A 10% tolerance lengthened each interval by about 11–34 days. All mean crossings fell within observed follow-up, and the two families agreed within three days. However, Varta's 10% crossings had only one interval from one camera still at risk in the matching cell, so those late estimates have thin support.

Table 2. Estimated revisit intervals, in days, corresponding to expected losses of 5% or 10% under the last-image-as-failure convention. Values are crossings of the posterior mean downtime curve; brackets give the 2.5th and 97.5th percentiles of draw-wise crossings. These describe parameter uncertainty, not a guarantee for individual cameras. Crossings beyond observed follow-up retain their right-censored mass in the percentile calculation (Section S9). Each row uses a different observed region, season and retrospective workload (Table S5), so row differences are not effects of switching batteries at one site. Follow-up is the maximum duration in the matching joint cell. † Thin support: only one interval from one camera remains at risk at both Varta 10% mean crossings; the other mean crossings meet the 20-interval/10-camera screen.

| Battery | Max. follow-up | 5%, Weibull | 5%, loglogistic | 10%, Weibull | 10%, loglogistic |
|---|---:|---:|---:|---:|---:|
| Procell | 117 | 71 [68, 74] | 73 [69, 76] | 83 [80, 86] | 83 [80, 87] |
| Wallaby | 168 | 99 [93, 106] | 101 [97, 106] | 117 [111, 124] | 117 [112, 122] |
| Ansmann | 164 | 108 [100, 116] | 110 [103, 117] | 128 [120, 135] | 129 [121, 136] |
| Varta | 175 | 129 [121, 137] | 130 [123, 137] | 156 [149, 164]† | 157 [149, 164]† |
| Energizer | 204 | 158 [151, 166] | 161 [153, 168] | 192 [184, 200] | 193 [185, 201] |

At a fixed revisit interval, the curves translate into the observation time a cheaper battery costs (Figs S4–S5). Relative to the Energizer scenario, the cheaper lithium scenarios lost fewer than three additional expected camera-days per cycle at 90 days but about 2.5–12 at 120 days. At 120 days the additional loss was 11.2–11.7 days for Wallaby across the two models, against 2.5–2.6 days for Varta. Lengthening visits by a third, from 90 to 120 days, therefore multiplied each additional loss four- to six-fold. These are contrasts between the observed scenarios, under the last-image-as-failure convention.

Valuing those days gives the economic comparison (Table 3). At 120 days, Wallaby saved 16 units per set but lost 11–12 extra days, while Varta saved 4 units and lost about 2.5–2.6. Across Ansmann, Varta and Wallaby, the value of a lost day that offset the saving was 1.37–1.65 units, about 3% of the 52-unit Energizer set price. Larger purchase savings came with larger losses of time, which placed the thresholds in a narrow range.

At 90 days the thresholds were higher, 2.31–9.91 units across all four alternatives. Procell had the lowest threshold at that horizon because it lost considerably more time than the cheaper lithium scenarios; 22 intervals from 22 cameras remained at risk in its Central/winter cell, which had no follow-up beyond 117 days, so its 120-day comparison is withheld. Weibull and loglogistic thresholds differed by at most 5% at 120 days but by up to 27% at 90 days, where the additional losses were small and their ratio to the saving correspondingly sensitive. Uncertainty was correspondingly wider: Ansmann's Weibull interval was 4.73–16.65 units at 90 days against 1.21–2.41 at 120 days.

Table 3. Lost-camera-day values at which each cheaper white-flash scenario matches the expected cost of the Energizer scenario, in illustrative units under the last-image-as-failure convention. Point estimates equate posterior expected losses, and brackets give 95% credible limits from paired parameter draws (Section S5). Below a threshold the cheaper scenario has the lower expected cost; above it, Energizer does. At-risk counts are intervals / cameras in the matching brand, flash, region and season cell; the Energizer scenario had 244 / 100 at risk at 90 days and 222 / 97 at 120 days. † No observations in the selected Procell cell reach 120 days, so the unsupported extrapolation is withheld.

| Days | Cheaper scenario | Weibull | Loglogistic | At risk |
|---:|---|---:|---:|---:|
| 90 | Ansmann | 7.84 [4.73, 16.65] | 9.91 [6.11, 19.50] | 57 / 57 |
| 90 | Procell | 2.33 [2.01, 2.71] | 2.31 [1.97, 2.75] | 22 / 22 |
| 90 | Varta | 6.65 [3.83, 16.49] | 7.23 [4.39, 16.78] | 90 / 90 |
| 90 | Wallaby | 6.65 [4.60, 10.91] | 8.19 [5.77, 12.99] | 85 / 85 |
| 120 | Ansmann | 1.65 [1.21, 2.41] | 1.64 [1.24, 2.32] | 38 / 38 |
| 120 | Procell | — | — | 0 / 0† |
| 120 | Varta | 1.60 [1.06, 2.83] | 1.53 [1.06, 2.60] | 85 / 85 |
| 120 | Wallaby | 1.43 [1.14, 1.85] | 1.37 [1.12, 1.72] | 35 / 35 |

Assumed gaps between the last image and shutdown mostly raised the supported 120-day thresholds, from 1.38–1.64 units in the matching unshifted refits to 1.36–3.09 across converged settings, with the largest increases under the longest gaps (Section S8; Table S6). The longest uncapped gaps caused Weibull fitting failures, so that setting is withheld. These are sensitivities to constructed gaps, not estimates of shutdown times.

### The endurance models underpredicted survival in the held region

Varta white-flash deployments in SW had a median flash workload of 1.66 images per day, compared with 0.54 in training, yet their recorded median lifetime was longer: 201 days (187–217) versus 166 (158–173). At 180 days, observed SW survival was 0.601. The original Weibull model predicted 0.289, and the highest prediction among the six no-region models was 0.400 (Fig. [3](#fig-sw-transfer)). Allowing different lifetime distributions and brand-specific scales did not reproduce the held-region survival pattern.

## Discussion

### Effort is set by batteries and schedule together

A camera's expected operating time is the area under its survival curve up to the next visit, so battery endurance and the revisit schedule jointly determine expected survey effort. In this network the dependence was strongly nonlinear: lengthening visits by a third, from 90 to 120 days, multiplied the additional loss from cheaper lithium scenarios four- to six-fold. Expected losses stayed close to zero while visits came before most failures and then grew quickly, so the same battery could be adequate on one schedule and costly on another. A single endurance ranking cannot convey this, and neither can a probability of failure before service, because the timing of failures determines how much observation is lost.

The effort accounting follows directly. For the supported white-flash scenarios at 120 days, modelled downtime ranged from about 1–2% for Energizer to 11% for Wallaby (Table S4). Under the endpoint convention, 120 deployed days in the Wallaby scenario corresponded to about 107 expected active days, with 35 joint-cell intervals still at risk, so counting every deployed day would inflate its effort denominator by about 12%. How much this matters depends on the analysis. Holding detections fixed, an inflated denominator lowers an encounter rate proportionately. In an occupancy model, an occasion on which the camera was inactive offered no opportunity for detection and should not be coded as an observed absence; the effect on estimates depends on when downtime occurred, the species and the observation model, not on the inflation factor alone. Work on camera-trap distance sampling likewise separates deployed time from effective survey duration, although there the lost time arises from trigger-recovery delays [@Kuhl2023], and survival analysis has been applied to another interruption of camera coverage, theft [@Cardona2025].

### How long can a camera be left?

Stated as a tolerance for expected loss, the answer needs no prices. Under the last-image convention, a 5% tolerance corresponded to about five months between visits in the summer Energizer scenario and ten weeks in the winter Procell scenario, with the other lithium scenarios between. Each scenario keeps the region, season and workload in which its battery was used, so the spread measures the scheduling problem as these deployments experienced it rather than the effect of swapping batteries at one site. For a survey constrained by access, a locally validated endurance curve makes the choice explicit: visit more often, accept more lost time, or change the equipment.

When a survey's schedule is fixed, the comparison becomes one of price against time. Dividing the battery-set saving by the additional expected lost days gives the value a lost day must exceed for the longer-lasting set to pay. At 120 days this threshold was about 3% of the Energizer set price per lost day, whereas at 90 days it was several times higher because little time was at stake. Whether a lost day is worth more than that depends on what the survey needs to observe. A breeding season, migration or management intervention may place a high value on continuity, whereas a broad inventory may tolerate gaps. Average expenditure per camera-day does not determine this marginal value, and choosing the schedule itself also involves access, survey duration and the observation requirement. White flash should likewise be weighed against the task: its association with shorter endurance does not make infrared preferable when colour images are needed.

### What transfers, and what does not

What transfers from this study is the calculation, not its numbers. Substantial within-camera overlap between brands, and the stability of brand estimates after camera adjustment, support the consistency of the fitted associations. They do not make the scenarios interchangeable. Brands were used in different regions, seasons and workloads, and each scenario retains a combination that occurred in the records; switching batteries at a common site is a different question. Procell's shorter endurance cannot establish a general chemistry effect either, because it was the only alkaline brand and the lithium brands differed substantially among themselves.

The held region gave a direct warning about prediction. Its Varta white-flash deployments combined three times the median flash workload with longer recorded endurance, contrary to the training association, and more flexible distributions did not resolve the mismatch. Unmeasured differences in hardware history, battery batches or environment could contribute, but these records cannot identify their roles. The calculation starts from routine field records: deployment and service dates, camera status at each visit and, for cameras found inactive, the date of the last image. Applied elsewhere, it needs local endurance curves with adequate follow-up, credible operation endpoints and predictors available when deployments begin. Those curves can then connect a survey's tolerance for lost time to revisit intervals and purchase costs.

### A last photograph is a last sighting

The last photograph confirms that a camera worked; it does not say when it stopped. For an individual deployment, using the last image as shutdown can only add to calculated lost time. This accounting bound does not establish the direction of error in fitted losses or tolerance intervals: refitting can alter curve shapes and covariate relationships. Cost thresholds also depend on how unrecorded operation differs among batteries. As with a species' last sighting before extinction, how informative that record is depends on how often observations were made [@Solow2005]. Here image production is part of the measurement process as well as a source of battery demand: a busy camera probably records its final image close to shutdown, while a quiet one may run on without leaving another record. This could contribute to the apparently protective association with daylight-image rate, which does not imply that daytime photographs extend battery life. The rate also shares its denominator with the response, and deployment differences remain possible explanations.

The exploratory gap analysis reinforces this measurement limit. Its largest-gap setting had a median extension of about six days but a much longer upper tail, which affected cost comparisons and caused numerical failures in one model family. The constructed shifts depend on image rate, so changes in the daylight coefficient reflect sensitivity to that assumption rather than identifying a cause of the observed association. The exercise addresses fixed-interval cost comparisons; it does not validate the tolerance-based schedules.

Better operation records would help constrain this uncertainty. Retaining service dates, status at every visit, camera identity, battery allocation, settings and environmental context would strengthen future endurance records [@Meek2014Reporting]. Service dates would bound the last-image gap for cameras found inactive. Where hardware permits, a scheduled test image independent of animal activity could narrow it further, provided the schedule and image records are reliable and its additional battery demand is evaluated. Such records would separate power loss from an absence of wildlife and allow battery and servicing choices to be evaluated prospectively.

## Conclusions

Battery endurance matters to a camera survey through the observation time preserved before its next visit. In this network, a 5% tolerance for lost time corresponded to revisit intervals from about ten weeks to five months across the fitted scenarios, and the extra time lost with cheaper batteries grew steeply as visits lengthened. These estimates remain conditional on the recorded endpoint and deployment conditions, and the held-region mismatch limits their transfer. The broader contribution is an explicit connection between equipment reliability and survey design: estimate expected observation time, state an acceptable loss, and compare the schedules or costs that follow.

## Data and code availability

Data, code, dependency records, saved model draws and numerical checks are retained in the private repository and project archives. Supplementary Information documents the analyses. A public archive identifier and release terms will be supplied before public distribution.

## References
