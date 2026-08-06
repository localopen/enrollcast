# swing_schedule rejects an over-long swing+recovery

    Code
      swing_schedule(fixture_ratios(), horizon = 2, swing_years = 2, recovery = 1.1,
      entry = NULL)
    Condition
      Error in `swing_schedule()`:
      ! `swing_years` plus recovery length must not exceed `horizon`.
      x 2 + 1 > 2.

# swing_schedule needs entry for normal years

    Code
      swing_schedule(fixture_ratios(), horizon = 4, swing_years = 1, recovery = c(1.1,
        1.05), entry = NULL)
    Condition
      Error in `swing_schedule()`:
      ! `entry` is required for the 1 normal year after recovery.

# swing_years must be a non-negative integer

    Code
      swing_schedule(fixture_ratios(), horizon = 3, swing_years = -1, recovery = 1.1,
      entry = 130)
    Condition
      Error in `swing_schedule()`:
      ! `swing_years` must be a non-negative integer.

# recovery matrix must have one row per grade

    Code
      swing_schedule(fixture_ratios(), horizon = 2, swing_years = 1, recovery = matrix(
        c(1.1, 1.2), nrow = 2), entry = NULL)
    Condition
      Error in `swing_schedule()`:
      ! `recovery` matrix must have one row per grade.
      x Expected 3 rows but got 2.

# recovery must be numeric or a matrix

    Code
      swing_schedule(fixture_ratios(), horizon = 3, swing_years = 1, recovery = "oops",
      entry = 130)
    Condition
      Error in `swing_schedule()`:
      ! `recovery` must be a numeric vector or a grade-by-year matrix.
      x You supplied a string.

# recovery values must be finite non-missing and non-negative

    Code
      swing_schedule(fixture_ratios(), horizon = 3, swing_years = 0, recovery = c(1.1,
        Inf), entry = 130)
    Condition
      Error in `swing_schedule()`:
      ! `recovery` values must be numeric, finite, non-missing, and non-negative.

# named recovery grades must uniquely match projection grades

    Code
      swing_schedule(fixture_ratios(), horizon = 1, swing_years = 0, recovery = matrix(
        1.1, nrow = 3, dimnames = list(c("K", "K", "2"), NULL)))
    Condition
      Error in `swing_schedule()`:
      ! Named `recovery` matrix rows must be unique and exactly match the projection grades.

# entry must be empty when there are no normal years

    Code
      swing_schedule(fixture_ratios(), horizon = 3, swing_years = 1, recovery = c(1.1,
        1.05), entry = 130)
    Condition
      Error in `swing_schedule()`:
      ! `entry` must be empty when there are no normal (GPR) years.

