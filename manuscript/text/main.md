# Keeping wildlife cameras running: battery survival and servicing trade-offs in a Tasmanian field network

<div id="authors"></div>

> Private working draft, 19 September 2026. Costs are illustrative units. Field-protocol details, authorship, contributions and acknowledgements remain to be confirmed before co-author circulation. Wildlife Research is the working target.

## Abstract

**Context.** Battery exhaustion reduces the observation time delivered by wildlife cameras, linking battery choice and servicing frequency to the cost and continuity of ecological surveys.

**Aims.** We assessed battery survival in a Tasmanian camera network and compared the value of longer runtime under fixed revisit schedules.

**Methods.** Survival analyses used 3,216 deployment intervals from 489 cameras. Operational cameras were censored at service; last-image times provided minimum confirmed runtimes for cameras found inactive. Camera-effect Weibull and loglogistic models translated this endpoint convention into conditional downtime and break-even costs for observed deployment scenarios.

**Key results.** Median recorded lifetime ranged from 85 days for Procell alkaline batteries to 191 days for Energizer lithium batteries. White flash was associated with 3.75 times the hazard of infrared flash. Most cameras used multiple brands, and accounting for persistent camera differences changed brand associations little. At 120-day revisits, three cheaper lithium/white-flash scenarios tied Energizer at lost-day values of 1.37–1.65 illustrative units, about 3% of its battery-set price. The selected Procell alkaline scenario lacked follow-up at 120 days. The two model families gave similar thresholds at 120 days, but differed more at 90 days. Varta batteries lasted longer in a held region despite greater flash workload.

**Conclusions.** Under the endpoint convention, lower modelled downtime could offset higher purchase prices in these scenarios. The trade-off depends on revisit interval and deployment conditions; fitted workload effects did not explain regional transfer.

**Implications.** The break-even framework makes observation priorities explicit. These conditional scenarios require local prices and validation with installation-time predictors before use as purchasing or servicing guidance.

## Keywords

camera trapping; battery life; survival analysis; survey effort; field logistics; wildlife monitoring

## Introduction

A camera contributes observation effort only while it can record wildlife. Battery exhaustion can leave a deployed camera inactive for weeks before its next service, especially where access is difficult. Counting that entire deployment as survey effort overstates the opportunity to detect animals. Camera-trap inference already depends on connecting animal activity, camera operation and recorded detections [@Burton2015]. As monitoring networks expand, maintaining their operation becomes a recurring ecological and logistical problem [@Steenweg2017].

Battery selection and revisit frequency are linked. A cheap set may require more visits; a longer-lasting set may reduce travel or preserve observations during a critical season. Field experience shows that camera settings, image volume and environmental conditions can undermine nominal endurance [@Newey2015]. Equipment loss is another source of interrupted coverage, as a survival analysis of camera theft in Tasmania demonstrates [@Cardona2025]. Battery depletion differs because replacing the power supply restores the next period of observation, making the timing of service central to the decision.

Servicing records can help quantify this trade-off, but a camera still operating at inspection has an unfinished lifetime. Averaging only completed runs discards that information. Survival analysis retains operational cameras as censored observations while estimating lifetime distributions and associations [@KaplanMeier1958; @Cox1972]. Those distributions can be translated into expected active days under a revisit schedule. The management question then requires an additional choice: how much is missed observation time worth, or how much can the survey tolerate?

We use a Tasmanian camera network to describe differences among battery brands, assess associations with flash type, season and image workload, and compare battery/servicing combinations under explicit cost assumptions. We also examine whether conclusions depend on lifetime distribution or recurring camera identifiers, and whether fitted relationships reproduce survival in a held region. The aim is to turn field records into interpretable planning information while keeping the recorded lifetime, environmental context and observation requirement visible.

```{=latex}
\clearpage
```

```{=openxml}
<w:p><w:r><w:br w:type="page"/></w:r></w:p>
```

## Methods

### Field records and the lifetime endpoint

The dataset contains 4,432 serviced deployment intervals. The primary analysis uses 3,216 intervals from 489 camera identifiers in the Central, South East, North West and West TAS-CAM regions: 1,735 intervals ended with cameras non-functioning at service and 1,481 with cameras operational. South West (SW; 589 intervals) is a held-region check from the same project and protocol. North East (564 intervals) and testbench records (63) are described separately (Table S1).

> Field-methods input: confirm dates, hardware and settings, fresh-set and allocation practices, identifier continuity, season assignment, visit rules and failure classification (author checklist: `docs/field_methods_author_questions.md`). The original outline describes Cuddeback 1279 cameras with eight AA cells and interchangeable flash units; its applicability to the complete analytical dataset needs confirmation.

Each row represents one serviced deployment. Operational cameras are right-censored at service. For cameras non-functioning because of dead batteries or an internal power error, duration ends at the last dated image. This is a minimum confirmed runtime, not an observed physical shutdown time. Service-date upper bounds for these records are unavailable; we assign last-image times as events without imputing the subsequent gap. The fitted survival describes this operational-lifetime proxy. Downtime calculations additionally assume that image production ended at power loss; they cannot separate subsequent unobserved operation from actual inactivity. Non-informative censoring also depends on how visits were scheduled.

Recorded predictors are brand, flash type, season, region, and flash and daylight images per recorded day. Daylight images equal total images minus flash images; one missing flash count is replaced by zero under the existing processing rule. Rates enter as $\log(1+\mathrm{images/day})$. Because these workloads were realised during the interval and use its duration in their denominator, their coefficients describe retrospective associations rather than independently assigned exposures. Procell is the only alkaline brand in the training cohort; the other four brands are lithium. Brand and chemistry therefore cannot be estimated as separate effects.

### Survival comparisons

Kaplan-Meier curves and median lifetimes describe the observed deployment mix by brand [@KaplanMeier1958]. Their ordinary pointwise confidence intervals do not adjust for repeated cameras. A region-stratified Cox model relates the lifetime endpoint to brand, flash type, season and both workload variables, with camera-cluster robust standard errors [@Cox1972]. Proportional-hazards diagnostics qualify interpretation of its hazard ratios.

Accelerated failure-time (AFT) models provide complete lifetime distributions for the servicing calculations [@Wei1992]. A sensitivity analysis compared three distribution families, common or brand-specific error scales, and inclusion or omission of region effects. Matched Bayesian Weibull and loglogistic models then assessed a normal camera random intercept, with the same covariates and priors within each family. Management predictions integrate over the distribution of effects for a new camera. Supplementary Methods give the model equations, priors, computation, diagnostics and comparison tables.

Training calibration compares predictions averaged over observed covariates with Kaplan-Meier survival. SW predictions use only the 183 Varta/white-flash intervals whose brand/flash combination is represented in training. We evaluate models without region terms there, avoiding an arbitrary coefficient for an unseen region. This is a support-limited transfer check, not independent external validation.

### Battery selection, servicing and lost observation time

A service cycle begins with an operational camera and a replacement battery set. Another set is installed at the scheduled visit after $T$ days, with no intervening rescue visit or restart. For survival function $S(t)$, expected active time is $A(T)=\int_0^T S(t)\,dt$ and the expected fraction of the interval lost is $D(T)=1-A(T)/T$. This fraction differs from the probability of failing before service, $1-S(T)$.

Let $K=C_s+C_b$ combine service and battery-set costs. Cost per expected active day, $K/A(T)$, cannot increase as servicing is delayed, so it alone cannot identify an interior optimum. We attach an explicit value $c_d$ to each lost camera-day and compare total expected cost per calendar day:

$$
L(T)=\frac{C_s+C_b}{T}+c_d D(T).
$$

Classical inspection scheduling balances checking costs against losses while failures remain undetected [@Barlow1963]. Here, each scheduled visit installs a fresh battery set, and the objective is cost per calendar day over repeated cycles.

The value of downtime is a management input, not estimated from battery records. Battery-set costs are illustrative units: 24 (Procell), 36 (Wallaby), 40 (Ansmann), 48 (Varta) and 52 (Energizer), rather than confirmed Australian-dollar prices. At a common revisit interval and common per-camera service cost, the service component cancels between alternatives.

We focus on the five white-flash profiles, comparing each cheaper alternative $X$ with Energizer $E$ at 90 and 120 days. For each brand/flash group, we select its most frequent observed region–season combination, then the observed workload pair nearest that cell's median transformed workloads (Table S5). This rule avoids constructing categorical combinations absent from the data. It compares observed deployment scenarios rather than isolating a causal effect of changing battery brand. Workloads were measured retrospectively, so these calculations are conditional illustrations, not validated forecasts from information available at installation. With $\bar D$ denoting posterior mean expected downtime, the break-even lost-day value is

$$
c_d^*(T)=\frac{C_{b,E}-C_{b,X}}{T[\bar D_X(T)-\bar D_E(T)]}.
$$

When the downtime difference is positive, the cheaper profile has lower expected loss below this threshold and Energizer above it. We calculate uncertainty using paired posterior draws from each camera model, integrating new-camera effects. Supplementary Methods distinguish this expected-loss threshold from its parameter-conditional uncertainty and describe cases without a positive crossing. Risk counts accompany each comparison and match brand, flash, region and season jointly; fewer than 20 intervals or 10 cameras is flagged as thin support. Predictions beyond that cell's maximum follow-up are identified separately. The full group size and event count also inform interpretation. These fixed-interval comparisons do not select an optimal revisit schedule.

```{=latex}
\clearpage
```

## Results

### Battery, flash and workload differences

Median recorded lifetimes ranged from 85 days for Procell to 191 days for Energizer, with substantial variation among the four lithium brands (Table 1; Fig. [1](#fig-km-brand)). Relative to Ansmann, adjusted hazard was lower for Energizer and Varta and higher for Procell and Wallaby. These comparisons describe brand-associated differences under the observed field conditions.

Table 1. Recorded lifetime and adjusted brand associations in the training cohort. Medians and ordinary pointwise 95% confidence intervals come from Kaplan-Meier estimates; they are not camera-cluster adjusted. Hazard ratios and 95% camera-cluster robust intervals come from the region-stratified Cox model, adjusted for flash type, season and realised workloads, with Ansmann as reference. Chemistry is nested within brand.

| Brand | Chemistry | Intervals | Median days (95% CI) | Hazard ratio (95% CI) |
|---|---|---:|---:|---:|
| Ansmann | Lithium | 206 | 132 (127-140) | Reference |
| Energizer | Lithium | 1,181 | 191 (185-200) | 0.23 (0.19-0.28) |
| Procell | Alkaline | 761 | 85 (84-87) | 7.54 (6.02-9.43) |
| Varta | Lithium | 842 | 181 (174-187) | 0.42 (0.34-0.51) |
| Wallaby | Lithium | 226 | 108 (104-115) | 2.33 (1.89-2.88) |

White flash was associated with higher hazard than infrared flash (3.75; 95% interval 2.95-4.77), and winter with higher hazard than autumn (1.53; 1.33-1.77). Hazard increased with realised flash workload (1.56; 1.30-1.88 per unit of log-one-plus rate) but decreased with daylight-image rate (0.85; 0.74-0.96; Fig. [2](#fig-cox-hazard-ratios)). The global proportional-hazards test gave $p=0.011$, so these ratios summarise associations across follow-up rather than establish constant multipliers.

Most cameras contributed more than one brand: 428 of 489 identifiers (87.5%) covered 3,027 intervals. The data therefore include substantial within-camera overlap. Brand coefficients retained their directions and changed by less than 0.013 on the log-time scale when camera effects were added to the matched AFT models. This strengthens the evidence that persistent camera differences alone do not explain the brand pattern, without removing differences in deployment timing, allocation or environment.

### Battery costs at fixed revisit intervals

At a 120-day revisit interval, the three cheaper lithium/white-flash profiles tied Energizer at lost-day values of 1.37–1.65 cost units across the two camera models (Table 2). Per lost camera-day, these values are equivalent to about 3% of the 52-unit Energizer set price. Above the corresponding threshold, the Energizer scenario's lower modelled downtime outweighed its higher purchase cost; below it, the cheaper alternative had lower expected loss. A common service cost cancels.

At 90 days, all four cheaper white-flash profiles had observations remaining at risk. Their break-even thresholds were higher, at 2.31–9.91 units. Family differences in the expected-loss thresholds were at most 5% for the supported 120-day comparisons but reached 27% at 90 days. Uncertainty was wider at 90 days: for Ansmann, the Weibull interval was 4.73–16.65 units, compared with 1.21–2.41 at 120 days. Procell's selected Central/winter cell ended at 117 days, so its 120-day comparison is withheld; at 90 days, 22 intervals from 22 cameras remained at risk. These comparisons condition on the lifetime proxy and retrospective workloads and do not validate prospective battery choices.

Table 2. Break-even lost-camera-day values for cheaper white-flash scenarios relative to Energizer, in illustrative units under the last-image-as-failure convention. Point estimates equate posterior expected losses; brackets give 95% credible limits from paired parameter draws (Section S5). Below each threshold the cheaper scenario has lower expected loss; above it Energizer does. Risk counts match brand, flash, region and season. Energizer has 244 / 100 intervals / cameras at risk at 90 days and 222 / 97 at 120 days. † No observations reach this horizon in the selected Procell cell; the unsupported extrapolation is withheld.

| Days | Cheaper profile | Weibull | Loglogistic | At risk |
|---:|---|---:|---:|---:|
| 90 | Ansmann | 7.84 [4.73, 16.65] | 9.91 [6.11, 19.50] | 57 / 57 |
| 90 | Procell | 2.33 [2.01, 2.71] | 2.31 [1.97, 2.75] | 22 / 22 |
| 90 | Varta | 6.65 [3.83, 16.49] | 7.23 [4.39, 16.78] | 90 / 90 |
| 90 | Wallaby | 6.65 [4.60, 10.91] | 8.19 [5.77, 12.99] | 85 / 85 |
| 120 | Ansmann | 1.65 [1.21, 2.41] | 1.64 [1.24, 2.32] | 38 / 38 |
| 120 | Procell | — | — | 0 / 0† |
| 120 | Varta | 1.60 [1.06, 2.83] | 1.53 [1.06, 2.60] | 85 / 85 |
| 120 | Wallaby | 1.43 [1.14, 1.85] | 1.37 [1.12, 1.72] | 35 / 35 |

### Sensitivity and regional transfer

The expanded independent-row AFT comparison favoured loglogistic over equivalent Weibull by 11.25 AIC units, with brand-specific scales and region effects improving fit (Fig. [3](#fig-aft-calibration); Table S2). Camera adjustment changed posterior median conditional intervals by at most 1.7 days among the 20 comparisons passing the joint-profile support screen. Family differences reached 8.3 days for Energizer/infrared at cost ratio 50, although that entire brand/flash stratum contained only 25 intervals and eight events (Fig. [4](#fig-camera-decisions); Table S3). SW exposed a more substantial transfer failure. Varta/white deployments there had median flash workload 1.66 images/day versus 0.54 in training, yet median lifetime was longer: 201 days (187-217) versus 166 (158-173). At 180 days, observed SW survival was 0.601, compared with 0.289 for the original Weibull and at most 0.400 among the six no-region models. Distributional flexibility did not explain the held-region difference.

## Discussion

### What the battery comparison means for practice

Battery purchase price is an incomplete guide to camera-trap running cost. The observed twofold range in median runtime changes the opportunity to avoid visits and retain survey coverage. White flash also had a substantial association with shorter lifetime. These results support evaluating battery and flash choices together with the intended observation task, rather than adopting one endurance figure for every deployment. Choosing infrared solely for endurance may be inappropriate when the study requires colour images or other attributes of white-flash photographs.

The chemistry pattern is consistent with the longer field endurance expected of lithium options, but this dataset cannot estimate a general lithium-versus-alkaline effect: Procell is its only alkaline brand, and lithium brands also differ markedly. Nor are the cost profiles interchangeable treatments. Each represents a different observed mix of region, season and workload. Multiple brands within cameras strengthen the comparison, and the small changes after camera adjustment are reassuring about persistent camera heterogeneity. They do not turn observational allocation into a controlled trial.

### Paying for observation continuity

The break-even comparison illustrates the value of retained observations under the fitted lifetime proxy and specified deployment conditions. It does not validate a purchasing rule for new deployments: image activity after the last recorded image is unknown, and the workload predictors were measured retrospectively. At 120 days, a value above about 1.7 units per lost camera-day favoured the Energizer scenario over the three cheaper lithium scenarios in both models; the selected alkaline scenario had no follow-up at that horizon. At 90 days, less observation time was lost and the purchase-price premium required a higher value per missed day to recover its cost. Uncertainty in each comparison remains relevant, especially where expected downtime differences are small.

An observation requirement should precede selection of a servicing interval. Continuous coverage during breeding, migration or a management intervention may warrant a different schedule from a broad inventory. The fixed-interval comparison accommodates an existing visit schedule; choosing that schedule requires additional assumptions about observation priorities, access and the survey's duration. Common service costs cancel here, but costs that differ between alternatives or change with the visit schedule would need explicit treatment. The illustrative battery prices and break-even values do not supply local prices or the scientific value of a missed day.

### Downtime and ecological effort

Under the last-image-as-failure convention, treating all deployed days as active gives a nominal-to-modelled-active-effort ratio of $1/[1-D(T)]$. Across supported white-flash scenarios at 120 days, this ratio ranged from 1.01–1.02 for Energizer to about 1.12 for Wallaby (Table S4). For Wallaby, both models predict about 11.1% downtime: 120 nominal days correspond to approximately 107 modelled active days, with 35 joint-cell intervals still at risk. The Procell scenario is excluded at this horizon because its joint-cell follow-up ends earlier. These calculations use the recorded-lifetime proxy; they do not measure the unknown gap after the last image.

For an encounter-rate calculation, holding detections fixed while using an inflated effort denominator lowers the estimated rate. Occupancy and other observation models require attention to when the camera was available: an inactive occasion offers no detection opportunity and should not automatically be coded as an observed absence. The direction and magnitude of resulting ecological bias depend on the model, species and timing of downtime; they are not universally equal to the effort-inflation factor. Work on camera-trap distance sampling similarly shows why effective survey duration matters, although its retrigger-delay mechanism differs from battery exhaustion [@Kuhl2023].

### Endpoint and transfer limitations

Two features qualify the workload associations. Realised image rates use the response duration in their denominator, and the last-image endpoint can stop earlier than physical shutdown. More frequent daylight images may place the last recorded image closer to shutdown, potentially contributing to the apparently protective daylight coefficient. That explanation is consistent with the endpoint, but cannot be distinguished here from deployment differences or other mechanisms. It does not imply that taking more daytime photographs extends battery life.

SW demonstrates why workload adjustment alone is insufficient for transfer. Its Varta/white cameras lasted longer despite roughly three times the median flash workload, whereas the training association would predict shorter lifetime as workload increased. Camera age, battery batches and drier, less humid conditions are possible explanations; their contributions were not established by these records. The held-region result limits a universal scheduling recommendation without negating the observed training contrasts.

Future records should retain service dates, operating status, camera identity, battery allocation, settings and environmental context, consistent with wider camera-trap reporting guidance [@Meek2014Reporting]. Service dates would bound the last-image gap rather than reveal an exact shutdown. Prospective servicing guidance will require predictors available at installation and evaluation on new deployments.

## Conclusions

Field records show substantial battery-brand and flash-associated differences in camera runtime. Linking these lifetimes to servicing costs makes the value of observation continuity explicit: the preferred operating profile depends on the revisit policy and the assumed cost of missed days. Fixed-interval break-even values make the purchase-price premium interpretable in terms of retained observation days. They illustrate how observation priorities affect the cost comparison, conditional on the last-image endpoint and retrospective operating scenarios. Prospective use requires validation with installation-time predictors and a better-resolved inactivity endpoint.

## Data and code availability

The private project repository contains the baseline CSV, data dictionary, targets workflow and dependency lockfile. The separate sensitivity analysis and management synthesis preserve their source, saved model draws, runtime versions and numerical checks; the latter reuses the camera fits without new sampling. Supplementary Information provides methods and additional tables. A public archive identifier and release terms will be added before public distribution.

## References
