# AGENTS.md

## Purpose
This repository is the canonical, reproducible analysis and publication workspace for the camera-trap battery survival project.

Primary outcomes:
1. Reproducible analyses (frequentist Cox + AFT plus optional Bayesian AFT) from raw CSV to publication artifacts.
2. Publication-ready display items (figures, tables, model summaries).
3. A Makedoc-aligned publication manuscript, supported by an executable Quarto analysis/review document.

## Document Surfaces
1. `manuscript/paper.qmd` is the executable Quarto analysis/review document.
2. `manuscript/text/main.md` is the publication-manuscript source. `settings/build.yaml` builds the private main manuscript and standalone supplement with a verified working bibliography and neutral author-date style.
3. Do not draft publication prose into `paper.qmd`. Draft builds omit unconfirmed author metadata. Authorship, the complete bibliography and journal requirements must be settled before a circulation/submission build is described as ready.

## Current Scope
In scope for this repo:
1. Data validation, feature engineering, exclusion governance, and quality-control reporting.
2. Survival analyses (Kaplan-Meier for descriptive displays, Cox PH, AFT model family comparison, optional Bayesian AFT with Stan backend).
3. `targets` DAG orchestration with `dev` and `full` profiles.
4. Reproducibility controls (`renv`, CI checks, deterministic scripts).
5. Quarto analysis/review rendering and a separate Makedoc-aligned publication source.

Out of scope for phase 1:
1. Legacy `rstanarm::stan_surv` workflows (superseded by `brms` + `cmdstanr` in this repo).
2. New data collection, cloud data ingestion, external services.

## Source-of-Truth Layout
1. `R/`: reusable analysis functions (no ad hoc throwaway scripts).
2. `_targets.R`: canonical DAG definition.
3. `config/`: runtime config, exclusions, and future scenario inputs.
4. `data/`: tracked baseline data + data dictionary.
5. `outputs/`: generated artifacts (figures/tables/model objects/QC/manuscript outputs).
6. `manuscript/`: Quarto analysis/review source plus Makedoc-aligned publication source.
7. `scripts/`: thin command entrypoints for `dev`, `full`, and render flows.
8. `tests/`: `testthat` unit and contract tests.
9. `methods/`: legacy analysis scripts retained for provenance only.

## Working Rules
1. Do not edit generated artifacts manually.
2. Do not mutate raw input data in place.
3. Prefer small, testable functions in `R/` over monolithic scripts.
4. Keep pipeline behavior controlled by config and environment profiles, not hardcoded local paths.
5. Any exclusion must be explicit in `config/exclusions.csv` with a reason code.
6. Keep manuscript numbers and visuals derived from pipeline outputs only.
7. Keep Cox association inference separate from AFT distribution selection by AIC.
8. Describe SW as a support-limited held-region check, not independent external validation.
9. Servicing outputs describe cost and downtime curves, not unconstrained optimal intervals. Read `docs/servicing_cost_interpretation.md` before changing this decision model.
10. The separately authorised September 2026 sensitivity analysis is specified in `docs/sensitivity_analysis_plan.md` and `config/sensitivity.yml`. Its conditional inspection-policy optima use an explicit lost-camera-day value. Keep these separate from the canonical cost-per-active-day curves. Barry authorised manuscript synthesis on 18 September 2026; the publication source now integrates these results while retaining the original analysis as a labelled baseline. This does not replace the canonical production fits.

## Canonical Commands
Use `just`.

Primary:
1. `just restore`
2. `just dev`
3. `just full`
4. `just manuscript` (Quarto analysis/review document)
5. `just test`
6. `just check`
7. `just bayes-check` / `just bayes-prod` for Bayesian validation and production profiles
8. `just bayes-gamma-check` for the slower exploratory gamma family smoke profile
9. `just publication` (main and supplementary Makedoc PDF/DOCX from saved model outputs)
10. `just management` (archived exploratory joint-cost comparisons from saved camera fits)
11. `just break-even` (current white-flash fixed-interval comparison from saved camera fits; use the documented runtime)

Lockfile maintenance:
1. `just lock`

## Definition of Done (per work package)
1. Pipeline executes in expected profile (`dev` or `full`) without manual edits.
2. New/changed logic has tests.
3. User-facing documentation is updated when the supported workflow changes.
4. The handoff reports verification performed and material residual risks.

## Handoff Format
When completing substantial work, report:
1. Work package/purpose.
2. Files changed grouped by code/tests/docs/config.
3. Commands run and pass/fail outcomes.
4. Material risks/caveats and the highest-value next task.

The September 18 response to Fable review is specified in `docs/management_revision_plan.md`. Joint decisions minimise posterior expected loss before choosing an interval; do not substitute a median of draw-wise optima. Costs remain illustrative units. Keep no-finite outcomes, regional extrapolation, pooled extrapolation and thin support distinct.

Barry authorised the focused follow-up to Fable message 226: the current main
management result is a white-flash break-even comparison at 90/120 days, with
paired-draw uncertainty. The older joint optimisation remains provenance and
must not be silently reinstated as a headline result. See the final amendment
in `docs/management_revision_plan.md`. Wildlife Research is the working target.


Barry authorised the 19 September independent-review correction in
`docs/profile_support_revision_plan.md`. Current profiles select an observed
joint region/season cell and an observed nearest-median workload pair. Support
must match brand/flash/region/season; regional and pooled counts are context.
`just refresh-profiles`, then `just break-even`, derive the current results under
`outputs/management/2026-09-19/` from the sealed 17 September fits. Do not overwrite
17/18 September archives. The current management quantities remain conditional
on the last-image endpoint convention and retrospective workload scenarios.
Unsigned legacy sensitivity directories cannot be resumed by the fitting runner;
use a new directory for any authorised new fitting. Saved-fit derivation scripts
may read sealed legacy directories without modifying them. Field facts requiring
author confirmation are listed in `docs/field_methods_author_questions.md`.
