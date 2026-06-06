# goodpractice Remediation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Address the findings from `goodpractice::gp()` on the `gpr` package while preserving behavior and the existing 87-test suite.

**Approach:** Apply safe lint/metadata fixes, raise test coverage to 100% by exercising defensive branches, refactor the two long/complex exported functions into small internal helpers, and selectively tighten test comparisons — verifying after each step that all tests stay green.

**Tech Stack:** Base R (`stats`, `utils`); testthat 3e (snapshot tests for errors/warnings); roxygen2; `air` formatter (tab indentation — intentional, and *not* flagged by goodpractice); `goodpractice`, `covr`, `cyclocomp` for verification.

**Decision (confirmed with maintainer):** declare `Depends: R (>= 4.0)` so removing redundant `stringsAsFactors = FALSE` is correct.

---

## Baseline: `goodpractice::gp()` findings (2026-06-06)

| # | Finding | Where | Tier |
|---|---------|-------|------|
| 1 | Add `URL` to DESCRIPTION | DESCRIPTION | 1 |
| 2 | Add `BugReports` to DESCRIPTION | DESCRIPTION | 1 |
| 3 | Line > 80 chars | `R/utils.R:123` (comment, 82 chars) | 1 |
| 4 | `anyNA()` over `any(is.na(x))` | `utils.R:38`, `progression-ratios.R:81,88`, `leslie-matrix.R:42` (×2) | 1 |
| 5 | `paste(x, collapse=", ")` → `toString(x)` | `leslie-matrix.R:66`, `utils.R:10,27,149,157` | 1 |
| 6 | Coverage 95.1% → 100% | 17 defensive lines (enumerated in Task 4) | 1 |
| 7 | Function length > 50 | `progression_ratios`, `project_enrollment` | 2 |
| 8 | Cyclomatic complexity > 15 | `progression_ratios` (31), `project_enrollment` (21) | 2 |
| 9 | Remove `stringsAsFactors` | 6 sites (see Task 3) | 2 |
| 10 | `expect_identical()` over `expect_equal()` | ~42 test assertions | 2 |
| 11 | R CMD check WARNING: LaTeX/PDF | environmental (no pdflatex) | 3 |

Findings 7 and 8 are addressed by one refactor each. Tier 3 is notes only (Appendix).

**Conventions for every task:** run `air format .` before committing (tab indentation expected); verify the full suite with `export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64; Rscript -e "devtools::test()"` (must stay `FAIL 0`); error/warning tests use `expect_snapshot()`.

---

## Task 1: DESCRIPTION metadata

**Files:** Modify `DESCRIPTION`

- [ ] **Step 1: Add `Depends`, `URL`, and `BugReports`**

Insert a `Depends` field before `Imports`, and add `URL`/`BugReports` (e.g. after `License`). Target DESCRIPTION fields:

```
Depends:
    R (>= 4.0)
Imports:
    stats,
    utils
URL: https://gitlab.com/rorylawless/gpr
BugReports: https://gitlab.com/rorylawless/gpr/-/issues
```

- [ ] **Step 2: Verify DESCRIPTION parses and package loads**

Run: `Rscript -e 'desc <- read.dcf("DESCRIPTION"); stopifnot(all(c("URL","BugReports","Depends") %in% colnames(desc))); devtools::load_all("."); cat("OK\n")'`
Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add DESCRIPTION
git commit -m "Add URL, BugReports, and R (>= 4.0) dependency"
```

---

## Task 2: Lint quick-fixes in `R/` (anyNA, toString, line length)

**Files:** Modify `R/utils.R`, `R/progression-ratios.R`, `R/leslie-matrix.R`

- [ ] **Step 1: Replace `any(is.na(x))` with `anyNA(x)`**

Make exactly these replacements (do NOT touch the `any(is.infinite(R)) || any(is.nan(R))` check in `progression-ratios.R` — that is not `is.na`):

- `R/utils.R` (`resolve_grade_order`): `if (!any(is.na(num))) {` → `if (!anyNA(num)) {`
- `R/progression-ratios.R`: `if (any(is.na(yr_num))) {` → `if (anyNA(yr_num)) {`
- `R/progression-ratios.R`: `if (any(is.na(ri))) {` → `if (anyNA(ri)) {`
- `R/leslie-matrix.R`: `if (any(is.na(ii)) || any(is.na(jj))) {` → `if (anyNA(ii) || anyNA(jj)) {`

- [ ] **Step 2: Replace `paste(x, collapse = ", ")` with `toString(x)`**

`toString(x)` is exactly `paste(x, collapse = ", ")`. Replace at:

- `R/leslie-matrix.R`: `paste(missing_in, collapse = ", ")` → `toString(missing_in)`
- `R/utils.R` (`check_columns`): `paste(missing, collapse = ", ")` → `toString(missing)`
- `R/utils.R` (`resolve_grade_order`): `paste(missing, collapse = ", ")` → `toString(missing)`
- `R/utils.R` (`as_base_vector` missing): `paste(missing, collapse = ", ")` → `toString(missing)`
- `R/utils.R` (`as_base_vector` extra): `paste(extra, collapse = ", ")` → `toString(extra)`

- [ ] **Step 3: Wrap the long comment at `R/utils.R:123`**

Replace the 82-char comment line:

```r
# Coerce `base` to a named numeric vector ordered by `go`; derive year if present.
```

with:

```r
# Coerce `base` to a named numeric vector ordered by `go`; derive the year
# when present.
```

- [ ] **Step 4: Verify behavior unchanged**

Run: `Rscript -e "devtools::test()"`
Expected: `FAIL 0`. (Snapshots that quote the error messages are unaffected — `toString` produces identical text and `anyNA` is logically identical here.)

- [ ] **Step 5: Format and commit**

```bash
air format .
git add R/
git commit -m "Use anyNA() and toString(); wrap long comment"
```

---

## Task 3: Remove redundant `stringsAsFactors = FALSE`

Safe because Task 1 declared `R (>= 4.0)` (default `stringsAsFactors = FALSE`).

**Files:** Modify `R/progression-ratios.R`, `R/project-enrollment.R`, `tests/testthat/test-project-enrollment.R`, `tests/testthat/test-leslie-matrix.R`

- [ ] **Step 1: Remove the argument at all 6 sites**

Delete the `stringsAsFactors = FALSE` argument (and fix the trailing comma on the preceding argument line so the `data.frame()` call stays valid) at:

- `R/progression-ratios.R` — output `data.frame()` in `progression_ratios()`
- `R/project-enrollment.R` — per-year `data.frame()` in the projection loop
- `tests/testthat/test-project-enrollment.R` — `proj_base()` fixture
- `tests/testthat/test-leslie-matrix.R` — `ratios_fixture()` and the two inline `data.frame()` calls in the duplicate-feeder and ambiguous-entry tests

Example (test fixture):

```r
# before
data.frame(
  grade = c("K", "1", "2"), enrollment = c(120, 99, 91),
  stringsAsFactors = FALSE
)
# after
data.frame(
  grade = c("K", "1", "2"), enrollment = c(120, 99, 91)
)
```

- [ ] **Step 2: Verify all data.frame columns keep their types**

Run: `Rscript -e 'devtools::load_all("."); r <- progression_ratios(within(data.frame(year=rep(2021:2023,each=3), grade=factor(rep(c("K","1","2"),3),levels=c("K","1","2")), enrollment=c(100,90,80,110,95,88,120,99,91)),{}) ); stopifnot(is.character(r$grade_from)); cat("char OK\n")'`
Then: `Rscript -e "devtools::test()"`
Expected: `char OK`; `FAIL 0` (grade columns remain character under R >= 4.0).

- [ ] **Step 3: Format and commit**

```bash
air format .
git add R/ tests/
git commit -m "Remove redundant stringsAsFactors arguments"
```

---

## Task 4: Raise coverage to 100% (defensive branches)

The 17 uncovered lines are all unexercised error/edge branches. Add tests that hit each.

**Files:** Modify `tests/testthat/test-leslie-matrix.R`, `tests/testthat/test-utils.R`, `tests/testthat/test-progression-ratios.R`

- [ ] **Step 1: `leslie_matrix` guards (lines 37, 43)**

Append to `tests/testthat/test-leslie-matrix.R`:

```r
test_that("leslie_matrix errors with fewer than two grades", {
  expect_snapshot(leslie_matrix(ratios_fixture(), grade_order = "K"), error = TRUE)
})

test_that("leslie_matrix errors when ratios reference an unknown grade", {
  expect_snapshot(
    leslie_matrix(ratios_fixture(), grade_order = c("K", "1")),
    error = TRUE
  )
})
```

- [ ] **Step 2: `summarise_ratios` all-NA `last`, `as_base_vector`/`as_entry_vector` errors (utils.R 92, 139-143, 173-176, 182-185)**

Append to `tests/testthat/test-utils.R`:

```r
test_that("summarise_ratios last returns NA when all transitions are NA", {
  R <- matrix(NA_real_, nrow = 1, dimnames = list("1", "2023"))
  expect_identical(summarise_ratios(R, "last"), c("1" = NA_real_))
})

test_that("as_base_vector errors on an invalid base type", {
  expect_snapshot(as_base_vector(c(1, 2, 3), c("K", "1", "2")), error = TRUE)
})

test_that("as_entry_vector errors on a data frame without a value column", {
  expect_snapshot(as_entry_vector(data.frame(x = 1:2), 2), error = TRUE)
})

test_that("as_entry_vector errors on an unsupported entry type", {
  expect_snapshot(as_entry_vector("oops", 2), error = TRUE)
})
```

- [ ] **Step 3: `progression_ratios` unmatched-grade guard (line 89)**

Append to `tests/testthat/test-progression-ratios.R`:

```r
test_that("progression_ratios errors on an unmatched (NA) grade", {
  fx <- gpr_fixture()
  fx$grade <- as.character(fx$grade)
  fx$grade[1] <- NA
  expect_snapshot(progression_ratios(fx), error = TRUE)
})
```

Note: this input also triggers the alphabetical-order warning from `resolve_grade_order()`; the snapshot will record both the warning and the error — review it to confirm the final error is "Some grades are not in the resolved grade order."

- [ ] **Step 4: Record snapshots, then confirm 100% coverage**

Run: `Rscript -e "devtools::test()"` (records new snapshots; review the new `_snaps/*.md` entries). Re-run once for stability.
Then: `Rscript -e 'cat(round(covr::percent_coverage(covr::package_coverage(".")), 2), "%\n")'`
Expected: `100 %` (or confirm `covr::zero_coverage()` is empty).

- [ ] **Step 5: Format and commit**

```bash
air format .
git add tests/
git commit -m "Cover remaining defensive branches (100% coverage)"
```

---

## Task 5: Refactor `progression_ratios()` (length + complexity 31 → < 15)

Extract cohesive steps into internal helpers (no roxygen; snake_case names to satisfy naming linters). Behavior must be identical.

**Files:** Modify `R/progression-ratios.R`

- [ ] **Step 1: Add internal helpers above `progression_ratios()`**

```r
# Validate inputs and return cleaned pieces (grades, enrollment, order, years).
prepare_enrollment <- function(data, year, grade, enrollment, grade_order) {
  check_columns(data, c(year, grade, enrollment), "data")
  gr_raw <- data[[grade]]
  en <- data[[enrollment]]
  if (!is.numeric(en)) {
    stop("`enrollment` column must be numeric.", call. = FALSE)
  }
  if (any(en < 0, na.rm = TRUE)) {
    stop("`enrollment` must be non-negative.", call. = FALSE)
  }
  go <- resolve_grade_order(gr_raw, grade_order)
  if (length(go) < 2) {
    stop("Need at least 2 grades to compute progression ratios.", call. = FALSE)
  }
  yr_num <- suppressWarnings(as.numeric(as.character(data[[year]])))
  if (anyNA(yr_num)) {
    stop("`year` must be numeric or coercible to numeric.", call. = FALSE)
  }
  list(grade = as.character(gr_raw), enrollment = en, go = go, year = yr_num)
}

# Build a grade x year enrollment matrix from long records.
enrollment_matrix <- function(grade, year, enrollment, go) {
  years <- sort(unique(year))
  ri <- match(grade, go)
  ci <- match(year, years)
  if (anyNA(ri)) {
    stop("Some grades are not in the resolved grade order.", call. = FALSE)
  }
  if (anyDuplicated(cbind(ri, ci))) {
    stop("Duplicate (grade, year) rows in `data`.", call. = FALSE)
  }
  w <- matrix(
    NA_real_,
    nrow = length(go), ncol = length(years),
    dimnames = list(go, as.character(years))
  )
  w[cbind(ri, ci)] <- enrollment
  w
}

# Per-transition ratios: destination grade at t+1 over feeder grade at t.
transition_ratios <- function(w) {
  years <- as.numeric(colnames(w))
  trans <- which(diff(years) == 1)
  if (length(trans) == 0) {
    stop("No consecutive year pairs found to form transitions.", call. = FALSE)
  }
  n_grades <- nrow(w)
  r <- matrix(
    NA_real_,
    nrow = n_grades - 1, ncol = length(trans),
    dimnames = list(rownames(w)[-1], as.character(years[trans + 1]))
  )
  for (j in seq_along(trans)) {
    r[, j] <- w[2:n_grades, trans[j] + 1] / w[1:(n_grades - 1), trans[j]]
  }
  r
}

# Validate the optional n_years argument.
check_n_years <- function(n_years) {
  if (is.null(n_years)) {
    return(invisible())
  }
  if (!is.numeric(n_years) || length(n_years) != 1 || is.na(n_years) ||
    n_years < 1 || n_years != floor(n_years)) {
    stop("`n_years` must be a positive integer.", call. = FALSE)
  }
}
```

- [ ] **Step 2: Replace the body of `progression_ratios()` (keep the roxygen block unchanged)**

```r
progression_ratios <- function(data,
                               year = "year",
                               grade = "grade",
                               enrollment = "enrollment",
                               method = c(
                                 "mean", "geometric", "median",
                                 "last", "weighted"
                               ),
                               n_years = NULL,
                               weights = NULL,
                               grade_order = NULL) {
  method <- match.arg(method)
  check_n_years(n_years)
  clean <- prepare_enrollment(data, year, grade, enrollment, grade_order)
  w <- enrollment_matrix(clean$grade, clean$year, clean$enrollment, clean$go)
  r <- transition_ratios(w)
  if (!is.null(n_years)) {
    r <- r[, utils::tail(seq_len(ncol(r)), n_years), drop = FALSE]
  }
  if (any(is.infinite(r)) || any(is.nan(r))) {
    warning(
      "Some progression ratios are infinite or NaN because a feeder grade ",
      "had zero enrollment in at least one transition.",
      call. = FALSE
    )
  }
  ratio <- summarise_ratios(r, method = method, weights = weights)
  go <- clean$go
  data.frame(
    grade_from = go[-length(go)],
    grade_to = go[-1],
    ratio = unname(ratio),
    row.names = NULL
  )
}
```

- [ ] **Step 3: Verify tests, coverage, and complexity**

Run: `Rscript -e "devtools::test()"` → `FAIL 0` (all existing behavior and snapshots preserved).
Run: `Rscript -e 'devtools::load_all("."); cat("progression_ratios:", cyclocomp::cyclocomp(progression_ratios), "\n")'`
Expected: complexity < 15. Re-check coverage is still 100%.

- [ ] **Step 4: Format and commit**

```bash
air format .
git add R/progression-ratios.R
git commit -m "Refactor progression_ratios into focused helpers"
```

---

## Task 6: Refactor `project_enrollment()` (complexity 21 → < 15)

**Files:** Modify `R/project-enrollment.R`

- [ ] **Step 1: Add internal helpers above `project_enrollment()`**

```r
# Validate horizon and return it as an integer.
check_horizon <- function(horizon) {
  if (!is.numeric(horizon) || length(horizon) != 1 || is.na(horizon) ||
    horizon < 1 || horizon != as.integer(horizon)) {
    stop("`horizon` must be a single positive integer.", call. = FALSE)
  }
  as.integer(horizon)
}

# Resolve exogenous entry-grade values for each projected year.
entry_values <- function(entry, horizon, base_vec, entry_grade) {
  if (is.null(entry)) {
    warning(
      sprintf(
        "`entry` not supplied; holding entry grade '%s' constant at %g.",
        entry_grade, base_vec[[entry_grade]]
      ),
      call. = FALSE
    )
    return(rep(base_vec[[entry_grade]], horizon))
  }
  as_entry_vector(entry, horizon)
}

# Advance enrollment one year at a time, overwriting the entry grade.
run_projection <- function(m, base_vec, entry_grade, entry_vals, out_years) {
  go <- rownames(m)
  n <- base_vec
  result <- vector("list", length(out_years))
  for (h in seq_along(out_years)) {
    n <- as.vector(m %*% n)
    names(n) <- go
    n[entry_grade] <- entry_vals[h]
    result[[h]] <- data.frame(
      year = out_years[h],
      grade = go,
      enrollment = unname(n),
      row.names = NULL
    )
  }
  do.call(rbind, result)
}
```

- [ ] **Step 2: Replace the body of `project_enrollment()` (keep the roxygen block unchanged)**

```r
project_enrollment <- function(base, ratios, horizon, entry = NULL,
                               start_year = NULL) {
  horizon <- check_horizon(horizon)
  m <- leslie_matrix(ratios)
  go <- rownames(m)
  entry_grade <- go[1]
  base_info <- as_base_vector(base, go)
  n <- base_info$vector
  if (is.null(start_year)) start_year <- base_info$year
  entry_vals <- entry_values(entry, horizon, n, entry_grade)
  out_years <- if (is.null(start_year)) {
    seq_len(horizon)
  } else {
    start_year + seq_len(horizon)
  }
  run_projection(m, n, entry_grade, entry_vals, out_years)
}
```

- [ ] **Step 3: Verify tests and complexity**

Run: `Rscript -e "devtools::test()"` → `FAIL 0`.
Run: `Rscript -e 'devtools::load_all("."); cat("project_enrollment:", cyclocomp::cyclocomp(project_enrollment), "\n")'`
Expected: complexity < 15. Coverage still 100%.

- [ ] **Step 4: Format and commit**

```bash
air format .
git add R/project-enrollment.R
git commit -m "Refactor project_enrollment into focused helpers"
```

---

## Task 7: Selective `expect_identical()` conversion (optional, lower priority)

`expect_identical()` is only appropriate for **exact** comparisons. Floating-point ratio/enrollment assertions MUST stay `expect_equal()` (with tolerance) — `expect_identical()` would fail on them. This task reduces, but will not eliminate, the finding; residual flags on float comparisons are intentional and correct.

**Files:** Modify the four `tests/testthat/test-*.R` files.

- [ ] **Step 1: Convert exact comparisons to `expect_identical()`**

Rule: if the expected value is an **integer count, logical, character vector, or structural value**, convert to `expect_identical()` and match the type exactly (use integer literals like `3L`). Examples:

```r
# structural / character / counts -> expect_identical
expect_identical(dim(M), c(3L, 3L))
expect_identical(rownames(M), c("K", "1", "2"))
expect_identical(colnames(M), c("K", "1", "2"))
expect_identical(sum(M != 0), 2L)
expect_identical(r$grade_from, c("K", "1"))
expect_identical(r$grade_to, c("1", "2"))
expect_identical(nrow(p), 6L)
expect_identical(unique(p$year), c(2024, 2025))      # numeric-but-exact year labels
```

- [ ] **Step 2: Leave floating-point comparisons as `expect_equal()`**

Keep (and, where missing, add `tolerance = 1e-8`) for all ratio/enrollment value assertions, e.g.:

```r
expect_equal(M["1", "K"], 0.925)
expect_equal(M["2", "1"], 0.96783626)
expect_equal(r$ratio, c(0.925, (88 / 90 + 91 / 95) / 2))
expect_equal(y24$enrollment[y24$grade == "2"], 0.96783626 * 99, tolerance = 1e-6)
```

- [ ] **Step 3: Verify and commit**

Run: `Rscript -e "devtools::test()"` → `FAIL 0` (if an `expect_identical` fails, that comparison was not actually exact — revert it to `expect_equal`).

```bash
air format .
git add tests/
git commit -m "Use expect_identical() for exact test comparisons"
```

---

## Task 8: Re-run goodpractice and final check

- [ ] **Step 1: Re-run `gp()`**

Run: `export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64; Rscript -e 'print(goodpractice::gp("."))'`
Expected resolved: URL, BugReports, line length, anyNA, toString, coverage (100%), function length, cyclomatic complexity, stringsAsFactors. Expected **residual**: the LaTeX/PDF WARNING (environmental, see Appendix) and any `expect_identical` flags on the floating-point comparisons (intentional).

- [ ] **Step 2: Confirm `R CMD check` still clean**

Run: `export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64; Rscript -e 'devtools::check(error_on = "never")' 2>&1 | tail -5`
Expected: `0 errors | 0 warnings | 0 notes`.

- [ ] **Step 3: Commit any final formatting**

```bash
air format .
git add -A
git commit -m "Finalize goodpractice remediation" || echo "nothing to commit"
```

---

## Appendix — Tier 3 (notes, not code changes)

**Finding 11 — R CMD check LaTeX/PDF WARNING.** Caused by no `pdflatex` in this environment (`devtools::check()` is 0/0/0 because it skips the PDF manual; the Rd checks all pass). Options: (a) `Rscript -e 'tinytex::install_tinytex()'` so the manual builds and the warning clears under `gp()`; (b) accept it as environmental. No package code change is warranted.

**Aside — tabs vs. default lintr (not a goodpractice finding).** `goodpractice` excludes the indentation/whitespace linters, so the `air` tab style is fine for `gp()`. But a raw `lintr::lint_package()` (e.g. in a future lintr-based CI) reports ~968 "use spaces not tabs" lints. If that becomes relevant, either add a `.lintr` config disabling `indentation_linter`/`whitespace_linter`, or switch `air` to space indentation. Deliberately out of scope here.

---

## Self-Review

- **Coverage of findings:** every numbered `gp()` finding maps to a task (1–2 → Task 1; 3–5 → Task 2; 6 → Task 4; 7–8 → Tasks 5–6; 9 → Tasks 1+3; 10 → Task 7; 11 → Appendix).
- **Behavior preservation:** Tasks 2, 3, 5, 6 are behavior-neutral (`anyNA`/`toString` are equivalent; `stringsAsFactors` removal is covered by the `R >= 4.0` default; refactors keep identical logic). Each task re-runs the full suite and snapshots.
- **Ordering/dependencies:** Task 1 (R >= 4.0) precedes Task 3 (stringsAsFactors removal). Coverage (Task 4) precedes the refactors (5–6), which preserve the defensive branches, so coverage stays 100%. The refactored function bodies already use `anyNA`/`toString` and omit `stringsAsFactors`, consistent with Tasks 2–3.
- **Type consistency:** new internal helpers use snake_case; matrices keep grade dimnames; output frames keep `grade_from`/`grade_to`/`ratio` and `year`/`grade`/`enrollment`.
- **Honest residuals:** the LaTeX warning (environmental) and float `expect_identical` flags are documented as expected to remain.
