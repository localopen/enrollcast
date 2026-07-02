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

# projection_matrix reports duplicate feeders when grade_order is omitted

    Code
      projection_matrix(r)
    Condition
      Error in `projection_matrix()`:
      ! Each grade in `ratios` may be fed by only one progression ratio.
      x Grade fed more than once: 1.
      i Check grade_to in `ratios` for duplicate rows.

# projection_matrix rejects a grade_order containing missing values

    Code
      projection_matrix(ratios_fixture(), grade_order = c("K", "1", "2", NA))
    Condition
      Error in `projection_matrix()`:
      ! `grade_order` must not contain missing values.
      x Found 1 missing value.

# projection_matrix rejects a grade_order containing duplicates

    Code
      projection_matrix(ratios_fixture(), grade_order = c("K", "1", "2", "2"))
    Condition
      Error in `projection_matrix()`:
      ! `grade_order` must not contain duplicate grades.
      x Duplicated grade: 2.

# projection_matrix rejects a non-numeric ratio column

    Code
      projection_matrix(r)
    Condition
      Error in `projection_matrix()`:
      ! The ratio column of `ratios` must be numeric.
      x ratio is <character>.

# projection_matrix rejects negative ratios

    Code
      projection_matrix(r)
    Condition
      Error in `projection_matrix()`:
      ! The ratio column of `ratios` must be non-negative.
      x Found 1 negative value.

# projection_matrix warns on NA ratios and keeps them in the matrix

    Code
      M <- projection_matrix(r)
    Condition
      Warning:
      1 ratio in `ratios` is NA or NaN.
      ! Grade fed by this ratio will project as NA.

# projection_matrix rejects a transition feeding the entry grade

    Code
      projection_matrix(r, grade_order = c("K", "1", "2"))
    Condition
      Error in `projection_matrix()`:
      ! Each ratio in `ratios` must feed the next grade up in `grade_order`.
      x Non-adjacent transition: "2 -> K".
      i Grade order: K, 1, and 2.

# projection_matrix rejects skipped and backward transitions

    Code
      projection_matrix(r, grade_order = c("K", "1", "2"))
    Condition
      Error in `projection_matrix()`:
      ! Each ratio in `ratios` must feed the next grade up in `grade_order`.
      x Non-adjacent transitions: "K -> 2" and "2 -> 1".
      i Grade order: K, 1, and 2.

# projection_matrix rejects branching transitions under an explicit grade_order

    Code
      projection_matrix(r, grade_order = c("K", "1", "2"))
    Condition
      Error in `projection_matrix()`:
      ! Each ratio in `ratios` must feed the next grade up in `grade_order`.
      x Non-adjacent transition: "K -> 2".
      i Grade order: K, 1, and 2.

# chain_order errors on ambiguous entry grade

    Code
      chain_order(c("K", "9"), c("1", "2"))
    Condition
      Error:
      ! Could not determine a unique entry grade from `ratios`.
      i Pass `grade_order` explicitly.

# chain_order errors on branching transitions

    Code
      chain_order(c("K", "K", "1"), c("1", "2", "2"))
    Condition
      Error:
      ! A grade feeds more than one grade in `ratios` (branching transitions).
      i Pass `grade_order` explicitly.

# chain_order errors on a cycle

    Code
      chain_order(c("Z", "a", "b"), c("a", "b", "a"))
    Condition
      Error:
      ! Cycle detected in grade transitions in `ratios`.
      i Pass `grade_order` explicitly.

