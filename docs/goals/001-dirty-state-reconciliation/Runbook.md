# Runbook: Goal 001 Dirty-State Reconciliation

## Ground Rules

- Work from `/Users/bwbrook/papers/battery-survival`.
- Do not edit source, config, tests, manuscripts, lockfiles, generated
  artifacts, or git state.
- You may update only files under this goal directory.
- If a command changes tracked files outside this goal directory, stop and
  report.

## 1. Capture Starting State

```sh
pwd
git status --short --branch
git rev-parse --short HEAD
git diff --stat
git diff --name-status
```

Append the results or a concise summary to `Log.md`.

## 2. Read Context

Read:

```text
AGENTS.md
README.md
docs/plan.md
docs/decisions.md
docs/release_readiness_2026-03-11.md
docs/log/2026-03-11.md
```

Focus on current state, not old history.

## 3. Inspect Dirty State

Use read-only commands such as:

```sh
git diff -- AGENTS.md README.md justfile Makefile Dockerfile compose.yml config/analysis.yml
git diff -- R/bayesian_config.R R/bayesian_fit.R R/config.R
git diff -- tests/testthat/test-bayesian.R tests/testthat/test-config.R
git diff -- renv.lock
sed -n '1,160p' .dockerignore
for f in logs/*2026-05-29*.log; do echo "== $f =="; tail -n 80 "$f"; done
```

Do not use destructive git commands.

## 4. Inspect Review Bundle

Use read-only commands such as:

```sh
find outputs/review -maxdepth 3 -type f | sort
sed -n '1,40p' outputs/review/bayesian_snapshot/manifest.csv
for f in outputs/review/bayesian_snapshot/tables/*.csv; do echo "== $f =="; sed -n '1,12p' "$f"; done
```

If files are missing, record that as evidence.

## 5. Run Targeted Validation

Run in this order, stopping at the first failure that needs source changes:

```sh
just test
just check
just bayes-check
just bayes-gamma-check
just manuscript-prod-bayes
```

Then probe Docker:

```sh
docker info
```

If Docker is available, run:

```sh
docker build --build-arg BASE_PLATFORM=linux/amd64 -t battery-survival-goal001-audit .
```

If Docker is unavailable or the build is clearly too expensive for this goal,
record the skip/blocker and continue to the decision memo.

Do not run:

```text
just bayes-prod
just review-prod-bayes
```

## 6. Write Findings

Create or update:

```text
docs/goals/001-dirty-state-reconciliation/Findings.md
```

Use this structure:

```md
# Goal 001 Findings

## Starting State
## Docs Read
## Dirty-State Classification
## Review Bundle Audit
## Validation Results
## Git State After Validation
## Recommendation
## Residual Risks
## Proposed Next Goal
```

## 7. Final Status And Wake-Up

Record:

```sh
git status --short --branch
```

Then send a short wake-up to Battery Survival thread
`019eac3b-28ae-7ad2-bd5e-16d76db78fcd` saying Goal 001 is complete or blocked,
with the one-line recommendation and the path to `Findings.md`.
