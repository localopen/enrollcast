# enrollcast

Initial-development R package for school-enrollment projection by grade
progression ratios. It projects one grade-by-year series per call; callers split
and map when projecting multiple schools or sectors.

## Setup and verification

- This machine needs
  `export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64` before devtools
  commands that load the vignette.
- Format with `air format .`.
- CI (`R-CMD-check.yaml`, `test-coverage.yaml`, `pkgdown.yaml`) is
  path-filtered and slow. Verify locally first: Windows and `oldrel-1` are where
  surprises land. All workflows support manual dispatch for filtered changes.

## Projection invariants

- A progression ratio is destination-grade enrollment at `t + 1` divided by
  feeder-grade enrollment at `t`.
- The lowest/entry grade is exogenous. Its projection-matrix row stays zero and
  `project_enrollment()` overwrites it each year from `entry` (or holds the base
  value with a warning when `entry = NULL`).
- `project_enrollment()` returns projected years only; it does not include the
  base year.
- A schedule step is `list(matrix, entry)` with an optional `total` that
  rescales that year's grades, entry grade included (`"base"` uses the aligned
  base total). The rescaled grades feed the next step; steps without a target
  apply no adjustment. `entry = NULL` means do not overwrite that year's entry
  grade; all step matrices must have identical row and column grade names in the
  same order.
- `swing_schedule()` advances cohorts with an entry value every year. Swing
  years match the base total and recovery years match annual target totals;
  later years continue from the rescaled grades with the supplied entry values
  and no adjustment. Ratios may vary by year through a list of tables or named
  matrices.
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
- pkgdown publishes every root-level `*.md` (and `.github/*.md`) except its own
  hardcoded skip list, and `.Rbuildignore` does not prevent this. `pkgdown.yaml`
  therefore deletes `AGENTS.md` and `CLAUDE.md` from the checkout before
  building, which keeps them out of the pages, the sitemap, and `search.json`.
  A new root-level `*.md` will be published unless it is added to that step.

## Code and tests

- Do not add a dependency without maintainer approval.
- User-facing conditions use `cli::cli_abort()`, `cli::cli_warn()`, or
  `cli::cli_inform()` and carry a stable `enrollcast_error_*` or
  `enrollcast_warning_*` class; raise them through the `ec_abort()`/`ec_warn()`
  helpers in `R/conditions.R`. Reuse shared validators: `is_count()`,
  `check_columns()`, and `has_unique_names()` live in `R/utils.R`,
  `resolve_grade_order()` in `R/checks-grades.R`, and `base`/`entry` coercion
  in `R/checks-base-entry.R`.
- Tests pair class assertions with snapshots of rendered cli messages. When a
  message changes, update and review `tests/testthat/_snaps/*.md` rather than
  weakening either assertion.
- Use `expect_identical()` for exact structure, integers, and characters;
  retain `expect_equal()` for floating-point ratios and enrollments.
- Assert missing projection results by missingness, not by `NA` versus `NaN`
  payload identity; that distinction is not portable across the CI matrix.
- `Depends: R (>= 4.0)` and the `oldrel-1` CI leg rule out the native pipe `|>`
  and `\(x)` lambdas (both R 4.1+).
- Reuse the shared fixtures and the `expect_enrollcast_error()` /
  `expect_enrollcast_warning()` helpers (snapshot + class in one call) in
  `tests/testthat/helper-enrollcast.R` instead of re-rolling snapshot/class
  two-liners.
