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

# n_years must be a positive integer

    Code
      progression_ratios(gpr_fixture(), n_years = 0)
    Condition
      Error:
      ! `n_years` must be a positive integer.

# zero feeder enrollment warns about non-finite ratios

    Code
      progression_ratios(fx)
    Condition
      Warning:
      Some progression ratios are infinite or NaN because a feeder grade had zero enrollment in at least one transition.
    Output
        grade_from grade_to     ratio
      1          K        1       Inf
      2          1        2 0.9678363

# progression_ratios errors on an unmatched (NA) grade

    Code
      progression_ratios(fx)
    Condition
      Warning:
      Grade order guessed by sorting labels alphabetically; pass `grade_order` or a factor `grade` to set it explicitly.
      Error:
      ! Some grades are not in the resolved grade order.

