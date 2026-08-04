# Project enrollment forward

Projects grade-level enrollment forward an arbitrary horizon using the
grade progression ratio method. Internally builds a projection matrix
from `ratios` and advances enrollment one year at a time (one
matrix-vector product per projected year), overwriting the entry grade
with the supplied exogenous value each year. `ratios` is optional when a
`schedule` is supplied.

## Usage

``` r
project_enrollment(
  base,
  ratios = NULL,
  horizon = NULL,
  entry = NULL,
  schedule = NULL,
  start_year = NULL
)
```

## Arguments

- base:

  Most recent observed enrollment: either a data frame with columns
  `grade` and `enrollment` (optionally `year`), or a named numeric
  vector. Grade values or vector names must be present and unique.
  Enrollment must be finite, non-missing, and non-negative.

- ratios:

  A data frame or data-frame subclass with columns `grade_from`,
  `grade_to`, and `ratio`, as returned by
  [`progression_ratios()`](https://github.com/localopen/enrollcast/reference/progression_ratios.md).
  `grade_from` and `grade_to` must not be missing. `ratio` must be
  numeric, non-negative, and finite; an infinite ratio (from a
  zero-enrollment feeder) is rejected, while `NA`/`NaN` ratios (e.g.
  from sparse history) are kept in the matrix with a warning.

- horizon:

  Number of years to project (a positive integer).

- entry:

  Exogenous entry-grade enrollment for each projected year: a numeric
  vector of length `horizon`, or a data frame with an `enrollment` or
  `value` column. Values must be finite, non-missing, and non-negative.
  If `NULL`, the entry grade is held constant at its base value and a
  warning is issued.

- schedule:

  Optional prebuilt projection schedule: a list of per-year steps, each
  `list(matrix = <square projection matrix>, entry = <NULL or a single number>)`,
  as produced by
  [`swing_schedule()`](https://github.com/localopen/enrollcast/reference/swing_schedule.md).
  When supplied, `ratios` and `entry` must be `NULL` and `horizon`
  defaults to the schedule length. Each matrix must be numeric and
  square; non-missing coefficients must be finite and non-negative.
  `NA`/`NaN` coefficients are preserved and trigger a warning. A missing
  coefficient can make its output row missing. If that missing
  enrollment remains after entry replacement, the next matrix
  multiplication spreads missingness to all grade results because zero
  times a missing value is still missing. A non-`NULL` entry value then
  restores only the entry grade. Matrix row and column names must be
  unique and identical in the same order; all steps must use the same
  names. A step's `entry` must be `NULL` or one finite, non-negative
  number.

- start_year:

  Optional integer label for the base year; output years run from
  `start_year + 1`. An explicit value and all resulting years must be
  within the R integer range. If `NULL`, the year is derived from
  `base$year` when present; that column must contain one unambiguous
  integer within the same range. With no year column, output years are
  `1..horizon`.

## Value

A long data frame with columns `year`, `grade`, and `enrollment`,
covering the projected years only.

## Examples

``` r
history <- data.frame(
  year = rep(2021:2023, each = 3),
  grade = factor(rep(c("K", "1", "2"), 3), levels = c("K", "1", "2")),
  enrollment = c(100, 90, 80, 110, 95, 88, 120, 99, 91)
)
ratios <- progression_ratios(history)
base <- subset(history, year == 2023, c("grade", "enrollment"))
project_enrollment(base, ratios,
  horizon = 3, entry = c(125, 130, 128),
  start_year = 2023
)
#>   year grade enrollment
#> 1 2024     K  125.00000
#> 2 2024     1  111.00000
#> 3 2024     2   95.81579
#> 4 2025     K  130.00000
#> 5 2025     1  115.62500
#> 6 2025     2  107.42982
#> 7 2026     K  128.00000
#> 8 2026     1  120.25000
#> 9 2026     2  111.90607
```
