# Goal: Acceptance Prep And Publication Boundary

## Objective

Prepare and, if the evidence remains clean, create one local commit for the
accepted R 4.6 / Bayesian review workflow hardening bundle without mixing in
unrelated generated artifacts or stale evidence logs.

## Why This Matters

Goal 001 established that the current tracked dirty state is a coherent,
bounded hardening package. The project now needs a clean publication boundary:
which files belong in the accepted baseline, which logs are evidence, and
whether current-date production review evidence still passes before commit.

This goal supports the decision: can Battery Survival move from accepted dirty
state to an auditable local commit ready for supervisor review and later push?

## Operating Mode

Acceptance-prep / publication-boundary goal with targeted release validation.

## Review Surface

Battery Survival will review:

- `docs/goals/002-acceptance-prep-publication-boundary/Findings.md`
- `docs/goals/002-acceptance-prep-publication-boundary/Log.md`
- the created local commit SHA, if a commit is made
- final `git status --short --branch`
- exact staged/committed path list
- validation logs and command outcomes

## Scope

In scope:

- read Goal 001 findings and current repo governance
- run current-date validation with `just test` and `just review-prod-bayes`
- decide exact commit boundary for the accepted package
- stage exact approved paths only
- create one local commit if validation passes and the staged set is clean
- leave the repo unpushed

Out of scope:

- source-code fixes or refactors
- new scientific modelling beyond the existing review workflow
- manuscript editing beyond generated review renders from validation commands
- remote jobs
- Docker rebuilds
- staging broad directories without review
- pushing, PR creation, merging, rebasing, stashing, resetting, or cleanup

## Read First

- `AGENTS.md` - repo rules and command surface
- `README.md` - workflow and review-output descriptions
- `docs/plan.md` - current WP9-WP11 project state
- `docs/decisions.md` - accepted Bayesian/review workflow decisions
- `docs/release_readiness_2026-03-11.md` - existing review readiness criteria
- `docs/goals/001-dirty-state-reconciliation/Findings.md` - accepted Goal 001 evidence
- `docs/goals/001-dirty-state-reconciliation/Log.md` - Goal 001 validation record
- this goal packet: `Goal.md`, `Plan.md`, `Runbook.md`, and `Log.md`

## Starting State Checks

Start by recording:

- `pwd`
- `git status --short --branch`
- `git rev-parse --short HEAD`
- `git diff --stat`
- `git diff --name-status`

## Git And Publication Policy

Commit policy:

- A single local commit is authorized if and only if validation passes and the
  exact staged set matches this goal.
- Push is not authorized.
- Stage exact paths only. Do not use broad `git add .`.

Default commit message:

```text
chore: publish R 4.6 Bayesian review hardening
```

Approved source/package paths:

```text
AGENTS.md
Dockerfile
Makefile
R/bayesian_config.R
R/bayesian_fit.R
R/config.R
README.md
compose.yml
config/analysis.yml
justfile
renv.lock
tests/testthat/test-bayesian.R
tests/testthat/test-config.R
.dockerignore
docs/goals/001-dirty-state-reconciliation/
docs/goals/002-acceptance-prep-publication-boundary/
```

Evidence-log policy:

- Run `just review-prod-bayes` once.
- Commit only the fresh logs produced by this Goal 002 validation run.
- Do not commit the May 29 logs or the June 15 Goal 001 log by default; they
  are cited in Goal 001 findings.
- If the fresh review run does not produce complete current-date evidence,
  pause and report instead of committing older logs as a substitute.

## Data, Compute, And Staging Policy

- Work in the existing local checkout only:
  `/Users/bwbrook/papers/battery-survival`.
- Do not run remote jobs.
- Do not run Docker builds in this goal. Goal 001 already validated the Docker
  image build.
- Generated `outputs/`, `_targets/`, `.quarto/`, and `_freeze/` paths remain
  ignored/local and must not be manually staged.

## Required Work

1. Confirm starting state and read required context.
2. Run validation:
   - `just test`
   - `just review-prod-bayes`
3. Identify fresh logs produced by Goal 002.
4. Write `Findings.md` with exact path decisions.
5. Stage exact approved paths and fresh Goal 002 logs only.
6. Run `git diff --cached --stat` and `git diff --cached --check`.
7. Create one local commit if the staged set is correct and checks pass.
8. Report final status and send a wake-up to Battery Survival.

## Validation Gates

The goal is complete only when:

- `just test` passes
- `just review-prod-bayes` passes
- `Findings.md` records the path decisions and validation outcomes
- staged paths match the approved set plus fresh Goal 002 evidence logs
- `git diff --cached --check` passes
- one local commit is created, or a clear blocker explains why no commit was made
- final status is reported

## Deliverables

- `docs/goals/002-acceptance-prep-publication-boundary/Findings.md`
- updated `docs/goals/002-acceptance-prep-publication-boundary/Log.md`
- one local commit SHA, if validation and staging gates pass
- final response in the `energizer` thread
- short wake-up message back to the Battery Survival orchestrator thread

## Decision Authority

You may decide:

- which fresh Goal 002 logs to stage, based on files actually produced by
  `just review-prod-bayes`
- whether to stop instead of committing if the staged set is not clean
- whether a fresh log is evidence or incidental noise

You must pause before:

- staging paths outside the approved source/package paths and fresh Goal 002 logs
- committing older May 29 or June 15 logs
- changing source, config, tests, docs, lockfiles, or scripts
- running Docker, remote jobs, or new validation not listed above
- pushing to any remote

## Stop Conditions

Stop when one of these is true:

- the local commit is created and final status is reported
- validation fails
- fresh production-review evidence is not produced
- staging would require paths outside the approved boundary
- a scientific/publication decision is needed

## Final Response Requirements

Report:

- docs read
- validation commands and outcomes
- fresh logs produced
- exact staged and committed paths
- local commit SHA, if created
- final `git status --short --branch`
- any residual risks
- confirmation that no push, remote job, Docker build, source fix, cleanup,
  stash, reset, broad add, or PR action occurred

Then send a short wake-up message to Battery Survival thread
`019eac3b-28ae-7ad2-bd5e-16d76db78fcd` using available thread tools. If thread
tools are unavailable, say so in your final response and stop.
