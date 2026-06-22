# Changelog

## enrollcast 0.0.0.9000

- Initial development version.
- [`progression_ratios()`](https://gitlab.com/localopen/enrollcast/reference/progression_ratios.md)
  computes grade progression ratios from historical grade-level
  enrollment, with configurable averaging (`mean`, `geometric`,
  `median`, `last`, `weighted`).
- [`projection_matrix()`](https://gitlab.com/localopen/enrollcast/reference/projection_matrix.md)
  assembles the projection matrix from progression ratios.
- [`project_enrollment()`](https://gitlab.com/localopen/enrollcast/reference/project_enrollment.md)
  projects enrollment forward an arbitrary horizon, taking the entry
  grade exogenously.
- [`project_enrollment()`](https://gitlab.com/localopen/enrollcast/reference/project_enrollment.md)
  accepts a prebuilt per-year `schedule` of projection steps as an
  alternative to the `ratios`/`horizon`/`entry` arguments.
- [`swing_schedule()`](https://gitlab.com/localopen/enrollcast/reference/swing_schedule.md)
  builds a swing/recovery projection schedule for a school passing
  through a temporary relocation.
