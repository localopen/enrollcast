# enrollcast 0.0.0.9000

* Initial development version.
* `progression_ratios()` validates column selectors, historical enrollment and
  years, and supports mean, geometric, median, last, and strictly validated
  weighted summaries.
* `project_enrollment()` validates base and entry enrollment, year labels, and
  prebuilt schedules while projecting an arbitrary horizon.
* `projection_matrix()` validates ratio values, grade labels and order, and
  requires one adjacent low-to-high transition per non-entry grade.
* `swing_schedule()` builds swing/recovery schedules with strictly validated
  entry and recovery values; named recovery rows are aligned by grade.
