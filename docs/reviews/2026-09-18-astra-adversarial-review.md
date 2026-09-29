# External adversarial review — 18 September 2026

Reviewer: Astra, independent reading of the current working tree. Review scope: empirical science, statistical implementation, management calculations, manuscript, evidence and reproducibility. This is a read-only review; the review report is the only repository file written by the reviewer. No personal memory, previous conversation, correspondence or other agents' conclusions were consulted.

## Initial manuscript-reader assessment (recorded before internal plans or review logs)

Read `manuscript/text/main.md`, `supplement.md`, `figures.md`, `supplement_figures.md`, the current integrated and supplement PDF proofs (14 and 7 pages), and their figure images. Inspected DOCX document structure and extracted text. The older September 12 backbone is not the current publication target. `settings/build.yaml` identifies the integrated draft and standalone supplement as current.

The paper poses a useful, concrete question for ecological monitoring: how much observation continuity can justify a battery-price premium at a fixed service interval? Its strongest potential contribution is an observational field dataset with explicit censoring and a transparent decision calculation, not a universally transferable battery ranking or a new survival method. The draft largely makes this distinction, separates brand from chemistry, warns about retrospective workload rates, treats the South West result as failed regional transfer, and avoids claiming that cost per active day has a finite unconstrained optimum. These are substantial strengths.

My initial concerns, to be tested against the evidence, are:

1. Field methods are still a placeholder: dates, camera hardware/settings, replacement rules, allocation and visit scheduling are not established. Those facts determine what the endpoint and repeated deployments represent and whether service censoring is plausibly non-informative. They are substantive prerequisites for submission, not merely missing background prose.
2. A last-image endpoint for inactive cameras and service-time censoring for active cameras do not automatically define one coherent observable lifetime. The disclosure of a proxy is helpful, but it may not rescue quantitative downtime claims if an inactive camera can remain functional after its last image. Internal power errors also need to be distinguished from battery depletion. The seriousness depends on source definitions and available field records.
3. Battery-price comparisons use different covariate profiles. This is disclosed, but readers cannot see the profiles' actual region, season and workloads in the paper or supplement. The abstract's approximately 1.6-unit threshold invites application beyond an unidentified profile.
4. The calibration figure shows material late discrepancies, especially for Energizer. Early 90/120-day calibration and the calculation of restricted active time therefore matter more than a global AIC ranking. Agreement between two families does not establish prediction validity.
5. The camera-effects comparison is reassuring about one form of dependence, but does not by itself identify within-camera causal brand effects or address time, deployment order, site or allocation confounding.
6. The main text retains an eight-panel conditional-optimum figure despite centring the practical result on fixed-interval thresholds. The diagnostic adds technical burden and risks diluting the central result. The Cox figure also exposes code-variable labels (`bbProcell`, `ftw`, etc.). Both are remediable presentation concerns.

The proofs are readable and the tables/captions are coherent; no gross PDF clipping or missing display was apparent. Fig. 3 and Fig. 4 need full-size viewing because their labels are small. At this stage the draft is suitable for the author's close read and targeted field-methods input, but a submission-readiness judgement must wait for data and implementation checks. The review below records the later evidence-based conclusions; the initial impressions above are retained rather than retrofitted.

## Full review

### Recommendation and scientific assessment

**APPROVE WITH CHANGES for the author's close read and targeted private methodological/field-protocol critique; not ready for submission.** General co-author circulation should respect the draft's own outstanding field-protocol and author-metadata requirements. No fatal arithmetic, likelihood, data-transformation or posterior-summarisation defect was found in the current fixed-interval analysis. There is one clear, consequential support-classification defect, plus two substantial conditions on the empirical and management interpretation that need resolution or firmer framing.

The study has a publishable applied contribution: a sizeable field dataset, strong descriptive brand-associated differences, an explicit treatment of unfinished runs, and a useful way of expressing battery-price premiums in units of observation continuity. It is strongest as an observational study of a defined recording endpoint, coupled to a conditional decision example. It has not established transferable physical battery lifetimes or a validated prospective brand-selection rule. The current manuscript usually recognises this, but its approximately 1.6-unit headline moves further towards operational advice than the endpoint, covariate construction and profile support justify.

The work merits revision rather than abandonment. The principal numerical machinery is substantially stronger than a superficial reading of the limitations might suggest. Conversely, successful computation cannot supply the missing field process or establish support for a covariate combination absent from the data.

Severity below follows the reviewer skill: **MAJOR** should be resolved before submission; **MINOR** is a bounded correction or reliability improvement; **NIT/optional** improves presentation without changing validity. A missing fact is identified as an evidence gap, not asserted to be a demonstrated field error.

### MAJOR 1 — The headline comparison includes an unobserved Ansmann profile, while the support screen ignores season

**Evidence.** [Profile construction](/home/bwbrook/papers/battery-survival/R/economics_core.R:42) chooses the modal season and modal region separately within each brand/flash group. The saved [profiles](/home/bwbrook/papers/battery-survival/outputs/sensitivity/2026-09-17/tables/profiles.csv) therefore assign Ansmann/white to **West, spring**. There are no such intervals. All 206 Ansmann observations fall into four cells: Central/spring 40, North West/autumn 67, South East/spring 31, and West/summer 68. Combining the two marginal modes creates a fifth, empty cell.

The [break-even support function](/home/bwbrook/papers/battery-survival/R/management_break_even.R:55) and [support classifier](/home/bwbrook/papers/battery-survival/R/management_policy.R:36) match brand, flash and region, but not season. The reported Ansmann risk count of 38 at 120 days is real, but consists entirely of **West/summer** intervals. It is not evidence for the complete West/spring profile. Nevertheless, [Table S4](/home/bwbrook/papers/battery-survival/manuscript/text/supplement.md:109) labels this profile “Within follow-up”, and the main text calls these “[typical operating conditions](/home/bwbrook/papers/battery-survival/manuscript/text/main.md:77)” and “[observed operating profiles](/home/bwbrook/papers/battery-survival/manuscript/text/main.md:113)”.

An independent count from the sealed training data gives:

| White-flash profile | Selected region / season | All brand/flash intervals | Intervals in selected joint categorical cell | Joint-cell intervals at risk, 90 / 120 days |
|---|---|---:|---:|---:|
| Ansmann | West / spring | 206 | **0** | **0 / 0** |
| Energizer | Central / summer | 1,156 | 251 | 244 / 222 |
| Procell | South East / autumn | 731 | 89 | 59 / 13 |
| Varta | West / summer | 501 | 80 | 77 / 56 |
| Wallaby | South East / autumn | 226 | 106 | 85 / 35 |

These are categorical-cell counts, not a demand that observations match continuous workloads exactly. The published matching-region counts are correctly calculated for their narrower stated definition; the defect is treating that definition as sufficient support for the whole profile. Even for populated cells, workload overlap still needs checking before describing a profile as representative.

**Impact.** Predictions for an empty cell are possible under the additive model, but depend on transferring season and region effects across brands. They are extrapolations across an unobserved combination, not an empirical within-cell comparison. Ansmann supplies the largest reported 120-day point threshold and the example behind the 2.6-day maximum camera-adjustment result. The same omission occurs in [sensitivity support calculations](/home/bwbrook/papers/battery-survival/R/sensitivity_run.R:83) and affects Fig. 4/Table S3 as well as Table 2/Table S4. This does not prove the predicted Ansmann lifetime is wrong or that the rounded 1.6-unit conclusion will change; it does invalidate its current support rationale.

**Proportional remedy.** Define the prediction target explicitly. Either use actual observed joint profiles, average predictions over a specified empirical covariate distribution, or retain a deliberately synthetic scenario and label its empty-cell extrapolation. Do not silently substitute a new target. Publish the actual region, season, workload values and support counts for every management profile. Separate categorical non-overlap, sparse follow-up and beyond-follow-up prediction. Recalculate derived predictions and manuscript summaries from the existing fits after this decision; a new fit is not the first necessary step. The cross-profile comparison must continue to be described as a comparison of operating scenarios, not the effect of choosing a different battery at an otherwise unchanged deployment.

**Verification.** Add a negative test in which marginal modes form an empty joint cell. Require that the profile is either changed under an explicit construction rule or flagged as unsupported. The current [test](/home/bwbrook/papers/battery-survival/tests/testthat/test-sensitivity-aft.R:133) actually locks in the incomplete brand/flash/region matching and would not catch this case. Recheck all affected tables, figure support symbols and the abstract after the derived-output refresh. A compact reproduction command appears below.

### MAJOR 2 — The field protocol and inception of a “deployment interval” remain insufficiently documented

**Evidence.** The [Methods placeholder](/home/bwbrook/papers/battery-survival/manuscript/text/main.md:49) explicitly leaves collection dates, camera model/settings, battery-set composition, allocation, replacement, season assignment and visit scheduling unconfirmed. The analysis CSV and dictionary do not establish these facts. The current cohort reconstruction is internally consistent, but that does not identify what was eligible to enter it. The statistical checks also establish that 99 camera identifiers occur in multiple regions, so the meaning and persistence of an identifier matter.

**Impact.** Several missing details determine the statistical estimand rather than merely improving descriptive reporting. Fresh versus partly used sets determines the start of a lifetime; visit rules determine the plausibility of non-informative censoring; the handling of cameras with no usable images, missing cards, hardware failures or early failures determines cohort selection; and the meanings of camera ID and internal power error determine what repeated observations and events represent. Calendar time, replacement order, hardware changes and purchasing batches can also be confounded with brand. The substantial multi-brand camera overlap and small random-intercept coefficient changes do not resolve those possibilities.

The absence of these details is **not evidence that any particular adverse protocol occurred**. For example, I found no active ad hoc exclusion hidden in the pipeline and no exact duplicate raw rows; I cannot infer from that that the source ledger includes every eligible deployment. The observed minimum duration does not establish how very early or zero-image failures were handled.

**Proportional remedy.** Obtain one source-grounded field-methods account covering:

1. Collection dates, start/end rules, fresh-set installation and whether all serviced deployments were eligible, including zero-image and unrecovered units.
2. Camera and flash models, material settings, number/type of cells, any battery mixing/reuse, and how brand was allocated across dates, cameras and regions.
3. Whether identifiers denote physical units, locations or another record key; how moves, replacements and repeated visits were linked.
4. Visit scheduling and reasons for unscheduled service; how functioning status and internal power errors were diagnosed; whether service dates or other shutdown bounds survive elsewhere.
5. How season was assigned and how missing counts or other ambiguous field records were encoded.

These points accord with the study's existing [camera-trap reporting citation](https://link.springer.com/article/10.1007/s10531-014-0712-8), which emphasises equipment, settings and deployment design. If information cannot be recovered, state what is unknown and narrow the conclusions accordingly. This need not trigger a new model unless the recovered facts show that the current event, censoring or dependence treatment is inappropriate.

**Verification.** Reconcile the field account to the raw column definitions, cohort counts and one or more traceable deployment sequences. Explicitly check that deployment origins and censored durations have the asserted meaning. If the underlying ledger is unavailable, record that limitation rather than presenting repository consistency as field verification.

### MAJOR 3 — The operational break-even headline needs a stronger boundary around the last-image proxy and retrospective predictors

**Evidence.** [Methods](/home/bwbrook/papers/battery-survival/manuscript/text/main.md:51) correctly disclose that inactive cameras have a last-image lower bound, not an observed shutdown, and that service-date upper bounds are unavailable. Operational cameras are censored at service. [Workload predictors](/home/bwbrook/papers/battery-survival/manuscript/text/main.md:53) use counts accumulated over the same response interval divided by that interval's duration. Despite those qualifications, the [abstract implication](/home/bwbrook/papers/battery-survival/manuscript/text/main.md:19), [management discussion](/home/bwbrook/papers/battery-survival/manuscript/text/main.md:142) and [effort example](/home/bwbrook/papers/battery-survival/manuscript/text/main.md:148) can be read as quantifying physical camera availability and a practicable battery choice.

**Impact.** Assigning last-image lower bounds as exact events is a transparent analysis convention. It is not automatically an observation model for physical shutdown. The unknown lag can vary with activity, settings, image-trigger frequency and deployment conditions. A lower bound for each inactive interval also does not establish a conservative *difference* in expected active time between profiles. The asymmetric use of last-image times for inactive cameras and service censoring for active cameras needs the observation process to justify its interpretation as one lifetime distribution.

This matters numerically because some thresholds divide a small predicted effort difference. From the saved results, the Energizer–Varta difference in restricted expected active time is only **0.72–0.85 days at a 90-day visit**, and **3.33–3.47 days at 120 days**. These values follow directly from price premium divided by break-even threshold. I have not established that actual last-image lags are that large or differ by that amount. The point is that the source data provide no bound showing the unmeasured difference is negligible relative to the quantity driving the decision.

Realised workloads pose a separate prediction limitation: a prospective manager does not know an interval's final image count or realised duration at installation. The draft correctly calls these associations retrospective and requests installation-time predictors in future work. That limitation should also govern the practical headline, rather than appearing chiefly in the Discussion. The two fitted families sharing a similar result cannot resolve a common endpoint or predictor problem.

**Proportional remedy.** Preserve the useful mathematical decision example, but tie all reported “downtime”, “active effort” and break-even conclusions explicitly to the fitted recorded-lifetime proxy and the stated retrospective scenarios. Qualify the abstract's 1.6-unit rule as a conditional model illustration, or remove that operational rule while retaining the underlying results. Do not imply that it has been validated as a physical battery-purchasing threshold. If field records establish sufficiently frequent diagnostic images or recover meaningful shutdown bounds, explain that evidence. Only then would a bounded gap sensitivity or interval-censoring analysis have a defensible empirical basis. Do not invent lags merely to create a reassuring sensitivity result.

A prospective prediction claim would additionally require covariates available before deployment and assessment on later/unseen deployments under the intended decision context. That is a different, consequential analysis tranche, not a mandatory refit for an explicitly retrospective, illustrative paper.

**Verification.** Read the abstract, Methods, Table 2 and ecological-effort paragraph without the Discussion. A reader should be able to identify the endpoint, the profiles being compared, the illustrative prices, and the absence of physical-shutdown/predictive validation. Check that any operational interpretation is supported by the recovered field facts rather than solely by narrow posterior intervals.

### MINOR 1 — The supplement goes beyond the SW checks actually performed

[Section S7](/home/bwbrook/papers/battery-survival/manuscript/text/supplement.md:119) says neither a region-adjusted AIC ranking “nor camera dependence explains” the transfer failure. The SW comparison described in [Section S2](/home/bwbrook/papers/battery-survival/manuscript/text/supplement.md:34) and implemented in the sensitivity analysis uses six **no-region independent-row** AFT models. The camera models contain training-region effects and were not evaluated as a comparable SW transfer test. Small camera-effect changes within training do not establish the explanation of an unseen-region discrepancy.

**Remedy:** state that the tested no-region distributions failed to reproduce SW survival, and that the separate camera analysis does not identify the cause. No new fit is needed for that wording correction. The main text's narrower distributional-flexibility statement is supported.

### MINOR 2 — Checkpoint reuse can relabel old fits with new inputs

[Camera fitting](/home/bwbrook/papers/battery-survival/R/sensitivity_camera_fit.R:72) writes a fresh `data.json` before checking whether `fit.rds` exists; if it exists, the old fit is reused without validating the input/model/prior identity. [The runner](/home/bwbrook/papers/battery-survival/scripts/run_sensitivity.R:20) also rewrites the cohort, profile and design objects before choosing a stage. An accidental rerun with changed data or configuration in the same output directory can therefore pair old posterior draws with new apparent inputs. A comment requiring a new output directory is helpful but does not enforce the invariant.

**Current impact:** I found **no such mismatch in the reviewed results**. Current raw-to-sealed data, design, profiles and all four stored Stan input objects match. This is a concrete future reproducibility failure mode, not evidence of current numerical corruption.

**Remedy and test:** validate a recorded input/model/prior signature before any checkpoint-associated input is overwritten or a fit reused; alternatively, fail if an existing completed directory is incompatible. A small negative test should change a data value or prior and require a clear refusal while preserving existing artifacts. This can be done without refitting or adding a new workflow framework.

### Presentation changes and optional improvements

- **MINOR, audience fit:** replace code-variable labels in [Fig. 2](/home/bwbrook/papers/battery-survival/outputs/figures/cox_hazard_ratios.png) with readable contrasts, units and reference levels. Labels such as `bbProcell`, `ftw` and `log_fi_pd` require the reader to decode implementation details. The information already exists in the caption/text; this is a derived-figure change.
- **Optional restructuring:** move the eight-panel conditional-optimum Fig. 4 to the supplement, retaining the camera-dependence finding in the main text. The main decision is now fixed-interval break-even; Table 2 carries it well. The conditional optima are properly distinguished from that decision, but take considerable space and attention for this audience. This is an editorial choice, not a validity requirement.
- **Optional final layout pass:** the supplied PDFs are readable and have no gross table/figure clipping. LibreOffice-rendered DOCX proofs retain the tables, equations and figures, but the main abstract's Implications/keywords spill onto an otherwise sparse second page and the references leave a short final page. Figures 3–4 require full-size viewing. Resolve these when the text and journal format are settled, not through another scientific-analysis cycle.
- **Optional numerical tidiness:** using all 6,000 saved draws instead of the balanced 1,000 changes these threshold point estimates by at most 1.7% and interval endpoints by at most 5.6% in my check. This is not a material defect. After correcting profile construction, all-draw summaries would reduce Monte Carlo dependence at little cost without new sampling.

### Findings that are reassuring, or limitations already handled adequately

**Data preparation and population accounting.** I reconstructed the training cohort from the current raw input, exclusions and partition code and obtained equality with the sealed training object and design data. The four cohort counts sum to 4,432; the training count is 3,216 intervals, 489 identifiers, 1,735 events and 1,481 censored observations. There are no exact duplicate raw rows. No active exclusion is concealed behind the template exclusions file. The one missing training flash count is processed as disclosed; the other missing image counts belong to the separately partitioned testbench records. I found no material numerical effect that warrants making that one-row rule a central revision issue.

**Descriptive survival and association.** Recomputed Kaplan–Meier medians and intervals reproduce Table 1. Cox intervals in the saved coefficient table use the camera-robust standard errors rather than the naive standard errors. Region stratification and the separation of Cox association from AFT AIC comparison are appropriate. The global PH test is not ignored, and the text avoids interpreting the fitted ratios as established constant multipliers. Ordinary KM intervals remain unadjusted for repeated cameras, but are explicitly labelled descriptive. I would not demand a new Cox model or cluster bootstrap simply to relabel an already qualified descriptive result.

**Repeated observations and confounding.** The reported 428 multi-brand camera identifiers, covering 3,027 intervals, are reproducible. The matched camera-effect models are a useful sensitivity to persistent identifier heterogeneity. They do not identify a causal within-camera brand contrast, account for arbitrary serial/calendar dependence or prove hardware identity. The manuscript largely states those limits accurately. Chemistry and brand are inseparable because there is only one alkaline brand; the text does not claim to estimate an independent chemistry effect.

**Likelihood, parameterisation and prediction mathematics.** The full fixed-effect design has rank 14/14. Independent calculations using Weibull and logistic densities reproduce the stored frequentist likelihoods to about \(4\times10^{-12}\). The Stan implementation includes the log-time Jacobian for observed events and the correct survival contribution for censoring. Brand-specific scales, centred design matrices, new-camera marginalisation and the normal quadrature are consistently implemented. Independent nested numerical integration of survival agrees with the analytic/quadrature restricted active-time calculation to \(3.5\times10^{-10}\) days across the checked profiles, families and horizons. No new fit was required to establish this.

**Sampling evidence.** The four saved objects contain 1,500 retained draws in each of four chains. From their embedded arrays I independently reproduced population-parameter rank-normalised split/folded \(\widehat R\) maxima below 1.003, zero divergences, zero maximum-depth hits and adequate energy behaviour; the smallest independently computed chain BFMI was approximately 0.553. Saved effective sample-size tables exceed the declared thresholds, but I did not independently reimplement their ESS calculation. Sampling diagnostics support computation under the models, not the field assumptions or their predictive adequacy.

**Family selection and calibration.** AIC values reproduce from all 12 saved frequentist fits, including the change in preference after adding brand scales and region. The supplement correctly labels this an exploratory, independent-row comparison rather than a selection procedure that accounts for camera dependence. At 90/120 days, observed brand/flash survival and fitted row-averaged survival are reasonably close at the aggregate level: for the expanded brand-scale region models the white-flash discrepancies are roughly three percentage points or less. This supports investigating the selected short horizons. It does not calibrate the empty Ansmann profile, correct informative censoring, or constitute prospective validation.

The late Energizer discrepancy is material but plainly reported: observed survival 0.405 at 270 days versus camera predictions 0.120/0.185, with 19 at risk. The manuscript does not hide it behind good AIC or use that tail as its main fixed-interval management result. I would not require an elaborate tail model solely to rescue an explicitly unsupported distant schedule.

**SW evidence.** The 183 supported Varta/white records and 406 unsupported records are distinguished. The no-region models avoid inventing an unseen SW coefficient. The strong underprediction is reported as transfer failure, not successful validation, and the region had already been examined. This is a useful negative result. Its within-project provenance and limited brand support prevent treating it as broad external validation, exactly as the main text states. Apart from the minor camera-dependence wording above, this limitation is handled appropriately.

**Decision calculation and uncertainty.** The current fixed-interval formula is correct for the specified repeated-cycle loss. Common service costs cancel, restricted active time is distinguished from survival probability at the visit, and the threshold averages downtime before forming the ratio. The code retains posterior pairing across profiles and preserves infinite crossings when appropriate. I independently reproduced all 16 current threshold point estimates and their 95% limits from the embedded saved draws to approximately \(4\times10^{-14}\). No posterior-mean versus median-of-optima substitution was found in this headline analysis. Conditional optima elsewhere are expressly labelled as diagnostics. The statement that cost per active day alone cannot select an interior optimum is correct.

Illustrative prices, omitted model/price/endpoint uncertainty, and the distinction between parameter uncertainty and individual-camera prediction are disclosed. It would be useful to show actual local prices for a real procurement recommendation, but illustrative units are adequate for the stated calculation if the operational claim is bounded as above. I found no reason to launch a larger joint optimisation.

**Ecological interpretation and citations.** The treatment of inactive occasions as unavailable observation opportunities is sensible, and the manuscript correctly avoids equating effort inflation with a universal bias multiplier for occupancy or other ecological estimators. The comparison with [Kühl et al.'s effective-duration study](https://pmc.ncbi.nlm.nih.gov/articles/PMC10571013/) explicitly distinguishes retrigger delay from battery failure. The operational caution attributed to [Newey et al.](https://link.springer.com/article/10.1007/s13280-015-0713-1), reporting requirements attributed to [Meek et al.](https://link.springer.com/article/10.1007/s10531-014-0712-8), and equipment-loss analogy from [Cardona et al.](https://link.springer.com/article/10.1007/s10531-025-03153-3) are supported by the primary sources inspected. I found no basis for alleging fabricated citations or an unsupported general novelty claim. The literature check was targeted, not a systematic search proving priority or exhaustive coverage.

### Evidence and reproducibility audit

**Scope actually inspected.** This review covers the current dirty working tree at HEAD `d2fb2a1d80387a404dbc43cfa6688adf0522f5c3`, including untracked sensitivity, Stan, management, tests and publication sources. I read the publication manuscript and supplement first; the initial assessment above was recorded before consulting the analysis specifications. Subsequent inspection covered raw data/dictionary/config/exclusions, core transformations and partitions, survival models, sensitivity and camera code, management calculations, `_targets.R`, command entrypoints, tests, CI/runtime configuration, saved fits and tables, figure scripts and publication build configuration. Internal specifications were checked against implementation, not accepted as validation. Prior review/correspondence conclusions were not used as evidence.

**Executed checks.** All scratch products are outside the repository in `/tmp/battery-astra-review/`; the only reviewer-owned repository change is this report.

| Check | Result and limitation |
|---|---|
| `R_PROFILE_USER=/dev/null OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 just test` | **217 passed, 0 failed, 0 warnings, 1 skipped.** The skipped posterior-extraction test requires the absent `posterior` package. No dependency installation was attempted. |
| Raw reconstruction, cohort/design/profile equality, design rank, KM and AIC recomputation | Passed; recorded in `numerical_checks.txt`. These are data/calculation checks, not source-ledger validation. |
| Independent likelihoods, sampler-array checks, break-even algebra and nested integration | Passed at tolerances reported above. Draw extraction used base R on embedded arrays, avoiding the missing `cmdstanr`/`posterior` runtime. |
| Comparison of current generated Stan data with all four stored `data.json` objects | Every component matched; stored metadata report CmdStan 2.38.0 and the specified sampling seed/iterations. |
| Management source/input/artifact SHA-256 lists | All entries matched: 6 source, 6 input and 8 derived-artifact entries. |
| Sensitivity artifact manifest | 75 available entries matched; 16 production chain CSVs listed in the 91-entry manifest were absent locally. All four saved RDS model objects retain their draws and sampler diagnostics. This local bundle is therefore not a complete copy of every listed raw chain artifact. |
| Archived source comparison | The older camera-source version differs from the current fit helper at the later draw-extraction coercion fix; the final-analysis source archive matches that current helper. I found no evidence that the fit likelihood was silently changed after fitting. |
| PDF/DOCX inspection | Reviewed all 14 main-PDF and 7 supplement-PDF pages, native figure files, DOCX XML/text, and all pages of temporary LibreOffice DOCX-to-PDF renders (18/9 pages). No gross loss of content or clipping found. Native Microsoft Word rendering was not tested. |

Temporary numerical checks can be repeated in the reviewed environment without fitting:

```bash
cd /home/bwbrook/papers/battery-survival
R_PROFILE_USER=/dev/null OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript --vanilla /tmp/battery-astra-review/numerical_checks.R
R_PROFILE_USER=/dev/null Rscript --vanilla /tmp/battery-astra-review/stan_input_checks.R
```

Those temporary scripts are audit aids, not a promised permanent repository interface. The central profile finding is independently reproducible directly from saved data:

```bash
cd /home/bwbrook/papers/battery-survival
Rscript --vanilla - <<'RS'
d <- readRDS('outputs/sensitivity/2026-09-17/cohorts.rds')$train
p <- read.csv('outputs/sensitivity/2026-09-17/tables/profiles.csv')
p <- p[p$ft == 'w', ]
for (i in seq_len(nrow(p))) {
  x <- p[i, ]
  g <- d[as.character(d$bb) == x$bb & as.character(d$ft) == x$ft &
         as.character(d$reg) == x$reg & as.character(d$seas) == x$seas, ]
  cat(x$bb, x$reg, x$seas, 'joint rows:', nrow(g),
      'at risk 90/120:', sum(g$rd >= 90), sum(g$rd >= 120), '\n')
}
print(with(subset(d, bb == 'Ansmann'), table(reg, seas)))
RS
```

**What was not established.** I did not verify field records outside the repository, actual physical shutdowns, installation-time exposure data, camera identity semantics, independent censoring, allocation randomness or transportability. I did not rerun the full empirical Cox fit (the original fit object was not present in the local baseline output set), regenerate all production fits, restore a clean environment, or run the complete raw-to-publication pipeline. The sensitivity fitting runtime differs from the project lockfile, as the supplement discloses; a recorded runtime is useful but not a demonstrated clean restoration. Baseline artifacts and the local sensitivity chain-CSV set are incomplete, so a public reproducibility release needs an explicit inventory and a clean rebuild/reuse test. No heavy computation, remote jobs, environment modification, external communication, commit or release was performed.

Passing tests alone would have missed MAJOR 1 because the support tests encode the same incomplete match. Source hashes establish identity of the checked files, not scientific adequacy. Conversely, absent local chain CSVs do not imply absent posterior evidence: the RDS arrays allowed direct numerical inspection.

### Finite revision agenda and stopping conditions

1. **Resolve the prediction target and empty-cell support defect.** Document the actual profiles, distinguish unsupported combinations from thin follow-up, and refresh the derived management/sensitivity summaries affected by the change. Start with saved draws; no automatic refit is warranted.
2. **Complete the field-methods account.** Determine whether any recovered fact changes the event, deployment origin, censoring or camera grouping. If so, specify the necessary analysis before running it. If facts remain unavailable, preserve that uncertainty in the scope.
3. **Align the headline with the estimand.** Keep the decision calculation as a conditional proxy-based illustration unless physical-availability and prospective-input claims can be supported. Correct the isolated SW camera-dependence sentence.
4. **Complete a focused presentation/reproducibility pass.** Replace code labels, make the profile/support table accessible, guard checkpoint reuse, and produce coherent proofs. Before public release, assemble the complete intended artifact set and verify the documented clean runtime/build; do not call the current private draft submission-ready merely because numerical checks pass.

The new, demonstrated scientific risk is **categorical non-overlap disguised by a coarser support screen**; its mitigation is a defined target plus truthful support reporting. The consequential unresolved field risks are **endpoint/inspection-process uncertainty and deployment/allocation provenance**; their magnitude is unknown and requires field evidence or narrower claims. The newly identified implementation risk is **unchecked checkpoint reuse**; it did not materialise in the inspected artifacts.

The author decisions needed are finite: what operating-profile population the management example should represent, which field facts can be substantiated, and whether the paper claims retrospective illustration or prospective operational prediction. There is no evidence-led reason at present to commission a general battery of additional families, heavy simulation or a new optimisation exercise.

The precise reassurance is conditional: **for the current archived cohort, stated endpoint convention, existing fitted models, specified profiles and illustrative prices, the checked likelihoods, posterior summaries and fixed-interval arithmetic are internally consistent.** After the profile/support defect is resolved and the field/interpretive conditions above are addressed, I see no demonstrated numerical obstacle to a credible applied paper. That conclusion is not validation of physical shutdown, a causal battery effect, or transfer to a new deployment setting.
