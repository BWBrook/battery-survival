# Battery Survival manuscript

## Private editorial reconstruction, 18 October 2026

`text/main.md` connects battery endurance to expected observation time and
revisit schedules, with three main tables and three figures supplied by
`text/figures.md`: brand survival, continuous lost-time curves, and the six-model
SW comparison. Main Table 2 gives conditional crossings of 5%/10% expected-loss
tolerances; Table 3 retains the fixed-interval break-even comparison. Thin
joint-cell support is marked in curves and tables, especially Varta at 10%.
The technical sensitivity analysis is in `text/supplement.md`, with six tables
and five supplementary figures (Cox associations, training calibration,
conditional-interval diagnostics, paired 90/120-day lost-time contrasts,
and continuous losses under both lifetime families).
The obsolete quantile-truncated cost and downtime figures remain archived.

The September 19 correction, specified in `../docs/profile_support_revision_plan.md`,
uses observed region/season cells and observed workload pairs, with support
matched to those joint cells. Field questions for Barry are in
`../docs/field_methods_author_questions.md`. The focused September 18 revision responds to Fable's message 226 in thread 42.
The main management table compares white-flash break-even values at fixed
90/120-day revisits, with paired posterior uncertainty and follow-up counts.
Earlier joint optimisation remains archived. Costs remain illustrative units.
Wildlife Research is the working target, with its structured abstract; field
protocol, authorship, contributions and acknowledgements remain open for
Barry's review. See `../docs/log/2026-09-18.md` and
`../docs/management_revision_plan.md`.

## Build

Run `just publication` from this repository. It generates:

- `outputs/publication/battery-survival-integrated.pdf` and `.docx`
- `outputs/publication/battery-survival-supplement.pdf` and `.docx`
- a provenance/build manifest for each pair.

The command regenerates the displays from the saved sensitivity cohort and
calibration tables, robust Cox estimates and corrected 19 September profile
and break-even tables. It then runs Makedoc checks for both profiles, formats
DOCX pages and tables, checks PDF integrity with `qpdf`, and refreshes final
output hashes. Each document uses its own LaTeX build directory under
`outputs/publication/` to avoid sharing the Makedoc-wide compiler workspace.
These saved inputs
must already exist; this
command does not refit models. The source text records numbers derived from
saved output tables, so future data changes require a fresh evidence synthesis.

The continuous observation-time figure and tolerance table use
`R/lost_day_curves.R`, `scripts/plot_lost_day_curves.R`, and
`scripts/summarise_tolerance_intervals.R`. `just lost-day-curves` regenerates
them from the saved camera-model draws; `just publication` includes both steps.
The main figure (`lost_day_curves.png`) shows the Weibull model alone; the
supplementary `lost_day_curves_detail.png` adds the loglogistic model and paired
differences from Energizer. Outputs and separate figure/tolerance input manifests are in
`outputs/management/2026-10-18/lost_day_curves/`. Tolerance summaries retain
right-censored crossings beyond follow-up and include joint-cell risk counts.

The supplementary 90/120-day display uses `R/editorial_lost_camera_days.R`
through `scripts/plot_editorial_lost_camera_days.R`, multiplying the saved
paired downtime-gap summaries by each horizon. It withholds Procell at
120 days. Its outputs and provenance remain in
`outputs/management/2026-10-18/editorial/`.

`just endpoint-gap` reproduces the separate exploratory response perturbation
using 200 frequentist refits per setting and model family. It is not run by the publication recipe. Its output
under `outputs/endpoint_gap/2026-10-18/` includes simulation Monte Carlo errors
and gap-tail summaries; those errors are not sampling or posterior uncertainty.
The exercise does not validate the tolerance schedules or diagnose the
observed daylight association. The current result is explicitly
`complete_with_withheld_groups`: the entire uncapped largest-gap Weibull
setting is excluded because two fits failed. Read `analysis_status.csv` and
`scenario_family_status.csv` alongside the numerical summaries; an exit-zero
run does not mean every setting was estimable. All reported supported 120-day
thresholds meet the 5% relative Monte Carlo SE criterion (maximum 0.89%).

The SW figure uses all six saved no-region specifications; their range is
model variation, not an uncertainty band. Correspondence thread 91 and
`../docs/reviews/2026-10-18-editorial-reconstruction.md` record the editorial
exchange. Numerical and wording repairs to the added calculations are recorded
in `../docs/log/2026-10-18-editorial-audit.md`.

`just refresh-profiles` regenerates the corrected joint operating profiles and
camera-dependence diagnostics. `just break-even` then regenerates the current
management table and uncertainty from those profiles and the sealed camera fits,
under `outputs/management/2026-09-19/`. The 18 September marginal-mode profiles
and their outputs are historical and must not supply the current manuscript. `just management` reproduces the archived exploratory
optimisation; both use the documented sensitivity runtime. For sustained work run
on deep-server under tmux. `scripts/summarise_manuscript_effects.R` regenerates
KM intervals, chemistry, camera overlap, SW contrasts and coefficient extracts.
Generated outputs are ignored by Git; restore them from the documented archive
before building a fresh clone. The earlier backbone proofs are superseded.

The bibliography includes verified methodological and ecological references and uses a neutral
author-date CSL. Canonical-library reconciliation and venue-specific formatting
remain open. Unconfirmed `authors.yaml` metadata is intentionally not injected.
See `../docs/journal_options.md` for a provisional venue comparison.

## Analysis surfaces

`paper.qmd` remains the canonical baseline Quarto analysis/review source.
The completed sensitivity report is `outputs/sensitivity/2026-09-17/report.md`.
Neither is the publication manuscript; the revision does not replace canonical
fits or alter the sealed sensitivity archive. No universal downtime value or
field schedule is recommended.
