# enrollcast

Initial-development R package for school-enrollment projection by grade
progression ratios. It projects one grade-by-year series per call; callers split
and map when projecting multiple schools or sectors.

## Setup and verification

- Run R commands from the package root. `.Rprofile` activates the project renv;
  running elsewhere can silently use the wrong library.
- On a fresh checkout run `Rscript -e 'renv::restore()'`. Do not run
  `renv::snapshot()` merely to install optional development tools.
- This machine needs
  `export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64` before devtools
  commands that load the vignette.
- Full tests: `Rscript -e 'devtools::test()'`.
- Focused test file: `Rscript -e 'devtools::test(filter = "project-enrollment")'`
  (replace the filter with the test filename stem).
- Full package check: `Rscript -e 'devtools::check(cran = TRUE)'`.
- Format with `air format .`; if `air` is not on `PATH`, use
  `/Users/rory/.local/bin/air format .`.
- GitHub Actions runs `R-CMD-check.yaml` (full `R CMD check` across macOS and
  Windows on R release plus Ubuntu on R devel, release, and `oldrel-1`) and
  `test-coverage.yaml` (covr to Codecov). Both fire on every pull request and on
  pushes to `main`, and failing snapshots upload as artifacts. Still verify
  locally first: the matrix is slow, and Windows and `oldrel-1` are where
  surprises land. `pkgdown.yaml` builds the site on the same triggers and, on
  non-PR runs, deploys it to the `gh-pages` branch.

## Projection invariants

- Pipeline: `progression_ratios()` computes `grade_from`, `grade_to`, `ratio`;
  `projection_matrix()` places ratios on the sub-diagonal;
  `project_enrollment()` advances the vector; `swing_schedule()` builds
  per-year matrix/entry steps.
- A progression ratio is destination-grade enrollment at `t + 1` divided by
  feeder-grade enrollment at `t`.
- The lowest/entry grade is exogenous. Its projection-matrix row stays zero and
  `project_enrollment()` overwrites it each year from `entry` (or holds the base
  value with a warning when `entry = NULL`).
- `project_enrollment()` returns projected years only; it does not include the
  base year.
- A schedule step is `list(matrix, entry)`. `entry = NULL` means do not
  overwrite that year's entry grade; all step matrices must have identical row
  and column grade names in the same order.
- `swing_schedule()` holds enrollment flat during swing years, applies recovery
  multipliers, then resumes normal projection.
- Grade order is semantic. Prefer an ordered factor or explicit `grade_order`;
  mixed labels such as `K`, `1`, `2` otherwise fall back to alphabetical order
  with a warning.
- Missingness spreads. A missing ratio makes its output row missing, and because
  `0 * NA` is `NA`, the next matrix product carries that missingness into every
  grade. A non-`NULL` `entry` restores only the entry grade.
- `progression_ratios()` scans the complete supplied history for calendar-year
  gaps before `n_years` selects recent transitions, so an older gap still warns
  even when it falls outside the selected window.

## Generated sources

- Edit roxygen comments in `R/`, then run
  `Rscript -e 'devtools::document()'`; never hand-edit `man/` or `NAMESPACE`.
- Edit `README.Rmd`, then run `Rscript -e 'devtools::build_readme()'`; do not
  edit generated `README.md` directly.
- `data-raw/synthetic_enrollment.R` generates
  `inst/extdata/synthetic_enrollment.csv`.
- The pkgdown site is built and deployed by CI (`pkgdown.yaml` to the `gh-pages`
  branch, served at <https://localopen.github.io/enrollcast/>). `docs/` is
  git-ignored local build output: run `Rscript -e 'pkgdown::build_site()'` only
  to preview, and never commit it. Keep the `url` in `_pkgdown.yml` identical to
  the GitHub Pages URL in `DESCRIPTION`.

## Code and tests

- Keep dependencies minimal (`cli`, `rlang`, and base-recommended packages are
  the only imports); do not add a dependency without maintainer approval.
- User-facing conditions use `cli::cli_abort()`, `cli::cli_warn()`, or
  `cli::cli_inform()` and carry a stable `enrollcast_error_*` or
  `enrollcast_warning_*` class. Reuse shared validators in `R/utils.R`, notably
  `is_count()` and `resolve_grade_order()`.
- Tests pair class assertions with snapshots of rendered cli messages. When a
  message changes, update and review `tests/testthat/_snaps/*.md` rather than
  weakening either assertion.
- Use `expect_identical()` for exact structure, integers, and characters;
  retain `expect_equal()` for floating-point ratios and enrollments.
- Assert missing projection results by missingness, not by `NA` versus `NaN`
  payload identity; that distinction is not portable across the CI matrix.
- `Depends: R (>= 4.0)` and the `oldrel-1` CI leg rule out the native pipe `|>`
  and `\(x)` lambdas (both R 4.1+). The codebase currently uses neither.
- `enrollcast_fixture()` in `tests/testthat/helper-enrollcast.R` is the shared
  ordered K-2, 2021-2023 fixture.
