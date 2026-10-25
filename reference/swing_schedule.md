# Build a swing/recovery projection schedule

Builds a per-year
[`project_enrollment()`](https://localopen.github.io/enrollcast/reference/project_enrollment.md)
schedule for a school that moves to temporary space ("swing") and then
recovers. Every year, classes move up by the grade progression ratios
and a new entry class arrives. The grades are then rescaled to the
base-year school total in swing years, and to the annual totals you
supply in recovery years.

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

  A ratios table as accepted by
  [`progression_matrix()`](https://localopen.github.io/enrollcast/reference/progression_matrix.md),
  a square projection matrix with grade dimnames, or a list of `horizon`
  such tables or matrices, one per projected year including swing and
  recovery years. All matrices must have identical grade dimnames in the
  same order, matching `grade_order` if supplied. To open a grade later,
  include it in every year's matrix and give it a zero row until it
  opens.

- horizon:

  Number of years to project (a positive integer).

- swing_years:

  Number of swing years at the start (a non-negative integer). In these
  years the school total stays at the total of the `base` passed to
  [`project_enrollment()`](https://localopen.github.io/enrollcast/reference/project_enrollment.md),
  while the grade mix progresses normally.

- recovery:

  Annual school target totals for the years right after the swing, one
  value per year. Values must be finite, non-missing, and non-negative.
  Use `numeric(0)` for no recovery years. These are totals, not
  year-over-year multipliers.

- entry:

  Required exogenous entry-grade enrollment for every projected year,
  including swing and recovery: a numeric vector of length `horizon`, or
  a data frame with an `enrollment` or `value` column. Values must be
  finite, non-missing, and non-negative. In swing and recovery years the
  entry grade is rescaled with the other grades, so reported entry
  enrollment is the supplied value times that year's rescaling factor. A
  larger entry class still gives a larger reported one. In later years
  the supplied values are used as given.

- grade_order:

  Optional character vector giving the low-to-high grade order for every
  year. If omitted, each ratios table's order is rebuilt from its chain
  of transitions, and supplied matrices keep their dimname order. Every
  year must end up with the same grade order.

## Value

A list of `horizon` projection steps suitable for the `schedule`
argument of
[`project_enrollment()`](https://localopen.github.io/enrollcast/reference/project_enrollment.md).
Each step contains `matrix` and `entry`; swing steps also have
`total = "base"` and recovery steps have a numeric `total`.

## Details

The rescaled grades are the students who move up the next year. After
the last swing or recovery year, nothing is rescaled: the projection
continues from the recovered grades using the progression ratios and the
supplied `entry` values. If the final target is far from the level the
ratios and entry values can sustain, later totals drift toward that
level. Recovery growth can also inflate a school's own ratios; in that
case, pass `ratios` as a list and use ordinary ratios for the years
after recovery.

To update calls written for enrollcast 0.1.0, see
[`vignette("enrollcast")`](https://localopen.github.io/enrollcast/articles/enrollcast.md).

## Examples

``` r
ratios <- data.frame(
  grade_from = c("K", "1"), grade_to = c("1", "2"), ratio = c(0.92, 0.97)
)
schedule <- swing_schedule(ratios,
  horizon = 6, swing_years = 2,
  recovery = c(225, 245, 260), entry = rep(90, 6)
)
project_enrollment(c(K = 80, `1` = 66, `2` = 60), schedule = schedule)
#>    year grade enrollment
#> 1     1     K   81.45154
#> 2     1     1   66.60926
#> 3     1     2   57.93920
#> 4     2     K   80.76798
#> 5     2     1   67.24870
#> 6     2     2   57.98332
#> 7     3     K   88.22077
#> 8     3     1   72.83756
#> 9     3     2   63.94167
#> 10    4     K   91.18520
#> 11    4     1   82.23194
#> 12    4     2   71.58285
#> 13    5     K   92.25115
#> 14    5     1   85.98872
#> 15    5     2   81.76013
#> 16    6     K   90.00000
#> 17    6     1   84.87106
#> 18    6     2   83.40906
```
