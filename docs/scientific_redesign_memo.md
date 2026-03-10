# Scientific Redesign Decision Memo

This memo records the highest-value redesign candidates that were intentionally not implemented in the current hardening pass.

## 1) Prediction Profile Construction

Current contract:
1. `build_prediction_profiles()` collapses each `bb`/`ft` group to modal categorical covariates and median continuous covariates.

Candidate redesign:
1. Replace mode/median profiles with either:
   - explicit reference scenarios curated in config, or
   - full empirical averaging over observed covariate rows.

Potential effect:
1. Changes economics outputs and service-interval recommendations.
2. May change manuscript interpretation because profile choice is a scientific assumption, not just presentation.

Approval required before implementation:
1. Decide whether economics should represent a “typical deployment”, a configured scenario library, or the empirical deployment mix.

## 2) AFT Survival Reconstruction

Current contract:
1. `predict_survival_from_aft()` reconstructs survival via dense quantile predictions and interpolation.

Candidate redesign:
1. Replace interpolation with direct analytic survival/CDF evaluation for supported AFT families where available.

Potential effect:
1. Can shift validation curves and economics estimates, especially in the tails.
2. Would need numerical comparison against current outputs and explicit sign-off on changed results.

Approval required before implementation:
1. Decide whether improved statistical fidelity is worth accepting changed numerical outputs and regenerated manuscript-linked artifacts.

## 3) Validation Aggregation Semantics

Current contract:
1. `predict_group_survival()` predicts row-wise, averages within `bb`/`ft`/horizon groups, and reports unsupported-row counts separately.

Candidate redesign:
1. Use calibration-style summaries, weighted aggregation, or scenario-level validation objects rather than row-average group predictions.

Potential effect:
1. Changes SW validation summary tables and how support gaps are interpreted.
2. May require manuscript changes to Methods/Results language.

Approval required before implementation:
1. Decide whether the validation objective is descriptive calibration, predictive scoring, or deployment decision support.
