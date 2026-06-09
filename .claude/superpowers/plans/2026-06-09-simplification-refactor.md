# enrollcast Simplification Refactor Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Simplify the enrollcast internals — vectorize two loops, drop the rlang dependency, and untangle one dual-purpose helper — without changing any exported behavior, error message, or test expectation.

**Architecture:** Five independent, behavior-preserving refactors to internal code. The existing 95-test suite (snapshots included) is the safety net: every task ends with a full green test run. No exported signature, return value, or user-facing message changes, so no snapshot in `tests/testthat/_snaps/` should change in any task — a snapshot diff means a task was done wrong.

**Tech Stack:** Base R only. After Task 3 the package's third-party dependency count is zero (`Imports:` becomes just `stats` and `utils`, both shipped with R).

---

## Review summary — why these changes and not others

### Overall assessment

This package is already in good shape: small single-purpose helpers, minimal
dependencies, near-total test coverage, consistent validation style. A
simplification review of a codebase like this should be honest that there is no
big structural win available — the pipeline decomposition
(`progression_ratios` → `leslie_matrix` → `project_enrollment`) is right, and
the helper factoring in `utils.R` is deliberate (cyclocomp < 15 convention).
What the review found instead is five *local* simplifications:

| # | Change | Kind | Win |
|---|--------|------|-----|
| 1 | Vectorize `transition_ratios()` | fewer lines, idiomatic | 17 lines → 8; deletes a loop, a preallocation, and a hand-built `dimnames` |
| 2 | Simplify `run_projection()` | fewer lines, faster | deletes `do.call(rbind, ...)` over per-year data frames and a manual `names<-` |
| 3 | Drop `rlang` | dependency removal | the only third-party dependency, used for one predicate replaceable by one line of base R |
| 4 | `setdiff()` in `leslie_matrix()` | consistency | replaces `x[!x %in% y]` with the idiom already used everywhere else in the package |
| 5 | Split `base_year()` out of `as_base_vector()` (optional) | single responsibility | removes a 3-deep nested `if` and a `list(vector=, year=)` return that forces unpacking at the call site |

### Changes considered and rejected

These were evaluated and deliberately **not** included. Do not "improve" beyond
the tasks below.

- **Replace the Leslie matrix product with a lagged vector multiply.**
  Inside `run_projection()`, `m %*% n` on a sub-diagonal matrix is
  mathematically just `n[-1] <- ratio * n[-G]`, so the whole matrix could be
  bypassed. Rejected: `leslie_matrix(ratios)` inside `project_enrollment()` is
  not only the operator — it is also the validator (chain reconstruction,
  duplicate-feeder and missing-ratio checks all run through it), so bypassing
  it would force duplicating that validation. The matrix is also the package's
  stated identity (DESCRIPTION, vignette, exported function), and at this scale
  (≤ ~15 grades × ≤ ~10 years) the multiply costs nothing.
- **Use `tapply()`/`xtabs()` to build the grade × year matrix.**
  `xtabs` silently *sums* duplicate (grade, year) rows — the current code
  correctly errors on them — and `tapply` returns list-cells for duplicates.
  The `match()` + matrix-index assignment in `enrollment_matrix()` is the
  simplest correct implementation. No change.
- **Drop the `stats`/`utils` imports too.**
  `utils::tail(seq_len(ncol(r)), n_years)` could be replaced by index
  arithmetic, but `stats` and `utils` ship with every R installation, cost
  nothing, and `tail()` reads better than `seq.int(max(1, nc - n + 1), nc)`.
  Dependency minimalism is about third-party packages, not base-distribution
  ones. No change.
- **Inline `check_horizon()` / `check_n_years()` / `entry_values()`.**
  These single-use helpers exist to keep exported functions readable and under
  the cyclocomplexity-15 convention in CLAUDE.md. Inlining would shrink the
  file listing but grow the functions that matter. No change.
- **Rewrite `chain_order()`.**
  A loop-bound trick (`for (i in seq_along(from))` + post-loop cycle check)
  could replace the explicit `visited` set, but it is the same line count and
  *less* obvious — the visited-set version states its intent directly, and the
  O(n²) accumulator is irrelevant at n ≤ ~15 grades. The function's
  defensiveness (branching/ambiguous-entry/cycle errors) is justified because
  `ratios` may be hand-constructed, not only produced by
  `progression_ratios()`. No change.
- **Restructure `summarise_ratios()` to select a function once instead of
  `switch()`-ing per row.** The function-table version repeats `function(x)`
  five times and ends up longer than what it replaces. The per-row `switch`
  and per-row `rev(weights)` are negligible at this scale. No change.
- **Adding any dependency** (cli for messages, vctrs for coercion, tidyverse
  for the data-frame work). Every data-frame manipulation in this package is a
  one-liner in base R already; a dependency would add weight without adding
  readability. Per the maintainer's instruction, none are proposed.

### Verified assumptions (already checked empirically — do not re-derive)

1. `w[-1, trans + 1, drop = FALSE] / w[-nrow(w), trans, drop = FALSE]` is
   `identical()` to the current loop's output, **including dimnames** (R takes
   element-wise-op dimnames from the first operand, and subsetting `w`
   preserves its row/column names).
2. `drop(m %*% n)` returns a *named* numeric vector (names = `rownames(m)`),
   so the explicit `names(n) <- go` in `run_projection()` is redundant.
3. The base-R predicate in Task 3 returns the same result as
   `rlang::is_scalar_integerish(x, finite = TRUE) && x >= 1` for every input
   shape that matters: `1L`, `5`, `3.0`, `1.5`, `0`, `-3`, `NA`, `NA_real_`,
   `Inf`, `"a"`, `c(1, 2)`, `TRUE`, `NULL`.

## Invariants for every task

- Run commands from the package root (`/Users/rory/repos/enrollcast`) with
  pandoc exported first, or `devtools` fails to find it:

  ```bash
  export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
  ```

- After each code change: `Rscript -e "devtools::test()"` must report
  **FAIL 0** and produce **no `_snaps/` diffs** (no user-facing message
  changes anywhere in this plan).
- `air format .` (air is at `/Users/rory/.local/bin/air`) before every commit.
- Never edit `man/` or `NAMESPACE` by hand. None of these tasks touch roxygen
  blocks, so `devtools::document()` should be a no-op (verified in Task 6).
- CI does not run tests — local verification is the only gate.

---

### Task 1: Vectorize `transition_ratios()`

**Files:**
- Modify: `R/progression-ratios.R:44-62`

The loop fills a preallocated matrix column-by-column, but each column is the
same shifted element-wise division — so the whole thing is one division of two
sub-matrices. Subsetting `w` carries the correct dimnames along for free
(rownames `rownames(w)[-1]`, colnames = the destination-year labels), which
also deletes the hand-built `dimnames` argument.

- [ ] **Step 1: Replace the function body**

Replace lines 44-62 of `R/progression-ratios.R` (the whole
`transition_ratios` definition, keeping its leading comment) with:

```r
# Per-transition ratios: destination grade at t+1 over feeder grade at t.
transition_ratios <- function(w) {
  years <- as.numeric(colnames(w))
  trans <- which(diff(years) == 1)
  if (length(trans) == 0) {
    stop("No consecutive year pairs found to form transitions.", call. = FALSE)
  }
  w[-1, trans + 1, drop = FALSE] / w[-nrow(w), trans, drop = FALSE]
}
```

Notes for the implementer:
- `drop = FALSE` matters on both operands: with exactly 2 grades the result is
  a 1 × k matrix and must stay a matrix for `summarise_ratios()`'s `apply()`.
- Non-consecutive years (e.g. 2021, 2023) produce `diff(years) == 2`, are
  excluded from `trans`, and hit the existing error when nothing remains —
  identical to before. The existing test "non-consecutive years yield no
  transitions" covers this.

- [ ] **Step 2: Run the test suite**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e "devtools::test()"
```

Expected: `FAIL 0` (95 tests pass), no snapshot changes.

- [ ] **Step 3: Format and commit**

```bash
/Users/rory/.local/bin/air format .
git add R/progression-ratios.R
git commit -m "Vectorize transition ratio computation"
```

---

### Task 2: Simplify `run_projection()`

**Files:**
- Modify: `R/project-enrollment.R:25-42`

The current version builds one small data frame per projected year and
`do.call(rbind, ...)`s them. Accumulating the numbers into a grades × years
matrix and building a single data frame at the end is shorter, avoids repeated
data-frame construction, and `drop()` lets the matrix product keep its names so
the manual `names(n) <- go` disappears.

- [ ] **Step 1: Replace the function body**

Replace lines 25-42 of `R/project-enrollment.R` (the whole `run_projection`
definition, keeping its leading comment) with:

```r
# Advance enrollment one year at a time, overwriting the entry grade.
run_projection <- function(m, base_vec, entry_grade, entry_vals, out_years) {
  go <- rownames(m)
  n <- base_vec
  out <- matrix(NA_real_, nrow = length(go), ncol = length(out_years))
  for (h in seq_along(out_years)) {
    n <- drop(m %*% n)
    n[entry_grade] <- entry_vals[h]
    out[, h] <- n
  }
  data.frame(
    year = rep(out_years, each = length(go)),
    grade = rep(go, times = length(out_years)),
    enrollment = as.vector(out)
  )
}
```

Notes for the implementer:
- Output ordering is unchanged: year-major with grades cycling within each
  year — `rep(year, each = G)` rows match the old per-year `rbind`, and
  `as.vector(out)` reads the matrix column-major (one column per year).
- The year-by-year loop itself must stay: year *t+1* depends on year *t*, and
  the entry grade is overwritten between steps. Do not try to vectorize it.
- The old `row.names = NULL` is unnecessary on a freshly built data frame.

- [ ] **Step 2: Run the test suite**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e "devtools::test()"
```

Expected: `FAIL 0`. The hand-computed projection test
(`test-project-enrollment.R:9`) is the key guard here — it checks exact
values, row count, and grade/year alignment.

- [ ] **Step 3: Format and commit**

```bash
/Users/rory/.local/bin/air format .
git add R/project-enrollment.R
git commit -m "Build projection output in one data frame"
```

---

### Task 3: Drop the rlang dependency

**Files:**
- Modify: `R/utils.R:3-6`
- Modify: `DESCRIPTION:20-23`

`rlang` is the package's only third-party dependency and it is used in exactly
one place (`R/utils.R:5`) for one predicate. The base-R equivalent is one line
and was verified to agree with rlang on all relevant input shapes (see
"Verified assumptions"). `NAMESPACE` contains no `import()` directives (the
call used `rlang::`), so only `DESCRIPTION` and `utils.R` change.

This is a dependency *removal*, which the maintainer-facing CLAUDE.md
philosophy ("minimal dependencies") endorses — but it is still a DESCRIPTION
change, which is the maintainer's call. It is approved by virtue of this plan
being accepted.

- [ ] **Step 1: Replace `is_count()`**

Replace lines 3-6 of `R/utils.R` with:

```r
# TRUE if `x` is a single, non-missing, positive integer value.
is_count <- function(x) {
  is.numeric(x) && length(x) == 1 && is.finite(x) && x %% 1 == 0 && x >= 1
}
```

- [ ] **Step 2: Remove rlang from DESCRIPTION**

In `DESCRIPTION`, change

```
Imports:
    stats,
    utils,
    rlang
```

to

```
Imports:
    stats,
    utils
```

- [ ] **Step 3: Confirm no rlang reference remains**

```bash
grep -rn "rlang" R/ tests/ vignettes/ DESCRIPTION NAMESPACE
```

Expected: no output.

- [ ] **Step 4: Run the test suite**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e "devtools::test()"
```

Expected: `FAIL 0`. The `horizon = 0`, `horizon = 1.5`, and `n_years = 0`
snapshot tests exercise the new predicate; their messages come from the
callers (`check_horizon`, `check_n_years`), which are untouched, so snapshots
must not change.

- [ ] **Step 5: Format and commit**

```bash
/Users/rory/.local/bin/air format .
git add R/utils.R DESCRIPTION
git commit -m "Replace rlang predicate with base R, dropping the dependency"
```

---

### Task 4: Use `setdiff()` for the missing-feeder check in `leslie_matrix()`

**Files:**
- Modify: `R/leslie-matrix.R:62`

`grade_order[-1][!grade_order[-1] %in% to]` computes a set difference by hand;
the rest of the package (`check_columns`, `resolve_grade_order`,
`as_base_vector`, `chain_order`) already uses `setdiff()` for exactly this.
One-line consistency fix.

- [ ] **Step 1: Apply the edit**

In `R/leslie-matrix.R`, change line 62 from

```r
  missing_in <- grade_order[-1][!grade_order[-1] %in% to]
```

to

```r
  missing_in <- setdiff(grade_order[-1], to)
```

(`grade_order` entries are unique here — duplicates would already have failed
the `match()`/duplicate checks above — so `setdiff`'s deduplication is a
no-op.)

- [ ] **Step 2: Run the test suite**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e "devtools::test()"
```

Expected: `FAIL 0`. "leslie_matrix errors on a missing feeding ratio" covers
this line, message unchanged.

- [ ] **Step 3: Format and commit**

```bash
/Users/rory/.local/bin/air format .
git add R/leslie-matrix.R
git commit -m "Use setdiff for missing-feeder check"
```

---

### Task 5 (optional — maintainer judgment call): Split `base_year()` out of `as_base_vector()`

**Files:**
- Modify: `R/utils.R:128-172` (the `as_base_vector` definition)
- Modify: `R/project-enrollment.R:93-97`
- Test: `tests/testthat/test-utils.R:33-49`

**Why, honestly stated:** this does *not* reduce line count (it adds ~5 lines
net). It is included because `as_base_vector()` is the muddiest spot in the
package: a coercion function that also smuggles out a derived year through a
`list(vector =, year =)` return, with the year logic buried in a 3-deep nested
`if`. Splitting gives two functions that each do what their name says, guard
clauses instead of nesting, and a call site that reads linearly
(`n <- as_base_vector(...)` with no `$vector` unpacking). If the maintainer
prefers minimal churn, skip this task — nothing later depends on it.

This task changes an *internal* helper's contract, so its unit tests change.
TDD order: update the tests first, watch them fail, then implement.

- [ ] **Step 1: Update the tests to the new contracts**

In `tests/testthat/test-utils.R`, replace the two tests at lines 33-49
("as_base_vector aligns df to grade order and derives year" and
"as_base_vector accepts a named numeric vector") with:

```r
test_that("as_base_vector aligns a data frame to the grade order", {
  df <- data.frame(
    year = 2023,
    grade = c("2", "K", "1"),
    enrollment = c(91, 120, 99)
  )
  expect_identical(
    as_base_vector(df, c("K", "1", "2")),
    c(K = 120, `1` = 99, `2` = 91)
  )
})

test_that("as_base_vector accepts a named numeric vector", {
  v <- c(K = 120, `1` = 99, `2` = 91)
  expect_identical(as_base_vector(v, c("K", "1", "2")), v)
})

test_that("base_year derives the year from a single-year base data frame", {
  df <- data.frame(year = 2023, grade = "K", enrollment = 120)
  expect_identical(base_year(df), 2023)
})

test_that("base_year returns NULL when no year can be derived", {
  expect_null(base_year(c(K = 120))) # not a data frame
  expect_null(base_year(data.frame(grade = "K", enrollment = 120))) # no column
  expect_null(base_year(
    data.frame(year = c(2022, 2023), grade = c("K", "1"), enrollment = c(1, 2))
  )) # ambiguous
  expect_null(base_year(
    data.frame(year = "spring", grade = "K", enrollment = 120)
  )) # not numeric-coercible
})
```

Also update the snapshot-warning test at line 117 ("as_base_vector warns on
extra grades") — it assigns `res <- as_base_vector(...)` inside the snapshot;
the assignment still works (it now binds a vector instead of a list), and the
warning text is unchanged, so **this test needs no edit**. Listed here only so
the implementer doesn't "fix" it.

- [ ] **Step 2: Run tests to verify the new ones fail**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e "devtools::test(filter = 'utils')"
```

Expected: FAILURES — `base_year` does not exist yet, and the two
`as_base_vector` tests fail because it still returns a list.

- [ ] **Step 3: Implement**

In `R/utils.R`, replace the whole `as_base_vector` definition (currently lines
128-172, comment included) with:

```r
# Coerce `base` to a named numeric vector ordered by `go`.
as_base_vector <- function(base, go) {
  if (is.data.frame(base)) {
    check_columns(base, c("grade", "enrollment"), "base")
    v <- stats::setNames(as.numeric(base$enrollment), as.character(base$grade))
  } else if (is.numeric(base) && !is.null(names(base))) {
    v <- base
  } else {
    stop(
      "`base` must be a data frame (grade, enrollment) or a named ",
      "numeric vector.",
      call. = FALSE
    )
  }
  missing <- setdiff(go, names(v))
  if (length(missing)) {
    stop(
      "`base` is missing enrollment for grade(s): ",
      toString(missing),
      call. = FALSE
    )
  }
  extra <- setdiff(names(v), go)
  if (length(extra)) {
    warning(
      "`base` contains grade(s) not in `ratios` that will be ignored: ",
      toString(extra),
      call. = FALSE
    )
  }
  vv <- v[go]
  if (any(!is.na(vv) & vv < 0)) {
    stop("`base` enrollment must be non-negative.", call. = FALSE)
  }
  vv
}

# Year label derived from `base`: the single numeric-coercible value of a
# `year` column when `base` is a data frame, else NULL.
base_year <- function(base) {
  if (!is.data.frame(base) || !"year" %in% names(base)) {
    return(NULL)
  }
  uy <- unique(base$year)
  if (length(uy) != 1) {
    return(NULL)
  }
  y <- suppressWarnings(as.numeric(as.character(uy)))
  if (is.na(y)) NULL else y
}
```

(Keep the explicit `"year" %in% names(base)` check — `base$year` would
partial-match a column like `yearly`, which is exactly the kind of silent bug
this check prevents.)

Then in `R/project-enrollment.R`, inside `project_enrollment()`, replace

```r
  base_info <- as_base_vector(base, go)
  n <- base_info$vector
  if (is.null(start_year)) {
    start_year <- base_info$year
  }
```

with

```r
  n <- as_base_vector(base, go)
  if (is.null(start_year)) {
    start_year <- base_year(base)
  }
```

- [ ] **Step 4: Run the full test suite**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e "devtools::test()"
```

Expected: `FAIL 0` (test count rises slightly from the new `base_year`
tests). The integration tests "start_year is derived from a base data frame
carrying a year" and "without any year, output years are 1..horizon" in
`test-project-enrollment.R` confirm the wiring end-to-end.

- [ ] **Step 5: Format and commit**

```bash
/Users/rory/.local/bin/air format .
git add R/utils.R R/project-enrollment.R tests/testthat/test-utils.R
git commit -m "Split base-year derivation out of as_base_vector"
```

---

### Task 6: Final verification sweep

**Files:** none (verification only)

- [ ] **Step 1: Full package check**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e 'devtools::check(cran = TRUE)'
```

Expected: 0 errors, 0 warnings, 0 notes.

- [ ] **Step 2: Confirm documentation is a no-op and coverage held**

```bash
Rscript -e 'devtools::document()'
git status --porcelain   # expected: empty (no man/ or NAMESPACE changes)
Rscript -e 'covr::package_coverage(".")'
```

Expected: coverage 100% (the target per CLAUDE.md). If `base_year` shows an
uncovered line, a Task 5 test case is missing — fix the test, don't drop the
target.

- [ ] **Step 3: Complexity and snapshot sanity**

```bash
Rscript -e 'cyclocomp::cyclocomp_package_dir(".")'
git diff --stat HEAD~5 -- tests/testthat/_snaps/
```

Expected: every function < 15; the `_snaps/` diff is empty (no message
changed anywhere in this plan). Adjust `HEAD~5` to `HEAD~4` if Task 5 was
skipped.
