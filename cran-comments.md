## Submission

This is an update of enrollcast (0.1.0 is on CRAN) to version 0.2.0.

`swing_schedule()` has a breaking change, noted in `NEWS.md`: `recovery` now
takes annual school totals instead of multipliers, grade-specific recovery
matrices are no longer accepted, and `entry` must cover the whole horizon. The
package is at an early stage and I know of no reverse dependencies.

## R CMD check results

0 errors | 0 warnings | 0 notes

Tested with `R CMD check --as-cran` on:

* local macOS (aarch64), R release

## Method reference

The method implemented by this package is described in the reference cited in
the `Description` field: Webster (1970) <doi:10.1080/00220973.1970.11011238>.
