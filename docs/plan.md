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

2026-02-17 (Step 3 service-interval economics):
1. Added economic assumption inputs (`config/cost_scenarios.csv`, `config/battery_costs.csv`).
2. Implemented AFT-driven service-interval tradeoff engine producing active-day, downtime, and cost-per-active-day outputs.
3. Added economics figures and tables to DAG and manuscript (`paper.qmd`).

## Next Work Packages (Post-Step-3)

### WP4: Regional Partitioning + Validation Framework
Purpose:
1. Establish a defensible design for confounding and censoring across regions by separating model-fitting and validation cohorts.

Deliverables:
1. Config-driven partition definitions:
   - TAS-CAM training: `ct`, `se`, `nw`, `wt`
   - SW validation: `sw`
   - NE descriptive-only: `ne`
   - Testbench descriptive: `tb`
2. Pipeline targets that produce:
   - Partitioned analysis datasets.
   - Partition summary table (rows, events, event-rate, camera count).
3. Validation artifacts comparing AFT-predicted survival against observed SW survival at fixed horizons.

Definition of Done:
1. `just full` writes partition + validation outputs under `outputs/tables/` and `outputs/figures/`.
2. Manuscript includes Methods + Results text that references these outputs.
3. Tests cover partition assignment and validation artifact generation.

### WP5: Bayesian Survival Track (Phase 2 Readiness)
Purpose:
1. Add Bayesian survival analysis alongside frequentist models while preserving stable default runtime.

Deliverables:
1. Optional Bayesian pipeline branch using `brms` + `cmdstanr`.
2. Config flags for:
   - enable/disable behavior,
   - backend and sampler settings,
   - Bayesian model family list.
3. Status/model-summary outputs generated even when Bayesian fitting is disabled or dependencies are missing.

Definition of Done:
1. Default profiles (`dev`, `full`) complete without requiring Stan stack.
2. Bayesian targets are in DAG and produce auditable status tables.
3. Documentation explains how to enable Bayesian fitting when toolchain is available.

### WP6: Testbench (TB) Integration
Purpose:
1. Treat TB as a complementary experiment with explicit separation from field inference.

Deliverables:
1. TB summary table and basic survival display generated from the same DAG.
2. Manuscript subsection clarifying TB’s role as descriptive/contrastive evidence.

Definition of Done:
1. TB outputs are generated automatically in `full` profile.
2. Manuscript references TB outputs without mixing TB into primary field model fitting.

### WP7: Main Results Manuscript Completion
Purpose:
1. Convert current scaffold into a coherent draft aligned with paper-outline requirements.

Deliverables:
1. Main Results includes:
   - Frequentist model comparison,
   - SW validation performance,
   - Service-interval economics,
   - Bayesian status or Bayesian estimates (when enabled).
2. Discussion updated with practical recommendations and scope statements (camera-model specific calibration guidance).

Definition of Done:
1. `just manuscript` builds `html` and `pdf` from one source.
2. Core claims in manuscript are tied to generated artifacts, not hand-entered values.

### WP8: Reproducibility + Release Hygiene
Purpose:
1. Ensure final paper workflow is robust to reruns and CI usage.

Deliverables:
1. Updated `README.md` and command docs for partitioned + Bayesian workflow.
2. Build Report evidence recorded for each substantial package.
3. CI-safe artifact policy maintained (`*.html` and `*.pdf` untracked in source tree).

Definition of Done:
1. Canonical commands pass locally:
   - `just test`
   - `just dev`
   - `just full`
   - `just manuscript`
   - `just check`
2. Repository remains clean after runs except expected ignored outputs.

## Post-Step-3 Status (Current Session)
2026-02-17:
1. WP4 completed:
   - Added config-driven regional partitions and SW validation artifacts.
   - Frequentist fitting now runs on TAS-CAM training subset.
2. WP5 completed (scaffold phase):
   - Added optional `brms` + `cmdstanr` branch with auditable status/model-summary outputs.
   - Added `bayes` profile and `just bayes`/`make bayes` entrypoints.
3. WP6 completed:
   - Added TB summary table and TB KM display as explicit descriptive outputs.
4. WP7 in progress:
   - Manuscript updated with partition, validation, TB, and Bayesian sections.
5. WP8 in progress:
   - Canonical commands passing locally; CI rerun expected on push.
