# AGENTS.md

## Purpose
This repository is the canonical, reproducible analysis and publication workspace for the camera-trap battery survival project.

Primary outcomes:
1. Reproducible analyses (frequentist Cox + AFT plus optional Bayesian AFT) from raw CSV to publication artifacts.
2. Publication-ready display items (figures, tables, model summaries).
3. A Makedoc-aligned publication manuscript, supported by an executable Quarto analysis/review document.

## Document Surfaces
1. `manuscript/paper.qmd` is the executable Quarto analysis/review document.
2. `manuscript/text/main.md` is the publication-manuscript source for the future Makedoc build.
3. Do not draft publication prose into `paper.qmd` or activate Makedoc until bibliography, CSL, authorship, and build settings are ready.

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
