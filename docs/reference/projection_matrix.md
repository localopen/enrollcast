# Build the projection matrix

Assembles the projection matrix used to advance enrollment. Progression
ratios are placed on the sub-diagonal (each non-entry grade is fed by
the grade below); the entry-grade row is left at zero because entry
enrollment is supplied exogenously to
[`project_enrollment()`](https://github.com/localopen/enrollcast/reference/project_enrollment.md).
The ratios must form a single low-to-high chain: each `grade_to` must be
the grade immediately above its `grade_from` in the resolved order.

## Usage

``` r
projection_matrix(ratios, grade_order = NULL)
```

## Arguments

- ratios:

  A data frame or data-frame subclass with columns `grade_from`,
  `grade_to`, and `ratio`, as returned by
  [`progression_ratios()`](https://github.com/localopen/enrollcast/reference/progression_ratios.md).
  `grade_from` and `grade_to` must not be missing. `ratio` must be
  numeric, non-negative, and finite; an infinite ratio (from a
  zero-enrollment feeder) is rejected, while `NA`/`NaN` ratios (e.g.
  from sparse history) are kept in the matrix with a warning.

- grade_order:

  Optional character vector giving the low-to-high grade order. If
  omitted, the order is reconstructed from the transition chain. Every
  non-entry grade in `grade_order` must appear as a `grade_to` in
  `ratios`. Must not contain duplicates or missing values.

## Value

A square numeric matrix with grade dimnames.

## Examples

``` r
ratios <- data.frame(
  grade_from = c("K", "1"),
  grade_to = c("1", "2"),
  ratio = c(0.92, 0.97)
)
projection_matrix(ratios)
#>      K    1 2
#> K 0.00 0.00 0
#> 1 0.92 0.00 0
#> 2 0.00 0.97 0
```
