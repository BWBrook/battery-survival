# Goal 001 Findings

## Starting State

- Working directory: `/Users/bwbrook/papers/battery-survival`
- Branch/status line: `## master...origin/master`
- Short HEAD: `e7e955d`
- Starting tracked diff: 13 files changed, 255 insertions(+), 177 deletions(-)
- Starting untracked paths:
  - `.dockerignore`
  - `docs/goals/`
  - `logs/manuscript-prod-bayes-2026-05-29-180621.log`
  - `logs/review-prod-bayes-2026-05-29-180650.log`
  - `logs/review-prod-bayes-2026-05-29-185738.log`

The dirty state was preserved. No cleanup, staging, commits, pushes, resets,
stashes, checkouts, or source fixes were performed.

## Docs Read

- `AGENTS.md`
- `README.md`
- `docs/plan.md`
- `docs/decisions.md`
- `docs/release_readiness_2026-03-11.md`
- `docs/log/2026-03-11.md`
- Goal packet files: `Goal.md`, `Plan.md`, `Runbook.md`, `Log.md`

Current intended semantics from the docs:

- `full` / `manuscript` remain the canonical standard workflow.
- `outputs/review/bayesian_snapshot/` is the authoritative production
  Bayesian review snapshot.
- `outputs/review/manuscript/` is the additive review manuscript that combines
  canonical non-Bayesian outputs with the production Bayesian snapshot.
- Production Bayesian families are `weibull` and `lognormal`.
- `gamma` remains exploratory and is not part of the default production run.

## Dirty-State Classification

Recommendation-level classification: coherent bounded package, with supporting
evidence artifacts.

Tracked source/config/docs/test changes:

1. R 4.6 / runtime portability:
   - `renv.lock` updates R from 4.5.3 to 4.6.0 and changes 43 package versions.
   - `Dockerfile` moves to `rocker/verse:4.6.0`, adds `BASE_PLATFORM`, and
     restores through repo-local `renv/activate.R`.
   - `compose.yml` pins the service platform to `linux/amd64`.
2. Bayesian operational hardening:
   - `R/bayesian_config.R` adds `resolve_bayesian_cores()` to cap requested
     chains/cores by host availability.
   - `R/bayesian_fit.R` uses that helper instead of local inline core logic.
   - `config/analysis.yml` narrows the general `bayes` family set to
     `weibull` + `lognormal` and adds `bayes_gamma_check` as an exploratory
     gamma smoke profile.
3. Review-path stability:
   - `R/config.R` normalizes additive review paths with `fs::path_norm()`.
4. Command surface and docs:
   - `justfile`, `Makefile`, `AGENTS.md`, and `README.md` add/document
     `bayes-gamma-check`.
5. Tests:
   - `tests/testthat/test-bayesian.R` covers host-core capping.
   - `tests/testthat/test-config.R` covers production/gamma family separation.

Untracked support paths:

- `.dockerignore` is coherent with the Docker changes and keeps `.git`,
  `_targets`, `outputs`, `logs`, local renv libraries, and common local files
  out of the build context.
- The May 29 logs are evidence artifacts. They support successful local
  additive review rendering, but the `review-prod-bayes` logs are cache-heavy
  and do not prove a fresh production fit in that session.
- `docs/goals/` is this active goal packet and findings surface.

No dirty file appeared unrelated to the R 4.6 / Bayesian review workflow bundle.

## Review Bundle Audit

The review bundle exists with:

- `outputs/review/bayesian_snapshot/manifest.csv`
- snapshot tables under `outputs/review/bayesian_snapshot/tables/`
- snapshot models under `outputs/review/bayesian_snapshot/models/`
- `outputs/review/bayesian_snapshot/figures/bayesian_time_ratios.png`
- `outputs/review/manuscript/paper.html`
- `outputs/review/manuscript/paper.pdf`

Snapshot table checks:

- `bayesian_status.csv`: `weibull` and `lognormal` both have
  `fit_status = ok`, `message = fit completed`, `backend = cmdstanr`.
- `bayesian_model_comparison.csv`: both production families have finite
  diagnostics, zero divergences, zero treedepth saturation, and finite BFMI.
- `bayesian_gate_results.csv`: both production families have
  `gate_status = pass`, `all_families_pass = TRUE`, and `fail_reasons = none`.
- `weibull` has lower `looic` than `lognormal` in the reviewed snapshot.

Review manuscript checks:

- `outputs/review/manuscript/paper.html` contains production Bayesian
  `fit completed` and `pass` rows for `weibull` and `lognormal`.
- `outputs/review/manuscript/paper.pdf` exists, is 16 pages, and was rendered
  on 2026-05-29 18:58:16 AEST before this goal's validation render.
- `just manuscript-prod-bayes` re-rendered the review manuscript during this
  goal and wrote `logs/manuscript-prod-bayes-2026-06-15-154019.log`.

Important artifact-state caveat after validation:

- The authoritative review snapshot still contains the production
  `weibull` + `lognormal` evidence with May 29 manifest timestamps.
- The ignored standard Bayesian tables under `outputs/tables/` currently
  reflect the last validation profile run, `bayes_gamma_check`: `gamma` fit
  completed but strict gate status fails on `rhat` and `bulk_ess`.
- This is expected for a smoke profile and does not change tracked git state,
  but it matters if a reviewer inspects working-tree `outputs/tables/` after
  this goal.

## Validation Results

Commands run:

| Command | Outcome | Notes |
| --- | --- | --- |
| `just test` | pass | `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 96 ]` |
| `just check` | pass | Includes `just test`; `just dev` completed 2 targets, 75 skipped |
| `just bayes-check` | pass | Real CmdStan MCMC ran with 8 chains; pipeline ended with 48 completed, 29 skipped |
| `just bayes-gamma-check` | pass | Gamma smoke profile ran with 4 chains; pipeline ended with 48 completed, 29 skipped |
| `just manuscript-prod-bayes` | pass | Rendered `outputs/review/manuscript/paper.html` and `paper.pdf`; wrote new log |
| `docker info` | pass | Docker Desktop daemon available, `desktop-linux`, server 29.5.3 |
| `docker build --build-arg BASE_PLATFORM=linux/amd64 -t battery-survival-goal001-audit .` | pass | Built `battery-survival-goal001-audit:latest`; restore step completed after 1660.3 s |

Validation intentionally did not run:

- `just bayes-prod`
- `just review-prod-bayes`
- remote jobs

Docker note:

- The build context was 839.70 kB, consistent with `.dockerignore` excluding
  large local/generated directories.
- `renv::restore()` emitted a GitHub credential warning while downloading
  `cmdstanr`, but the package downloaded and installed successfully.

## Git State After Validation

Final status after validation and before this memo write:

```text
## master...origin/master
 M AGENTS.md
 M Dockerfile
 M Makefile
 M R/bayesian_config.R
 M R/bayesian_fit.R
 M R/config.R
 M README.md
 M compose.yml
 M config/analysis.yml
 M justfile
 M renv.lock
 M tests/testthat/test-bayesian.R
 M tests/testthat/test-config.R
?? .dockerignore
?? docs/goals/
?? logs/manuscript-prod-bayes-2026-05-29-180621.log
?? logs/manuscript-prod-bayes-2026-06-15-154019.log
?? logs/review-prod-bayes-2026-05-29-180650.log
?? logs/review-prod-bayes-2026-05-29-185738.log
```

No tracked file outside the pre-existing dirty set and this goal directory was
added to git status. The new untracked validation log is expected evidence from
`just manuscript-prod-bayes`.

## Recommendation

Accept the tracked dirty bundle as a coherent, bounded R 4.6 / Bayesian review
workflow hardening package.

Rationale:

- The source/config/docs/tests changes align with accepted decisions D-004
  through D-007 and the WP11 additive review workflow.
- The dirty changes are internally coherent: production families remain
  `weibull` + `lognormal`, `gamma` is split into an exploratory smoke profile,
  local core use is capped for smaller hosts, Docker is made R 4.6/amd64-aware,
  and tests cover the changed contracts.
- Targeted validation passed locally, including test/check, Bayesian check,
  gamma smoke, review-manuscript render, and Docker image build.
- No source fix was required during this goal.

Acceptance should treat `.dockerignore` as part of the Docker/R 4.6 package.
The May 29 and June 15 logs should be treated as evidence artifacts; Battery
Survival can decide whether to keep them in git or cite them only in the
review packet.

## Residual Risks

- This goal did not rerun `just bayes-prod` or `just review-prod-bayes` because
  they were explicitly out of scope.
- The latest production Bayesian fit evidence in the review snapshot is from
  the existing May 29 artifacts, not a fresh production rerun from this goal.
- The standard ignored `outputs/tables/bayesian_*` files currently reflect the
  gamma smoke validation profile and should not be mistaken for the production
  review snapshot.
- The Docker build passed but was expensive, largely due source package
  installation inside the image.

## Proposed Next Goal

Run an acceptance-prep goal that:

1. Decides which evidence logs should be included with the package.
2. Optionally runs a fresh `just review-prod-bayes` if Battery Survival wants
   current-date production evidence before acceptance.
3. Prepares a clean commit/PR boundary for the accepted tracked bundle plus
   `.dockerignore`, without mixing in unrelated generated artifacts.
