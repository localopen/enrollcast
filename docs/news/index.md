# Changelog

## enrollcast 0.0.0.9000

- Initial development version.
- [`progression_ratios()`](https://github.com/localopen/enrollcast/reference/progression_ratios.md)
  validates column selectors, historical enrollment and years, and
  supports mean, geometric, median, last, and strictly validated
  weighted summaries.
- [`project_enrollment()`](https://github.com/localopen/enrollcast/reference/project_enrollment.md)
  validates base and entry enrollment, year labels, and prebuilt
  schedules while projecting an arbitrary horizon.
- [`projection_matrix()`](https://github.com/localopen/enrollcast/reference/projection_matrix.md)
  validates ratio values, grade labels and order, and requires one
  adjacent low-to-high transition per non-entry grade.
- [`swing_schedule()`](https://github.com/localopen/enrollcast/reference/swing_schedule.md)
  builds swing/recovery schedules with strictly validated entry and
  recovery values; named recovery rows are aligned by grade.
