# Data Dictionary: `batt_life_aug22.csv`

## Unit of Observation
One row represents a single camera deployment interval between service checks.

## Columns
1. `camera` (character): camera identifier.
2. `rd` (numeric/integer): run duration in days for the interval.
3. `bok` (integer/binary): battery status at end of interval (`1` = battery operational, `0` = battery failed).
4. `ti` (numeric/integer): total images captured in interval.
5. `fi` (numeric/integer): flash images captured in interval (subset of total images).
6. `ft` (character/factor): flash type code (`w`, `i`).
7. `bt` (character/factor): battery chemistry/type class (e.g., `alkaline`, `lithium`).
8. `bb` (character/factor): battery brand label.
9. `seas` (character/factor): season label for interval context.
10. `reg` (character/factor): region code (`ct`, `se`, `wt`, `nw`, `ne`, `sw`, `tb`).

## Derived Variables (pipeline)
1. `event = 1 - bok`
2. `fi_pd = fi / rd`
3. `ti_pd = ti / rd`
4. `day_pd = pmax(ti - fi, 0) / rd`
5. `log_fi_pd = log1p(fi_pd)`
6. `log_ti_pd = log1p(ti_pd)`
7. `log_day_pd = log1p(day_pd)`

## Notes
1. The pipeline enforces schema and value checks before analysis.
2. Exclusions are applied from `config/exclusions.csv` and logged to QC outputs.
