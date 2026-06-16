# AGENTS.md

## Purpose
This repository is the canonical, reproducible analysis and manuscript workspace for the camera-trap battery survival project.

Primary outcomes:
1. Reproducible analyses (frequentist Cox + AFT plus optional Bayesian AFT) from raw CSV to publication artifacts.
2. Publication-ready display items (figures, tables, model summaries).
3. Manuscript source in Quarto with outputs wired directly from generated artifacts.

## Current Scope
In scope for this repo:
1. Data validation, feature engineering, exclusion governance, and quality-control reporting.
2. Survival analyses (Kaplan-Meier for descriptive displays, Cox PH, AFT model family comparison, optional Bayesian AFT with Stan backend).
3. `targets` DAG orchestration with `dev` and `full` profiles.
4. Reproducibility controls (`renv`, CI checks, deterministic scripts).
5. Quarto manuscript render (`html` + `pdf`) from one source.

Out of scope for phase 1:
1. Legacy `rstanarm::stan_surv` workflows (superseded by `brms` + `cmdstanr` in this repo).
2. New data collection, cloud data ingestion, external services.

## Source-of-Truth Layout
1. `R/`: reusable analysis functions (no ad hoc throwaway scripts).
2. `_targets.R`: canonical DAG definition.
3. `config/`: runtime config, exclusions, and future scenario inputs.
4. `data/`: tracked baseline data + data dictionary.
5. `outputs/`: generated artifacts (figures/tables/model objects/QC/manuscript outputs).
6. `manuscript/`: Quarto manuscript source and bibliography files.
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

## Canonical Commands
Use either `just` (preferred) or `make`.

Primary:
1. `just restore` (or `make restore`)
2. `just dev` (or `make dev`)
3. `just full` (or `make full`)
4. `just manuscript` (or `make manuscript`)
5. `just test` (or `make test`)
6. `just check` (or `make check`)
7. `just bayes-check` / `just bayes-prod` (or `make bayes-check` / `make bayes-prod`) for Bayesian validation and production profiles
8. `just bayes-gamma-check` for the slower exploratory gamma family smoke profile

Lockfile maintenance:
1. `just lock` (or `make lock`)

## Definition of Done (per work package)
1. Pipeline executes in expected profile (`dev` or `full`) without manual edits.
2. New/changed logic has tests.
3. Documentation is updated (`README.md`, `docs/plan.md`, and manuscript notes if relevant).
4. Reproducibility commands and outputs are listed in the Build Report.

## Build Report Format
When completing substantial work, report:
1. Work package/purpose.
2. Files changed grouped by code/tests/docs/config.
3. Commands run and pass/fail outcomes.
4. Generated artifacts with exact output paths.
5. Risks/caveats and suggested next tasks.
