# Project enrollment forward

Projects grade-level enrollment forward an arbitrary horizon using the
grade progression ratio method. Internally builds a projection matrix
from `ratios` and advances enrollment one year at a time (one
matrix-vector product per projected year), overwriting the entry grade
with the supplied exogenous value each year.

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
  vector (names are grades).

- ratios:

  A data frame of progression ratios from
  [`progression_ratios()`](progression_ratios.md). Optional when a
  `schedule` is supplied.

- horizon:

  Number of years to project (a positive integer).

- entry:

  Exogenous entry-grade enrollment for each projected year: a numeric
  vector of length `horizon`, or a data frame with an `enrollment` or
  `value` column. If `NULL`, the entry grade is held constant at its
  base value and a warning is issued.

- schedule:

  Optional prebuilt projection schedule: a list of per-year steps, each
  `list(matrix = <square projection matrix>, entry = <NULL or a single number>)`,
  as produced by [`swing_schedule()`](swing_schedule.md). When supplied,
  `ratios` and `entry` must be `NULL` and `horizon` defaults to the
  schedule length. Step matrices must share identical grade dimnames,
  which determine the grade order `base` is aligned to.

- start_year:

  Optional integer label for the base year; output years run from
  `start_year + 1`. If `NULL`, it is derived from a `year` column in
  `base` when present, otherwise output years are `1..horizon`.

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
