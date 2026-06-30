# check_columns errors on missing columns

    Code
      check_columns(df, c("a", "c"), "df")
    Condition
      Error:
      ! `df` is missing required column: c.

# resolve_grade_order errors when grade_order omits a grade

    Code
      resolve_grade_order(c("K", "1", "2"), grade_order = c("K", "1"))
    Condition
      Error:
      ! `grade_order` is missing grade: 2.

# resolve_grade_order warns when guessing character order

    Code
      resolve_grade_order(c("K", "1", "2"))
    Condition
      Warning:
      Grade order guessed by sorting labels alphabetically.
      i Pass `grade_order` or a factor `grade` to set it explicitly.
    Output
      [1] "1" "2" "K"

# resolve_grade_order warns when grade_order has grades absent from data

    Code
      res <- resolve_grade_order(c("K", "1", "2"), grade_order = c("K", "1", "2", "3"))
    Condition
      Warning:
      `grade_order` contains grade missing from data: 3.

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

# summarise_ratios weighted errors on length mismatch

    Code
      summarise_ratios(R, "weighted", weights = c(1, 2, 3))
    Condition
      Error:
      ! `weights` length must equal the number of transition years used.
      x `weights` has length 3.
      i There are 2 transition years.

# as_base_vector errors on missing grade

    Code
      as_base_vector(c(K = 120, `1` = 99), c("K", "1", "2"))
    Condition
      Error:
      ! `base` is missing enrollment for grade: 2.

# as_entry_vector errors on length mismatch

    Code
      as_entry_vector(c(130, 140), 3)
    Condition
      Error:
      ! `entry` length must equal `horizon`.
      x `entry` has length 2 but `horizon` is 3.

# as_base_vector warns on extra grades

    Code
      res <- as_base_vector(v, c("K", "1", "2"))
    Condition
      Warning:
      `base` contains grade not in `ratios` that will be ignored: 3.

# as_base_vector errors on negative enrollment

    Code
      as_base_vector(c(K = -1, `1` = 99, `2` = 91), c("K", "1", "2"))
    Condition
      Error:
      ! `base` enrollment must be non-negative.

# as_entry_vector errors on negative values

    Code
      as_entry_vector(c(130, -5), 2)
    Condition
      Error:
      ! `entry` values must be non-negative.

# summarise_ratios weighted errors when weights are missing

    Code
      summarise_ratios(R, "weighted")
    Condition
      Error:
      ! `weights` is required for `method = "weighted"`.

# as_base_vector errors on an invalid base type

    Code
      as_base_vector(c(1, 2, 3), c("K", "1", "2"))
    Condition
      Error:
      ! `base` must be a data frame (grade, enrollment) or a named numeric vector.
      x You supplied a double vector.

# as_entry_vector errors on a data frame without a value column

    Code
      as_entry_vector(data.frame(x = 1:2), 2)
    Condition
      Error:
      ! `entry` data frame must have an enrollment or value column.

# as_entry_vector errors on an unsupported entry type

    Code
      as_entry_vector("oops", 2)
    Condition
      Error:
      ! `entry` must be a numeric vector or a data frame with a value column.
      x You supplied a string.

# check_schedule rejects malformed schedules

    Code
      check_schedule(list())
    Condition
      Error:
      ! `schedule` must be a non-empty list of projection steps.

---

    Code
      check_schedule(list(list(entry = 1)))
    Condition
      Error:
      ! Each `schedule` step must be a list with a `matrix` element.

---

    Code
      check_schedule(list(list(matrix = m[, 1, drop = FALSE])))
    Condition
      Error:
      ! Each `schedule` step `matrix` must be square.

---

    Code
      check_schedule(list(list(matrix = bad)))
    Condition
      Error:
      ! Each `schedule` step `matrix` must have identical row and column dimnames.

---

    Code
      check_schedule(list(list(matrix = m), list(matrix = m2)))
    Condition
      Error:
      ! All `schedule` step matrices must share the same grade dimnames in the same order.

---

    Code
      check_schedule(list(list(matrix = m, entry = c(1, 2))))
    Condition
      Error:
      ! Each `schedule` step `entry` must be NULL or a single number.

