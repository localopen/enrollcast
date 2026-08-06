# Changelog

## enrollcast 0.0.0.9000

- Initial development version.
- [`progression_ratios()`](https://localopen.github.io/enrollcast/reference/progression_ratios.md)
  validates column selectors, historical enrollment and years, warns
  about gaps across the complete history before `n_years` selects recent
  transitions, and supports mean, geometric, median, last, and strictly
  validated weighted summaries.
- [`project_enrollment()`](https://localopen.github.io/enrollcast/reference/project_enrollment.md)
  validates base and entry enrollment, year labels, and prebuilt
  schedules while projecting an arbitrary horizon. Missing schedule
  coefficients are preserved with an aggregate warning and can spread
  missingness through later matrix products; a supplied entry value
  restores only the entry grade.
- [`projection_matrix()`](https://localopen.github.io/enrollcast/reference/projection_matrix.md)
  validates ratio values, grade labels and order, and requires a data
  frame with one adjacent low-to-high transition per non-entry grade.
- [`swing_schedule()`](https://localopen.github.io/enrollcast/reference/swing_schedule.md)
  builds swing/recovery schedules with strictly validated entry and
  recovery values; named recovery rows are aligned by grade.
