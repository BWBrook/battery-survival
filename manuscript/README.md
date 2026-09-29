# Battery Survival manuscript

## Private practice-focused draft

`text/main.md` contains the field and management narrative, two main tables
and four figures supplied by `text/figures.md`. The technical sensitivity
analysis is in `text/supplement.md`, with five supplementary tables and the SW
figure from `text/supplement_figures.md`. The obsolete quantile-truncated cost
and downtime figures are excluded from the publication; their archive remains.

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

The command regenerates four publication figures from the saved sensitivity
cohort, robust Cox estimates and corrected profile tables, runs Makedoc checks for both profiles, formats DOCX pages and
tables, and refreshes final output hashes from the research repository.
The saved SW figure, sensitivity inputs, field-effect estimates and corrected
19 September profile tables must already exist; this
command does not refit models. The source text records numbers derived from
saved output tables, so future data changes require a fresh evidence synthesis.

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

The bibliography now contains ten verified references and uses a neutral
author-date CSL. Canonical-library reconciliation and venue-specific formatting
remain open. Unconfirmed `authors.yaml` metadata is intentionally not injected.
See `../docs/journal_options.md` for a provisional venue comparison.

## Analysis surfaces

`paper.qmd` remains the canonical baseline Quarto analysis/review source.
The completed sensitivity report is `outputs/sensitivity/2026-09-17/report.md`.
Neither is the publication manuscript; the revision does not replace canonical
fits or alter the sealed sensitivity archive. No universal downtime value or
field schedule is recommended.
