# swing_schedule rejects an over-long swing+recovery

    Code
      swing_schedule(ss_ratios(), horizon = 2, swing_years = 2, recovery = c(1.1),
      entry = NULL)
    Condition
      Error:
      ! `swing_years` plus recovery length must not exceed `horizon`.

# swing_schedule needs entry for normal years

    Code
      swing_schedule(ss_ratios(), horizon = 4, swing_years = 1, recovery = c(1.1,
        1.05), entry = NULL)
    Condition
      Error:
      ! `entry` is required for the 1 normal year(s) after recovery.

# entry length must match the number of normal years

    Code
      swing_schedule(ss_ratios(), horizon = 5, swing_years = 1, recovery = c(1.1),
      entry = c(130, 140))
    Condition
      Error:
      ! `entry` length (2) must equal `horizon` (3).

# swing_years must be a non-negative integer

    Code
      swing_schedule(ss_ratios(), horizon = 3, swing_years = -1, recovery = c(1.1),
      entry = 130)
    Condition
      Error:
      ! `swing_years` must be a non-negative integer.

# recovery matrix must have one row per grade

    Code
      swing_schedule(ss_ratios(), horizon = 2, swing_years = 1, recovery = matrix(c(
        1.1, 1.2), nrow = 2), entry = NULL)
    Condition
      Error:
      ! `recovery` matrix must have one row per grade (3).

# recovery must be numeric or a matrix

    Code
      swing_schedule(ss_ratios(), horizon = 3, swing_years = 1, recovery = "oops",
      entry = 130)
    Condition
      Error:
      ! `recovery` must be a numeric vector or a grade-by-year matrix.

# entry must be empty when there are no normal years

    Code
      swing_schedule(ss_ratios(), horizon = 3, swing_years = 1, recovery = c(1.1,
        1.05), entry = 130)
    Condition
      Error:
      ! `entry` must be empty when there are no normal (GPR) years.

