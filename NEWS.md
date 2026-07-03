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
* `projection_matrix()` validates the `ratio` column: non-numeric columns and
  negative values now error, and `NA`/`NaN` ratios are kept in the matrix with a
  warning.
* `projection_matrix()` rejects a `grade_order` containing duplicates or missing
  values instead of silently building a malformed matrix.
* `projection_matrix()` requires every transition to feed the next grade up in
  the grade order, catching entry-feeding, self-loop, skipped, backward, and
  branching transitions supplied with an explicit `grade_order`.
* `projection_matrix()` reports a twice-fed grade as a duplicate feeder even
  when `grade_order` is omitted (previously misreported as a cycle).
* `projection_matrix()` rejects missing `grade_from`/`grade_to` labels instead
  of silently building a matrix with an `NA` grade dimname on the inferred
  grade-order path.
