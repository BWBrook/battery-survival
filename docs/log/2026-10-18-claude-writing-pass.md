# 18 October 2026 — Claude writing pass on the effort-first draft

> Historical record of the pass handed to Codex in message 1987. The subsequent
> numerical and wording audit found material support and simulation-precision
> qualifications; see `2026-10-18-editorial-audit.md` for the corrected candidate.

Starting point: Codex commit `7e154fd`, handed over in correspondence thread 91
(message 1960). Barry's standing authorisation for new analyses and display
items is quoted in thread 91, message 1952. Nothing in this pass refits a
model, changes raw data or alters a sealed archive; nothing is committed.

## Argument

The draft now leads with a practitioner question that a general ecology editor
recognises at once, "How long can a camera trap be left?", and answers it from
the survival curves before turning to prices. The organising idea is unchanged
from the effort-first draft: a camera's effort is the area under its survival
curve up to the next visit. The new evidence makes the threshold behaviour
visible: expected lost time is negligible until revisits reach a scenario's
failure window, then rises steeply. Limits are stated once beside each claim,
and the closing message is that the method transfers while the numbers are
local.

## New derived analyses (saved fits only)

- **Continuous lost-day curves** (main Fig. 2). `R/lost_day_curves.R`,
  `scripts/plot_lost_day_curves.R`; outputs in
  `outputs/management/2026-10-18/lost_day_curves/`. Expected lost camera-days
  per cycle, and additional days relative to Energizer, on a three-day grid of
  revisit intervals up to each scenario's maximum joint-cell follow-up, from the
  same balanced 1,000 posterior draws and 30-node quadrature as the published
  break-even values. Draws are read from the saved fit objects in base R
  because `cmdstanr` and `posterior` are not installed locally. The script stops
  unless its 90- and 120-day values reproduce the published additional lost
  days to within 1e-6 days; they do.
- **Tolerance intervals** (main Table 2). `scripts/summarise_tolerance_intervals.R`;
  `tolerance_intervals.csv` in the same folder. Longest revisit interval at
  which the posterior mean downtime fraction stays below 5% or 10%, on a
  one-day grid within support; per-draw crossings give parameter uncertainty.
  All intervals fall within observed follow-up; 0.5–0.6% of Energizer draws do
  not reach the 10% tolerance within its 204-day follow-up.
- **Last-image gap stress test** (Supplement S8, Table S6). Recorded in
  `docs/log/2026-10-18-endpoint-gap.md`, with Codex's five safeguards applied.

Astra's 90/120-day dot plot moves to Supplementary Fig. S4; its code is unchanged.
`justfile` gains `lost-day-curves` and `endpoint-gap` recipes, and
`publication` now regenerates the curve figure.

## Literature search behind the Introduction's gap statement

On 18 October 2026 Claude ran two web searches in extended mode: "camera trap
battery life survival analysis field deployments brands lithium alkaline", and
"camera trap" downtime battery failure effective sampling effort with
"time-to-event" or "Kaplan-Meier" and malfunction. Neither found a published
survival analysis of field battery records from camera traps. Results were
vendor and retailer guides with inconsistent, protocol-free lifetimes, effort
corrections that exclude non-functioning days, Kühl et al. (2023) on effective
survey duration, and Bischof et al. (2014) on time to detection. The
Introduction states this as a targeted search, not a priority claim. A
systematic search would be needed before any stronger statement.

## Checks

- `just publication` passes: lint, citation audit (main: 0 unknown, 0 unused),
  build checks, DOCX formatting and manifests. Main PDF 14 pages; supplement
  15. Main tables and Figs 1–3 inspected visually; Table 2 redesigned once to
  stop column wrapping.
- Every Table 2 cell matches `tolerance_intervals.csv` (automated check).
- Full test suite: 292 passed, 0 failed, 1 existing skip (`posterior` absent).
- Abstract 332 words (limit 350); body about 3,800 words excluding tables.

## Open for Codex and Barry

- Title choice.
- Whether the tolerance framing should also enter the 90/120-day economic
  discussion more strongly, or stay as the price-free answer.
- Codex has not yet audited the gap stress test or the new curves.
