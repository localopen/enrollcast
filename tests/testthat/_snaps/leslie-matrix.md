# leslie_matrix errors on a missing feeding ratio

    Code
      leslie_matrix(r, grade_order = c("K", "1", "2"))
    Condition
      Error:
      ! Missing progression ratio(s) feeding grade(s): 2

# leslie_matrix errors on ambiguous entry grade

    Code
      leslie_matrix(r)
    Condition
      Error:
      ! Could not determine a unique entry grade from `ratios`; pass `grade_order` explicitly.

# leslie_matrix errors on duplicate feeding ratios

    Code
      leslie_matrix(r, grade_order = c("K", "1", "2"))
    Condition
      Error:
      ! `ratios` has more than one ratio feeding the same grade; each grade may be fed only once.

