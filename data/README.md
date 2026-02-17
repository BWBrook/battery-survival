# Data Directory

This directory stores tracked analysis inputs used by the reproducible pipeline.

## Primary input
1. `batt_life_aug22.csv`: baseline camera-trap battery survival dataset used in phase-1 analyses.

## Documentation
1. `data_dictionary.md`: schema definitions and derived variable contracts.

## Notes
1. If a new data release is added, document provenance and schema differences in `data_dictionary.md` and `docs/plan.md`.
2. Do not overwrite the baseline file in place; add a new dated file and update config explicitly.
