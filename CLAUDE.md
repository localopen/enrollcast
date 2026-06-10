# enrollcast

R package that projects school enrollment with the cohort survival / grade
progression ratio (GPR) method, implemented as a Leslie matrix. Works at any
aggregation level (school, district, LEA, city-wide) and any number of grades,
because it operates on a single grade-by-year enrollment series.

Status: initial development (`0.0.0.9000`). Not yet on CRAN. Hosted on GitLab
(`gitlab.com/localopen/enrollcast`). **Renamed from `gpr`** — the planning docs
under `docs/superpowers/` and the built artifacts under `doc/` still say `gpr`;
the package, vignette, and tests are all `enrollcast`.

## The method (what the code computes)

The three exported functions form a pipeline:

1. **`progression_ratios(data, ...)`** — from long historical enrollment (one
   row per grade per year), compute one ratio per non-entry grade. A transition
   ratio is *destination grade enrollment at t+1 ÷ feeder grade enrollment at
   t*, summarised across year-to-year transitions (`method`: `mean` (default),
   `geometric`, `median`, `last`, `weighted`). Returns a data frame:
   `grade_from`, `grade_to`, `ratio`.
2. **`leslie_matrix(ratios, ...)`** — assemble the square projection matrix.
   Ratios sit on the **sub-diagonal** (each non-entry grade is fed by the grade
   below). The **entry-grade (lowest) row is left at zero** because entry
   enrollment is supplied exogenously, not projected.
3. **`project_enrollment(base, ratios, horizon, entry, ...)`** — advance one
   year at a time (one matrix-vector product per year), **overwriting the entry
   grade each year** with the supplied exogenous `entry` value. Returns a long
   data frame: `year`, `grade`, `enrollment`, for projected years only.

Key idea to keep in mind: the lowest grade (e.g. K or PK3) is never projected
from a feeder — the caller must supply it via `entry`. One call projects one
series; map over `split()` for multiple schools/sectors (see README).

## Commands

All R commands assume the package root. Tests and the vignette need pandoc —
**export `RSTUDIO_PANDOC` first** or `devtools` won't find it:

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64

Rscript -e "devtools::test()"                          # run tests (currently 98, FAIL 0)
Rscript -e 'devtools::check(cran = TRUE)'              # full R CMD check; expect 0/0/0
Rscript -e 'covr::package_coverage(".")'              # coverage — target is 100%
Rscript -e 'print(goodpractice::gp("."))'             # package quality gate
Rscript -e 'cyclocomp::cyclocomp_package_dir(".")'    # complexity — keep every fn < 15
air format .                                           # format (run before every commit)
Rscript -e 'devtools::document()'                     # regenerate man/*.Rd + NAMESPACE
Rscript -e 'source("data-raw/synthetic_enrollment.R")' # rebuild inst/extdata CSV
```

`air` is at `/Users/rory/.local/bin/air`.

## Layout

```
R/
  enrollcast-package.R     # "_PACKAGE" doc stub
  progression-ratios.R     # progression_ratios() + its internal helpers
  leslie-matrix.R          # leslie_matrix()
  project-enrollment.R     # project_enrollment() + its internal helpers
  utils.R                  # shared internals: is_count, check_columns,
                           #   resolve_grade_order, chain_order, summarise_ratios,
                           #   as_base_vector, as_entry_vector
tests/testthat/            # test-*.R, helper-enrollcast.R, _snaps/*.md
man/                       # roxygen-generated — never edit by hand
data-raw/                  # synthetic_enrollment.R generates the example CSV
inst/extdata/              # synthetic_enrollment.csv (the generated data)
vignettes/enrollcast.Rmd   # the only vignette source
docs/superpowers/          # design specs + implementation plans (history, says "gpr")
```

Not tracked / build artifacts: `doc/`, `Meta/` (gitignored, still reference the
old `gpr` name — don't treat them as current sources).

## Conventions

- **2-space indentation, enforced by `air`** with default settings (`air.toml`
  is intentionally empty). Run `air format .` before every commit. (The code was
  tab-indented through early development; commit `ce31a5c` reformatted everything
  to Air defaults — don't reintroduce tabs, and ignore stale tab references in
  `docs/superpowers/`.)
- **Minimal dependencies.** Imports are `stats` and `utils` only (both ship
  with R — zero third-party dependencies); `Depends: R (>= 4.0)`.
  No tidyverse. Don't add new dependencies without maintainer sign-off.
- **roxygen2 with markdown** (`Roxygen: list(markdown = TRUE)`). Edit roxygen
  comments in `R/`, then `devtools::document()` — never edit `man/` or `NAMESPACE`.
- Internal helpers are **not exported**, use **snake_case**, and carry a plain
  one-line comment (no roxygen). Exported functions are factored into small
  helpers to keep cyclomatic complexity < 15.
- Error/validation messages use `stop(..., call. = FALSE)`. Reuse the shared
  predicate `is_count()` (base-R one-liner in `R/utils.R`) for positive-integer
  checks rather than re-inlining it.

## Testing

- **testthat 3rd edition** (`Config/testthat/edition: 3`).
- Errors and warnings are tested with **snapshots**: `expect_snapshot(expr,
  error = TRUE)`. After changing user-facing messages, re-run tests to update
  `_snaps/*.md` and review the diff.
- `expect_identical()` for exact values (integers like `3L`, character vectors,
  structure); `expect_equal()` (with `tolerance`) for floating-point ratios and
  enrollments. Don't convert float comparisons to `expect_identical` — they'll
  fail.
- Shared fixture: `enrollcast_fixture()` in `tests/testthat/helper-enrollcast.R`
  (canonical K–2, 2021–2023 series; grade is a factor for unambiguous order).

## Gotchas

- Without `RSTUDIO_PANDOC` exported, `devtools::test()`/`check()` fail to find
  pandoc on this machine. See Commands above.
- CI (`.gitlab-ci.yml`) only runs **secret detection** — it does *not* run R CMD
  check or tests. Verify locally before pushing; nothing else will.
- Grade ordering: pass a **factor `grade`** or an explicit `grade_order`. With
  mixed labels like `"K","1","2"` the code falls back to alphabetical sorting
  *with a warning* (because they aren't all numeric-coercible).
- The DESCRIPTION `URL` returns 403 under `urlchecker` because the GitLab repo is
  private. Make it public before any CRAN submission. `R CMD check --as-cran`
  does not flag it.
