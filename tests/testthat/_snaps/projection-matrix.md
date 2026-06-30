# projection_matrix errors on a missing feeding ratio

    Code
      projection_matrix(r, grade_order = c("K", "1", "2"))
    Condition
      Error in `projection_matrix()`:
      ! Every non-entry grade must be fed by a progression ratio.
      x Missing ratio feeding grade: 2.
      i Add row to `ratios` with grade_to set to this grade.

# projection_matrix errors with fewer than two grades

    Code
      projection_matrix(ratios_fixture(), grade_order = "K")
    Condition
      Error in `projection_matrix()`:
      ! A projection matrix needs at least 2 grades.
      x Found 1 grade.
      i Supply a longer series via `ratios` or `grade_order`.

# projection_matrix errors when ratios reference an unknown grade

    Code
      projection_matrix(ratios_fixture(), grade_order = c("K", "1"))
    Condition
      Error in `projection_matrix()`:
      ! `ratios` references grade not in `grade_order`.
      x Unknown grade: 2.
      i Known grades: K and 1.

# projection_matrix errors on ambiguous entry grade

    Code
      projection_matrix(r)
    Condition
      Error in `projection_matrix()`:
      ! Could not determine a unique entry grade from `ratios`.
      i Pass `grade_order` explicitly.

# projection_matrix errors on duplicate feeding ratios

    Code
      projection_matrix(r, grade_order = c("K", "1", "2"))
    Condition
      Error in `projection_matrix()`:
      ! Each grade in `ratios` may be fed by only one progression ratio.
      x Grade fed more than once: 1.
      i Check grade_to in `ratios` for duplicate rows.

