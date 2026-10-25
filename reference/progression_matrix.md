# Build the projection matrix

Builds the matrix that advances enrollment by one year. Progression
ratios go on the sub-diagonal, so each grade above the entry grade is
fed by the grade below it. The entry-grade row is zero because you
supply entry enrollment to
[`project_enrollment()`](https://localopen.github.io/enrollcast/reference/project_enrollment.md)
yourself. The ratios must form a single chain from the lowest grade to
the highest: each `grade_to` must be the grade directly above its
`grade_from`.

## Usage

``` r
progression_matrix(ratios, grade_order = NULL)
```

## Arguments

- ratios:

  A data frame or data-frame subclass with columns `grade_from`,
  `grade_to`, and `ratio`, as returned by
  [`progression_ratios()`](https://localopen.github.io/enrollcast/reference/progression_ratios.md).
  `grade_from` and `grade_to` must not be missing. `ratio` must be
  numeric, non-negative, and finite. An infinite ratio (from a feeder
  grade with zero enrollment) is an error. `NA`/`NaN` ratios, for
  example from sparse history, stay in the matrix with a warning.

- grade_order:

  Optional character vector giving the low-to-high grade order. If
  omitted, the order is rebuilt from the chain of transitions. Every
  grade in `grade_order` except the entry grade must appear as a
  `grade_to` in `ratios`. It must not contain duplicates or missing
  values.

## Value

A square numeric matrix with grade dimnames.

## Examples

``` r
ratios <- data.frame(
  grade_from = c("K", "1"),
  grade_to = c("1", "2"),
  ratio = c(0.92, 0.97)
)
progression_matrix(ratios)
#>      K    1 2
#> K 0.00 0.00 0
#> 1 0.92 0.00 0
#> 2 0.00 0.97 0
```
