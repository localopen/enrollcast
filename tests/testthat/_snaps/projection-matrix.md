# projection_matrix errors on a missing feeding ratio

    Code
      projection_matrix(r, grade_order = c("K", "1", "2"))
    Condition
      Error:
      ! Missing progression ratio(s) feeding grade(s): 2

# projection_matrix errors with fewer than two grades

    Code
      projection_matrix(ratios_fixture(), grade_order = "K")
    Condition
      Error:
      ! Need at least 2 grades to build a projection matrix.

# projection_matrix errors when ratios reference an unknown grade

    Code
      projection_matrix(ratios_fixture(), grade_order = c("K", "1"))
    Condition
      Error:
      ! `ratios` references a grade not in `grade_order`.

# projection_matrix errors on ambiguous entry grade

    Code
      projection_matrix(r)
    Condition
      Error:
      ! Could not determine a unique entry grade from `ratios`; pass `grade_order` explicitly.

# projection_matrix errors on duplicate feeding ratios

    Code
      projection_matrix(r, grade_order = c("K", "1", "2"))
    Condition
      Error:
      ! `ratios` has more than one ratio feeding the same grade; each grade may be fed only once.

