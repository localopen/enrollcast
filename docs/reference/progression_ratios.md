# Compute grade progression ratios

Calculates cohort survival / grade progression ratios from historical
grade-level enrollment. For each non-entry grade, the ratio is
enrollment in that grade divided by enrollment in the grade below one
year earlier, summarised across the available year-to-year transitions.

## Usage

``` r
progression_ratios(
  data,
  year = "year",
  grade = "grade",
  enrollment = "enrollment",
  method = c("mean", "geometric", "median", "last", "weighted"),
  n_years = NULL,
  weights = NULL,
  grade_order = NULL
)
```

## Arguments

- data:

  A long data frame of historical enrollment with one row per grade per
  year.

- year, grade, enrollment:

  Column names in `data` (character scalars). Defaults are `"year"`,
  `"grade"`, `"enrollment"`.

- method:

  How to summarise per-year ratios into one ratio per grade: `"mean"`
  (default), `"geometric"`, `"median"`, `"last"` (most recent transition
  only), or `"weighted"`.

- n_years:

  Optional. Use only the most recent `n_years` transitions. If `n_years`
  exceeds the number of available transitions, all are used.

- weights:

  For `method = "weighted"`, a numeric vector aligned most-recent to
  oldest, with one weight per transition year used.

- grade_order:

  Optional character vector giving the low-to-high grade order. If
  omitted, factor levels, numeric ordering, or (with a warning)
  alphabetical ordering is used.

## Value

A data frame with columns `grade_from`, `grade_to`, and `ratio`, one row
per non-entry grade.

## Examples

``` r
history <- data.frame(
  year = rep(2021:2023, each = 3),
  grade = factor(rep(c("K", "1", "2"), 3), levels = c("K", "1", "2")),
  enrollment = c(100, 90, 80, 110, 95, 88, 120, 99, 91)
)
progression_ratios(history)
#>   grade_from grade_to     ratio
#> 1          K        1 0.9250000
#> 2          1        2 0.9678363
```
