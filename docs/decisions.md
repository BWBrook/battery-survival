# Decisions

## 2026-03-10

### D-001: Autonomous workflow baseline
Status: accepted

Decision:
1. Treat the current WP10-hardening worktree as the baseline for the autonomous remaining-work workflow rather than resetting or rebranching.

Rationale:
1. The hardening work already adds characterization tests, restore hardening, and internal module boundaries that are part of the agreed execution path.
2. Rewinding would add churn without reducing scientific or operational risk.

Evidence:
1. Current worktree contains the WP10 changes and canonical checks previously passed locally.

Follow-up:
1. Capture dated baseline evidence and artifact snapshots before attempting Bayesian backend enablement or redesign comparisons.

### D-002: Enable local CmdStan backend autonomously
Status: accepted

Decision:
1. Install CmdStan locally with `cmdstanr::install_cmdstan()` because the required compiler toolchain (`g++`, `make`) is already present and no sudo escalation is required.

Rationale:
1. Real Bayesian execution is the highest remaining operational gap.
2. The install path is repo-compatible and environment-local.

Evidence:
1. CmdStan 2.38.0 installed under `/home/bwbrook/.cmdstan/cmdstan-2.38.0`.
2. Fresh R sessions now resolve `cmdstanr::cmdstan_path()` successfully.

Follow-up:
1. Run `just bayes-check` and `just bayes-prod` against the real backend and review the resulting diagnostics before deciding whether Bayesian narrative belongs in the manuscript.

### D-003: Track Bayesian backend readiness in the DAG
Status: accepted

Decision:
1. Add an always-checked Bayesian dependency-status target so backend/toolchain changes invalidate stale cached `missing_cmdstan` results.

Rationale:
1. Installing CmdStan after a previous missing-backend run must trigger a real rerun.
2. Backend availability is runtime state, not source/config state, so the DAG needs an explicit cue for it.

Evidence:
1. Before the fix, `just bayes-check` reused stale `missing_cmdstan` outputs after CmdStan became available.
2. After the fix, `bayesian_dependency_status` reran and `bayes-check` executed a real CmdStan fit.

### D-004: Keep `bayes_prod` to production-ready families on this server
Status: accepted

Decision:
1. Narrow the `bayes_prod` profile family set to `weibull` and `lognormal`.
2. Leave `gamma` available only for exploratory Bayesian runs until it is re-parameterized or otherwise demonstrated to complete reliably on the full dataset.

Rationale:
1. `bayes_prod` is a reproducibility command, so it must complete end-to-end on the target server rather than depend on an aspirational family set.
2. The current full-data censored gamma formulation is an operational outlier and blocks downstream artifact review without improving the strict-gate evidence available for sign-off.

Evidence:
1. On `deep-server`, the `weibull` and `lognormal` `bayes_prod` families completed 32-chain fits in seconds, while the `gamma` family remained active across all 32 chains for more than 35 minutes with no completed chain output written.
2. Interrupting the stalled gamma run was necessary to proceed with the canonical `bayes_prod` -> `full` -> `manuscript` verification sequence.

Follow-up:
1. Revisit gamma only with an explicit profiling/reparameterization pass and record the outcome in `docs/log/`.

### D-005: Preserve current Bayesian artifact paths during onboarding verification
Status: accepted

Decision:
1. Keep the existing Bayesian output paths unchanged for now, even though `full`/`manuscript` regenerate those paths in disabled mode.
2. Use a final `just bayes-prod` refresh after `just manuscript` when both the full-manuscript render and standalone production Bayesian artifacts need to be reviewed in the same session.

Rationale:
1. The current priority is reproducible execution on this server without changing public artifact schemas or manuscript-linked filenames.
2. Renaming or splitting Bayesian output paths would ripple through targets, documentation, tests, and manuscript references.

Evidence:
1. `just full` and `just manuscript` rewrote `outputs/tables/bayesian_*.csv` and `outputs/figures/bayesian_time_ratios.png` into disabled-state artifacts under the `full` profile.
2. A final `just bayes-prod` rerun restored the production Bayesian diagnostics and figure for explicit review without changing output contracts.

Follow-up:
1. If concurrent preservation of full-manuscript and production Bayesian artifacts becomes a recurring need, evaluate profile-specific artifact snapshots or output segregation as a separately approved work package.

## 2026-03-11

### D-006: Add a production-review workflow instead of redefining `full` / `manuscript`
Status: accepted

Decision:
1. Keep the existing standard outputs and commands unchanged.
2. Add a production Bayesian snapshot under `outputs/review/bayesian_snapshot/`.
3. Add a separate review-manuscript render under `outputs/review/manuscript/` that reuses canonical non-Bayesian outputs and reads Bayesian tables/figure from the snapshot.

Rationale:
1. This was the explicitly chosen implementation direction for resolving the workflow inconsistency without breaking the current public contract.
2. A snapshot plus additive render path keeps the standard manuscript semantics stable while making production Bayesian review self-consistent.

Evidence:
1. `just bayes-prod` now snapshots the authoritative production Bayesian tables, figure, and model objects under `outputs/review/bayesian_snapshot/`.
2. `just manuscript-prod-bayes` renders `outputs/review/manuscript/paper.html` and `paper.pdf` with Bayesian sections showing `fit completed` / `pass` rows from the snapshot rather than the disabled-state standard outputs.

Follow-up:
1. If a future release needs the review manuscript to be fully targets-managed without any direct render helper, revisit a dedicated review target graph as a separate work package.

### D-007: Treat the additive review bundle as the authoritative Bayesian release-review surface
Status: accepted

Decision:
1. Use `outputs/review/bayesian_snapshot/` and `outputs/review/manuscript/` as the authoritative review surface for production Bayesian evidence.
2. Keep `outputs/manuscript/` as the canonical full-profile manuscript output and do not reinterpret it as the production-Bayesian review document.

Rationale:
1. The additive review workflow was introduced specifically to avoid changing the semantics of the standard `full` / `manuscript` path.
2. The synced review bundle now resolves the previous evidence mismatch: the review manuscript renders Bayesian `ok` / `pass` rows from the production snapshot while the canonical manuscript remains full-profile by design.

Evidence:
1. `outputs/review/bayesian_snapshot/tables/bayesian_model_comparison.csv` contains only `weibull` and `lognormal` with `fit_status = ok`.
2. `outputs/review/manuscript/paper.html` renders Bayesian `fit completed` / `pass` rows that match the snapshot tables.
3. Real workflow logs exist for `review-prod-bayes` and `manuscript-prod-bayes` under `logs/`.

Follow-up:
1. Use the additive review bundle for release/readiness review until or unless the project intentionally changes the meaning of the standard manuscript path.
