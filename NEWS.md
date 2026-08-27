# enrollcast (development version)

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
