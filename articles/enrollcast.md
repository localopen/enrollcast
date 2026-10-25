# Projecting enrollment with enrollcast

``` r

library(enrollcast)
```

## The grade progression ratio method

The grade progression ratio method, also called cohort survival,
projects enrollment from one question: of this year’s students in grade
*g*, how many will be in grade *g+1* next year? The answer, a ratio,
folds net retention, migration, and grade repetition into one number.
`enrollcast` estimates these ratios from past enrollment and applies
them with a matrix projection.

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

[`progression_ratios()`](https://localopen.github.io/enrollcast/reference/progression_ratios.md)
only uses pairs of consecutive calendar years. If the history has a gap,
it warns and uses the consecutive pairs on either side; it never builds
a transition across the missing years. A history with no consecutive
pair is an error. The gap check covers the whole history before
`n_years` picks the most recent transitions, so an old gap still warns
even if it falls outside the transitions you asked for.

Each ratio sits on the sub-diagonal of the projection matrix, where it
moves students from one grade into the next. The entry-grade row is zero
because you supply entry enrollment yourself.

``` r

progression_matrix(ratios)
#>       K         1 2
#> K 0.000 0.0000000 0
#> 1 0.925 0.0000000 0
#> 2 0.000 0.9678363 0
```

## Step 2: project forward

The entry grade (kindergarten here) has no grade below it, so you supply
its future values, for example from a birth-cohort or housing model.

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

## Combining history and projection

[`project_enrollment()`](https://localopen.github.io/enrollcast/reference/project_enrollment.md)
returns only the projected years. To plot history and projection
together, bind them:

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

## Modeling a school modernization swing

A school that moves to temporary space during a modernization (a
“swing”) usually loses students, then regains them after it moves back.
[`swing_schedule()`](https://localopen.github.io/enrollcast/reference/swing_schedule.md)
builds a year-by-year schedule for this. Every year, including swing and
recovery years, classes move up by the progression ratios and a new
entry class arrives. The grades are then rescaled to a school total: the
base-year total in swing years, and a target you supply in recovery
years.

``` r

depressed <- c(K = 80, `1` = 66, `2` = 60)
schedule <- swing_schedule(ratios,
  horizon = 6, swing_years = 2,
  recovery = c(225, 245, 260), entry = rep(90, 6)
)
recovered <- project_enrollment(depressed, schedule = schedule, start_year = 2023)
recovered
#>    year grade enrollment
#> 1  2024     K   81.35961
#> 2  2024     1   66.89568
#> 3  2024     2   57.74471
#> 4  2025     K   80.60810
#> 5  2025     1   67.40417
#> 6  2025     2   57.98773
#> 7  2026     K   88.12061
#> 8  2026     1   73.00547
#> 9  2026     2   63.87393
#> 10 2027     K   91.05215
#> 11 2027     1   82.46448
#> 12 2027     2   71.48336
#> 13 2028     K   92.11316
#> 14 2028     1   86.20077
#> 15 2028     2   81.68607
#> 16 2029     K   90.00000
#> 17 2029     1   85.20467
#> 18 2029     2   83.42823
tapply(recovered$enrollment, recovered$year, sum)
#>     2024     2025     2026     2027     2028     2029 
#> 206.0000 206.0000 225.0000 245.0000 260.0000 258.6329
```

The first two totals equal `sum(depressed)`, 206, and the next three are
the recovery targets 225, 245, and 260. In each of these years, every
grade is multiplied by the same factor, the target divided by the
projected total (`T[h] / sum(n[h])`), so the grades add up to the
target. Those rescaled grades are the students who move up the following
year. The entry class is rescaled too, so reported entry enrollment in
these years is the supplied value times that factor. A larger supplied
entry class still gives a larger reported one.

After the last target year, nothing is rescaled. The school carries on
from the recovered grades using the progression ratios and the supplied
`entry` values, which are reported as given. If the final target is far
from the level the ratios and entry values can sustain, later totals
drift toward that level. Recovery growth can also inflate a school’s own
ratios. In that case, pass `ratios` as a list and use ordinary ratios
for the years after recovery (see the next section).

### Changing ratios and opening grades

To vary ratios by year, pass a list of `horizon` ratios tables or
projection matrices. Every matrix must use the same grade names, in the
same order, for its rows and columns, including grades that haven’t
opened yet. A grade stays closed while its row is zero; give it its
progression ratio from the year it opens. An entry value of zero keeps
the entry grade closed. Targets are whole-school totals, so set each one
for the grades open that year.

``` r

m <- progression_matrix(ratios)
closed <- m
closed["2", ] <- 0
opening <- swing_schedule(
  ratios = list(closed, closed, m, m),
  horizon = 4, swing_years = 1,
  recovery = c(165, 235), entry = rep(90, 4)
)
project_enrollment(c(K = 80, `1` = 66, `2` = 0), schedule = opening)
#>    year grade enrollment
#> 1     1     K   80.12195
#> 2     1     1   65.87805
#> 3     1     2    0.00000
#> 4     2     K   90.48654
#> 5     2     1   74.51346
#> 6     2     2    0.00000
#> 7     3     K   86.03966
#> 8     3     1   80.01693
#> 9     3     2   68.94341
#> 10    4     K   90.00000
#> 11    4     1   79.58668
#> 12    4     2   77.44329
```

### Schedule targets and missing values

Each step in a schedule is `list(matrix = m, entry = value)`, plus an
optional `total` that rescales that year’s grades. `total = "base"` uses
the sum of the base-year grades, and a number sets the target directly.
The rescaled grades carry into the next step. A step without a `total`
isn’t rescaled. You can still build identity or diagonal steps by hand
and pass them to
[`project_enrollment()`](https://localopen.github.io/enrollcast/reference/project_enrollment.md).

Schedule matrices can contain `NA` or `NaN` coefficients.
[`project_enrollment()`](https://localopen.github.io/enrollcast/reference/project_enrollment.md)
keeps them and warns instead of filling them in. A missing coefficient
can make its grade missing in the output. If that grade is still missing
after the entry value is applied, the next year’s matrix multiplication
makes every grade missing, because zero times a missing value is still
missing. A non-`NULL` entry value then restores only the entry grade.

Rescaling needs a finite, positive projected total. A missing or
infinite total is an error, and so is a positive target when the
projection is zero. If both the projection and the target are zero, the
grades are left as they are. A zero target on a positive projection
empties the school that year, so a later target has only the entry
classes that arrive afterwards to rescale.

### Updating code written for enrollcast 0.1.0

In enrollcast 0.1.0,
[`swing_schedule()`](https://localopen.github.io/enrollcast/reference/swing_schedule.md)
froze the grade mix during swing and recovery years and took recovery
multipliers. To update an older call, supply `entry` values for the
whole `horizon` and replace the multipliers with annual totals.
Whole-school multipliers `multipliers` become the targets
`sum(depressed) * cumprod(multipliers)`. Grade-specific recovery
matrices are no longer accepted.
