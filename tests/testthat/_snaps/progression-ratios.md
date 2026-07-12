# column selectors are distinct non-missing character scalars

    Code
      progression_ratios(fx, year = "year", grade = "year")
    Condition
      Error in `progression_ratios()`:
      ! `year`, `grade`, and `enrollment` must be distinct non-missing character scalars.
      x Each argument must select exactly one different column in `data`.

# non-numeric enrollment is rejected

    Code
      progression_ratios(fx)
    Condition
      Error in `progression_ratios()`:
      ! The enrollment column of `data` must be numeric.
      x enrollment is <character>.

# missing columns are reported

    Code
      progression_ratios(data.frame(a = 1))
    Condition
      Error in `progression_ratios()`:
      ! `data` is missing required column: year, grade, and enrollment.

# non-consecutive years yield no transitions

    Code
      progression_ratios(fx)
    Condition
      Error in `progression_ratios()`:
      ! Cannot compute progression ratios without consecutive years.
      x `data` has no adjacent year pair.
      i Years present: 2021 and 2023.

# duplicate grade-year rows are rejected

    Code
      progression_ratios(fx)
    Condition
      Error in `progression_ratios()`:
      ! `data` must have one row per grade per year.
      x Found duplicate (grade, year) row.
      i Aggregate or de-duplicate before calling `progression_ratios()`.

# negative enrollment is rejected

    Code
      progression_ratios(fx)
    Condition
      Error in `progression_ratios()`:
      ! The enrollment column of `data` must be non-negative.
      x Found 1 negative value.

# non-finite historical enrollment is rejected but NA is allowed

    Code
      progression_ratios(fx)
    Condition
      Error in `progression_ratios()`:
      ! The enrollment column of `data` must contain finite values or NA.
      x Found 1 non-finite value.

# fewer than two grades is rejected

    Code
      progression_ratios(fx)
    Condition
      Error in `progression_ratios()`:
      ! `data` must contain at least 2 grades to compute progression ratios.
      x The grade column has 1 grade.

# all-missing grades are rejected as missing

    Code
      progression_ratios(fx)
    Condition
      Error in `progression_ratios()`:
      ! The grade column of `data` must not contain missing values.
      x Found 9 missing values.

# non-numeric year is rejected

    Code
      progression_ratios(fx)
    Condition
      Error in `progression_ratios()`:
      ! The year column of `data` must be coercible to finite integers.
      x Found 1 invalid value.

# years must coerce to finite integers

    Code
      progression_ratios(fx)
    Condition
      Error in `progression_ratios()`:
      ! The year column of `data` must be coercible to finite integers.
      x Found 1 invalid value.

# weights are accepted only by the weighted method

    Code
      progression_ratios(enrollcast_fixture(), method = "mean", weights = 1:2)
    Condition
      Error in `progression_ratios()`:
      ! `weights` may only be supplied for `method = "weighted"`.

# weighted method validates weight values

    Code
      progression_ratios(enrollcast_fixture(), method = "weighted", weights = c(1, -1))
    Condition
      Error in `progression_ratios()`:
      ! `weights` must be numeric, finite, non-missing, and non-negative.

# weighted method requires a positive weight sum

    Code
      progression_ratios(enrollcast_fixture(), method = "weighted", weights = c(0, 0))
    Condition
      Error in `progression_ratios()`:
      ! `weights` must have a positive sum.

# n_years must be a positive integer

    Code
      progression_ratios(enrollcast_fixture(), n_years = 0)
    Condition
      Error in `progression_ratios()`:
      ! `n_years` must be a single positive integer.
      x You supplied a number.

# zero feeder enrollment warns about non-finite ratios

    Code
      progression_ratios(fx)
    Condition
      Warning:
      1 progression ratio is infinite or NaN.
      ! A feeder grade had zero enrollment in at least one transition.
    Output
        grade_from grade_to     ratio
      1          K        1       Inf
      2          1        2 0.9678363

# progression_ratios errors on an unmatched (NA) grade

    Code
      progression_ratios(fx)
    Condition
      Error in `progression_ratios()`:
      ! The grade column of `data` must not contain missing values.
      x Found 1 missing value.

