# check_columns errors on missing columns

    Code
      check_columns(df, c("a", "c"), "df")
    Condition
      Error:
      ! `df` is missing required column(s): c

# resolve_grade_order errors when grade_order omits a grade

    Code
      resolve_grade_order(c("K", "1", "2"), grade_order = c("K", "1"))
    Condition
      Error:
      ! `grade_order` is missing grade(s): 2

# resolve_grade_order warns when guessing character order

    Code
      resolve_grade_order(c("K", "1", "2"))
    Condition
      Warning:
      Grade order guessed by sorting labels alphabetically; pass `grade_order` or a factor `grade` to set it explicitly.
    Output
      [1] "1" "2" "K"

# chain_order errors on ambiguous entry grade

    Code
      chain_order(c("K", "9"), c("1", "2"))
    Condition
      Error:
      ! Could not determine a unique entry grade from `ratios`; pass `grade_order` explicitly.

# summarise_ratios weighted errors on length mismatch

    Code
      summarise_ratios(R, "weighted", weights = c(1, 2, 3))
    Condition
      Error:
      ! `weights` length (3) must equal number of transition years used (2).

# as_base_vector errors on missing grade

    Code
      as_base_vector(c(K = 120, `1` = 99), c("K", "1", "2"))
    Condition
      Error:
      ! `base` is missing enrollment for grade(s): 2

# as_entry_vector errors on length mismatch

    Code
      as_entry_vector(c(130, 140), 3)
    Condition
      Error:
      ! `entry` length (2) must equal `horizon` (3).

