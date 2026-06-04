# gpr: School Enrollment Projection via Grade Progression Ratios

**Date:** 2026-06-04
**Status:** Approved design, pending implementation plan

## Purpose

An R package providing an intuitive interface for projecting school enrollment
using the **cohort survival / grade progression ratio (GPR)** method. It works at
any level of aggregation (school, district, LEA, city-wide) and any number of
grades, because it operates on a single grade-by-year enrollment series and is
agnostic to what that series represents.

The numerical engine is a **Leslie matrix**: progression ratios live on the
sub-diagonal, and projection is repeated matrix–vector multiplication. This
replaces per-grade/per-cohort iteration with linear algebra.

## Goals

- Compute grade progression ratios from historical grade-level enrollment.
- Project future enrollment forward an arbitrary horizon.
- Minimal dependencies (base R + `stats` only in `Imports`).
- Tidy, long data frames as the user-facing interface.
- Transparent, inspectable internals (the Leslie matrix is a first-class,
  exported object).

## Non-Goals (YAGNI)

- No grouped/multi-unit projection in a single call. The package projects **one
  series per call**; callers map over schools/LEAs themselves (e.g. with
  `split()` + `lapply()`). This keeps the core aggregation-agnostic.
- No birth-cohort or population-capture entry-grade model. Entry grade is
  **exogenous** (caller-supplied). Other entry methods can be layered later.
- No model object / `fit()`/`predict()` S3 machinery, no plotting.
- No tidyverse dependency.

## The Method

For a series with grades ordered low → high as `g_1, ..., g_G`:

- The **progression ratio** feeding grade `g_i` (for `i >= 2`) in a given year
  transition is `enrollment[g_i, t] / enrollment[g_{i-1}, t-1]`. It captures net
  retention/migration/repetition between adjacent grades across one year.
- The **entry grade** `g_1` has no feeder grade, so it gets no ratio; its future
  values are supplied exogenously by the caller.
- With multiple historical transitions, per-year ratios are summarised into the
  ratios used for projection (mean by default; see `method` below).

### Leslie matrix formulation

`M` is `G x G` with grade dimnames:

- `M[i, i-1] = ratio` feeding grade `g_i`, for `i = 2..G` (the sub-diagonal).
- The entry-grade row (`i = 1`) is all zeros — entry is exogenous, not a function
  of existing enrollment.
- All other entries are zero.

One projection step:

```
n_{t+1} = M %*% n_t        # matrix-vector product
n_{t+1}[entry] = entry_t   # overwrite entry grade with exogenous value
```

Projection over a horizon `h` is a short loop of `h` such steps (one matrix
multiply per projected year). Linear algebra removes the per-grade/per-cohort
looping; the remaining loop is over projection years, which is the natural and
efficient form. We document this honestly rather than forcing a closed form.

## Public API

Three exported functions operating on tidy long data frames.

### `progression_ratios(data, year = "year", grade = "grade", enrollment = "enrollment", method = c("mean", "geometric", "median", "last", "weighted"), n_years = NULL, weights = NULL, grade_order = NULL)`

- **Input:** long historical enrollment. Column names are overridable via the
  `year`/`grade`/`enrollment` arguments (defaults shown).
- Computes every adjacent-grade, adjacent-year transition ratio, then summarises
  across the available transition years:
  - `"mean"` (default) — arithmetic mean of per-year ratios.
  - `"geometric"` — geometric mean.
  - `"median"`.
  - `"last"` — most recent transition year only.
  - `"weighted"` — `stats::weighted.mean` using `weights` (one weight per
    transition year, recent → older or matched by year; see Open Questions).
- `n_years`: if set, use only the most recent `n_years` transition years.
- `grade_order`: explicit low→high grade order (see Grade Ordering).
- **Output:** long df with columns `grade_from`, `grade_to`, `ratio` — one row
  per non-entry grade.

### `leslie_matrix(ratios, grade_order = NULL)`

- **Input:** a `ratios` data frame as returned by `progression_ratios()` (or a
  compatible `grade_from`/`grade_to`/`ratio` frame).
- **Output:** the `G x G` Leslie matrix with grade dimnames, sub-diagonal set
  from the ratios, entry row zero.
- Exported because it is the conceptual core and makes the method inspectable.

### `project_enrollment(base, ratios, horizon, entry = NULL, start_year = NULL)`

- **Input:**
  - `base`: most recent observed year's enrollment — a long df (`grade`,
    `enrollment`) or a named numeric vector (names = grades).
  - `ratios`: from `progression_ratios()`.
  - `horizon`: number of years to project (positive integer).
  - `entry`: exogenous entry-grade enrollment per projected year — numeric vector
    of length `horizon` (or a df with year/value). If `NULL`, hold the entry
    grade constant at its base value and emit a warning.
  - `start_year`: integer label for the base year; output years are
    `start_year + 1 ... start_year + horizon`. If `NULL`, years are labelled
    `1..horizon` (or derived from `base` if it carries a year — see Open
    Questions).
- Builds `M` via `leslie_matrix()`, iterates `horizon` steps, overwriting the
  entry grade each step.
- **Output:** long df with columns `year`, `grade`, `enrollment` for the
  projected years.

## Grade Ordering

Text grade labels do not sort correctly (`"K", "1", "2", "10"`). Resolution:

1. If `grade` is a **factor**, use its levels as the order.
2. Else if `grade_order` is supplied, use it.
3. Else if grades are **numeric**, sort numerically.
4. Else sort lexically and **warn** that the order was guessed.

The **lowest grade** in the resolved order is the entry grade.

## Error Handling

Base-R `stop()` / `warning()` with informative messages. Validated conditions
include:

- Required columns missing from `data` / `base`.
- Ragged or non-contiguous years where a transition cannot be formed.
- Missing ratios for one or more non-entry grades when building `M`.
- `entry` length != `horizon`.
- `horizon` not a positive integer.
- Negative or non-numeric enrollment.
- Unknown `method`.
- Grade order could not be determined unambiguously (warn, per above).

## Dependencies

- **Imports:** none beyond base R and `stats` (`weighted.mean`, `median`).
- **Suggests:** `testthat (>= 3.0.0)`, `knitr`, `rmarkdown`.
- **Dev:** roxygen2.

## Package Conventions

- **Name:** `gpr`
- **License:** MIT
- **Author:** Rory Lawless <rory@mensahlawless.com>
- **Docs:** roxygen2; README with a quick example; one vignette projecting a
  small K–5 district end to end.
- **Tests:** testthat 3e, test-driven. Tiny hand-computable fixtures so expected
  values can be verified by hand.

## Testing Strategy

- `progression_ratios()`: known ratios from a tiny K–5, 3-year fixture; each
  `method` variant; `n_years` truncation; weighted with explicit weights;
  column-name overrides; factor vs numeric vs character grade ordering.
- `leslie_matrix()`: correct shape, dimnames, sub-diagonal placement, zero entry
  row, error on missing transitions.
- `project_enrollment()`: reproduces a hand-computed multi-year projection;
  exogenous `entry` applied correctly each year; `entry = NULL` holds-constant +
  warns; `start_year` labelling; vector and df `base` inputs; error on
  `entry`/`horizon` mismatch.
- Error/edge conditions enumerated above.

## Worked Example (illustrative)

```r
library(gpr)

# history: long df with year, grade, enrollment for grades K-5, 2019-2023
ratios <- progression_ratios(history, method = "mean")

base <- subset(history, year == 2023, select = c("grade", "enrollment"))

# project 5 years; entry (kindergarten) supplied exogenously
proj <- project_enrollment(
  base       = base,
  ratios     = ratios,
  horizon    = 5,
  entry      = c(102, 100, 99, 101, 103),
  start_year = 2023
)
```

## Open Questions (resolve during implementation)

1. **`weights` semantics** for `method = "weighted"`: ordered most-recent-first,
   or matched to transition years by name? Lean: a plain numeric vector aligned
   most-recent → oldest, recycled/validated against the number of transition
   years used.
2. **`start_year` defaulting** when `base` is a df that happens to carry a `year`
   column: derive from it, or require `start_year` explicitly? Lean: derive if
   unambiguous, else label `1..horizon`.
3. Whether to include the base year as a row in `project_enrollment()` output
   (for easy plotting of history + projection). Lean: no by default; document the
   simple `rbind` if wanted.
