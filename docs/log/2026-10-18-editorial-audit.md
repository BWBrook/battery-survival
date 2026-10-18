# 18 October 2026 — audit and integration of the second editorial candidate

## Outcome and collaboration

This pass follows Claude's message 1987 in Correspondence thread 91 and the
first assembled candidate at `7e154fd`. It retains his continuous lost-time
curves and tolerance-based comparison because they show how endurance enters
a survey requirement before prices are introduced. The working question title
is retained. The abstract is 247 words. Main text has three tables and three
figures; Supplementary Information has six tables and four figures.

The rewrite removes an unsubstantiated absence-of-literature claim, treats
nonlinear growth in expected losses as a property of the fitted curves rather
than a mathematical threshold, and distinguishes expected effort from realised
operation and individual-camera guarantees. Scenario differences are not
battery-switching effects. A separate endpoint perturbation remains exploratory
and cannot validate the new tolerance schedules or diagnose the daylight
association.

## Independent numerical findings and repairs

The curves/tolerance audit independently integrated the lifetime CDF over time
and camera heterogeneity for 30 family/scenario/horizon combinations. Maximum
mean discrepancy was 9.90e-11 days (maximum draw discrepancy 1.09e-7). All 20
mean-curve crossings were checked independently; one-day-grid interpolation
error was at most 0.00536 days. Explicit chain/iteration reconstruction matched
the 1,000 balanced saved draws. All 14 supported 90/120-day means and interval
limits matched the archived paired summaries within 8e-14 days.

Three repairs were consequential:

1. Varta's 10% crossings have only one deployment interval and one camera at
   risk in the exact SE/summer white-flash cell. They are now flagged in main
   Table 2 and prose. Thin curve tails fade, and machine-readable outputs
   retain joint-cell counts at each horizon and at interval limits.
2. The original tolerance summary discarded 0.5–0.6% of Energizer draws that
   did not cross within 204 days. Right-censored draws now retain their ranks.
   The 10% upper limits are 200.2959589 days (Weibull) and 201.4215423
   (loglogistic); rounded main-table values are unchanged. Unavailable bounds
   are explicitly censored, not labelled as infinite crossing times.
3. Curve grids now include the exact maxima, including Ansmann 164 and Varta
   175 days. Falling below a maximum is distinguished from adequate risk-set
   support. Standalone tolerance provenance includes inputs, code and runtime.

The endpoint audit independently replayed six fits (unshifted, first uncapped
largest-gap replicate, and its paired capped replicate, in both families).
Saved thresholds matched within 7e-13. Direct survival integration agreed
within 1e-7, and independent aggregation reproduced all 80 original pooled
thresholds within 4.1e-14. Pooling order and original support flags were correct.

However, 20 imputations gave up to 10.6% relative Monte Carlo SE at 120 days.
The median six-day gap concealed a long tail; capping only a few records changed
some Weibull comparisons appreciably. The original claim that the cap changed
almost nothing was withdrawn. The uncapped flash coefficient had also been
confused with the capped value. The revised reporting distinguishes the
frequentist baseline, variation across assumed gaps, Monte Carlo error, and
posterior uncertainty from the main models.

Increasing to 200 imputations exposed Weibull convergence failures at the
largest uncapped gap setting. Imputation 63 failed both the default 30 and
200-iteration attempts. Three targeted fits, including starts from converged
unshifted brand-scale and common-scale fits, also failed and had inconsistent
returned states and large scores. No further optimiser tuning was pursued.
The reporting rule withholds an entire setting/family if any imputation fails;
it must never average a selected converged subset. Failed attempts and the
unchecked intermediate run are retained separately. The main archived
camera-effect fits are unaffected.

## Implementation and scope

- New analysis helpers: `R/lost_day_curves.R` and
  `R/endpoint_gap_sensitivity.R`.
- Entry points: `scripts/plot_lost_day_curves.R`,
  `scripts/summarise_tolerance_intervals.R`, and
  `scripts/run_endpoint_gap_sensitivity.R`.
- Tests: the two corresponding files under `tests/testthat/`, including
  right-censored ranks, inversion of mean downtime, joint-cell support,
  expected-loss pooling, Monte Carlo SE and imputation-count validation.
- Sources: main/supplement manuscript and captions; `justfile` now regenerates
  tolerance summaries as well as figures during publication. The exploratory
  fitting recipe remains separate.
- Documentation: manuscript README, handover, editorial decision record and
  dated writing/audit logs.

Raw input data and sealed September model archives were not changed. Curve
and tolerance derivation uses saved fits. The separate endpoint runner refits
only its stated frequentist response perturbations and writes October outputs.
No push, public release or submission is part of this work.

## Verification record

`R_PROFILE_USER=/dev/null OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 just test`:
381 passed, no failures or warnings, one existing skip because `posterior` is
not installed locally. This is not a complete renv-restoration claim. The
saved-draw calculations were checked independently despite that skipped
package-specific adapter test.

Audit scripts/results and test logs are retained under
`outputs/publication/review-2026-10-18/round3-audit/`.

The main manuscript build passed Makedoc's reference and author-injection
checks. All 14 pages of the rebuilt PDF were visually inspected; tables,
equations, captions and all three figures fit without clipping or overlap.
`qpdf --check` passed. The original brand-association and break-even tables
are unchanged; all 20 displayed tolerance cells match the regenerated CSV.
The new 60/90/120-day lost-time statements were also checked against the curve
table. Both 12-input curve/tolerance MD5 manifests match their inputs.

The final endpoint run completed in 99.40 seconds on one CPU with explicit
status `complete_with_withheld_groups`: 1,602 fits attempted, 1,600 accepted,
and 1,604 optimiser attempts including retries. Weibull b10 imputations 63 and
121 failed; the entire group is absent from all model-dependent summaries.
Every one of the seven reported perturbed groups has 200 accepted fits; both
unshifted baselines also passed. The maximum supported 120-day relative MCSE
is 0.889985%, below the prespecified 5% target. The 14 top-level output files
were verified against a fresh run before replacing unchecked files; archives
remain intact. All seven input/code MD5 hashes match.

The main DOCX was independently rendered with LibreOffice and all 21 pages
visually inspected. ZIP/XML/A4 checks, all three tables and figures, all 21
math objects and text recovery passed; the original DOCX hash was unchanged.
This does not test Microsoft Word desktop rendering.


Rendered-document QA found two source issues and prompted one repair pass:
the moved point figure had an identifier that Makedoc numbered as Fig. 1
instead of S4; the identifier now follows the existing `-s4` convention.
LibreOffice rendered an ASCII asterisk superscript in the break-even equation
as an error glyph. A bounded probe showed that explicit `\star` converts to
a clean superscript in both document formats, so both sources use it.
Supplement S8 was shortened to keep its small result table together and avoid
a nearly empty continuation page. These edits change presentation, not values.

The final Word check also identified U+203E overbar accents displayed as acute
marks by LibreOffice. A second bounded notation probe confirmed that explicit
`\overline{A}`, `\overline{D}` and `\overline{L}` preserve horizontal mean bars.
All eleven affected source occurrences now use that equivalent notation.


Final `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 just publication` passed.
Both PDFs have 14 pages. All manuscript and supplement pages were visually
reviewed; affected pages were rechecked after the notation fixes. Table S6 now
fits together, the extra title-only page is gone, and captions/figures are
ordered S1–S4. All 30 S6 numeric/withheld cells match the qualified output.
Both PDF structural checks and all 14 current build-manifest input/output
SHA256 checks passed. Curve, tolerance and endpoint input hashes also match.
Evidence is in `round3-audit/`, `round3-pdf-qa/` and `round3-docx-qa/` beneath
`outputs/publication/review-2026-10-18/`.

The next useful step is a bounded editorial read of the assembled argument,
not more default model fitting. Field protocol and author metadata remain open
for author confirmation before circulation or public release.


Final DOCX QA passed at 15:54 AEDT on 18 October 2026: 21 main pages
(three tables/three figures) and 17 supplement pages (six tables/four figures).
The star and all eleven mean bars render correctly. Only main pages 6–7 and
supplement pages 5/7 changed after the notation repair; those were re-inspected,
and every other rendered page was byte-identical to its inspected predecessor.
All 196 main and 289 supplement nonmath text units were recovered. ZIP/XML,
A4 geometry, page bounds, PDF checks and unchanged-original hashes passed.
The final report is `round3-docx-qa/final/qa-report.md`. Microsoft Word desktop
rendering remains untested.
