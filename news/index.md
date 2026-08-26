# Changelog

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
