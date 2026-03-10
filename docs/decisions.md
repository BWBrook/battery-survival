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
