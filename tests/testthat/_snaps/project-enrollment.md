# omitting entry warns

    Code
      invisible(project_enrollment(proj_base(), proj_ratios(), horizon = 2))
    Condition
      Warning:
      `entry` not supplied.
      i Holding entry grade K constant at 120 for all 2 projected years.

# entry length must equal horizon

    Code
      project_enrollment(proj_base(), proj_ratios(), horizon = 3, entry = c(130, 140))
    Condition
      Error in `project_enrollment()`:
      ! `entry` length must equal `horizon`.
      x `entry` has length 2 but `horizon` is 3.

# horizon must be a positive integer

    Code
      project_enrollment(proj_base(), proj_ratios(), horizon = 0, entry = 1)
    Condition
      Error in `project_enrollment()`:
      ! `horizon` must be a single positive integer.
      x You supplied a number of length 1.

---

    Code
      project_enrollment(proj_base(), proj_ratios(), horizon = 1.5, entry = 1)
    Condition
      Error in `project_enrollment()`:
      ! `horizon` must be a single positive integer.
      x You supplied a number of length 1.

# base enrollment cannot contain NA

    Code
      project_enrollment(v, proj_ratios(), horizon = 1, entry = 130)
    Condition
      Error in `project_enrollment()`:
      ! `base` enrollment must be numeric, finite, and non-missing.

# start_year must be one finite integer

    Code
      project_enrollment(proj_base(), proj_ratios(), horizon = 1, entry = 130,
      start_year = 2023.5)
    Condition
      Error in `project_enrollment()`:
      ! `start_year` must be one finite integer.

# start_year must be within the R integer range

    Code
      project_enrollment(proj_base(), proj_ratios(), horizon = 1, entry = 130,
      start_year = .Machine$integer.max + 1)
    Condition
      Error in `project_enrollment()`:
      ! `start_year` must be within the R integer range.

---

    Code
      project_enrollment(base, proj_ratios(), horizon = 1, entry = 130)
    Condition
      Error in `project_enrollment()`:
      ! `base` year and `horizon` must produce years within the R integer range.

# invalid base years do not fall back to relative years

    Code
      project_enrollment(base, proj_ratios(), horizon = 1, entry = 130)
    Condition
      Error in `project_enrollment()`:
      ! `base` year must contain one finite integer value.

# schedule and ratios are mutually exclusive

    Code
      project_enrollment(proj_base(), ratios = proj_ratios(), schedule = sched)
    Condition
      Error in `project_enrollment()`:
      ! Supply either `ratios`/`entry` or `schedule`, not both.
      x You also supplied `ratios`.

# project_enrollment needs ratios or a schedule

    Code
      project_enrollment(proj_base(), horizon = 2)
    Condition
      Error in `project_enrollment()`:
      ! Supply `ratios` (or a `schedule`).
      i `ratios` comes from `progression_ratios()`.

# horizon must match schedule length when both are given

    Code
      project_enrollment(proj_base(), schedule = sched, horizon = 2)
    Condition
      Error in `project_enrollment()`:
      ! `horizon` must equal the `schedule` length.
      x `horizon` is 2 but `schedule` has 1 step.

# schedule matrices must contain valid numeric values

    Code
      project_enrollment(proj_base(), schedule = list(list(matrix = replace(valid, 1,
        Inf))))
    Condition
      Error in `project_enrollment()`:
      ! Each `schedule` step matrix must contain non-negative numeric values or NA/NaN, without infinite values.

# schedule matrices allow NA coefficients

    Code
      invisible(project_enrollment(proj_base(), schedule = schedule))
    Condition
      Warning:
      1 missing matrix coefficient was found in `schedule`.
      ! Affected step: 1.
      i Missing coefficients are preserved and may propagate into later grades and years.

# schedule matrices allow missing coefficients with one warning

    Code
      invisible(project_enrollment(proj_base(), schedule = schedule))
    Condition
      Warning:
      2 missing matrix coefficients were found in `schedule`.
      ! Affected steps: 1 and 2.
      i Missing coefficients are preserved and may propagate into later grades and years.

# check_step rejects a non-list step

    Code
      check_step("not a list")
    Condition
      Error:
      ! Each `schedule` step must be a <list> with a matrix element.
      x Got a string.

# check_step rejects a non-square matrix

    Code
      check_step(list(matrix = m[, 1, drop = FALSE]))
    Condition
      Error:
      ! Each `schedule` step matrix must be square.
      x This matrix is 3x1.

# check_step rejects a matrix with no row names

    Code
      check_step(list(matrix = m))
    Condition
      Error:
      ! Each `schedule` step matrix must have present, unique, identical row and column names in the same order.
      x This matrix is missing row or column names.

# check_step rejects a matrix with mismatched row and col names

    Code
      check_step(list(matrix = m))
    Condition
      Error:
      ! Each `schedule` step matrix must have present, unique, identical row and column names in the same order.
      x Row names "K" and "1" and column names "K" and "2" are invalid or do not match.

# check_step rejects an invalid step entry

    Code
      check_step(list(matrix = m, entry = c(1, 2)))
    Condition
      Error:
      ! Each `schedule` step entry must be `NULL` or one finite, non-negative number.
      x Got a double vector of length 2.

# check_schedule rejects a non-list schedule

    Code
      check_schedule(42)
    Condition
      Error:
      ! `schedule` must be a non-empty <list> of projection steps.
      x You supplied a number.

# check_schedule rejects an empty list

    Code
      check_schedule(list())
    Condition
      Error:
      ! `schedule` must be a non-empty <list> of projection steps.
      x You supplied an empty list.

# check_schedule rejects inconsistent grade dimnames

    Code
      check_schedule(sched)
    Condition
      Error:
      ! All `schedule` step matrices must share the same grade dimnames in the same order.
      i Step 1 grades: "K", "1", and "2".
      x Differing step: 2.

