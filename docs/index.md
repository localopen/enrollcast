# enrollcast

`enrollcast` projects school enrollment using the cohort survival /
grade progression ratio method, implemented as a matrix projection. It
works at any level of aggregation (school, district, LEA, city-wide) and
any number of grades, because it operates on a single grade-by-year
enrollment series.

## Installation

``` r

# install.packages("pak")
pak::pak("gitlab::localopen/enrollcast")
```

## Usage

``` r

library(enrollcast)

# Historical grade-level enrollment (long format).
history <- data.frame(
  year = rep(2021:2023, each = 3),
  grade = factor(rep(c("K", "1", "2"), 3), levels = c("K", "1", "2")),
  enrollment = c(100, 90, 80, 110, 95, 88, 120, 99, 91)
)

# 1. Calculate progression ratios.
ratios <- progression_ratios(history, method = "mean")
ratios

# 2. Project forward. The entry grade (K) is supplied exogenously.
base <- history[history$year == 2023, c("grade", "enrollment")]
projection <- project_enrollment(
  base       = base,
  ratios     = ratios,
  horizon    = 3,
  entry      = c(125, 130, 128),
  start_year = 2023
)
projection
```

Inspect the underlying projection matrix at any time:

``` r

projection_matrix(ratios)
```

### Multiple aggregation units

`enrollcast` projects one series per call. To project many schools or
LEAs, split and map:

``` r

projections <- lapply(split(history, history$school), function(df) {
  ratios <- progression_ratios(df)
  base <- df[df$year == max(df$year), c("grade", "enrollment")]
  project_enrollment(base, ratios, horizon = 3, entry = rep(100, 3))
})
```
