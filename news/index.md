# Changelog

## enrollcast 0.2.0

CRAN release: 2026-10-24

- [`swing_schedule()`](https://localopen.github.io/enrollcast/reference/swing_schedule.md)
  now moves classes up and adds a new entry class every year, including
  swing and recovery years
  ([\#8](https://github.com/localopen/enrollcast/issues/8)). Swing years
  are rescaled to the base total and recovery years to the totals you
  supply, and the rescaled grades are the ones that move up the next
  year. After recovery nothing is rescaled: the projection continues
  from the recovered grades with the supplied entry values.
- Breaking:
  [`swing_schedule()`](https://localopen.github.io/enrollcast/reference/swing_schedule.md)’s
  `recovery` now takes annual school totals instead of multipliers,
  grade-specific recovery matrices are no longer accepted, and `entry`
  must cover the whole horizon. The vignette shows how to convert older
  calls.
- [`swing_schedule()`](https://localopen.github.io/enrollcast/reference/swing_schedule.md)’s
  `ratios` can be a list with one ratios table or projection matrix per
  year, for ratios that change or grades that open later.
- Schedule steps accept an optional `total` that rescales that year’s
  grades; `"base"` means the base-year total. The rescaled grades carry
  into the next step.

## enrollcast 0.1.0

CRAN release: 2026-08-26

- Initial CRAN release.
- [`progression_ratios()`](https://localopen.github.io/enrollcast/reference/progression_ratios.md)
  computes progression ratios from historical grade-level enrollment,
  with mean, geometric, median, last, and weighted summaries. It warns
  about calendar-year gaps across the complete supplied history before
  `n_years` selects the most recent transitions.
- [`progression_matrix()`](https://localopen.github.io/enrollcast/reference/progression_matrix.md)
  places ratios on the sub-diagonal of a square projection matrix,
  leaving the entry-grade row at zero.
- [`project_enrollment()`](https://localopen.github.io/enrollcast/reference/project_enrollment.md)
  advances a base enrollment vector over an arbitrary horizon, from
  either ratios or a prebuilt schedule, overwriting the exogenous entry
  grade each year. Missing schedule coefficients are preserved with an
  aggregate warning rather than imputed.
- [`swing_schedule()`](https://localopen.github.io/enrollcast/reference/swing_schedule.md)
  builds per-year schedules that hold enrollment flat during swing
  years, apply recovery multipliers, then resume normal projection.
