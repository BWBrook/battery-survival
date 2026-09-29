# Battery Survival: Successor Handover

Updated: 2026-09-19

## September 19 independent-review correction — current state

The current correction follows `docs/profile_support_revision_plan.md` and the
fresh adversarial review in `docs/reviews/2026-09-18-astra-adversarial-review.md`.
It replaces marginal-mode operating profiles with observed joint region/season
cells and observed nearest-median workload pairs, then refreshes support counts
and saved-fit predictions. Current derived outputs are in
`outputs/management/2026-09-19/`; all profile-dependent September 18 numbers below
are historical. No fits, priors or raw data change. Run `just refresh-profiles`
then `just break-even` in the documented runtime before `just publication`.

The publication explicitly treats downtime and break-even values as conditional
illustrations of the last-image endpoint and retrospective workload scenarios.
The SW check did not test camera dependence. The Cox figure now has readable
labels. A signature guard stops the fitting runner before overwriting inputs
or reusing incompatible checkpoints; unsigned legacy archives are read-only
inputs to derivation scripts, not resumable destinations. Use a new output
directory for authorised new fitting. Author field questions are consolidated
in `docs/field_methods_author_questions.md`; unavailable service dates remain
outside scope. Completion evidence is recorded in `docs/log/2026-09-19.md`.

## September 18 practice-focused revision after Fable review (historical)

The publication now has a concise main manuscript (two tables, four figures)
and standalone Supplementary Information (four tables and the SW figure).
`just publication` builds both PDF/DOCX pairs. The main cost table is derived
from saved camera models, not the old quantile-interpolated curves. Details are
in `docs/management_revision_plan.md` and `docs/log/2026-09-18.md`.

The focused follow-up to Fable message 226 replaces the joint-optimisation
headline with white-flash break-even lost-day values at 90/120-day visits.
The 120-day expected-loss thresholds are approximately 0.95–1.54 illustrative
units (2–3% of an Energizer set), with paired posterior uncertainty and regional
risk counts. Family differences reach 25% at 90 days, but are below 5% at 120.
Profile conditions differ, so this is not a causal battery-treatment contrast.
The prior optimisation and posterior-tail discussion remain archived in the
management plan/log and earlier generated results. They are not reinstated in
the publication. No fits, priors or raw data changed.

`just break-even` generates the current derivation under
`outputs/management/2026-09-18/break_even/`; `just management` retains the earlier
exploratory output. Wildlife Research is now the working target and the draft
has its structured abstract. Field protocol, author metadata and canonical
bibliography reconciliation still need completion before circulation. Source
changes remain local and uncommitted.

## September 17 sensitivity analysis

The authorised bounded AFT and camera-dependence sensitivity analysis is
complete. Read `docs/log/2026-09-17.md` and
`docs/sensitivity_analysis_plan.md`; the generated report, tables, figures and
model checkpoints are under `outputs/sensitivity/2026-09-17`, mirrored from
the dated deep-server snapshot recorded in the log. All 12 frequentist fits
and four Bayesian fits completed; all Bayesian gates and 182 tests passed.

Brand-specific scales and region change the AIC preference to loglogistic.
Camera-associated heterogeneity is appreciable, while its effect on the
better-supported conditional servicing intervals is small. Family sensitivity
and failed SW transfer remain consequential. Treat the last image as minimum
confirmed runtime; service-date reconstruction is outside scope. The canonical production outputs retain the earlier baseline; the September 18
manuscript synthesis distinguishes that baseline from the new sensitivity.

## Current amendment

The servicing interpretation has been corrected and a private Makedoc manuscript
backbone now exists. Read `docs/servicing_cost_interpretation.md`,
`docs/log/2026-09-12.md`, and `manuscript/README.md` first. The older briefing
below preserves the accepted model evidence and history, but its template-only
Makedoc status and grid-minimum interpretation are superseded. The active
pipeline reports cost and downtime curves without unconstrained optima. The
backbone uses saved full-data outputs and a small verified starter bibliography;
field details, complete references, authorship and journal decisions remain open.

## September 5 briefing

This is a current-state briefing, not a chronology. Read it with the repository
instructions and verify live state before changing anything.

## Project in One Paragraph

Battery Survival asks how long camera-trap battery deployments remain
operational under field conditions, which factors are associated with failure,
and how those survival patterns can inform servicing decisions. The scientific
product is a reproducible ecological reliability analysis linked to a concise
paper: nominal trap days are not necessarily effective observation effort, and
battery choice, camera workload, and revisit interval should be treated as an
empirical decision problem rather than rules of thumb.

The analysis is mature enough for manuscript drafting. Do not begin another
major modelling phase unless manuscript synthesis exposes a consequential flaw
or Barry changes the scientific question.

## Start Here

At handover, the repository was consolidated onto `main`, tracking
`origin/main`, with no side branches or auxiliary worktrees. The literature
reports, identifier list, Makedoc scaffold, and this briefing are tracked. Old
goal-packet machinery, duplicate scaffold copies, and superseded local logs
were deliberately retired after their useful scientific content was captured
here.

Begin with `git status --short --branch`, `AGENTS.md`, and this file. If the
checkout is no longer clean, inspect and preserve the new state rather than
assuming it is disposable.

## Accepted Baseline

Two published commits define the current product:

1. `9a00fe3 refactor: simplify analysis workflow`
   - Removed the duplicate Make interface, obsolete install wrapper, empty
     signpost modules, and unused `rstan` compatibility path.
   - Simplified repeated economics computation and made supported-validation
     failures visible rather than silently replacing them with missing values.
2. `bef50b2 refactor: freeze scientific output contract`
   - Separated Cox association inference from AFT distribution selection.
   - Restricted AIC ranking to Weibull, lognormal, and loglogistic AFT models.
   - Fixed the supported Quarto project-render path and made the manuscript
     source an explicit `targets` dependency.
   - Added the Makedoc-aligned manuscript scaffold without activating it.

The last local verification for `bef50b2` was `just full`, 107 passing tests,
clean whitespace checks, an HTML manuscript, and a 16-page PDF. GitHub
`ci-dev` passed, and four subsequent scheduled `ci-full` runs through
2026-08-31 also passed on the same commit. Re-run proportionate checks after
changes that affect analysis; do not repeat expensive validation merely to
reproduce this receipt.

## Fixed Scientific Contract

Treat the following as settled unless new evidence materially changes the
paper:

1. **Endpoint.** One row is a serviced deployment interval. For `bok = 1`, the
   camera was operational at service and `rd` is an exact right-censoring time.
   For `bok = 0`, the camera was non-functioning because of dead batteries or
   an internal power error, and `rd` is the date of the last image. The estimand
   is therefore time to last confirmed operation; last-image `rd` is a
   conservative lower-bound proxy for latent failure time, not an observed
   exact failure date. The service-date upper bound is absent from the analysis
   CSV, so an interval-censored refit is not currently identifiable from these
   data.
2. **Analysis populations.** TAS-CAM regions `ct`, `se`, `nw`, and `wt` form
   the training/inference set. `sw` is a held-region check, `ne` is descriptive,
   and `tb` remains a separate testbench cohort.
3. **Model roles.** Kaplan-Meier curves are descriptive. The region-stratified
   Cox model uses camera-cluster robust inference and supports association
   statements. It is not the prediction engine, especially because the global
   proportional-hazards test is non-null (`p = 0.011`).
4. **Prediction model.** AIC compares only the three comparable AFT
   distributions. Weibull is clearly preferred: AIC 18,763.23, versus
   loglogistic at delta AIC 49.46 and lognormal at delta AIC 134.99. The
   Weibull AFT model supplies prediction and service-interval economics.
5. **SW evidence.** SW is from the same project and protocol, not independent
   external validation. Only 183 of 589 SW rows occupy supported
   battery/flash strata. Report it as a support-limited held-region check and
   do not imply broad transferability.
6. **Bayesian evidence.** The production Bayesian review is corroborating, not
   the primary analytical spine. Its clean diagnostics and preference for
   Weibull over lognormal support the frequentist result. Gamma remains
   deferred; do not reopen it without a decision-relevant reason.
7. **Economics.** Battery and servicing costs are credible scenario inputs,
   including their relative ordering, but will drift with inflation and
   manufacturing costs. Interpret 359-day minima as the lowest evaluated
   values near the grid boundary, not estimated interior optima or universal
   prescriptions.
8. **Covariate interpretation.** Image-rate variables are realised
   within-deployment workloads, not clean baseline exposures. Avoid causal
   language. Camera model, battery chemistry/brand, flash type, settings,
   climate, and protocol constrain generalisation.
9. **Repeated deployments.** The AFT fits treat deployment intervals as
   independent even though cameras can recur. A bounded camera-level
   uncertainty sensitivity remains a legitimate pre-submission decision, but
   it is not a drafting blocker and should be run only if it could change the
   headline inference.

Useful descriptive anchors from the accepted outputs are median survival of
85 days for Procell, 108 for Wallaby, 132 for Ansmann, 181 for Varta, and 191
for Energizer. Use the generated tables for exact estimates and uncertainty;
do not manually transcribe numbers into analysis code.

## Literature Package

The current local checkout contains the material needed for drafting:

- `docs/battery_survival_deep-research-report.md`
- `docs/battery_survival_literature_second_pass.md`
- `docs/battery_survival_identifiers.txt`

The second pass includes an annotated source list, claim-to-citation matrix,
overclaim warnings, and suggested framing. Its main conclusion is useful:
camera-trap ecology has sophisticated animal-state and observation models, but
device-state reliability and battery exhaustion are still handled mainly by
heuristics. The paper's contribution is therefore direct field survival
analysis joined to risk-cost servicing decisions.

Draft with these boundaries:

- Battery downtime reduces realised effort and can affect ecological inference;
  do not claim it necessarily biases every study.
- Operational support for lithium batteries is stronger than the direct,
  camera-specific experimental literature.
- Device, settings, environment, and workload heterogeneity make universal
  transfer claims indefensible.
- Solar and wireless systems are relevant alternatives, but add complexity and
  other failure modes. Their increased visibility can increase theft or
  vandalism exposure, except where remoteness changes that trade-off.
- Cardona, Buettel, and Brook (2025) is the closest camera-trap survival
  precedent, although its event is theft rather than battery failure.
- State novelty as no direct battery-survival precedent located in the present
  search, not as an unqualified first-ever claim.

`docs/battery_survival_identifiers.txt` is an import list, not a finished
bibliography. `references/refs.yaml` on `main` is still a placeholder.
Before citation-complete drafting, locate or obtain Barry's BetterBibTeX YAML
export, validate its identifiers and metadata against the literature reports,
and use Pandoc citation keys consistently. Do not build a new evidence ledger.

## Manuscript and Reproducibility Surfaces

- `manuscript/paper.qmd` is the executable Quarto analysis/review document. It
  proves that generated tables and figures can be consumed reproducibly; it is
  not the publication-prose source.
- `manuscript/text/main.md` and `manuscript/text/figures.md` are the intended
  publication manuscript for `/Users/bwbrook/work/makedoc`.
- `manuscript/authors.yaml`, `references/refs.yaml`, `csl/`, and
  `settings/build.yaml.template` are intentionally incomplete.
- Generated analysis artefacts belong under `outputs/` and must not be edited
  manually.
- The historical scripts under `methods/` are provenance, not the active path.
  Do not revive or refactor them unless a specific scientific need earns it.

Before activating Makedoc, inspect its current live README and configuration
contract; the scaffold was written in August 2026 and Makedoc may have moved.
Final author order/metadata and target-journal/CSL choices remain Barry-level
decisions when they become necessary.

## Recommended Next Programme

The next coherent tranche is **literature synthesis and an 80/20 first
manuscript draft**, not another goal-by-goal analysis cycle.

1. Ingest and validate the BetterBibTeX YAML bibliography, or clearly flag its
   absence before citation-complete work.
2. Draft the full publication manuscript in the Makedoc source around the
   fixed evidence hierarchy: ecological motivation; data/endpoint; KM
   description; qualified Cox associations; Weibull AFT prediction;
   support-limited SW check; scenario economics; concise Bayesian
   corroboration; limitations and reproducibility.
3. Activate and run the smallest current Makedoc build only when bibliography,
   authorship, CSL, and build settings are sufficiently specified.
4. Perform one substantive scientific/prose review and one material repair
   pass. Return to Barry for domain judgment rather than polishing indefinitely.

The gold stamp is a complete, citation-backed, reproducibly built first paper
that is scientifically honest about endpoint uncertainty and transportability,
and is good enough for Barry to critique as a coauthor. It does not need to be
submission-perfect.

## Working Style and Skills

Use these as active disciplines, not ceremonial workflows:

1. `/Users/bwbrook/.codex/skills/twilight-laboratory/SKILL.md`
   - Work as an assertive scientific collaborator.
   - Preserve Barry's attention for consequential interpretation, authorship,
     journal posture, public release, and genuine trade-offs.
   - Keep the reporting horizon large enough to produce a coherent manuscript
     advance rather than asking for approval after every internal step.
2. `/Users/bwbrook/.codex/skills/kill-your-darlings/SKILL.md`
   - Keep the active path lean and resist compatibility layers, duplicate
     commands, ledgers, speculative abstractions, and redundant tests.
   - Protect scientific validity, data integrity, and reproducibility while
     simplifying the machinery around them.
3. `/Users/bwbrook/.codex/skills/audit-ai-writing/SKILL.md`
   - Use once on the assembled manuscript to remove generic AI phrasing and
     preserve a credible ecological voice. Do not repeatedly sand the prose.

The working principle is: **rigour at the scientific decision boundary;
proportional engineering everywhere else**. Inspect evidence directly, make
routine reversible choices autonomously, and stop when further work is mainly
polish or engineering theatre.
