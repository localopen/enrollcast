# enrollcast (development version)

* `swing_schedule()` now advances cohorts and takes new entry classes in every
  year, rescaling to the base total during swing and explicit annual target
  totals during recovery (#8). The rescaled grades move up the next year, and
  nothing is adjusted after recovery: the projection continues from the
  recovered grades with the supplied entry classes. Recovery totals replace
  multipliers, and grade-specific recovery matrices are no longer accepted;
  `entry` must now cover the full horizon. Per-year ratios tables or projection
  matrices support changing ratios and grades opening later.
* Projection schedule steps accept an optional `total` that rescales that
  year's grades, with `"base"` referring to the aligned base total. The rescaled
  grades feed the next step.

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
