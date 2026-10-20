# enrollcast (development version)

* `swing_schedule()` now advances cohorts and takes new entry classes in every
  year, rescaling output to the base total during swing and explicit annual
  target totals during recovery (#8). The final target-year adjustment keeps
  applying after recovery, including to new entry classes. Recovery totals
  replace multipliers; `entry` must now cover the full horizon. Per-year ratios
  tables or projection matrices support changing ratios and grades opening later.
* Projection schedule steps accept an optional `total` for output rescaling,
  with `"base"` referring to the aligned base total. Rescaling leaves the
  underlying cohort projection unadjusted.

# enrollcast 0.1.0

* Initial CRAN release.
* `progression_ratios()` computes progression ratios from historical
  grade-level enrollment, with mean, geometric, median, last, and weighted
  summaries. It warns about calendar-year gaps across the complete supplied
  history before `n_years` selects the most recent transitions.
* `progression_matrix()` places ratios on the sub-diagonal of a square
  projection matrix, leaving the entry-grade row at zero.
* `project_enrollment()` advances a base enrollment vector over an arbitrary
  horizon, from either ratios or a prebuilt schedule, overwriting the exogenous
  entry grade each year. Missing schedule coefficients are preserved with an
  aggregate warning rather than imputed.
* `swing_schedule()` builds per-year schedules that hold enrollment flat during
  swing years, apply recovery multipliers, then resume normal projection.
