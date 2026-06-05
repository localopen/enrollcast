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

