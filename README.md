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
2. Cox proportional hazards modeling.
3. AFT model family comparison (Weibull, lognormal, loglogistic).

Bayesian survival models are intentionally deferred to a later phase.

## Quick Start

### 1) Restore dependencies

Using `just` (preferred):

```bash
just restore
```

Or using `make`:

```bash
make restore
```

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

### 4) Render manuscript only

```bash
just manuscript
```

### 5) Run tests and checks

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

## Legacy Scripts

Historic exploratory scripts remain in `methods/` for reference and provenance. They are not the canonical execution path.

## Development Notes

Project governance and agent instructions:
1. `AGENTS.md`

Execution plan tracker:
1. `docs/plan.md`
