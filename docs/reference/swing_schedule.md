# Build a swing/recovery projection schedule

Assembles a per-year [`project_enrollment()`](project_enrollment.md)
schedule for a school passing through a temporary relocation ("swing"):
enrollment is held flat at the depressed observed level during the swing
(identity steps), scaled by year-over-year recovery multipliers for the
recovery window (diagonal steps), then projected with the grade
progression ratio method (the normal projection matrix) for the
remaining years.

## Usage

``` r
swing_schedule(
  ratios,
  horizon,
  swing_years,
  recovery,
  entry = NULL,
  grade_order = NULL
)
```

## Arguments

- ratios:

  A data frame of progression ratios from
  [`progression_ratios()`](progression_ratios.md).

- horizon:

  Number of years to project (a positive integer).

- swing_years:

  Number of leading years the school is swinging (a non-negative
  integer); enrollment is held flat at `base`.

- recovery:

  Recovery multipliers applied for one year each, immediately after the
  swing and compounding on the prior year: a numeric vector
  (whole-school, one multiplier per recovery year) or a grade-by-year
  numeric matrix (one row per grade). Use `numeric(0)` for no recovery
  window.

- entry:

  Exogenous entry-grade enrollment for the normal (GPR) years only — the
  `horizon - swing_years - length(recovery)` years after recovery. Must
  be empty when there are no normal years.

- grade_order:

  Optional low-to-high grade order, passed to
  [`projection_matrix()`](projection_matrix.md).

## Value

A list of `horizon` projection steps suitable for the `schedule`
argument of [`project_enrollment()`](project_enrollment.md).

## Examples

``` r
ratios <- data.frame(
  grade_from = c("K", "1"), grade_to = c("1", "2"), ratio = c(0.92, 0.97)
)
schedule <- swing_schedule(ratios,
  horizon = 6, swing_years = 2,
  recovery = c(1.10, 1.10, 1.05), entry = 130
)
project_enrollment(c(K = 80, `1` = 66, `2` = 60), schedule = schedule)
#>    year grade enrollment
#> 1     1     K   80.00000
#> 2     1     1   66.00000
#> 3     1     2   60.00000
#> 4     2     K   80.00000
#> 5     2     1   66.00000
#> 6     2     2   60.00000
#> 7     3     K   88.00000
#> 8     3     1   72.60000
#> 9     3     2   66.00000
#> 10    4     K   96.80000
#> 11    4     1   79.86000
#> 12    4     2   72.60000
#> 13    5     K  101.64000
#> 14    5     1   83.85300
#> 15    5     2   76.23000
#> 16    6     K  130.00000
#> 17    6     1   93.50880
#> 18    6     2   81.33741
```
