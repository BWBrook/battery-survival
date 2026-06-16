# Runbook: Goal 002 Acceptance Prep And Publication Boundary

## Ground Rules

- Work from `/Users/bwbrook/papers/battery-survival`.
- Do not edit source/config/test/docs outside this goal directory.
- Do not use `git add .`.
- Do not push.
- Do not run Docker or remote jobs.

## 1. Capture Starting State

```sh
pwd
git status --short --branch
git rev-parse --short HEAD
git diff --stat
git diff --name-status
```

Append a concise summary to `Log.md`.

## 2. Read Context

Read:

```text
AGENTS.md
README.md
docs/plan.md
docs/decisions.md
docs/release_readiness_2026-03-11.md
docs/goals/001-dirty-state-reconciliation/Findings.md
docs/goals/001-dirty-state-reconciliation/Log.md
docs/goals/002-acceptance-prep-publication-boundary/Goal.md
docs/goals/002-acceptance-prep-publication-boundary/Plan.md
docs/goals/002-acceptance-prep-publication-boundary/Runbook.md
docs/goals/002-acceptance-prep-publication-boundary/Log.md
```

## 3. Run Validation

```sh
just test
just review-prod-bayes
```

Record exact outcomes in `Log.md`.

If either command fails, stop. Do not patch.

## 4. Identify Fresh Goal 002 Logs

Before staging, identify logs created by this run:

```sh
find logs -maxdepth 1 -type f -name '*2026-06-16*.log' -print | sort
```

If the actual date-stamped filenames differ, use the files produced during this
Goal 002 run and explain the timestamp.

## 5. Write Findings

Create or update:

```text
docs/goals/002-acceptance-prep-publication-boundary/Findings.md
```

Use this structure:

```md
# Goal 002 Findings

## Starting State
## Docs Read
## Validation Results
## Evidence Logs
## Staging Decision
## Commit
## Final Git State
## Residual Risks
## Proposed Next Goal
```

## 6. Stage Exact Paths

Stage only approved paths. Start with this exact set:

```sh
git add \
  AGENTS.md \
  Dockerfile \
  Makefile \
  R/bayesian_config.R \
  R/bayesian_fit.R \
  R/config.R \
  README.md \
  compose.yml \
  config/analysis.yml \
  justfile \
  renv.lock \
  tests/testthat/test-bayesian.R \
  tests/testthat/test-config.R \
  .dockerignore \
  docs/goals/001-dirty-state-reconciliation \
  docs/goals/002-acceptance-prep-publication-boundary
```

Then add fresh Goal 002 logs one by one, for example:

```sh
git add logs/<fresh-goal-002-log>.log
```

Do not stage May 29 logs or the June 15 Goal 001 log unless you stop and
explain why the fresh Goal 002 logs are insufficient.

## 7. Verify Staging

```sh
git diff --cached --stat
git diff --cached --name-status
git diff --cached --check
```

If unexpected paths are staged, unstage only those exact paths with:

```sh
git restore --staged <path>
```

Do not use broad reset commands.

## 8. Commit

If validation passed and staging is exact:

```sh
git commit -m "chore: publish R 4.6 Bayesian review hardening"
```

Then record:

```sh
git rev-parse --short HEAD
git status --short --branch
```

## 9. Wake-Up

Send a short wake-up to Battery Survival thread
`019eac3b-28ae-7ad2-bd5e-16d76db78fcd` with:

- complete or blocked
- commit SHA if created
- validation summary
- final status
- `Findings.md` path
