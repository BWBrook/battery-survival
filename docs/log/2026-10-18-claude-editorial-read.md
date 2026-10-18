# 18 October 2026 — Claude editorial read of candidate 98911fa

Codex handed main text, captions and supplement back in Correspondence thread
91 (message 2005), asking for a general-ecology editor's read that preserves the
audited evidence boundaries. No model was refitted and no sealed output changed.

## Independent triage

A fresh Claude Sonnet subagent with no project context read the
`candidate-98911fa` PDF as a Wildlife Research handling editor. Its verdict was
"send to review, lukewarm-positive". It found the opening sentence and the
Fig. 2 curve shape memorable. It flagged these problems:

- Brand colours differed between Figs 1 and 2.
- Fig. 2 carried four encodings per curve and a small legend, and its panel b
  looked like panel a.
- Fig. 1's "Days" label overlapped the at-risk header, and Fig. 3's title
  overlapped its subtitle.
- Several caveat-first sentences sat where the reader wanted the finding.
- The abstract's key result was weak: "losses increased more rapidly".
- The 72- versus 160-day headline did not say that it compares a winter scenario
  with a summer one.
- The paper never said which way the last-image convention biases lost time.

Administrative gaps (the draft banner, field-methods input and private data)
remain Barry's.

## Changes

- **Main Fig. 2** is now a single panel showing the Weibull model only. It has
  an opaque legend with full region and season names, and grey 5% and 10% loss
  lines, so each curve's crossing is its Table 2 interval.
- **New Fig. S5.** The former two-panel figure, with both families and paired
  differences from Energizer, is now Fig. S5 (`lost_day_curves_detail.png`).
  The 90/120-day validation against the published break-even outputs still
  passes.
- **Fig. 1** now uses the Fig. 2 brand colours, ordered by endurance. Its
  at-risk table is aligned with the time axis and the label overlap is fixed.
- **Fig. 3:** the overlapping subtitle was removed; its content is already in
  the caption.
- **Abstract** (348 words including headings). Key results now give the
  following, each traceable to existing outputs:
  - The 4.2–6.0-fold growth in additional loss between 90 and 120 days, from
    `break_even_estimates.csv`.
  - The winter and summer labels on the tolerance contrast.
  - The 12% effort inflation, from Table S4.

  Conclusions now state the finding, and Implications lead with what surveys
  can do.
- **Methods and Discussion** state that the last-image convention tends to
  overstate lost time, and therefore to shorten tolerance intervals. Its effect
  on cost thresholds is not signed. "Tends" is deliberate: shortening event
  times does not guarantee a lower Kaplan–Meier or parametric survival curve at
  every time.
- **Results and Discussion:**
  - The Results heading now states the finding.
  - The tolerance paragraph refers to the diagonal lines and gives 10% gains of
    about 11–34 days, checked against `tolerance_intervals.csv`.
  - The stress-test sentence reports the magnitude from Table S6: thresholds
    move from 1.38–1.64 to 1.36–3.09 across converged settings.
  - The 27% sentence is plainer.
  - The 90/120-day horizon disclosure is kept but no longer reads as a
    confession.
  - The transfer section opens with "What transfers from this study is the
    calculation, not its numbers". It lists the routine field inputs alongside
    the conditions for applying the calculation elsewhere.

## Checks

- `just publication` passes: 0 unknown citation keys, and both build checks
  pass. The main PDF is now 15 pages and the supplement 15. Table 2 and Figs 1–3
  were inspected in the PDF.
- Tests: 381 passed, 0 failed, 1 existing skip.
- Every new number was checked against its source CSV in this session.
