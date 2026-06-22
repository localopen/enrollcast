# Build the projection matrix

Assembles the projection matrix used to advance enrollment. Progression
ratios are placed on the sub-diagonal (each non-entry grade is fed by
the grade below); the entry-grade row is left at zero because entry
enrollment is supplied exogenously to
[`project_enrollment()`](https://gitlab.com/localopen/enrollcast/reference/project_enrollment.md).

## Usage

``` r
projection_matrix(ratios, grade_order = NULL)
```

## Arguments

- ratios:

  A data frame with columns `grade_from`, `grade_to`, and `ratio`, as
  returned by
  [`progression_ratios()`](https://gitlab.com/localopen/enrollcast/reference/progression_ratios.md).

- grade_order:

  Optional character vector giving the low-to-high grade order. If
  omitted, the order is reconstructed from the transition chain. Every
  non-entry grade in `grade_order` must appear as a `grade_to` in
  `ratios`.

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
