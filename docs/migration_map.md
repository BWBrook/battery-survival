# Legacy-to-Modern Migration Map

## Canonical execution now
1. Old: numbered scripts in `methods/`.
2. New: `_targets.R` DAG + reusable functions in `R/`.

## Key mappings
1. `methods/00_data.R` -> `R/data_io.R`, `R/data_transform.R`
2. `methods/01_fit_surv.R` -> `R/models.R` (KM + Cox)
3. `methods/02_fit_stan.R` -> deferred (out of phase 1 scope)
4. `methods/03_visualisation*.R` -> `R/artifacts.R` + Quarto manuscript
5. `methods/04_loo.R` -> deferred (out of phase 1 scope)

## Data and config
1. Old: `methods/config.yml` + environment variable toggles.
2. New: `config/analysis.yml` profile overlays (`dev`, `full`).

## Outputs
1. Old: `results/` ad hoc file writes.
2. New: structured `outputs/` directories with manifest and QC tables.

## Governance
1. `AGENTS.md` is the operating contract for contributors and agents.
2. `docs/plan.md` tracks milestone-level progress.
