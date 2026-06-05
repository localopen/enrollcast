# non-numeric enrollment is rejected

    Code
      progression_ratios(fx)
    Condition
      Error:
      ! `enrollment` column must be numeric.

# missing columns are reported

    Code
      progression_ratios(data.frame(a = 1))
    Condition
      Error:
      ! `data` is missing required column(s): year, grade, enrollment

# non-consecutive years yield no transitions

    Code
      progression_ratios(fx)
    Condition
      Error:
      ! No consecutive year pairs found to form transitions.

# duplicate grade-year rows are rejected

    Code
      progression_ratios(fx)
    Condition
      Error:
      ! Duplicate (grade, year) rows in `data`.

# negative enrollment is rejected

    Code
      progression_ratios(fx)
    Condition
      Error:
      ! `enrollment` must be non-negative.

# fewer than two grades is rejected

    Code
      progression_ratios(fx)
    Condition
      Error:
      ! Need at least 2 grades to compute progression ratios.

# non-numeric year is rejected

    Code
      progression_ratios(fx)
    Condition
      Error:
      ! `year` must be numeric or coercible to numeric.

