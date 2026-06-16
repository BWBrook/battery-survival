# Plan: Goal 001 Dirty-State Reconciliation

## Strategy

This goal should turn the existing dirty worktree from an ambiguous local state
into a reviewable decision packet. The work should stay audit-shaped: classify,
validate, recommend. Do not repair or publish in this goal.

## Work Packages

1. **Starting-state capture**
   - Record `pwd`, branch, short HEAD, status, diff stat, and changed-file list.
   - Confirm the goal packet is the only intended new source of writes.

2. **Document-grounded context**
   - Read the required governance and current-state docs.
   - Extract the current intended semantics of:
     - standard `full` / `manuscript` outputs
     - production Bayesian snapshot
     - additive review manuscript
     - gamma-family status
     - local versus server validation expectations

3. **Dirty-state classification**
   - Group tracked changes into coherent work-package themes.
   - Treat untracked `.dockerignore` and May 29 logs as possible supporting
     evidence, not automatic commit candidates.
   - Identify any file that appears unrelated to the main bundle.

4. **Artifact and log audit**
   - Inspect existing `outputs/review/` snapshot tables, manifest, and review
     manuscript file presence/metadata.
   - Inspect May 29 logs enough to know what they prove and what they do not.
   - Distinguish cached-target evidence from fresh validation evidence.

5. **Targeted validation**
   - Run the validation ladder in `Runbook.md`.
   - Record exact commands and outcomes in `Log.md`.
   - Stop rather than patch if validation exposes a defect.

6. **Decision memo**
   - Write `Findings.md` with the evidence and recommendation.
   - Recommendation must choose one: accept, fix narrowly, split, or pause.
   - Include a proposed next goal if further work is needed.

7. **Wake-up**
   - Send a short wake-up to Battery Survival when complete or blocked.

## Expected Shape Of A Good Result

A good result lets Battery Survival decide, without rereading the whole repo,
whether the current dirty state is ready for supervisor acceptance and eventual
publication, or whether a narrow follow-up goal is needed first.
