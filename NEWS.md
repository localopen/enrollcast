# enrollcast 0.1.0

* Missing-columns errors now pluralize correctly when multiple required columns
  are absent.
* Internal refactor with no user-facing changes: base R, `cli`, `rlang`, and
  `testthat` idioms replace hand-rolled equivalents. Apart from the separately
  listed missing-columns message correction, exported behavior, condition
  classes, and all other messages are unchanged.

# enrollcast 0.0.0.9000

* Initial development version.
* `projection_matrix()` is renamed to `progression_matrix()` (hard rename, no
  alias): the name completes the pipeline vocabulary alongside
  `progression_ratios()` and avoids a function-name collision with the risdr
  package.
* Internal refactor with no user-facing changes: conditions are raised through
  shared `ec_abort()`/`ec_warn()` helpers, validators are consolidated, and the
  `utils` package is no longer imported. All exported behavior, condition
  classes, and messages are unchanged.
* `progression_ratios()` validates column selectors, historical enrollment and
  years, warns about gaps across the complete history before `n_years` selects
  recent transitions, and supports mean, geometric, median, last, and strictly
  validated weighted summaries.
* `project_enrollment()` validates base and entry enrollment, year labels, and
  prebuilt schedules while projecting an arbitrary horizon. Missing schedule
  coefficients are preserved with an aggregate warning and can spread
  missingness through later matrix products; a supplied entry value restores
  only the entry grade.
* `progression_matrix()` validates ratio values, grade labels and order, and
  requires a data frame with one adjacent low-to-high transition per non-entry
  grade.
* `swing_schedule()` builds swing/recovery schedules with strictly validated
  entry and recovery values; named recovery rows are aligned by grade.
