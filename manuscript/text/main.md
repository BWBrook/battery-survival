# How battery endurance and revisit schedules shape camera-trap effort

<div id="authors"></div>

> Private working draft, 18 October 2026. Illustrative costs; field protocol and author information await confirmation before circulation. Working target: Wildlife Research.

## Abstract

**Context.** Planned camera-trap effort exceeds delivered observation when batteries fail between visits.

**Aims.** We quantified recorded battery endurance and compared observation time lost under fixed revisit schedules.

**Methods.** Survival analyses used 3,216 serviced deployments from 489 Tasmanian cameras. Working cameras were censored; failed cameras' last images supplied minimum confirmed runtimes. Weibull and loglogistic camera-effect models estimated lost days and break-even costs under this convention. Separate models assessed regional transfer.

**Key results.** Median recorded endurance ranged from 85 days for Procell alkaline to 191 days for Energizer lithium. Relative to Energizer, cheaper lithium white-flash scenarios lost fewer than three additional expected camera-days per cycle at 90-day revisits, but about 2.5–12 at 120 days. At 120 days, the premium was offset at lost-day values of 1.37–1.65 illustrative units; Procell lacked follow-up at that horizon. Held-region Varta deployments outlasted model predictions despite greater flash workload.

**Conclusions.** The observation time at stake depends on the revisit schedule. Strong local endurance associations did not yield reliable regional predictions.

**Implications.** Servicing records can connect equipment reliability to survey design. These scenarios compare batteries under different observed conditions; prospective purchasing guidance needs installation-time predictors and local validation.

## Keywords

camera trapping; battery life; survival analysis; survey effort; field logistics; wildlife monitoring

## Introduction

A camera survey scheduled to run for four months does not necessarily deliver four months of observation. If batteries fail between visits, replacing them restores the camera but cannot recover the missed part of the survey. Where effort is counted from deployment dates alone, nominal trap-days continue to accumulate while nothing is recorded. This gap matters because ecological inference depends on when cameras offered an opportunity to detect animals [@Burton2015]. In networks maintained through periodic visits, battery endurance is consequently part of the sampling design [@Steenweg2017].

The useful quantity is the time a camera is expected to operate before its next visit. A battery's median lifetime alone does not give that quantity: failures early in an interval forfeit more observation than failures just before service. The area under a survival curve up to the visit gives expected runtime over that interval. This is the restricted mean survival time [@RoystonParmar2013], expressed here as camera-days. Comparing those areas makes the trade-off tangible. A premium battery buys little extra time when both alternatives usually outlast the visit interval; it can buy much more once failures become common before the next visit.

Field experience shows that camera batteries can fall far short of anticipated endurance, especially under winter and flash-heavy conditions [@Newey2015]. Servicing records offer a way to quantify this variation. They identify batteries still working at a visit and, for inactive cameras, the date of the last photograph. These records support an analysis of recorded operation, although the last photograph can precede shutdown. Linking that analysis to a revisit policy can show both how much observation time is at stake and what a price premium would need to preserve to be worthwhile.

We use 3,216 deployment intervals from 489 cameras in a Tasmanian network to make this connection. We estimate field differences in recorded endurance, compare expected lost camera-days at 90- and 120-day revisits, and translate those differences into break-even values of observation time. A held region tests how far the fitted endurance relationships travel within the network. The resulting comparison concerns batteries under their observed deployment conditions, rather than the effect of substituting one battery for another at a common site.

## Methods

### Field records and the lifetime endpoint

The dataset contains 4,432 serviced deployment intervals from six Tasmanian regions and a testbench cohort. The primary analysis uses 3,216 intervals from 489 camera identifiers in the Central, South East, North West and West regions of the TAS-CAM network. The camera was non-functioning at service in 1,735 intervals and operating in 1,481. South West (SW; 589 intervals), monitored within the same project and protocol, was held out of fitting. North East (564 intervals, most still operating) and testbench records (63, all ending in failure) are described separately (Table S1).

> Field-methods input: confirm dates, hardware and settings, fresh-set and allocation practices, identifier continuity, season assignment, visit rules and failure classification (author checklist: `docs/field_methods_author_questions.md`). The original outline describes Cuddeback 1279 cameras with eight AA cells and interchangeable flash units; its applicability to the complete analytical dataset needs confirmation.

A camera operating at service is right-censored: its batteries lasted at least as long as the recorded interval. For a camera found non-functioning because of dead batteries or an internal power error, duration ends at the last dated image. The camera may have continued to operate without taking another photograph. This endpoint is therefore minimum confirmed runtime, not observed shutdown. Service dates for these records, which would bound the gap from above, are unavailable. We assign last-image times as event times without imputing the gap. Survival and downtime estimates consequently use this operational-lifetime proxy. The non-informative-censoring assumption additionally requires that visits were not timed in response to battery condition; this awaits confirmation of field practice.

Predictors were battery brand, flash type (white or infrared), season, region, and flash and daylight images per recorded day. Daylight images are total images minus flash images; one missing flash count was replaced by zero under the existing processing rule. Both rates enter as $\log(1+\mathrm{images/day})$. They accumulated during the interval being analysed and share its duration as their denominator, so their coefficients describe retrospective associations. They are not known when a camera is installed. Procell is the only alkaline brand in the training cohort; the other four are lithium. Brand and chemistry therefore cannot be estimated as separate effects.

### Survival comparisons and regional transfer

Kaplan–Meier curves describe recorded survival by brand under the observed deployment mix [@KaplanMeier1958]. Their ordinary pointwise confidence intervals do not adjust for repeated cameras. A region-stratified Cox model related recorded lifetime to brand, flash, season and both workloads [@Cox1972]. Each region has its own baseline hazard; camera-cluster robust standard errors account for repeated intervals. Proportional-hazards diagnostics assessed whether the estimated hazard ratios could be interpreted as constant over follow-up.

For the observation-time calculations, we used parametric accelerated failure-time (AFT) models, which express covariate associations as multiplicative changes in lifetime [@Wei1992]. A sensitivity analysis compared Weibull, lognormal and loglogistic distributions, with common or brand-specific scales and with or without region effects. Matched Bayesian Weibull and loglogistic models, each with and without a normal camera random intercept, then assessed persistent differences among cameras. Covariates and priors were matched within each family. Management predictions integrate over camera variation and refer to a new camera from the fitted population. Model specification, priors, computation and diagnostics are in Supplementary Sections S2–S4.

Training calibration compares predictions averaged over each brand's observed covariates with Kaplan–Meier estimates. In SW, only 183 Varta white-flash intervals share a brand/flash combination with training. The transfer check uses the six independent-row AFT models without region effects; region-adjusted models have no estimated coefficient for SW. This is a support-limited held-region check within the same project, not independent external validation. It does not evaluate the regional transfer of the camera-effect models.

### From endurance to observation time and cost

Each modelled cycle starts with an operational camera and a replacement battery set. A scheduled visit at $T$ days installs another set, with no intervening rescue or restart. If $S(t)$ is its survival function, expected active time and the expected fraction lost are

$$
A(T)=\int_0^T S(t)\,dt,\qquad D(T)=1-\frac{A(T)}{T}.
$$

Thus $T D(T)$ is expected lost camera-days per cycle. Unlike the probability of failure before service, $1-S(T)$, this quantity accounts for how early failure occurs. Here it treats the last-image endpoint as failure; unrecorded operation after that image is counted as lost time. It is a modelled quantity under that convention, not a measurement of physical inactivity.

We compare the five white-flash brands using an observed operating scenario for each. The scenario uses the most frequent observed region–season cell and, within it, the observed workload pair nearest the cell's median transformed workloads (Table S5). This avoids combinations of region and season that never occurred with a brand. It does not standardise conditions across brands: each scenario combines a battery with its region, season and retrospective workload. The 90- and 120-day horizons were chosen during exploratory manuscript development after inspection of follow-up support. They illustrate fixed policies rather than optimise a schedule.

Expected lost days can be valued explicitly. Let $C_s$ be the service cost, $C_b$ the battery-set cost and $c_d$ the value of a lost camera-day. Expected cost per calendar day is

$$
L(T)=\frac{C_s+C_b}{T}+c_d D(T).
$$

This connects periodic servicing to the losses incurred while a failed unit remains unattended [@Barlow1963]. Our cycle assumes scheduled battery replacement at every visit. Costs are illustrative units: 24 for Procell, 36 for Wallaby, 40 for Ansmann, 48 for Varta and 52 for Energizer. The value $c_d$ is a management input, not something battery records identify. Cost per active day alone, $(C_s+C_b)/A(T)$, cannot select an interior optimum because it never increases as $T$ grows.

At a common revisit interval, a cheaper scenario $X$ saves $C_{b,E}-C_{b,X}$ relative to Energizer $E$. With $\bar D$ denoting posterior mean expected downtime, their expected costs match at

$$
c_d^*(T)=\frac{C_{b,E}-C_{b,X}}{T[\bar D_X(T)-\bar D_E(T)]}.
$$

The denominator is the additional expected lost camera-days under the cheaper scenario. For a positive denominator, values below the threshold favour the cheaper scenario and values above it favour Energizer. Common service costs cancel. Paired posterior draws preserve shared parameters across scenarios when calculating uncertainty in additional lost days and in the threshold. Section S5 distinguishes the ratio of expected quantities from its parameter-conditional uncertainty; the intervals exclude uncertainty about prices, the endpoint gap and scenario construction.

Support counts match brand, flash, region and season. Fewer than 20 intervals or 10 cameras at risk is flagged as thin support, a descriptive screen rather than a validated reliability threshold. Horizons beyond the matching cell's maximum follow-up are identified separately. These checks restrict extrapolation; they do not establish prospective validity for the retrospective scenarios.

## Results

### Endurance differed widely within the network

Recorded median lifetime ranged from 85 days for Procell to 191 days for Energizer (Table 1; Fig. [1](#fig-km-brand)). Lithium brands also differed substantially: Wallaby and Ansmann had shorter recorded lifetimes than Varta and Energizer. At 120 days, estimated recorded survival was 0.897 for Energizer and 0.871 for Varta, compared with 0.345 for Wallaby and 0.070 for Procell. These curves describe each brand's observed deployment mix.

The differences persisted after adjustment for flash, season and workload within regions. Relative to Ansmann, Energizer had less than a quarter of the hazard, Varta less than half, Wallaby more than twice, and Procell about seven and a half times the hazard (Table 1). White flash was associated with a hazard ratio of 3.75 relative to infrared (95% interval 2.95–4.77), and winter with 1.53 relative to autumn (1.33–1.77). Flash workload had a positive association (1.56; 1.30–1.88 per unit of log-one-plus rate), whereas daylight-image rate had a negative association (0.85; 0.74–0.96; Fig. S1). The global proportional-hazards test gave $p=0.011$, so these ratios summarise associations across follow-up.

Table 1. Recorded lifetime and adjusted brand associations in the training cohort. Medians and their ordinary pointwise 95% confidence intervals are Kaplan–Meier estimates, not adjusted for repeated cameras. Hazard ratios and 95% camera-cluster robust intervals come from the region-stratified Cox model, adjusted for flash type, season and realised workloads, with Ansmann as the reference brand. Chemistry is nested within brand.

| Brand | Chemistry | Intervals | Median days (95% CI) | Hazard ratio (95% CI) |
|---|---|---:|---:|---:|
| Ansmann | Lithium | 206 | 132 (127–140) | Reference |
| Energizer | Lithium | 1,181 | 191 (185–200) | 0.23 (0.19–0.28) |
| Procell | Alkaline | 761 | 85 (84–87) | 7.54 (6.02–9.43) |
| Varta | Lithium | 842 | 181 (174–187) | 0.42 (0.34–0.51) |
| Wallaby | Lithium | 226 | 108 (104–115) | 2.33 (1.89–2.88) |

Most cameras were used with more than one brand: 428 of 489 identifiers (87.5%), contributing 3,027 intervals. Adding camera effects to the matched AFT models left brand-coefficient directions unchanged and shifted them by less than 0.013 on the log-time scale. Under these models, accounting for persistent camera heterogeneity left the brand associations largely unchanged. This sensitivity check does not remove confounding by allocation or operating conditions. Model-family and camera-dependence diagnostics are reported in Sections S3–S4 and Figs S2–S3.

### The revisit interval changed the observation time at stake

At 90 days, the cheaper lithium white-flash scenarios lost fewer than three additional expected camera-days per cycle relative to the Energizer scenario. At 120 days, the difference was about 2.5–12 days (Fig. [2](#fig-additional-lost-days)). For Wallaby, extending the interval exposed a difference of 11.2–11.7 days across the two models; for Varta the corresponding difference was 2.5–2.6 days. These are contrasts between the observed scenarios in Table S5, under the last-image-as-failure convention.

These modelled time differences explain the economic contrasts. At 120 days, Wallaby saved 16 units per set but lost 11–12 extra days, while Varta saved 4 units and lost about 2.5–2.6 days. Across Ansmann, Varta and Wallaby, the value of a lost day that offset the saving was 1.37–1.65 units, about 3% of the 52-unit Energizer set price (Table 2). Larger purchase savings were accompanied by larger losses of time, placing these thresholds in a narrow range.

At 90 days, thresholds were higher, at 2.31–9.91 units across all four alternatives. Procell had the lowest threshold at that horizon because it lost considerably more time than the cheaper lithium scenarios; 22 intervals from 22 cameras remained at risk in its selected Central/winter cell. That cell had no follow-up beyond 117 days, so its 120-day comparison is withheld.

Weibull and loglogistic thresholds differed by at most 5% in supported 120-day comparisons, but by up to 27% at 90 days. Small differences in expected lost time at 90 days amplify model differences when used as the threshold's denominator. Uncertainty was also wider there: Ansmann's Weibull interval was 4.73–16.65 units at 90 days versus 1.21–2.41 at 120 days.

Table 2. Lost-camera-day values at which each cheaper white-flash scenario matches the expected cost of the Energizer scenario, in illustrative units under the last-image-as-failure convention. Point estimates equate posterior expected losses, and brackets give 95% credible limits from paired parameter draws (Section S5). Below a threshold the cheaper scenario has the lower expected cost; above it, Energizer does. At-risk counts are intervals / cameras in the matching brand, flash, region and season cell; the Energizer scenario had 244 / 100 at risk at 90 days and 222 / 97 at 120 days. † No observations in the selected Procell cell reach 120 days, so the unsupported extrapolation is withheld.

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

### The endurance models underpredicted survival in the held region

Varta white-flash deployments in SW had a median flash workload of 1.66 images per day, compared with 0.54 in training, yet their recorded median lifetime was longer: 201 days (187–217) versus 166 (158–173). At 180 days, observed SW survival was 0.601. The original Weibull model predicted 0.289, and the highest prediction among the six no-region models was 0.400 (Fig. [3](#fig-sw-transfer)). Allowing different lifetime distributions and brand-specific scales did not reproduce the held-region survival pattern.

## Discussion

### Observation time connects reliability to survey effort

The field differences have a practical consequence beyond ranking battery brands: the same planned deployment length can correspond to different amounts of observation time. Survival curves make that consequence calculable. Their area up to a scheduled visit describes expected runtime, while the remaining area describes time lost before service. The distinction matters whenever equipment can stop operating between visits, and complements survival analyses of other interruptions to camera coverage, such as theft [@Cardona2025].

For the supported white-flash scenarios at 120 days, modelled downtime ranged from about 1–2% for Energizer to 11% for Wallaby. Under the endpoint convention, 120 deployed days in the Wallaby scenario corresponded to approximately 107 expected active days, with 35 joint-cell intervals still at risk. Counting every deployed day would inflate its expected-effort denominator by about 12%, compared with 1–2% for Energizer (Table S4). This illustrates the accounting consequence of the fitted curves; it does not establish how much true operation went unrecorded after a last image.

The ecological consequence depends on the analysis. Holding detections fixed, an inflated effort denominator lowers an encounter rate proportionately. In an occupancy model, an inactive occasion offered no opportunity for detection and should not automatically be coded as an observed absence. Effects on occupancy or other ecological estimates depend on when downtime occurred, the species and the observation model; they are not given by the effort-inflation factor. Work on camera-trap distance sampling likewise distinguishes deployed time from effective survey duration, although trigger-recovery delays create a different form of lost time [@Kuhl2023].

### A longer-lasting battery buys time before the next visit

The contrast between 90 and 120 days shows why endurance and visit frequency must be considered together. At the shorter interval, the cheaper lithium scenarios forfeited little additional time relative to Energizer. Thirty days later, the difference reached nearly 12 days for Wallaby. A single endurance ranking cannot communicate this dependence on the survey schedule. Nor does a lower failure probability fully describe it: the timing of failures determines how much observation is lost.

The break-even calculation translates that time into a decision a survey manager can make with local prices. Divide the battery-set saving by the additional expected lost days, then judge whether those days are worth more or less than the resulting threshold. A breeding season, migration or management intervention may place a high value on continuity; a broad inventory may tolerate gaps. Average expenditure per camera-day does not determine this marginal value. It comes from what the survey needs to observe.

Common service costs cancel when comparing batteries at the same interval. Choosing the interval itself requires access constraints, survey duration and an observation requirement or explicit value of missed days. Our fixed-interval examples do not select that schedule. White flash also needs to be judged against the observation task: its association with shorter endurance does not make infrared preferable when colour images are required. Procell's shorter recorded endurance cannot establish a general chemistry effect, because it was the only alkaline brand and the lithium brands themselves differed substantially.

### Local associations did not supply portable predictions

Substantial within-camera brand overlap and the stability of estimates after camera adjustment support the consistency of the fitted associations. They do not make the deployments interchangeable or isolate a battery effect from allocation and environmental differences. Brands were used in different regions, seasons and workloads; the management scenarios deliberately retain combinations that occurred in the records. Switching brands at a common site is a different question from comparing those scenarios.

SW provides a direct warning about prediction. Its Varta white-flash deployments combined higher flash workload with longer recorded endurance, contrary to the training association. More flexible distributions did not resolve the mismatch. Unmeasured differences in hardware history, battery batches or environment could contribute, but these records cannot identify their roles. The evidence supports substantial local contrasts and an explicit way to evaluate observation-time trade-offs. Numerical purchasing or servicing guidance for new conditions requires local checking with predictors available when the deployment starts.

### Recording operation as well as animal detections

The last photograph confirms that a camera worked; it does not identify when it stopped. The distinction resembles the gap between a species' last sighting and its extinction, where observation frequency affects what can be inferred about the endpoint [@Solow2005]. Here image production is part of the measurement process as well as a source of battery demand. A frequently triggered camera may record its final image close to shutdown, while a quiet camera may remain operational without leaving another record.

This mechanism could contribute to the apparently protective association with daylight-image rate. It does not imply that taking more daytime photographs extends battery life. The rate also shares its duration denominator with the response, and deployment differences remain possible explanations. Total image counts and mean spacing cannot reconstruct the unobserved final gap. That uncertainty is especially consequential for interpreting contrasts of only a few modelled lost days at the 90-day horizon.

Retaining service dates, status at every visit, camera identity, battery allocation, settings and environmental context would strengthen future endurance records [@Meek2014Reporting]. Service dates would bound the last-image gap for cameras found inactive. Where hardware permits, a scheduled test image independent of animal activity could narrow it further, provided the schedule and image records are reliable and its additional battery demand is evaluated. Such records would distinguish power loss from an absence of wildlife detections and support prospective evaluation of battery and servicing choices.

## Conclusions

Battery endurance matters to a camera survey through the observation time it preserves before the next visit. In this network, cheaper lithium scenarios lost little additional time at 90 days relative to Energizer, but substantially more at 120 days. Survival analysis makes that schedule-dependent difference explicit and provides an observation-time basis for comparing purchase costs. The recorded endpoint and uneven deployment conditions constrain its interpretation, while the held-region mismatch shows why the numerical comparison needs local validation. Better records of camera operation would make the connection between reliability and survey effort more direct.

## Data and code availability

Data, code, dependency records, saved model draws and numerical checks are retained in the private repository and project archives. Supplementary Information documents the analyses. A public archive identifier and release terms will be supplied before public distribution.

## References
