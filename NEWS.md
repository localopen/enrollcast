# gpr (development version)

* Initial development version.
* `progression_ratios()` computes grade progression ratios from historical
  grade-level enrollment, with configurable averaging (`mean`, `geometric`,
  `median`, `last`, `weighted`).
* `leslie_matrix()` assembles the Leslie projection matrix from progression
  ratios.
* `project_enrollment()` projects enrollment forward an arbitrary horizon,
  taking the entry grade exogenously.
