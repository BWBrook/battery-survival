# Plan: Goal 002 Acceptance Prep And Publication Boundary

## Strategy

This goal converts the accepted dirty bundle into one auditable local commit,
but only after fresh current-date review validation. It should avoid mixing
source changes, generated artifacts, and historical logs into one vague commit.

## Work Packages

1. **Starting state**
   - Record current branch, HEAD, status, diff stat, and changed-file list.
   - Confirm Goal 001 files and the new Goal 002 packet are visible.

2. **Context refresh**
   - Read repo governance, current workflow docs, and Goal 001 findings.
   - Extract the acceptance boundary from the Goal 002 contract.

3. **Validation**
   - Run `just test`.
   - Run `just review-prod-bayes`.
   - Record fresh logs and whether production review snapshot/manuscript
     evidence is current.

4. **Path decision**
   - Build an exact list of paths to stage.
   - Include the accepted source/config/docs/tests bundle.
   - Include `.dockerignore`.
   - Include Goal 001 and Goal 002 goal folders.
   - Include only fresh Goal 002 logs from the current validation run.
   - Exclude May 29 logs and the June 15 Goal 001 log by default.

5. **Findings**
   - Write `Findings.md` with validation, path decisions, and residual risk.

6. **Staging and commit**
   - Stage exact paths only.
   - Check staged diff stat and whitespace.
   - Commit once with the approved message if gates pass.

7. **Wake-up**
   - Send Battery Survival a short completion or blocker notice.

## Expected Good Result

The action repo should end with one new local commit on `master`, no push, and
only expected leftover untracked logs or ignored generated outputs. The commit
should be reviewable without requiring Barry to reconstruct the dirty-state
history from chat.
