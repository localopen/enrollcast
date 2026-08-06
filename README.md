
<!-- README.md is generated from README.Rmd. Please edit that file -->

# enrollcast

<!-- badges: start -->

[![Project Status: WIP – Initial development is in progress, but there
has not yet been a stable, usable release suitable for the
public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![name status
badge](https://rorylawless.r-universe.dev/badges/:name)](https://rorylawless.r-universe.dev/)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/localopen/enrollcast/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/localopen/enrollcast/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/localopen/enrollcast/graph/badge.svg)](https://app.codecov.io/gh/localopen/enrollcast)
<!-- badges: end -->

`enrollcast` projects school enrollment using the cohort survival /
grade progression ratio method, implemented as a matrix projection. It
works at any level of aggregation (school, district, LEA, city-wide) and
any number of grades, because it operates on a single grade-by-year
enrollment series.

## Installation

``` r
# install.packages("pak")
pak::pak("localopen/enrollcast")
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
#>   grade_from grade_to     ratio
#> 1          K        1 0.9250000
#> 2          1        2 0.9678363

# 2. Project forward. The entry grade (K) is supplied exogenously.
base <- history[history$year == 2023, c("grade", "enrollment")]
projection <- project_enrollment(
  base = base,
  ratios = ratios,
  horizon = 3,
  entry = c(125, 130, 128),
  start_year = 2023
)
projection
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

Inspect the underlying projection matrix at any time:

``` r
projection_matrix(ratios)
#>       K         1 2
#> K 0.000 0.0000000 0
#> 1 0.925 0.0000000 0
#> 2 0.000 0.9678363 0
```

### Multiple aggregation units

`enrollcast` projects one series per call. To project many schools or
LEAs, split and map:

``` r
# fmt: skip
school_history <- data.frame(
  school = rep(c("North", "South"), each = 9),
  year = rep(2021:2023, each = 3, times = 2),
  grade = factor(rep(c("K", "1", "2"), times = 6), levels = c("K", "1", "2")),
  enrollment = c(100, 90, 80, 110, 95, 88, 120, 99, 91, 120, 
                 110, 100, 130, 115, 108, 140, 119, 111)
)

projections <- lapply(
  split(school_history, school_history$school),
  function(df) {
    ratios <- progression_ratios(df)
    base <- df[df$year == max(df$year), c("year", "grade", "enrollment")]
    project_enrollment(base, ratios, horizon = 3, entry = rep(100, 3))
  }
)

projections$North
#>   year grade enrollment
#> 1 2024     K  100.00000
#> 2 2024     1  111.00000
#> 3 2024     2   95.81579
#> 4 2025     K  100.00000
#> 5 2025     1   92.50000
#> 6 2025     2  107.42982
#> 7 2026     K  100.00000
#> 8 2026     1   92.50000
#> 9 2026     2   89.52485
```
