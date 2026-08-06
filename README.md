# battery-survival

Reproducible survival analysis workflow for camera-trap battery performance in Tasmania.

This repository now uses a modern analysis stack:
1. `renv` for locked R dependencies.
2. `targets` for a declarative analysis DAG.
3. Quarto for manuscript rendering (`html` + `pdf`).
4. Auditable exclusion and QC reporting.

## Current Analysis Scope
Phase 1 focuses on:
1. Kaplan-Meier descriptive curves.
2. Cox proportional hazards modeling on TAS-CAM training regions (`ct`, `se`, `nw`, `wt`).
3. AFT model family comparison (Weibull, lognormal, loglogistic) with SW (`sw`) validation outputs.
4. Separate descriptive handling for NE (`ne`) and testbench (`tb`) cohorts.
5. Optional Bayesian survival models (`brms` + `cmdstanr`) via config/profile.

## Quick Start

### 1) Restore dependencies

Using `just`:

```bash
just restore
```

The restore command runs in a repo-local `renv` context and does not rely on user-level R startup preferences.

### 2) Run the dev pipeline

```bash
just dev
```

This runs a fast profile intended for iteration and CI.

### 3) Run the full pipeline

```bash
just full
```

This runs the full dataset analysis and renders manuscript artifacts.

### 4) Run the Bayesian-enabled profile (optional)

```bash
just bayes
```

This enables the Bayesian branch in the DAG across the production family set (Weibull + lognormal). It requires `brms` plus a working Stan backend (configured as `cmdstanr`).
Parallel settings (chains, cores, optional threads per chain) are controlled in `config/analysis.yml` under `bayesian:`.

The gamma family is available as an explicit exploratory smoke profile:

```bash
just bayes-gamma-check
```

### 5) Run Bayesian check and production profiles

```bash
just bayes-check
just bayes-prod
```

`bayes-check` is a faster diagnostics-focused run, while `bayes-prod` is the strict-gate production profile across the production family set (currently Weibull + lognormal). The gamma family remains available for exploratory Bayesian profiling, but is not part of the default production run because its current censored-data formulation is materially slower on the full dataset.

CmdStan backend notes:
1. The repo installs the `cmdstanr` R package through `renv`, but `CmdStan` itself must be installed separately.
2. Typical setup is `Rscript --vanilla -e "cmdstanr::install_cmdstan()"` followed by `cmdstanr::set_cmdstan_path()` if needed.
3. When `cmdstanr` is available but `CmdStan` is not configured, Bayesian runs emit `missing_cmdstan` status/gate rows instead of fitting models.

### 6) Render manuscript only

```bash
just manuscript
```

### 7) Render production-Bayesian review outputs

```bash
just manuscript-prod-bayes
just review-prod-bayes
```

`manuscript-prod-bayes` renders an additive review manuscript under `outputs/review/manuscript/` using:
1. The canonical frequentist/full outputs already present under `outputs/`.
2. The production Bayesian snapshot written by `just bayes-prod` under `outputs/review/bayesian_snapshot/`.

`review-prod-bayes` is a composite convenience command that runs:
1. `just bayes-prod`
2. `just full`
3. `just manuscript-prod-bayes`

Both additive review commands write real command logs under `logs/`.

### 8) Run tests and checks

```bash
just test
just check
```

## Repository Structure

1. `R/`: reusable analysis and reporting functions.
2. `_targets.R`: canonical DAG entrypoint.
3. `config/`: profile config and exclusion rules.
4. `data/`: tracked data and dictionary.
5. `outputs/`: generated figures, tables, QC, model objects, manuscript outputs.
6. `manuscript/`: Quarto manuscript source.
7. `scripts/`: script entrypoints for `dev`, `full`, and manuscript render.
8. `tests/`: `testthat` tests.
9. `methods/`: legacy provenance scripts from the previous workflow.

## Data and Exclusions

Primary data:
1. `data/batt_life_aug22.csv`

Data definitions:
1. `data/data_dictionary.md`

Exclusion governance:
1. Configure in `config/exclusions.csv`.
2. Applied exclusions and reason summaries are written to `outputs/qc/`.

Economics assumptions:
1. Service cost scenarios: `config/cost_scenarios.csv`
2. Battery set costs: `config/battery_costs.csv`

## Manuscript Output

Source:
1. `manuscript/paper.qmd`

Generated outputs:
1. `outputs/manuscript/paper.html`
2. `outputs/manuscript/paper.pdf`

Additional phase-1 economics outputs:
1. `outputs/tables/service_interval_economics.csv`
2. `outputs/tables/service_interval_optima.csv`
3. `outputs/figures/cost_per_active_day_vs_interval.png`
4. `outputs/figures/downtime_fraction_vs_interval.png`
5. `outputs/figures/optimal_service_interval.png`

Partition + validation outputs:
1. `outputs/tables/partition_summary.csv`
2. `outputs/tables/validation_survival_summary.csv`
3. `outputs/figures/validation_observed_vs_predicted.png`
4. `outputs/tables/testbench_summary.csv`
5. `outputs/figures/testbench_km_by_brand.png`

Bayesian status outputs:
1. `outputs/tables/bayesian_status.csv`
2. `outputs/tables/bayesian_model_comparison.csv`
3. `outputs/tables/bayesian_coefficients.csv`
4. `outputs/tables/bayesian_gate_results.csv`
5. `outputs/figures/bayesian_time_ratios.png`

Additive production-review outputs:
1. `outputs/review/bayesian_snapshot/tables/bayesian_status.csv`
2. `outputs/review/bayesian_snapshot/tables/bayesian_model_comparison.csv`
3. `outputs/review/bayesian_snapshot/tables/bayesian_coefficients.csv`
4. `outputs/review/bayesian_snapshot/tables/bayesian_gate_results.csv`
5. `outputs/review/bayesian_snapshot/figures/bayesian_time_ratios.png`
6. `outputs/review/manuscript/paper.html`
7. `outputs/review/manuscript/paper.pdf`

## Legacy Scripts

Historic exploratory scripts remain in `methods/` for reference and provenance. They are not the canonical execution path.

## Development Notes

Project governance and agent instructions:
1. `AGENTS.md`
