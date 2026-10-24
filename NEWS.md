# enrollcast 0.2.0

* `swing_schedule()` now moves classes up and adds a new entry class every
  year, including swing and recovery years (#8). Swing years are rescaled to
  the base total and recovery years to the totals you supply, and the rescaled
  grades are the ones that move up the next year. After recovery nothing is
  rescaled: the projection continues from the recovered grades with the
  supplied entry values.
* Breaking: `swing_schedule()`'s `recovery` now takes annual school totals
  instead of multipliers, grade-specific recovery matrices are no longer
  accepted, and `entry` must cover the whole horizon. The vignette shows how to
  convert older calls.
* `swing_schedule()`'s `ratios` can be a list with one ratios table or
  projection matrix per year, for ratios that change or grades that open later.
* Schedule steps accept an optional `total` that rescales that year's grades;
  `"base"` means the base-year total. The rescaled grades carry into the next
  step.

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
