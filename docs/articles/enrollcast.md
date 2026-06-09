# Projecting enrollment with enrollcast

``` r

library(enrollcast)
```

## The grade progression ratio method

The cohort survival / grade progression ratio method projects enrollment
by asking: of the students in grade *g* this year, how many appear in
grade *g+1* next year? That ratio captures net retention, migration, and
repetition. `enrollcast` estimates these ratios from history and applies
them forward with a Leslie matrix.

## A small district

``` r

history <- data.frame(
  year = rep(2021:2023, each = 3),
  grade = factor(rep(c("K", "1", "2"), 3), levels = c("K", "1", "2")),
  enrollment = c(100, 90, 80, 110, 95, 88, 120, 99, 91)
)
history
#>   year grade enrollment
#> 1 2021     K        100
#> 2 2021     1         90
#> 3 2021     2         80
#> 4 2022     K        110
#> 5 2022     1         95
#> 6 2022     2         88
#> 7 2023     K        120
#> 8 2023     1         99
#> 9 2023     2         91
```

## Step 1: progression ratios

``` r

ratios <- progression_ratios(history, method = "mean")
ratios
#>   grade_from grade_to     ratio
#> 1          K        1 0.9250000
#> 2          1        2 0.9678363
```

The ratios sit on the sub-diagonal of the Leslie matrix; the entry-grade
row is zero because entry is supplied exogenously.

``` r

leslie_matrix(ratios)
#>       K         1 2
#> K 0.000 0.0000000 0
#> 1 0.925 0.0000000 0
#> 2 0.000 0.9678363 0
```

## Step 2: project forward

The entry grade (kindergarten here) has no feeder grade, so you supply
its future values — for example from a birth-cohort or housing model.

``` r

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

## Stitching history and projection

[`project_enrollment()`](../reference/project_enrollment.md) returns
projected years only. Combine with history for plotting:

``` r

observed <- data.frame(
  year = history$year,
  grade = as.character(history$grade),
  enrollment = history$enrollment
)
combined <- rbind(observed, projection)
head(combined)
#>   year grade enrollment
#> 1 2021     K        100
#> 2 2021     1         90
#> 3 2021     2         80
#> 4 2022     K        110
#> 5 2022     1         95
#> 6 2022     2         88
```
