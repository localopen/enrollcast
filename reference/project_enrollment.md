# Project enrollment forward

Projects grade-level enrollment forward any number of years with the
grade progression ratio method. It builds a projection matrix from
`ratios` and advances enrollment one year at a time (one matrix-vector
product per year), replacing the entry grade each year with the value
you supply. `ratios` is optional when you supply a `schedule`.

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
  [`progression_ratios()`](https://localopen.github.io/enrollcast/reference/progression_ratios.md).
  `grade_from` and `grade_to` must not be missing. `ratio` must be
  numeric, non-negative, and finite. An infinite ratio (from a feeder
  grade with zero enrollment) is an error. `NA`/`NaN` ratios, for
  example from sparse history, stay in the matrix with a warning.

- horizon:

  Number of years to project (a positive integer).

- entry:

  Exogenous entry-grade enrollment for each projected year: a numeric
  vector of length `horizon`, or a data frame with an `enrollment` or
  `value` column. Values must be finite, non-missing, and non-negative.
  If `NULL`, the entry grade stays at its base value, with a warning.

- schedule:

  Optional prebuilt projection schedule: a list of per-year steps, such
  as one produced by
  [`swing_schedule()`](https://localopen.github.io/enrollcast/reference/swing_schedule.md).
  See the Schedules section for what a step contains. When supplied,
  `ratios` and `entry` must be `NULL`, and `horizon` defaults to the
  number of steps.

- start_year:

  Optional integer label for the base year; output years start at
  `start_year + 1`. It and every resulting year must fit in R's integer
  range. If `NULL`, the year comes from `base$year` when present; that
  column must hold a single integer value in the same range. Without a
  year column, output years are `1` to `horizon`.

## Value

A long data frame with columns `year`, `grade`, and `enrollment`,
covering the projected years only.

## Schedules

Each step is
`list(matrix = <square projection matrix>, entry = <NULL or a single number>)`,
with an optional `total`. Each matrix must be numeric and square, and
its non-missing coefficients must be finite and non-negative. Row and
column names must be unique and identical, in the same order, and every
step must use the same names. A step's `entry` must be `NULL` or one
finite, non-negative number.

A step's `total` rescales that year's grades, entry grade included,
after the entry value is applied. It is either one finite, non-negative
school total or `"base"`, the sum of the base grades. The rescaled
grades are recorded and carried into the next step. Steps without a
`total` aren't rescaled, so the projection continues from the last
rescaled grades with the supplied `entry` values.

Rescaling needs a finite, positive projected total. A missing or
infinite projected total is an error, and so is a positive target on a
zero projection. If both the projection and the target are zero, the
grades are left as they are. A zero target empties that year, so a later
target has only the entry classes that arrive afterwards to rescale.

`NA`/`NaN` coefficients are kept, with a warning. A missing coefficient
can make its grade missing in the output. If that grade is still missing
after the entry value is applied, the next matrix multiplication makes
every grade missing, because zero times a missing value is still
missing. A non-`NULL` entry value then restores only the entry grade.

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
