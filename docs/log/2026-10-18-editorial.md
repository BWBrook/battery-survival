# 18 October 2026 — editorial reconstruction with Claude

## Purpose and delivered draft

Barry requested substantial reworking for an ecology editor as well as a
specialist, through asynchronous collaboration with Claude. Thread 91 contains
the request and argument exchange. This package assembles an effort-first
paper from the 29 September draft (`7d8d443`), implements new evidence displays,
and gives Claude the next direct writing pass. It is a private working draft,
not a circulation or submission release.

The paper now opens with the observation time that a nominal deployment may
fail to deliver. The sequence is field endurance, additional expected lost
days at fixed revisits, and failed regional transfer. Costs follow the lost
time as a worked application. The main manuscript has two tables and three
figures; the supplement has five tables and three diagnostic figures. Neither
main table's numerical rows changed. The 190-word abstract retains the core
result and inference boundaries.

## Files and derivation

- Prose and captions: `manuscript/text/main.md`, `figures.md`, `supplement.md`,
  and `supplement_figures.md`; workflow notes in `manuscript/README.md`.
- Figure code: `R/editorial_lost_camera_days.R`, thin entrypoint
  `scripts/plot_editorial_lost_camera_days.R`, and the updated
  `scripts/plot_manuscript_sensitivity.R`. The latter adds 90/120-day guides
  and risk counts to KM and displays the saved six-model SW comparison.
- Tests: `tests/testthat/test-editorial-lost-camera-days.R` covers signed
  paired limits, joint-cell follow-up, reference/workload support and duplicate
  comparisons.
- Build and references: `justfile`, `settings/build.yaml`, `references/refs.yaml`
  and `references/README.md`. Royston and Parmar (2013) and Solow (2005) were
  checked against primary publications before addition.
- Decision record: `docs/reviews/2026-10-18-editorial-reconstruction.md` and
  `docs/HANDOVER.md`.

The additional-days display transforms the saved 19 September posterior
downtime gaps by multiplying each mean and interval endpoint by the positive
visit horizon. It shows 14 supported comparisons and withholds both
Procell/120-day rows. This preserves paired parameter uncertainty; it does not
add a new fit or a predictive interval for individual cameras. Source and
artifact hashes are saved with the CSV, PDF and PNG in
`outputs/management/2026-10-18/editorial/`. The input CSV hash remains
`85a98ae0f3d27a47d55e0b88e99d47a06fdc15f89578b76378514afcfdd780b5`.

No raw inputs or sealed model archives were changed by this package. Claude's
concurrent endpoint-gap analysis occupies separate files and outputs; its
results are not integrated here.

## Verification

- `just publication`: passed for both main and supplement, including the
  saved-output plotting steps and Makedoc checks. After final prose/layout
  edits, each Makedoc profile was rebuilt and its DOCX formatter and build
  manifest regenerated successfully. Logs are under
  `outputs/publication/review-2026-10-18/`.
- Focused `testthat` run with `R_PROFILE_USER=/dev/null`: nine expectations
  passed, with no failures, warnings or skips. The project's restored renv
  environment was not claimed as validated. The full analysis pipeline and
  model fitting were not run for this editorial change.
- An independent arithmetic check matched all 14 plotted mean/lower/upper
  triplets to the source summaries. September worked-example numbers were
  separately traced to their CSVs and the training rows; the review note
  records exact values and sources.
- An independent manuscript review found no material remaining claim drift
  after three wording repairs concerning intervals versus cameras, model-
  conditional camera-effect stability and modelled rather than measured time.
  This was a wording/evidence-boundary review, not independent estimation.
- Citation keys resolve and figure identifiers are unique. `qpdf --check`
  passes for both PDFs. Both build manifests match all seven recorded input
  and output hashes apiece. `git diff --check` passes.
- Main PDF: 13 pages; supplement PDF: 11 pages. All pages were visually
  reviewed, with changed pages reviewed again after the final prose edits.
  Tables, axes, legends and captions are legible and unclipped.
- DOCX: all 19 main and 14 supplementary LibreOffice-rendered pages were
  visually reviewed, with ZIP/XML and A4-page checks. Microsoft Word desktop
  rendering was not tested. The full QA report is
  `outputs/publication/review-2026-10-18/docx-qa/final/qa-report.md`. Main and supplement contain the intended two/five tables and three
  figures each. Word pagination retains small spills: Keywords on a separate
  main page, two availability lines before References, and five lines of
  supplementary S7 before References. These affect layout, not content.

## Boundaries and next exchange

Recorded last-image times remain minimum confirmed operation, workloads remain
retrospective, and scenarios differ in region, season and workload. Procell at
120 days remains withheld. The SW comparison tests independent-row no-region
fits within the same project, not external validation or transfer of the
camera-effect models. Average spending is no longer treated as evidence of
the marginal scientific value of a missed day. Conditional-interval optima
remain supplementary diagnostics rather than the headline management result.

Claude's next pass can edit text and captions directly. His constructed-gap
sensitivity needs its own numerical review before use; it cannot validate a
shutdown-time mechanism. Field-protocol answers and author metadata remain
necessary before circulation. No push, public release or submission is part
of this package.
