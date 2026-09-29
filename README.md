# battery-survival

Reproducible survival analysis workflow for camera-trap battery performance in Tasmania.

This repository now uses a modern analysis stack:
1. `renv` for locked R dependencies.
2. `targets` for a declarative analysis DAG.
3. Quarto for executable analysis/review rendering (`html` + `pdf`).
4. Auditable exclusion and QC reporting.

## Analysis and Publication Documents

`manuscript/paper.qmd` is the executable Quarto analysis/review document.
`manuscript/text/main.md` is the Pandoc Markdown publication manuscript for the
external Makedoc build. The active private main and supplementary profiles use a verified working
bibliography and neutral author-date style, omitting unconfirmed author metadata.
The 18 September revision leads with field effects and fixed-interval white-flash break-even comparisons,
with the detailed model/camera sensitivity in a standalone supplement; see
`manuscript/README.md` for PDF/DOCX build instructions. It is a private working
draft, not a circulation-ready or submission-ready paper.

## Current Analysis Scope
Phase 1 focuses on:
1. Kaplan-Meier descriptive curves.
2. Cox proportional hazards modeling on TAS-CAM training regions (`ct`, `se`, `nw`, `wt`).
3. AFT model family comparison (Weibull, lognormal, loglogistic) with SW (`sw`) validation outputs.
4. Separate descriptive handling for NE (`ne`) and testbench (`tb`) cohorts.
5. Optional Bayesian survival models (`brms` + `cmdstanr`) via config/profile.

## Scientific Interpretation Contract

1. The endpoint is time to last confirmed camera operation, not exact latent failure time.
2. Kaplan-Meier curves are descriptive; Cox provides camera-cluster robust association evidence.
3. AIC ranks comparable AFT likelihoods; the expanded sensitivity also varies brand-specific scale and region. The Cox partial likelihood is excluded.
4. The original Weibull supplies baseline curves; the integrated draft also reports flexible Weibull/loglogistic and camera-dependent scenarios. SW calibration limits prospective advice.
5. SW is a support-limited held-region check from the same project and protocol, not independent external validation.
6. Matched Bayesian models assess camera dependence under the existing endpoint. Service costs, battery prices and lost-camera-day values remain scenario inputs.
7. Fixed cycle cost per expected active day cannot increase with the service interval. Report cost and downtime curves together; no unconstrained economic optimum is identified. See `docs/servicing_cost_interpretation.md`.

## Bounded sensitivity analysis (17 September 2026)

The separately authorised analysis tests 12 AFT specifications and four matched
Bayesian fits with/without a camera effect. Read
[`docs/sensitivity_analysis_plan.md`](docs/sensitivity_analysis_plan.md) for the
endpoint, comparison, prior, support and diagnostic definitions. It uses direct
CmdStan for matched Weibull and loglogistic camera models, with brand-specific
scales and region effects. It does not replace the canonical production fits or
the manuscript automatically. Barry authorised a separate synthesis on 18 September,
now incorporated into `manuscript/text/main.md` without changing production fits.

Run model stages on deep-server in tmux, using a compatible R library and
CmdStan installation:

```bash
just sensitivity prepare
just sensitivity aft
just sensitivity camera
just sensitivity summarise
Rscript --vanilla scripts/plot_sensitivity.R
Rscript --vanilla scripts/report_sensitivity.R
```

`just sensitivity all` runs the four analysis stages. Configuration and priors
are in `config/sensitivity.yml`; tables, draws, figures and a generated report
are written under its `output_dir`. Completed camera fits are checkpoints:
reuse them only within an unchanged run snapshot, and choose a new output
directory for a new specification. No fitting stage should overwrite a running
snapshot's source files.

The September run uses an isolated library, not an exact restoration of the
original lockfile. Its runtime versions, source hashes and run notes accompany
the outputs; `docs/log/2026-09-17.md` records provenance and interpretation.
For that provisioned library, the full test command is
`R_PROFILE_USER=/dev/null R_LIBS_USER=<isolated-library> just test`.

Servicing optima in this sensitivity analysis refer only to the explicitly
valued-downtime objective `J(T) = (K/c_d)/T + 1 - A(T)/T`. They are conditional
scenarios with uncertainty and follow-up limits, not recovered optima of the
original cost-per-active-day criterion or validated field schedules.

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

This runs the full dataset analysis and renders the Quarto analysis/review artifacts.

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

### 6) Render the Quarto analysis/review document

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
6. `manuscript/`: Quarto analysis/review source plus Makedoc publication source.
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

Primary model outputs:
1. `outputs/tables/cox_coefficients.csv`
2. `outputs/tables/cox_ph_assumption.csv`
3. `outputs/tables/aft_model_comparison.csv`
4. `outputs/figures/aft_model_aic_comparison.png`

## Quarto Analysis/Review Output

Source:
1. `manuscript/paper.qmd`

Generated outputs:
1. `outputs/manuscript/paper.html`
2. `outputs/manuscript/paper.pdf`

Additional phase-1 economics outputs:
1. `outputs/tables/service_interval_economics.csv`
2. `outputs/figures/cost_per_active_day_vs_interval.png`
3. `outputs/figures/downtime_fraction_vs_interval.png`

The former optima table and bar chart are retired. Older ignored copies are
historical artifacts and are not consumed by either manuscript build.

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

## Publication Manuscript

Source:
1. `manuscript/text/main.md`
2. `manuscript/text/figures.md`
3. `manuscript/authors.yaml`
4. `references/refs.yaml`
5. `settings/build.yaml`

Build the private integrated draft using the existing external Makedoc tooling:

```bash
just publication
```

This produces `outputs/publication/battery-survival-integrated.pdf` and `.docx`,
plus `battery-survival-supplement.pdf` and `.docx`, including regenerated
publication figures and DOCX layout corrections.
The saved SW figure, robust Cox estimates, sensitivity cohort and corrected
19 September profile tables must already exist. `just refresh-profiles` followed
by `just break-even` derives those current tables from the sealed camera fits,
using the documented sensitivity runtime; neither command fits models. See
`manuscript/README.md` for prerequisites and `docs/log/2026-09-18.md` for the
integration record. The September 12 backbone outputs are earlier proofs.
Build checks verify rendering and citations, not scientific or submission readiness.

## Legacy Scripts

Historic exploratory scripts remain in `methods/` for reference and provenance. They are not the canonical execution path.

## Development Notes

Project governance and agent instructions:
1. `AGENTS.md`
