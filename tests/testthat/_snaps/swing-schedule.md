# swing_schedule rejects an over-long swing+recovery

    Code
      swing_schedule(fixture_ratios(), horizon = 2, swing_years = 2, recovery = 350,
      entry = c(130, 140))
    Condition
      Error in `swing_schedule()`:
      ! `swing_years` plus recovery length must not exceed `horizon`.
      x 2 + 1 > 2.

# entry is required even without post-recovery years

    Code
      swing_schedule(fixture_ratios(), horizon = 2, swing_years = 1, recovery = 350)
    Condition
      Error in `swing_schedule()`:
      ! `entry` is required for all 2 projected years.

# entry length includes swing and recovery years

    Code
      swing_schedule(fixture_ratios(), horizon = 3, swing_years = 1, recovery = 350,
      entry = 130)
    Condition
      Error in `swing_schedule()`:
      ! `entry` length must equal `horizon`.
      x `entry` has length 1 but `horizon` is 3.

# swing_years must be a non-negative integer

    Code
      swing_schedule(fixture_ratios(), horizon = 3, swing_years = -1, recovery = 350,
      entry = rep(130, 3))
    Condition
      Error in `swing_schedule()`:
      ! `swing_years` must be a non-negative integer.

# recovery must be a vector of target totals

    Code
      swing_schedule(fixture_ratios(), horizon = 3, swing_years = 1, recovery = "oops",
      entry = rep(130, 3))
    Condition
      Error in `swing_schedule()`:
      ! `recovery` must be a numeric vector of annual target totals.

# recovery totals must be finite non-missing and non-negative

    Code
      swing_schedule(fixture_ratios(), horizon = 3, swing_years = 0, recovery = c(350,
        Inf), entry = rep(130, 3))
    Condition
      Error in `swing_schedule()`:
      ! `recovery` totals must be finite, non-missing, and non-negative.

# per-year ratios require one valid table or matrix per year

    Code
      swing_schedule(list(fixture_ratios()), horizon = 2, swing_years = 0, recovery = 350,
      entry = c(130, 140))
    Condition
      Error in `swing_schedule()`:
      ! `ratios` must be a ratios table, a projection matrix, or a list of `horizon` tables or matrices.

# per-year matrices must share grade names and order

    Code
      swing_schedule(list(m, reordered), horizon = 2, swing_years = 0, recovery = 350,
      entry = c(130, 140))
    Condition
      Error in `swing_schedule()`:
      ! All `ratios` matrices must share the same grade dimnames in the same order.
      i Step 1 grades: "K", "1", and "2".
      x Differing step: 2.

---

    Code
      swing_schedule(reordered, horizon = 2, swing_years = 0, recovery = 350, entry = c(
        130, 140), grade_order = c("K", "1", "2"))
    Condition
      Error in `swing_schedule()`:
      ! Projection matrix dimnames must match `grade_order` in order.

---

    Code
      swing_schedule(matrix(1:6, nrow = 2), horizon = 2, swing_years = 0, recovery = 350,
      entry = c(130, 140))
    Condition
      Error in `swing_schedule()`:
      ! Each `ratios` matrix must be square.
      x This matrix is 2x3.

---

    Code
      swing_schedule(unname(m), horizon = 2, swing_years = 0, recovery = 350, entry = c(
        130, 140))
    Condition
      Error in `swing_schedule()`:
      ! Each `ratios` matrix must have present, unique, identical row and column names in the same order.
      x This matrix is missing row or column names.

---

    Code
      swing_schedule(m, horizon = 2, swing_years = 0, recovery = 350, entry = c(130,
        140))
    Condition
      Error in `swing_schedule()`:
      ! Each `ratios` matrix must contain non-negative numeric values or NA/NaN, without infinite values.

