# Modernization Plan and Progress

## Objective
Rebuild this repository into a fully reproducible, publication-ready analysis system using:
1. `renv` for pinned dependencies.
2. `targets` for DAG orchestration.
3. Quarto for manuscript and artifact rendering.
4. Auditable QC/exclusion governance.
5. CI checks for reproducibility hygiene.

## Scope Locked In
1. Phase 1 model scope: Cox + AFT only.
2. Dataset policy: keep current full CSV tracked in git.
3. Manuscript structure: single article `.qmd`.
4. Pipeline profiles: `dev` + `full`.
5. Exclusion policy: explicit tracked exclusion table.
6. Outputs: manuscript renders to PDF + HTML.

## Milestones
- [x] M0: Establish governance files (`AGENTS.md`, this plan document).
- [x] M1: Create modern repo structure and core configs.
- [x] M2: Implement reusable analysis functions in `R/`.
- [x] M3: Implement `_targets.R` DAG and profile handling.
- [x] M4: Add scripts + task runners (`justfile`, `Makefile`).
- [x] M5: Add Quarto manuscript wired to generated outputs.
- [x] M6: Add tests and CI workflows.
- [x] M7: Pin dependencies with `renv.lock`.
- [x] M8: Run canonical checks and produce build evidence.

## Decision-Complete Implementation Outline
### 1) Structure
Create/maintain:
1. `R/`
2. `config/`
3. `scripts/`
4. `tests/testthat/`
5. `outputs/` subfolders
6. `manuscript/paper.qmd`
7. `_targets.R`

### 2) Config and Data Contracts
1. `config/analysis.yml` with `default`, `dev`, and `full` profile overlays.
2. `config/exclusions.csv` with required columns:
   - `scope,id,reason_code,reason_detail,active,source`
3. `data/data_dictionary.md` documenting schema and definitions.

### 3) Analysis Layer
Implement explicit functions for:
1. config loading and profile overlays.
2. data loading and validation.
3. feature derivation.
4. exclusion application and logging.
5. QC summaries.
6. Cox and AFT fitting + diagnostics.
7. figure/table generation.
8. manuscript rendering hooks.

### 4) DAG
Canonical execution through `_targets.R`:
1. data input and validation.
2. feature derivation and profile sampling.
3. exclusion application.
4. model fitting.
5. artifact generation.
6. manuscript render.

### 5) Reproducibility and Execution
1. `justfile` + `Makefile` as user entrypoints.
2. `renv` lockfile and restore flow.
3. CI workflows for dev checks and full artifact builds.

## Acceptance Criteria
1. Fresh clone + restore + `just dev` works.
2. `just full` produces models/tables/figures under `outputs/`.
3. `just manuscript` renders `paper.html` and `paper.pdf`.
4. Tests pass in local and CI paths.
5. No manual copy-paste pipeline for manuscript numbers.

## Risks and Mitigations
1. Package compatibility drift:
   - Mitigation: strict `renv` lock and CI restore.
2. Legacy script confusion:
   - Mitigation: clearly mark `methods/` as legacy provenance.
3. Heavy runtime in CI:
   - Mitigation: split `dev` vs `full` profiles.

## Progress Notes
2026-02-17:
1. Plan initialized.
2. Governance file `AGENTS.md` added.
3. Modern structure, pipeline, tests, CI, and manuscript scaffold implemented.
4. Canonical checks executed locally: `just test`, `just dev`, `just full`, `just manuscript`, `just check`.

2026-02-17 (Step 2 scientific hardening):
1. Finalized phase-1 covariate framing to use flash-rate and daylight-rate terms (`log_fi_pd`, `log_day_pd`).
2. Added dataset and model diagnostics artifacts (overview tables, KM median table, Cox PH diagnostics table, region event-rate figure).
3. Upgraded manuscript from generic scaffold to structured phase-1 draft with linked diagnostic and summary outputs.
