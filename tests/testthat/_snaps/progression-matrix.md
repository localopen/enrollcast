# ratios must be a data frame or subclass

    Code
      progression_matrix(as.list(ratios))
    Condition
      Error in `progression_matrix()`:
      ! `ratios` must be a data frame.
      x You supplied a list.

# progression_matrix errors on a missing feeding ratio

    Code
      progression_matrix(r, grade_order = c("K", "1", "2"))
    Condition
      Error in `progression_matrix()`:
      ! Every non-entry grade must be fed by a progression ratio.
      x Missing ratio feeding grade: 2.
      i Add row to `ratios` with grade_to set to this grade.

# progression_matrix errors with fewer than two grades

    Code
      progression_matrix(fixture_ratios(), grade_order = "K")
    Condition
      Error in `progression_matrix()`:
      ! A projection matrix needs at least 2 grades.
      x Found 1 grade.
      i Supply a longer series via `ratios` or `grade_order`.

# progression_matrix errors when ratios reference an unknown grade

    Code
      progression_matrix(fixture_ratios(), grade_order = c("K", "1"))
    Condition
      Error in `progression_matrix()`:
      ! `ratios` references grade not in `grade_order`.
      x Unknown grade: 2.
      i Known grades: K and 1.

# progression_matrix errors on ambiguous entry grade

    Code
      progression_matrix(r)
    Condition
      Error in `progression_matrix()`:
      ! Could not determine a unique entry grade from `ratios`.
      i Pass `grade_order` explicitly.

# progression_matrix errors on duplicate feeding ratios

    Code
      progression_matrix(r, grade_order = c("K", "1", "2"))
    Condition
      Error in `progression_matrix()`:
      ! Each grade in `ratios` may be fed by only one progression ratio.
      x Grade fed more than once: 1.
      i Check grade_to in `ratios` for duplicate rows.

# duplicate feeders are reported when grade_order is omitted

    Code
      progression_matrix(r)
    Condition
      Error in `progression_matrix()`:
      ! Each grade in `ratios` may be fed by only one progression ratio.
      x Grade fed more than once: 1.
      i Check grade_to in `ratios` for duplicate rows.

# progression_matrix validates explicit grade_order

    Code
      progression_matrix(fixture_ratios(), grade_order = c("K", "1", "2", NA))
    Condition
      Error in `progression_matrix()`:
      ! `grade_order` must not contain missing values.
      x Found 1 missing value.

---

    Code
      progression_matrix(fixture_ratios(), grade_order = c("K", "1", "2", "2"))
    Condition
      Error in `progression_matrix()`:
      ! `grade_order` must not contain duplicate grades.
      x Duplicated grade: 2.

# missing grade labels are rejected on the inferred path

    Code
      progression_matrix(r)
    Condition
      Error in `progression_matrix()`:
      ! grade_from and grade_to in `ratios` must not be missing.
      x Found 1 missing grade label.

# progression_matrix rejects a non-numeric ratio column

    Code
      progression_matrix(r)
    Condition
      Error in `progression_matrix()`:
      ! The ratio column of `ratios` must be numeric.
      x ratio is <character>.

# an all-NA (logical) ratio column is rejected as non-numeric

    Code
      progression_matrix(r)
    Condition
      Error in `progression_matrix()`:
      ! The ratio column of `ratios` must be numeric.
      x ratio is <logical>.

# progression_matrix rejects negative ratios

    Code
      progression_matrix(r)
    Condition
      Error in `progression_matrix()`:
      ! The ratio column of `ratios` must be non-negative.
      x Found 1 negative value.

# progression_matrix rejects an infinite ratio

    Code
      progression_matrix(r)
    Condition
      Error in `progression_matrix()`:
      ! The ratio column of `ratios` must be finite.
      x Found 1 infinite value.
      i An infinite ratio comes from a zero-enrollment feeder grade; drop or adjust it before building the matrix.

# progression_matrix warns on NA ratios and keeps them in the matrix

    Code
      invisible(progression_matrix(r))
    Condition
      Warning:
      1 ratio in `ratios` is NA or NaN.
      ! Grade fed by this ratio will project as NA.

# progression_matrix rejects a transition feeding the entry grade

    Code
      progression_matrix(r, grade_order = c("K", "1", "2"))
    Condition
      Error in `progression_matrix()`:
      ! Each ratio in `ratios` must feed the next grade up in `grade_order`.
      x Non-adjacent transition: "2 -> K".
      i Grade order: K, 1, and 2.

# progression_matrix rejects skipped and backward transitions

    Code
      progression_matrix(r, grade_order = c("K", "1", "2"))
    Condition
      Error in `progression_matrix()`:
      ! Each ratio in `ratios` must feed the next grade up in `grade_order`.
      x Non-adjacent transitions: "K -> 2" and "2 -> 1".
      i Grade order: K, 1, and 2.

# branching transitions are rejected with explicit grade_order

    Code
      progression_matrix(r, grade_order = c("K", "1", "2"))
    Condition
      Error in `progression_matrix()`:
      ! Each ratio in `ratios` must feed the next grade up in `grade_order`.
      x Non-adjacent transition: "K -> 2".
      i Grade order: K, 1, and 2.

# chain_order reports branching transitions

    Code
      chain_order(from, to)
    Condition
      Error:
      ! A grade feeds more than one grade in `ratios` (branching transitions).
      i Pass `grade_order` explicitly.

# chain_order reports cyclic transitions

    Code
      chain_order(from, to)
    Condition
      Error:
      ! Cycle detected in grade transitions in `ratios`.
      i Pass `grade_order` explicitly.

