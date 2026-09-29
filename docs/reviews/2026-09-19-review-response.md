# Response to the independent Astra review

19 September 2026. Implements Barry's authorised bounded revision. The original
review remains unchanged in `2026-09-18-astra-adversarial-review.md`.

| Finding | Response and present status |
|---|---|
| Major 1: unobserved Ansmann profile and season-blind support | Corrected with the uniform rule fixed in `../profile_support_revision_plan.md`: observed joint region/season cell, observed workload pair nearest its medians. Support matches all four categorical variables. Table S5 gives actual values, counts and workload ranges. All affected predictions were rederived from sealed fits. |
| Major 2: field protocol incomplete | Remains an author-information requirement. `../field_methods_author_questions.md` consolidates the missing facts. The draft retains an explicit prompt; no hardware, dates, allocation or failure criteria were invented. Service-date reconstruction remains outside scope. |
| Major 3: management claim exceeds endpoint/predictor identification | Abstract, Methods, Results, tables, effort discussion and conclusions now describe conditional scenario calculations under last-image-as-failure and retrospective workloads. The paper does not claim prospective purchasing validation or measured physical inactivity. |
| Minor 1: SW camera-dependence overstatement | Supplement states that six no-region independent-row families were tested; camera models were not evaluated in SW. |
| Minor 2: unsafe checkpoint reuse | Signature checks run before writes/fit reuse, covering data/design, configuration, Stan source and fit-defining R function bodies/formals. Legacy unsigned archives are refused as resume targets; saved-fit derivation remains read-only. |
| Presentation: Cox code labels | Regenerated the figure from saved robust estimates with readable brand, flash, season and workload labels. |

## Consequence for the scientific message

The corrected Procell white-flash scenario is Central/winter and its joint-cell
follow-up ends at 117 days. Its 120-day numerical extrapolation is retained in
the machine-readable archive but withheld from main Table 2 and Table S4. At
90 days it has 22 intervals from 22 cameras at risk. The supported 120-day
comparison is therefore among lithium scenarios: expected-loss thresholds span
1.37–1.65 illustrative units per lost camera-day. Across all cheaper scenarios
at 90 days they span 2.31–9.91. These are conditional comparisons, not causal
brand contrasts. The narrower scope is a result of correcting support, not of
choosing a profile to preserve a desired finding.

Among 20 of 64 camera-versus-independent comparisons passing joint support and
finite-follow-up criteria, the largest median shift is 1.667 days. The family
contrast reaches 8.281 days in the small Energizer infrared stratum. Unsupported
roots remain explicitly diagnostic, including Varta white at ratio 100 beyond
its selected cell's follow-up. Fitted coefficients, raw data and the SW finding
are unchanged.

## Independent correction checks

A separate methodological agent independently reconstructed all eight selected
profiles and their metadata, checked joint/regional/pooled support counts, and
recomputed all 16 cost thresholds and paired uncertainty from saved posterior
draws. It also checked all 128 conditional-decision summaries against the
128,000 saved roots. No numerical discrepancies remained beyond CSV precision.
Its implementation audit prompted two further fixes: exact-minimum workload
selection, and a destination guard preventing derivations from writing inside
or over sealed archives (including symlink aliases). Legacy support API aliases
remain documented regional/pooled fields; the current manuscript consumes
explicit `profile_*` fields and the new diagnostic exports label pooled context.

The final runtime, source hashes, archive-preservation check, tests and rendered
proof verification are recorded in `../log/2026-09-19.md`. This closes the bounded
technical revision. Barry's field-methods input and substantive editing remain
necessary before a co-author circulation build is described as complete.
