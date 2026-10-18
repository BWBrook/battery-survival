# 18 October 2026 — final editorial integration

## Scope and disposition

Codex checked Claude's editorial candidate `ebfbea9` (Correspondence thread 91,
messages 2024–2025) after Barry returned the work. The question title remains
settled. The single-panel main lost-time figure, consistent brand colours,
explicit operating scenarios, quantitative abstract and supplementary two-family
comparison are retained. This pass changes prose and references only; it does
not refit the empirical models or change the sealed September evidence.

## Numerical checks

Direct recalculation from the full-precision saved CSVs confirms:

- Across the three supported cheaper lithium scenarios and both families,
  additional expected lost days increase 4.148–6.028-fold from 90 to 120 days.
  At 120 days the range is 2.494–11.696 additional days.
- Relaxing the expected-loss tolerance from 5% to 10% lengthens the interval by
  10.685–33.609 days across the ten scenario/family combinations.
- The supported 120-day break-even range is 1.36799–1.64542 units, or
  2.631–3.164% of the illustrative 52-unit Energizer set price.
- The largest nominal-to-active-effort inflation is 12.499995%, in the
  loglogistic Wallaby scenario (106.6667 expected active days of 120).
  The abstract now says "about 12%" rather than "up to 12%".

Inputs: `outputs/management/2026-09-19/break_even/break_even_estimates.csv`,
`effort_inflation_120.csv` in that directory, and
`outputs/management/2026-10-18/lost_day_curves/tolerance_intervals.csv`.
Detailed arithmetic is in
`outputs/publication/review-2026-10-18/round4-audit/editorial-number-check.json`.
The other abstract numbers retain the previous audit's supporting evidence.

## Endpoint direction: individual accounting versus fitted predictions

The two claims that assigning failure at the last image "tends to" overstate
fitted lost time and shorten tolerance intervals were not supported. For a
last image L no later than shutdown F, individual lost time at a fixed visit T
obeys `(T-L)+ >= (T-F)+`. The direction need not survive model fitting.

An independent audit found a reversal even in uncensored, fixed-shape Weibull
regression. Let x = (-1, 0, 1), with event times changed from (1, 1, 1) to
(1, 1, 4), and fix AFT scale to 1 (an exponential lifetime model). At observed
x = -1 the fitted mean decreases from 1 to 5/6. Expected lost time at T = 1
increases from 0.367879 to 0.417662; the 5% crossing decreases from 0.103479 to
0.086232. This is a mathematical counterexample, not an empirical estimate of
the project's endpoint bias. The parent reproduced it with `survival::survreg`;
script and output are in `round4-audit/endpoint_direction_counterexample.*`.

Methods now states the direct accounting effect. Discussion explains why it
does not establish the direction of error in fitted losses or tolerance
intervals. The previous gap sensitivity addressed fixed-interval costs and
cannot establish that the tolerance schedules are conservative. Its withheld
uncapped largest-gap Weibull setting remains explicit and unchanged.

## Integration and artifact checks

Removed the obsolete main Fig. 2a panel reference, pointed the supplement's
continuous paired differences to Fig. S5b, clarified the field-records sentence,
and updated the handover/README to five supplementary figures.

Final build and layout results follow.

The first full publication build returned exit zero, but a separate `qpdf`
check found a damaged main-PDF cross-reference table (status 3). The supplement
passed. Its saved manifest matched the damaged file, demonstrating that hashes
and the renderer's exit status alone did not detect this failure. The earlier
Claude PDF captured by the layout reviewer passed. No competing build was
running when the processes were inspected; the precise cause is unconfirmed.

A source rebuild in a fresh, dedicated LaTeX directory produced an intact main
PDF. The publication recipe now gives main and supplement separate compiler
workspaces under this repository's ignored output directory and requires
`qpdf --check` before either final manifest. This isolates the documents from
the shared Makedoc compiler directory and makes a structural PDF failure stop
the command. Generated PDFs were regenerated from source, not manually repaired.
The complete revised recipe passed end to end.


Final `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 just publication` passed, including
both 38-test Makedoc checks, zero unknown references, both new PDF integrity
checks, and Word formatting. Each publication PDF has 15 pages. All 14 source
and output SHA256 hashes match the build manifests; all 12 curve, 12 tolerance
and seven endpoint-input MD5 entries match their recorded files. The derivation
script again checked its 90/120-day means against the saved break-even outputs.
Logs and arithmetic are in the `round4-audit/` directory cited above.

No statistical implementation changed in this pass, so the R test suite was
not rerun: the most recent recorded result remains 381 passes and one existing
skip from Claude's preceding candidate. The fixed-shape regression counterexample
was run and checked independently in this pass. It is a small mathematical
probe, not a new analysis of the camera records.

At 20:17 AEDT the independent layout reviewer returned PASS with no material
issue. All 40 Word-render pages were covered by individual inspection or
byte-identical page images from inspected versions (main 21; supplement 19).
All 30 final publication-PDF pages received a contact-sheet layout scan; the
revised figure pages and added S5 were also individually inspected in this
round. Fig. 2/S5b references, mean bars and stars, table continuations and
withheld cells are preserved. Both final publication PDF copies independently
passed `qpdf`. Report:
`outputs/publication/review-2026-10-18/round4-docx-qa/final/qa-report.md`.
Word verification used LibreOffice; native Microsoft Word was not tested.

This candidate is ready for Barry's reading and the outstanding field-method
and author confirmations before circulation. No further generic editing round
or model fitting is required for this work package.
