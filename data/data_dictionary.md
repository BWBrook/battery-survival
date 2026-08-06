# Data Dictionary: `batt_life_aug22.csv`

## Unit of Observation
One row represents a camera deployment interval evaluated when the camera was
serviced. The recorded duration has different observational meaning according
to the camera state at that service:

1. If `bok = 1`, the camera was operational and `rd` is the precisely observed
   interval duration, used as a right-censoring time.
2. If `bok = 0`, the camera was non-functioning and `rd` ends at its last
   recorded image, the last confirmed evidence of operation.

## Columns
1. `camera` (character): camera identifier.
2. `rd` (numeric/integer): recorded run duration in days. For an operational
   camera (`bok = 1`), this is the exact observed duration through service. For
   a non-functioning camera (`bok = 0`), this is days to the last recorded
   image and therefore time to last confirmed operation, not an exact failure
   time.
3. `bok` (integer/binary): camera power/operational status when serviced
   (`1` = operational; `0` = non-functioning because of dead batteries or an
   internal power error, typically low-battery-triggered).
4. `ti` (numeric/integer): total images captured in interval.
5. `fi` (numeric/integer): flash images captured in interval (subset of total images).
6. `ft` (character/factor): flash type code (`w`, `i`).
7. `bt` (character/factor): battery chemistry/type class (e.g., `alkaline`, `lithium`).
8. `bb` (character/factor): battery brand label.
9. `seas` (character/factor): season label for interval context.
10. `reg` (character/factor): region code (`ct`, `se`, `wt`, `nw`, `ne`, `sw`, `tb`).

## Derived Variables (pipeline)
1. `event = 1 - bok`: `0` denotes right censoring for a camera operational at
   service; `1` denotes a camera found non-functioning, assigned by the current
   analysis to its last-image `rd`.
2. `fi_pd = fi / rd`
3. `ti_pd = ti / rd`
4. `day_pd = pmax(ti - fi, 0) / rd`
5. `log_fi_pd = log1p(fi_pd)`
6. `log_ti_pd = log1p(ti_pd)`
7. `log_day_pd = log1p(day_pd)`

## Notes
1. The pipeline enforces schema and value checks before analysis.
2. Exclusions are applied from `config/exclusions.csv` and logged to QC outputs.
3. For `event = 1`, latent failure occurred no earlier than the last recorded
   image and no later than the subsequent service, but the analytical CSV does
   not contain the service-date upper bound. Last-image `rd` is therefore a
   conservative lower-bound proxy for latent failure time.
4. The current KM, Cox, AFT, and Bayesian models treat that proxy as the event
   time. Publication should describe the estimand as time to last confirmed
   operation under the observed deployment protocol.
5. No interval-censored refit or fixed-lag sensitivity is defined because the
   upper bound is unavailable and an assumed lag would be arbitrary.
6. Image-rate covariates are realized within-deployment workloads, not baseline
   covariates, and should not receive unqualified causal interpretations.
