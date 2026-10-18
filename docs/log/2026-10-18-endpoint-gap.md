# Last-image gap sensitivity: audited disposition, 18 October 2026

Claude introduced the assumed-gap analysis during the editorial exchange in
Correspondence thread 91 and reported Barry's permission for additional
analyses. This log records the subsequent numerical audit and bounded
verification. The initial 20-imputation note is preserved under
`outputs/publication/review-2026-10-18/round3-audit/claude-endpoint-gap-initial-note.md`;
its stronger interpretations are superseded here.

## Assumptions and estimand

Failed intervals receive independent exponential gaps at rates equal to their
recorded images per day divided by 1, 3 or 10. This is an assumed gap law, not
an identified conditional shutdown distribution or an estimated burst process.
Workloads, censoring and observed operating scenarios stay fixed. A paired
largest-gap variant caps shifted lifetimes at 366 days, an illustrative limit
rather than a bound on failed-camera service dates. No simulated extension
creates empirical follow-up; Procell at 120 days remains withheld.

Independent-row, brand-scale, region-adjusted Weibull and loglogistic fits
supply their own unshifted baseline. Pooling averages expected additional loss
before dividing the saving. Similar baseline ranges do not make these models
identical to the main camera-effect models; Weibull Ansmann differs by about
10% at 120 days. Imputation variation and Monte Carlo error are not posterior
or sampling uncertainty. Tolerance schedules were not reanalysed.

## Numerical qualification

The original 20-imputation run had up to 10.6% relative Monte Carlo SE among
supported 120-day thresholds. It is preserved in `pilot-20/`. Before expanding
to 200, the numerical criterion was set at at most 5% relative Monte Carlo SE
for every reported supported 120-day threshold. The first unchecked 200-run
output and the subsequent failed diagnostics are preserved separately.

The final run attempted all 1,602 fits (two unshifted and eight groups of 200).
Two uncapped largest-gap Weibull fits, imputations 63 and 121, failed after the
permitted iteration-limit retry. Targeted diagnosis of imputation 63 also
failed with two different starting points; no more optimiser tuning was used.
The **entire uncapped b10 / Weibull group is withheld**, including its 198
accepted fits. No selected successful subset enters a model-dependent summary.
The nine other groups (including two unshifted baselines) passed all fit checks.
The explicit status is `complete_with_withheld_groups`, not all-fit success.

All reported supported 120-day thresholds met the precision criterion:
maximum relative MCSE 0.889985% (Varta, Weibull, b3); maximum absolute MCSE
0.0189701. The corresponding table is in Supplement S8; the CSV retains full
precision and per-comparison MCSE. The final run takes about two minutes on one
CPU; tests exercise whole-group suppression and numerical-status reporting.

## Interpretation and retained evidence

At b10, the median assumed gap is 6.16 days, but the mean is 14.96 days and the
average within-imputation 99th percentile is 134.71 days. Maximum shifted
lifetimes range from 385.99 to 1857.59 days. Only 6.135 rows on average are
capped, yet the capped Weibull fits converge and the uncapped group does not.
The original claim that the cap changes almost nothing is withdrawn.

Daylight coefficients change sign in converged large-gap settings. Because
extensions depend on image rate while that rate stays a predictor, this is
sensitivity to the constructed perturbation. It cannot establish that endpoint
gaps caused the observed association, and it does not validate the new
expected-loss tolerance schedules. No blanket robustness claim is made.

Code: `R/endpoint_gap_sensitivity.R`,
`scripts/run_endpoint_gap_sensitivity.R`, and the corresponding test file.
Final outputs: `outputs/endpoint_gap/2026-10-18/`, with scenario-family and run
status CSVs, every fit attempt, labelled raw results, seven input/code MD5
hashes, session information, gap tails and Monte Carlo summaries. Failed-run
and targeted-start evidence is in `diagnostics-b10-63/`; unchecked output is
in `pilot-200-unchecked/`. Main fits, raw data and September archives are
unchanged. `just endpoint-gap` is separate from the publication build.
