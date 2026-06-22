# enrollcast 0.0.0.9000

* Initial development version.
* `progression_ratios()` computes grade progression ratios from historical
  grade-level enrollment, with configurable averaging (`mean`, `geometric`,
  `median`, `last`, `weighted`).
* `projection_matrix()` assembles the projection matrix from
  progression ratios.
* `project_enrollment()` projects enrollment forward an arbitrary horizon,
  taking the entry grade exogenously.
* `project_enrollment()` accepts a prebuilt per-year `schedule` of projection
  steps as an alternative to the `ratios`/`horizon`/`entry` arguments.
* `swing_schedule()` builds a swing/recovery projection schedule for a school
  passing through a temporary relocation.
