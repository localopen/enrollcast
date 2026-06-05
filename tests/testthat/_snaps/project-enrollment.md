# omitting entry warns

    Code
      invisible(project_enrollment(proj_base(), proj_ratios(), horizon = 2))
    Condition
      Warning:
      `entry` not supplied; holding entry grade 'K' constant at 120.

# entry length must equal horizon

    Code
      project_enrollment(proj_base(), proj_ratios(), horizon = 3, entry = c(130, 140))
    Condition
      Error:
      ! `entry` length (2) must equal `horizon` (3).

# horizon must be a positive integer

    Code
      project_enrollment(proj_base(), proj_ratios(), horizon = 0, entry = 1)
    Condition
      Error:
      ! `horizon` must be a single positive integer.

---

    Code
      project_enrollment(proj_base(), proj_ratios(), horizon = 1.5, entry = 1)
    Condition
      Error:
      ! `horizon` must be a single positive integer.

