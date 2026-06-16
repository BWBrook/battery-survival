# Goal: Reconcile and Validate the Existing Dirty State

## Objective

Produce a supervisor-reviewable decision memo that determines whether the
current dirty Battery Survival worktree is a coherent, bounded work package
ready for acceptance, needs narrow follow-up fixes, should be split, or should
pause for Barry/Battery Survival direction.

## Why This Matters

The repo already contains uncommitted changes touching project governance,
Docker/R runtime setup, Bayesian profile configuration, Bayesian helper code,
tests, `renv.lock`, and local review logs. Those changes appear related to the
R 4.6 / Bayesian production-review workflow, but they have not yet been
classified or validated as an accepted work package.

This goal supports the decision: what, exactly, should Battery Survival accept
as the next project baseline, and what evidence is still missing?

## Operating Mode

Review/audit with targeted validation.

## Review Surface

Battery Survival will review:

- `docs/goals/001-dirty-state-reconciliation/Findings.md`
- `docs/goals/001-dirty-state-reconciliation/Log.md`
- final `git status --short --branch`
- validation command outcomes and any new log/artifact paths reported

## Scope

In scope:

- classify the existing tracked and untracked dirty state by purpose
- inspect relevant diffs, existing review logs, and review-bundle artifacts
- compare the dirty state against repo governance and current planning docs
- run the bounded validation ladder in `Runbook.md`
- produce a concise decision memo with accept/fix/split/pause recommendation

Out of scope:

- new scientific modelling or interpretation
- manuscript rewriting
- source-code fixes or refactors
- dependency upgrades beyond observing the existing `renv.lock` change
- cleanup, deletion, staging, commits, pushes, PRs, or branch changes
- remote jobs or production Bayesian reruns
- changing generated artifacts by hand

## Read First

- `AGENTS.md` - repo governance and command surface
- `README.md` - current workflow and review-output descriptions
- `docs/plan.md` - current WP9-WP11 project state
- `docs/decisions.md` - accepted Bayesian/review workflow decisions
- `docs/release_readiness_2026-03-11.md` - existing readiness criteria
- `docs/log/2026-03-11.md` - latest documented review workflow evidence
- this goal packet: `Goal.md`, `Plan.md`, `Runbook.md`, and `Log.md`

## Starting State Checks

Start by recording:

- `pwd`
- `git status --short --branch`
- `git rev-parse --short HEAD`
- `git diff --stat`
- `git diff --name-status`

Treat pre-existing dirty state as project state. Do not normalize it.

## Git And Publication Policy

- No staging, commits, pushes, PRs, merges, resets, stashes, branch checkouts,
  file cleanups, or deletion.
- Goal files may be updated inside
  `docs/goals/001-dirty-state-reconciliation/`.
- Validation commands may create ordinary ignored outputs, target cache updates,
  and logs; report them explicitly.
- If any validation unexpectedly modifies tracked files outside this goal
  folder, stop and report the exact status.

## Data, Compute, And Staging Policy

- Work in the existing local checkout only:
  `/Users/bwbrook/papers/battery-survival`.
- Do not run remote jobs.
- Do not run `just bayes-prod` or `just review-prod-bayes` in this goal.
- Docker validation is optional and gated: probe `docker info`; if the daemon is
  unavailable, report that fact. If it is available, run only the bounded Docker
  check in `Runbook.md`.

## Required Work

1. Reconstruct the dirty-state story.
2. Audit the relevant review artifacts and logs.
3. Run the bounded validation ladder.
4. Write `Findings.md` with a recommendation.
5. Update `Log.md` as work proceeds.
6. Send a wake-up to the Battery Survival orchestrator when complete or blocked.

## Validation Gates

The goal is complete only when:

- dirty-state classification is documented
- current review artifacts/logs are checked for internal consistency
- targeted validation outcomes are recorded
- any skipped validation is justified
- `Findings.md` recommends accept, fix, split, or pause
- final git status is reported

This is targeted validation for a pre-existing dirty state, not full release
validation.

## Deliverables

- `docs/goals/001-dirty-state-reconciliation/Findings.md`
- updated `docs/goals/001-dirty-state-reconciliation/Log.md`
- final response in the `energizer` thread
- short wake-up message back to the Battery Survival orchestrator thread

## Decision Authority

You may decide:

- how best to group the dirty files by work-package purpose
- whether evidence is strong enough to recommend accept, fix, split, or pause
- whether Docker validation is feasible after the `docker info` probe
- whether to stop early if validation would exceed the scope

You must pause before:

- changing source, tests, configs, docs outside this goal folder, or lockfiles
- changing scientific assumptions or model defaults
- launching remote or long production jobs
- deleting, cleaning, staging, committing, or pushing anything
- making publication claims not supported by inspected evidence

## Stop Conditions

Stop when one of these is true:

- the validation gates are satisfied and deliverables are complete
- validation fails in a way that requires source changes
- Docker or local runtime state blocks the bounded validation ladder
- an ambiguity affects scientific or publication direction

## Final Response Requirements

Report:

- what you read
- dirty-state classification
- validation commands and pass/fail/skipped outcomes
- generated or updated logs/artifacts, if any
- recommendation: accept, fix, split, or pause
- residual risks
- final `git status --short --branch`
- confirmation that no source fixes, cleanup, staging, commits, pushes,
  remote jobs, production Bayesian reruns, or manuscript rewrites occurred

Then send a short wake-up message to the Battery Survival orchestrator thread
`019eac3b-28ae-7ad2-bd5e-16d76db78fcd` using available thread tools. If thread
tools are unavailable, say so in your final response and stop.
