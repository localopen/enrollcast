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
      ! Each `schedule` step matrix must have identical row and column dimnames.
      x This matrix has no row names.

# check_step rejects a matrix with mismatched row and col names

    Code
      check_step(list(matrix = m))
    Condition
      Error:
      ! Each `schedule` step matrix must have identical row and column dimnames.
      x Row names "K" and "1" do not match column names "K" and "2".

# check_step rejects an invalid step entry

    Code
      check_step(list(matrix = m, entry = c(1, 2)))
    Condition
      Error:
      ! Each `schedule` step entry must be `NULL` or a single number.
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

