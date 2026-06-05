# gpr Enrollment Projection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `gpr` R package: compute grade progression ratios from historical grade-level enrollment and project future enrollment via a Leslie matrix, with a tidy long-data-frame interface and minimal dependencies.

**Architecture:** Three exported functions — `progression_ratios()`, `leslie_matrix()`, `project_enrollment()` — backed by small internal helpers. The projection engine is a Leslie matrix (progression ratios on the sub-diagonal, entry-grade row zero); projection is one matrix–vector multiply per projected year with the exogenous entry grade overwritten each step. One series per call; aggregation level is the caller's concern.

**Tech Stack:** Base R + `stats` (Imports). Dev/test: roxygen2, testthat 3e, knitr/rmarkdown (Suggests). MIT license.

Reference spec: `docs/superpowers/specs/2026-06-04-gpr-enrollment-projection-design.md`

---

## File Structure

**Source (`R/`)**
- `R/gpr-package.R` — package-level roxygen doc (`"_PACKAGE"`).
- `R/utils.R` — internal helpers: `check_columns()`, `resolve_grade_order()`, `chain_order()`, `summarise_ratios()`, `as_base_vector()`, `as_entry_vector()`.
- `R/progression-ratios.R` — `progression_ratios()` (exported).
- `R/leslie-matrix.R` — `leslie_matrix()` (exported).
- `R/project-enrollment.R` — `project_enrollment()` (exported).

**Tests (`tests/`)**
- `tests/testthat.R` — test runner.
- `tests/testthat/helper-gpr.R` — shared hand-computable fixtures.
- `tests/testthat/test-utils.R`
- `tests/testthat/test-progression-ratios.R`
- `tests/testthat/test-leslie-matrix.R`
- `tests/testthat/test-project-enrollment.R`

**Metadata / docs**
- `DESCRIPTION`, `NAMESPACE` (roxygen-generated), `LICENSE`, `LICENSE.md`
- `.gitignore`, `.Rbuildignore`
- `README.md`
- `vignettes/gpr.Rmd`
- `man/` (roxygen-generated)

**The canonical fixture** (grades K, 1, 2; years 2021–2023), used across tests:

| year | grade | enrollment |
|------|-------|-----------|
| 2021 | K | 100 |
| 2021 | 1 | 90 |
| 2021 | 2 | 80 |
| 2022 | K | 110 |
| 2022 | 1 | 95 |
| 2022 | 2 | 88 |
| 2023 | K | 120 |
| 2023 | 1 | 99 |
| 2023 | 2 | 91 |

Hand-computed transition ratios (destination grade fed by grade below, one year earlier):
- Grade 1 ← K: 2022 = 95/100 = 0.95; 2023 = 99/110 = 0.9. Mean = **0.925**. Geometric = sqrt(0.855) = **0.9246621**. Last = **0.9**.
- Grade 2 ← 1: 2022 = 88/90 = 0.97777778; 2023 = 91/95 = 0.95789474. Mean = **0.96783626**. Last = **0.95789474**.

---

## Task 1: Package scaffold

**Files:**
- Create: `DESCRIPTION`, `LICENSE`, `LICENSE.md`, `.gitignore`, `.Rbuildignore`, `R/gpr-package.R`, `tests/testthat.R`

- [ ] **Step 1: Write `DESCRIPTION`**

```
Package: gpr
Title: Project School Enrollment with Grade Progression Ratios
Version: 0.0.0.9000
Authors@R:
    person("Rory", "Lawless", email = "rory@rorylawless.com",
           role = c("aut", "cre"))
Description: Projects school enrollment using the cohort survival / grade
    progression ratio method, implemented with a Leslie matrix. Works at any
    level of aggregation (school, district, local education agency, city-wide)
    and any number of grades. Provides functions to compute progression ratios
    from historical grade-level enrollment and to project future enrollment
    forward an arbitrary horizon.
License: MIT + file LICENSE
Encoding: UTF-8
Roxygen: list(markdown = TRUE)
RoxygenNote: 7.3.2
Imports:
    stats
Suggests:
    knitr,
    rmarkdown,
    testthat (>= 3.0.0)
Config/testthat/edition: 3
VignetteBuilder: knitr
```

- [ ] **Step 2: Write `LICENSE`**

```
YEAR: 2026
COPYRIGHT HOLDER: Rory Lawless
```

- [ ] **Step 3: Write `LICENSE.md`**

```
# MIT License

Copyright (c) 2026 Rory Lawless

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 4: Write `.gitignore`**

```
.Rproj.user
.Rhistory
.RData
.Ruserdata
*.Rproj
*.tar.gz
..Rcheck/
inst/doc
```

- [ ] **Step 5: Write `.Rbuildignore`**

```
^docs$
^LICENSE\.md$
^\.gitignore$
^.*\.Rproj$
^\.Rproj\.user$
```

- [ ] **Step 6: Write `R/gpr-package.R`**

```r
#' @keywords internal
"_PACKAGE"
```

- [ ] **Step 7: Write `tests/testthat.R`**

```r
library(testthat)
library(gpr)

test_check("gpr")
```

- [ ] **Step 8: Generate docs/NAMESPACE and verify the package loads**

Run: `R -q -e 'roxygen2::roxygenise(); devtools::load_all("."); cat("LOADED OK\n")'`
Expected: writes `NAMESPACE` and `man/`, prints `LOADED OK` with no errors. (`NAMESPACE` will only contain the autogen comment for now — that's expected.)

- [ ] **Step 9: Commit**

```bash
git add DESCRIPTION LICENSE LICENSE.md .gitignore .Rbuildignore R/ NAMESPACE man/ tests/testthat.R
git commit -m "Scaffold gpr package"
```

---

## Task 2: Internal utilities

**Files:**
- Create: `R/utils.R`
- Test: `tests/testthat/test-utils.R`

- [ ] **Step 1: Write the failing tests**

`tests/testthat/test-utils.R`:

```r
test_that("check_columns errors on missing columns", {
  df <- data.frame(a = 1, b = 2)
  expect_error(check_columns(df, c("a", "c"), "df"), "missing required column")
})

test_that("resolve_grade_order uses factor levels", {
  g <- factor(c("1", "K", "2"), levels = c("K", "1", "2"))
  expect_equal(resolve_grade_order(g), c("K", "1", "2"))
})

test_that("resolve_grade_order sorts numeric grades numerically", {
  g <- c(10, 2, 1)
  expect_equal(resolve_grade_order(g), c("1", "2", "10"))
})

test_that("resolve_grade_order honours explicit grade_order", {
  g <- c("1", "K", "2")
  expect_equal(resolve_grade_order(g, grade_order = c("K", "1", "2")),
               c("K", "1", "2"))
})

test_that("resolve_grade_order errors when grade_order omits a grade", {
  g <- c("K", "1", "2")
  expect_error(resolve_grade_order(g, grade_order = c("K", "1")),
               "missing grade")
})

test_that("resolve_grade_order warns when guessing character order", {
  g <- c("K", "1", "2")
  expect_warning(resolve_grade_order(g), "guessed")
})

test_that("chain_order reconstructs the grade sequence", {
  expect_equal(chain_order(c("K", "1"), c("1", "2")), c("K", "1", "2"))
})

test_that("chain_order errors on ambiguous entry grade", {
  expect_error(chain_order(c("K", "9"), c("1", "2")), "unique entry grade")
})

test_that("summarise_ratios computes each method", {
  R <- matrix(c(0.95, 0.9), nrow = 1, dimnames = list("1", c("2022", "2023")))
  expect_equal(summarise_ratios(R, "mean"), c("1" = 0.925))
  expect_equal(summarise_ratios(R, "last"), c("1" = 0.9))
  expect_equal(summarise_ratios(R, "median"), c("1" = 0.925))
  expect_equal(summarise_ratios(R, "geometric"), c("1" = sqrt(0.855)))
  expect_equal(summarise_ratios(R, "weighted", weights = c(2, 1)),
               c("1" = (0.9 * 2 + 0.95 * 1) / 3))
})

test_that("summarise_ratios weighted errors on length mismatch", {
  R <- matrix(c(0.95, 0.9), nrow = 1, dimnames = list("1", c("2022", "2023")))
  expect_error(summarise_ratios(R, "weighted", weights = c(1, 2, 3)),
               "must equal number of transition years")
})

test_that("as_base_vector aligns df to grade order and derives year", {
  df <- data.frame(year = 2023, grade = c("2", "K", "1"),
                   enrollment = c(91, 120, 99))
  res <- as_base_vector(df, c("K", "1", "2"))
  expect_equal(res$vector, c(K = 120, `1` = 99, `2` = 91))
  expect_equal(res$year, 2023)
})

test_that("as_base_vector accepts a named numeric vector", {
  v <- c(K = 120, `1` = 99, `2` = 91)
  res <- as_base_vector(v, c("K", "1", "2"))
  expect_equal(res$vector, v)
  expect_null(res$year)
})

test_that("as_base_vector errors on missing grade", {
  v <- c(K = 120, `1` = 99)
  expect_error(as_base_vector(v, c("K", "1", "2")), "missing enrollment")
})

test_that("as_entry_vector validates length", {
  expect_equal(as_entry_vector(c(130, 140), 2), c(130, 140))
  expect_error(as_entry_vector(c(130, 140), 3), "must equal `horizon`")
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `R -q -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-utils.R")'`
Expected: FAIL — `could not find function "check_columns"` (etc.).

- [ ] **Step 3: Write `R/utils.R`**

```r
# Internal helpers. Not exported.

check_columns <- function(data, cols, arg = "data") {
  missing <- setdiff(cols, names(data))
  if (length(missing)) {
    stop(sprintf("`%s` is missing required column(s): %s", arg,
                 paste(missing, collapse = ", ")), call. = FALSE)
  }
  invisible(data)
}

# Resolve grades to a low -> high character ordering.
resolve_grade_order <- function(grade, grade_order = NULL) {
  u <- unique(as.character(grade))
  if (!is.null(grade_order)) {
    grade_order <- as.character(grade_order)
    missing <- setdiff(u, grade_order)
    if (length(missing)) {
      stop("`grade_order` is missing grade(s): ",
           paste(missing, collapse = ", "), call. = FALSE)
    }
    return(grade_order[grade_order %in% u])
  }
  if (is.factor(grade)) {
    lev <- levels(grade)
    return(lev[lev %in% u])
  }
  num <- suppressWarnings(as.numeric(u))
  if (!any(is.na(num))) {
    return(u[order(num)])
  }
  warning("Grade order guessed by sorting labels alphabetically; ",
          "pass `grade_order` or a factor `grade` to set it explicitly.",
          call. = FALSE)
  sort(u)
}

# Reconstruct grade order from from/to transition pairs (linear chain).
chain_order <- function(from, to) {
  from <- as.character(from)
  to <- as.character(to)
  entry <- setdiff(from, to)
  if (length(entry) != 1) {
    stop("Could not determine a unique entry grade from `ratios`; ",
         "pass `grade_order` explicitly.", call. = FALSE)
  }
  nxt <- stats::setNames(to, from)
  order <- entry
  cur <- entry
  while (cur %in% names(nxt)) {
    cur <- nxt[[cur]]
    order <- c(order, cur)
  }
  order
}

# Collapse a (grades x transition-years) ratio matrix to one ratio per grade.
summarise_ratios <- function(R, method, weights = NULL) {
  apply(R, 1, function(x) {
    switch(method,
      mean = mean(x, na.rm = TRUE),
      median = stats::median(x, na.rm = TRUE),
      geometric = exp(mean(log(x), na.rm = TRUE)),
      last = x[length(x)],
      weighted = {
        if (is.null(weights)) {
          stop("`weights` is required for method = 'weighted'.", call. = FALSE)
        }
        if (length(weights) != length(x)) {
          stop(sprintf(
            paste0("`weights` length (%d) must equal number of transition ",
                   "years used (%d)."),
            length(weights), length(x)), call. = FALSE)
        }
        # weights are aligned most-recent -> oldest; x runs oldest -> newest.
        stats::weighted.mean(x, w = rev(weights), na.rm = TRUE)
      }
    )
  })
}

# Coerce `base` to a named numeric vector ordered by `go`; derive year if present.
as_base_vector <- function(base, go) {
  year <- NULL
  if (is.data.frame(base)) {
    check_columns(base, c("grade", "enrollment"), "base")
    if ("year" %in% names(base)) {
      uy <- unique(base$year)
      if (length(uy) == 1) {
        y <- suppressWarnings(as.numeric(as.character(uy)))
        if (!is.na(y)) year <- y
      }
    }
    v <- stats::setNames(as.numeric(base$enrollment), as.character(base$grade))
  } else if (is.numeric(base) && !is.null(names(base))) {
    v <- base
  } else {
    stop("`base` must be a data frame (grade, enrollment) or a named ",
         "numeric vector.", call. = FALSE)
  }
  missing <- setdiff(go, names(v))
  if (length(missing)) {
    stop("`base` is missing enrollment for grade(s): ",
         paste(missing, collapse = ", "), call. = FALSE)
  }
  list(vector = v[go], year = year)
}

# Coerce `entry` to a numeric vector of length `horizon`.
as_entry_vector <- function(entry, horizon) {
  if (is.data.frame(entry)) {
    valcol <- intersect(c("enrollment", "value"), names(entry))
    if (length(valcol) == 0) {
      stop("`entry` data frame must have an 'enrollment' or 'value' column.",
           call. = FALSE)
    }
    vals <- as.numeric(entry[[valcol[1]]])
  } else if (is.numeric(entry)) {
    vals <- entry
  } else {
    stop("`entry` must be a numeric vector or a data frame with a value column.",
         call. = FALSE)
  }
  if (length(vals) != horizon) {
    stop(sprintf("`entry` length (%d) must equal `horizon` (%d).",
                 length(vals), horizon), call. = FALSE)
  }
  vals
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `R -q -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-utils.R")'`
Expected: PASS (all expectations green).

- [ ] **Step 5: Commit**

```bash
git add R/utils.R tests/testthat/test-utils.R
git commit -m "Add internal utility helpers"
```

---

## Task 3: progression_ratios()

**Files:**
- Create: `R/progression-ratios.R`, `tests/testthat/helper-gpr.R`
- Test: `tests/testthat/test-progression-ratios.R`

- [ ] **Step 1: Write the shared fixture helper**

`tests/testthat/helper-gpr.R`:

```r
# Canonical K-2, 2021-2023 fixture used across tests. Grade is a factor so
# ordering is unambiguous.
gpr_fixture <- function() {
  data.frame(
    year = rep(c(2021, 2022, 2023), each = 3),
    grade = factor(rep(c("K", "1", "2"), times = 3),
                   levels = c("K", "1", "2")),
    enrollment = c(100, 90, 80, 110, 95, 88, 120, 99, 91),
    stringsAsFactors = FALSE
  )
}
```

- [ ] **Step 2: Write the failing tests**

`tests/testthat/test-progression-ratios.R`:

```r
test_that("mean is the default method", {
  r <- progression_ratios(gpr_fixture())
  expect_equal(r$grade_from, c("K", "1"))
  expect_equal(r$grade_to, c("1", "2"))
  expect_equal(r$ratio, c(0.925, (88 / 90 + 91 / 95) / 2))
})

test_that("geometric, median, and last methods work", {
  fx <- gpr_fixture()
  expect_equal(progression_ratios(fx, method = "geometric")$ratio[1],
               sqrt(0.95 * 0.9))
  expect_equal(progression_ratios(fx, method = "median")$ratio[1], 0.925)
  expect_equal(progression_ratios(fx, method = "last")$ratio,
               c(0.9, 91 / 95))
})

test_that("weighted method uses most-recent-first weights", {
  r <- progression_ratios(gpr_fixture(), method = "weighted",
                          weights = c(2, 1))
  expect_equal(r$ratio[1], (0.9 * 2 + 0.95 * 1) / 3)
})

test_that("n_years restricts to the most recent transitions", {
  r <- progression_ratios(gpr_fixture(), n_years = 1)
  expect_equal(r$ratio, c(0.9, 91 / 95))
})

test_that("column names are overridable", {
  fx <- gpr_fixture()
  names(fx) <- c("yr", "gr", "n")
  r <- progression_ratios(fx, year = "yr", grade = "gr", enrollment = "n")
  expect_equal(r$ratio[1], 0.925)
})

test_that("non-numeric enrollment is rejected", {
  fx <- gpr_fixture()
  fx$enrollment <- as.character(fx$enrollment)
  expect_error(progression_ratios(fx), "must be numeric")
})

test_that("missing columns are reported", {
  expect_error(progression_ratios(data.frame(a = 1)),
               "missing required column")
})

test_that("non-consecutive years yield no transitions", {
  fx <- gpr_fixture()
  fx <- fx[fx$year != 2022, ]  # leaves 2021 and 2023 -> gap
  expect_error(progression_ratios(fx), "consecutive year")
})

test_that("duplicate grade-year rows are rejected", {
  fx <- rbind(gpr_fixture(), gpr_fixture()[1, ])
  expect_error(progression_ratios(fx), "[Dd]uplicate")
})
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `R -q -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-progression-ratios.R")'`
Expected: FAIL — `could not find function "progression_ratios"`.

- [ ] **Step 4: Write `R/progression-ratios.R`**

```r
#' Compute grade progression ratios
#'
#' Calculates cohort survival / grade progression ratios from historical
#' grade-level enrollment. For each non-entry grade, the ratio is enrollment in
#' that grade divided by enrollment in the grade below one year earlier,
#' summarised across the available year-to-year transitions.
#'
#' @param data A long data frame of historical enrollment with one row per
#'   grade per year.
#' @param year,grade,enrollment Column names in `data` (character scalars).
#'   Defaults are `"year"`, `"grade"`, `"enrollment"`.
#' @param method How to summarise per-year ratios into one ratio per grade:
#'   `"mean"` (default), `"geometric"`, `"median"`, `"last"` (most recent
#'   transition only), or `"weighted"`.
#' @param n_years Optional. Use only the most recent `n_years` transitions.
#' @param weights For `method = "weighted"`, a numeric vector aligned
#'   most-recent to oldest, with one weight per transition year used.
#' @param grade_order Optional character vector giving the low-to-high grade
#'   order. If omitted, factor levels, numeric ordering, or (with a warning)
#'   alphabetical ordering is used.
#'
#' @return A data frame with columns `grade_from`, `grade_to`, and `ratio`, one
#'   row per non-entry grade.
#' @export
#'
#' @examples
#' history <- data.frame(
#'   year = rep(2021:2023, each = 3),
#'   grade = factor(rep(c("K", "1", "2"), 3), levels = c("K", "1", "2")),
#'   enrollment = c(100, 90, 80, 110, 95, 88, 120, 99, 91)
#' )
#' progression_ratios(history)
progression_ratios <- function(data,
                               year = "year",
                               grade = "grade",
                               enrollment = "enrollment",
                               method = c("mean", "geometric", "median",
                                          "last", "weighted"),
                               n_years = NULL,
                               weights = NULL,
                               grade_order = NULL) {
  method <- match.arg(method)
  check_columns(data, c(year, grade, enrollment), "data")

  gr_raw <- data[[grade]]
  gr <- as.character(gr_raw)
  en <- data[[enrollment]]

  if (!is.numeric(en)) {
    stop("`enrollment` column must be numeric.", call. = FALSE)
  }
  if (any(en < 0, na.rm = TRUE)) {
    stop("`enrollment` must be non-negative.", call. = FALSE)
  }

  go <- resolve_grade_order(gr_raw, grade_order)
  G <- length(go)
  if (G < 2) {
    stop("Need at least 2 grades to compute progression ratios.", call. = FALSE)
  }

  yr_num <- suppressWarnings(as.numeric(as.character(data[[year]])))
  if (any(is.na(yr_num))) {
    stop("`year` must be numeric or coercible to numeric.", call. = FALSE)
  }

  years <- sort(unique(yr_num))
  ri <- match(gr, go)
  ci <- match(yr_num, years)
  if (any(is.na(ri))) {
    stop("Some grades are not in the resolved grade order.", call. = FALSE)
  }
  if (anyDuplicated(cbind(ri, ci))) {
    stop("Duplicate (grade, year) rows in `data`.", call. = FALSE)
  }

  W <- matrix(NA_real_, nrow = G, ncol = length(years),
              dimnames = list(go, as.character(years)))
  W[cbind(ri, ci)] <- en

  trans <- which(diff(years) == 1)
  if (length(trans) == 0) {
    stop("No consecutive year pairs found to form transitions.", call. = FALSE)
  }
  trans_years <- years[trans + 1]

  R <- matrix(NA_real_, nrow = G - 1, ncol = length(trans),
              dimnames = list(go[-1], as.character(trans_years)))
  for (j in seq_along(trans)) {
    t0 <- trans[j]
    t1 <- trans[j] + 1
    R[, j] <- W[2:G, t1] / W[1:(G - 1), t0]
  }

  if (!is.null(n_years)) {
    keep <- utils::tail(seq_len(ncol(R)), n_years)
    R <- R[, keep, drop = FALSE]
  }

  ratio <- summarise_ratios(R, method = method, weights = weights)

  data.frame(
    grade_from = go[-G],
    grade_to = go[-1],
    ratio = unname(ratio),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}
```

Note: this uses `utils::tail`, so add `utils` to `Imports` in `DESCRIPTION` (Step 6).

- [ ] **Step 5: Run tests to verify they pass**

Run: `R -q -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-progression-ratios.R")'`
Expected: PASS.

- [ ] **Step 6: Add `utils` to Imports**

Edit `DESCRIPTION`, changing the `Imports` block to:

```
Imports:
    stats,
    utils
```

- [ ] **Step 7: Commit**

```bash
git add R/progression-ratios.R tests/testthat/test-progression-ratios.R tests/testthat/helper-gpr.R DESCRIPTION
git commit -m "Add progression_ratios()"
```

---

## Task 4: leslie_matrix()

**Files:**
- Create: `R/leslie-matrix.R`
- Test: `tests/testthat/test-leslie-matrix.R`

- [ ] **Step 1: Write the failing tests**

`tests/testthat/test-leslie-matrix.R`:

```r
ratios_fixture <- function() {
  data.frame(
    grade_from = c("K", "1"),
    grade_to = c("1", "2"),
    ratio = c(0.925, 0.96783626),
    stringsAsFactors = FALSE
  )
}

test_that("leslie_matrix builds the correct shape and sub-diagonal", {
  M <- leslie_matrix(ratios_fixture())
  expect_equal(dim(M), c(3, 3))
  expect_equal(rownames(M), c("K", "1", "2"))
  expect_equal(colnames(M), c("K", "1", "2"))
  expect_equal(M["1", "K"], 0.925)
  expect_equal(M["2", "1"], 0.96783626)
})

test_that("leslie_matrix zeroes the entry row and all non-feeder cells", {
  M <- leslie_matrix(ratios_fixture())
  expect_true(all(M["K", ] == 0))
  expect_equal(sum(M != 0), 2)
})

test_that("leslie_matrix honours an explicit grade_order", {
  M <- leslie_matrix(ratios_fixture(), grade_order = c("K", "1", "2"))
  expect_equal(rownames(M), c("K", "1", "2"))
})

test_that("leslie_matrix errors on a missing feeding ratio", {
  r <- ratios_fixture()
  r <- r[r$grade_to != "2", ]
  expect_error(leslie_matrix(r, grade_order = c("K", "1", "2")),
               "Missing progression ratio")
})

test_that("leslie_matrix errors on ambiguous entry grade", {
  r <- data.frame(grade_from = c("K", "9"), grade_to = c("1", "2"),
                  ratio = c(0.9, 0.9), stringsAsFactors = FALSE)
  expect_error(leslie_matrix(r), "unique entry grade")
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `R -q -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-leslie-matrix.R")'`
Expected: FAIL — `could not find function "leslie_matrix"`.

- [ ] **Step 3: Write `R/leslie-matrix.R`**

```r
#' Build the Leslie projection matrix
#'
#' Assembles the Leslie matrix used to project enrollment. Progression ratios
#' are placed on the sub-diagonal (each non-entry grade is fed by the grade
#' below); the entry-grade row is left at zero because entry enrollment is
#' supplied exogenously to [project_enrollment()].
#'
#' @param ratios A data frame with columns `grade_from`, `grade_to`, and
#'   `ratio`, as returned by [progression_ratios()].
#' @param grade_order Optional character vector giving the low-to-high grade
#'   order. If omitted, the order is reconstructed from the transition chain.
#'
#' @return A square numeric matrix with grade dimnames.
#' @export
#'
#' @examples
#' ratios <- data.frame(
#'   grade_from = c("K", "1"),
#'   grade_to = c("1", "2"),
#'   ratio = c(0.92, 0.97)
#' )
#' leslie_matrix(ratios)
leslie_matrix <- function(ratios, grade_order = NULL) {
  check_columns(ratios, c("grade_from", "grade_to", "ratio"), "ratios")
  from <- as.character(ratios$grade_from)
  to <- as.character(ratios$grade_to)

  if (is.null(grade_order)) {
    grade_order <- chain_order(from, to)
  } else {
    grade_order <- as.character(grade_order)
  }
  G <- length(grade_order)
  if (G < 2) {
    stop("Need at least 2 grades to build a Leslie matrix.", call. = FALSE)
  }

  ii <- match(to, grade_order)
  jj <- match(from, grade_order)
  if (any(is.na(ii)) || any(is.na(jj))) {
    stop("`ratios` references a grade not in `grade_order`.", call. = FALSE)
  }

  M <- matrix(0, nrow = G, ncol = G,
              dimnames = list(grade_order, grade_order))
  M[cbind(ii, jj)] <- ratios$ratio

  incoming <- rowSums(M != 0)
  missing_in <- grade_order[-1][incoming[-1] == 0]
  if (length(missing_in)) {
    stop("Missing progression ratio(s) feeding grade(s): ",
         paste(missing_in, collapse = ", "), call. = FALSE)
  }
  M
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `R -q -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-leslie-matrix.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/leslie-matrix.R tests/testthat/test-leslie-matrix.R
git commit -m "Add leslie_matrix()"
```

---

## Task 5: project_enrollment()

**Files:**
- Create: `R/project-enrollment.R`
- Test: `tests/testthat/test-project-enrollment.R`

Hand-computed projection from base year 2023 (K=120, 1=99, 2=91), ratios mean
(g1←K = 0.925, g2←1 = 0.96783626), entry = c(130, 140):
- **2024:** K = 130; grade 1 = 0.925 × 120 = 111; grade 2 = 0.96783626 × 99 = 95.8157897.
- **2025:** K = 140; grade 1 = 0.925 × 130 = 120.25; grade 2 = 0.96783626 × 111 = 107.4298249.

- [ ] **Step 1: Write the failing tests**

`tests/testthat/test-project-enrollment.R`:

```r
proj_ratios <- function() progression_ratios(gpr_fixture())
proj_base <- function() {
  data.frame(grade = c("K", "1", "2"), enrollment = c(120, 99, 91),
             stringsAsFactors = FALSE)
}

test_that("project_enrollment reproduces a hand-computed projection", {
  p <- project_enrollment(proj_base(), proj_ratios(), horizon = 2,
                          entry = c(130, 140), start_year = 2023)
  expect_equal(nrow(p), 6)
  expect_equal(unique(p$year), c(2024, 2025))

  y24 <- p[p$year == 2024, ]
  expect_equal(y24$enrollment[y24$grade == "K"], 130)
  expect_equal(y24$enrollment[y24$grade == "1"], 111)
  expect_equal(y24$enrollment[y24$grade == "2"], 0.96783626 * 99,
               tolerance = 1e-6)

  y25 <- p[p$year == 2025, ]
  expect_equal(y25$enrollment[y25$grade == "K"], 140)
  expect_equal(y25$enrollment[y25$grade == "1"], 120.25)
  expect_equal(y25$enrollment[y25$grade == "2"], 0.96783626 * 111,
               tolerance = 1e-6)
})

test_that("omitting entry holds the entry grade constant with a warning", {
  expect_warning(
    p <- project_enrollment(proj_base(), proj_ratios(), horizon = 2),
    "holding entry grade"
  )
  expect_equal(p$enrollment[p$grade == "K"], c(120, 120))
})

test_that("start_year is derived from a base data frame carrying a year", {
  base <- data.frame(year = 2023, grade = c("K", "1", "2"),
                     enrollment = c(120, 99, 91))
  p <- project_enrollment(base, proj_ratios(), horizon = 1, entry = 130)
  expect_equal(unique(p$year), 2024)
})

test_that("without any year, output years are 1..horizon", {
  p <- project_enrollment(proj_base(), proj_ratios(), horizon = 2,
                          entry = c(130, 140))
  expect_equal(unique(p$year), c(1, 2))
})

test_that("a named numeric vector works as base", {
  v <- c(K = 120, `1` = 99, `2` = 91)
  p <- project_enrollment(v, proj_ratios(), horizon = 1, entry = 130,
                          start_year = 2023)
  expect_equal(p$enrollment[p$grade == "1"], 111)
})

test_that("entry length must equal horizon", {
  expect_error(
    project_enrollment(proj_base(), proj_ratios(), horizon = 3,
                       entry = c(130, 140)),
    "must equal `horizon`"
  )
})

test_that("horizon must be a positive integer", {
  expect_error(
    project_enrollment(proj_base(), proj_ratios(), horizon = 0, entry = 1),
    "positive integer"
  )
  expect_error(
    project_enrollment(proj_base(), proj_ratios(), horizon = 1.5, entry = 1),
    "positive integer"
  )
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `R -q -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-project-enrollment.R")'`
Expected: FAIL — `could not find function "project_enrollment"`.

- [ ] **Step 3: Write `R/project-enrollment.R`**

```r
#' Project enrollment forward
#'
#' Projects grade-level enrollment forward an arbitrary horizon using the grade
#' progression ratio method. Internally builds a Leslie matrix from `ratios`
#' and advances enrollment one year at a time (one matrix-vector product per
#' projected year), overwriting the entry grade with the supplied exogenous
#' value each year.
#'
#' @param base Most recent observed enrollment: either a data frame with columns
#'   `grade` and `enrollment` (optionally `year`), or a named numeric vector
#'   (names are grades).
#' @param ratios A data frame of progression ratios from [progression_ratios()].
#' @param horizon Number of years to project (a positive integer).
#' @param entry Exogenous entry-grade enrollment for each projected year: a
#'   numeric vector of length `horizon`, or a data frame with an `enrollment` or
#'   `value` column. If `NULL`, the entry grade is held constant at its base
#'   value and a warning is issued.
#' @param start_year Optional integer label for the base year; output years run
#'   from `start_year + 1`. If `NULL`, it is derived from a `year` column in
#'   `base` when present, otherwise output years are `1..horizon`.
#'
#' @return A long data frame with columns `year`, `grade`, and `enrollment`,
#'   covering the projected years only.
#' @export
#'
#' @examples
#' history <- data.frame(
#'   year = rep(2021:2023, each = 3),
#'   grade = factor(rep(c("K", "1", "2"), 3), levels = c("K", "1", "2")),
#'   enrollment = c(100, 90, 80, 110, 95, 88, 120, 99, 91)
#' )
#' ratios <- progression_ratios(history)
#' base <- subset(history, year == 2023, c("grade", "enrollment"))
#' project_enrollment(base, ratios, horizon = 3, entry = c(125, 130, 128),
#'                    start_year = 2023)
project_enrollment <- function(base, ratios, horizon, entry = NULL,
                               start_year = NULL) {
  if (!is.numeric(horizon) || length(horizon) != 1 || is.na(horizon) ||
      horizon < 1 || horizon != as.integer(horizon)) {
    stop("`horizon` must be a single positive integer.", call. = FALSE)
  }
  horizon <- as.integer(horizon)

  M <- leslie_matrix(ratios)
  go <- rownames(M)
  entry_grade <- go[1]

  base_info <- as_base_vector(base, go)
  n <- base_info$vector
  if (is.null(start_year)) start_year <- base_info$year

  if (is.null(entry)) {
    warning(sprintf(
      "`entry` not supplied; holding entry grade '%s' constant at %g.",
      entry_grade, n[[entry_grade]]), call. = FALSE)
    entry_vals <- rep(n[[entry_grade]], horizon)
  } else {
    entry_vals <- as_entry_vector(entry, horizon)
  }

  out_years <- if (is.null(start_year)) {
    seq_len(horizon)
  } else {
    start_year + seq_len(horizon)
  }

  result <- vector("list", horizon)
  for (h in seq_len(horizon)) {
    n <- as.vector(M %*% n)
    names(n) <- go
    n[entry_grade] <- entry_vals[h]
    result[[h]] <- data.frame(
      year = out_years[h],
      grade = go,
      enrollment = unname(n),
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  }
  do.call(rbind, result)
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `R -q -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-project-enrollment.R")'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/project-enrollment.R tests/testthat/test-project-enrollment.R
git commit -m "Add project_enrollment()"
```

---

## Task 6: Documentation, NAMESPACE, and full test run

**Files:**
- Modify: `NAMESPACE`, `man/` (regenerated)

- [ ] **Step 1: Regenerate docs and NAMESPACE**

Run: `R -q -e 'roxygen2::roxygenise()'`
Expected: writes `man/progression_ratios.Rd`, `man/leslie_matrix.Rd`, `man/project_enrollment.Rd`, and a `NAMESPACE` exporting all three functions. No errors.

- [ ] **Step 2: Verify NAMESPACE exports the three functions**

Run: `R -q -e 'cat(readLines("NAMESPACE"), sep = "\n")'`
Expected output includes:
```
export(leslie_matrix)
export(progression_ratios)
export(project_enrollment)
```

- [ ] **Step 3: Run the full test suite**

Run: `R -q -e 'devtools::test()'`
Expected: all tests PASS, 0 failures.

- [ ] **Step 4: Commit**

```bash
git add NAMESPACE man/
git commit -m "Generate documentation and NAMESPACE"
```

---

## Task 7: README and vignette

**Files:**
- Create: `README.md`, `vignettes/gpr.Rmd`

- [ ] **Step 1: Write `README.md`**

````markdown
# gpr

<!-- badges: start -->
<!-- badges: end -->

`gpr` projects school enrollment using the cohort survival / grade
progression ratio method, implemented with a Leslie matrix. It works at any
level of aggregation (school, district, LEA, city-wide) and any number of
grades, because it operates on a single grade-by-year enrollment series.

## Installation

```r
# install.packages("pak")
pak::pak("rorylawless/gpr")
```

## Usage

```r
library(gpr)

# Historical grade-level enrollment (long format).
history <- data.frame(
  year = rep(2021:2023, each = 3),
  grade = factor(rep(c("K", "1", "2"), 3), levels = c("K", "1", "2")),
  enrollment = c(100, 90, 80, 110, 95, 88, 120, 99, 91)
)

# 1. Calculate progression ratios.
ratios <- progression_ratios(history, method = "mean")
ratios

# 2. Project forward. The entry grade (K) is supplied exogenously.
base <- subset(history, year == 2023, c("grade", "enrollment"))
projection <- project_enrollment(
  base       = base,
  ratios     = ratios,
  horizon    = 3,
  entry      = c(125, 130, 128),
  start_year = 2023
)
projection
```

Inspect the underlying Leslie matrix at any time:

```r
leslie_matrix(ratios)
```

### Multiple aggregation units

`gpr` projects one series per call. To project many schools or LEAs, split and
map:

```r
projections <- lapply(split(history, history$school), function(df) {
  ratios <- progression_ratios(df)
  base <- subset(df, year == max(df$year), c("grade", "enrollment"))
  project_enrollment(base, ratios, horizon = 3, entry = rep(100, 3))
})
```
````

- [ ] **Step 2: Write `vignettes/gpr.Rmd`**

````markdown
---
title: "Projecting enrollment with gpr"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Projecting enrollment with gpr}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

```{r, include = FALSE}
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
```

```{r setup}
library(gpr)
```

## The grade progression ratio method

The cohort survival / grade progression ratio method projects enrollment by
asking: of the students in grade *g* this year, how many appear in grade *g+1*
next year? That ratio captures net retention, migration, and repetition. `gpr`
estimates these ratios from history and applies them forward with a Leslie
matrix.

## A small district

```{r}
history <- data.frame(
  year = rep(2021:2023, each = 3),
  grade = factor(rep(c("K", "1", "2"), 3), levels = c("K", "1", "2")),
  enrollment = c(100, 90, 80, 110, 95, 88, 120, 99, 91)
)
history
```

## Step 1: progression ratios

```{r}
ratios <- progression_ratios(history, method = "mean")
ratios
```

The ratios sit on the sub-diagonal of the Leslie matrix; the entry-grade row is
zero because entry is supplied exogenously.

```{r}
leslie_matrix(ratios)
```

## Step 2: project forward

The entry grade (kindergarten here) has no feeder grade, so you supply its
future values — for example from a birth-cohort or housing model.

```{r}
base <- subset(history, year == 2023, c("grade", "enrollment"))
projection <- project_enrollment(
  base       = base,
  ratios     = ratios,
  horizon    = 3,
  entry      = c(125, 130, 128),
  start_year = 2023
)
projection
```

## Stitching history and projection

`project_enrollment()` returns projected years only. Combine with history for
plotting:

```{r}
observed <- data.frame(
  year = history$year,
  grade = as.character(history$grade),
  enrollment = history$enrollment
)
combined <- rbind(observed, projection)
head(combined)
```
````

- [ ] **Step 3: Verify the vignette builds**

Run: `R -q -e 'devtools::build_vignettes()'`
Expected: builds `gpr.html` with no errors.

- [ ] **Step 4: Commit**

```bash
git add README.md vignettes/ .gitignore
git commit -m "Add README and getting-started vignette"
```

---

## Task 8: Final R CMD check

- [ ] **Step 1: Run R CMD check**

Run: `R -q -e 'devtools::check()'`
Expected: `0 errors | 0 warnings | 0 notes` (a NOTE about the new-submission/version is acceptable; investigate any others).

- [ ] **Step 2: Fix any check findings**

Address any errors/warnings surfaced (e.g. undocumented arguments, missing
imports in `NAMESPACE`/`DESCRIPTION`). Re-run until clean. Commit fixes:

```bash
git add -A
git commit -m "Resolve R CMD check findings"
```

---

## Self-Review Notes

- **Spec coverage:** `progression_ratios()` (Task 3) covers ratio calculation + all `method`s + `n_years` + `weights` + column overrides; `leslie_matrix()` (Task 4) covers the engine; `project_enrollment()` (Task 5) covers projection, exogenous + held-constant entry, `start_year`, vector/df base. Grade-ordering rules, error handling, dependencies (base + stats + utils), naming, license, README, and vignette are all covered (Tasks 1–8).
- **Resolved decisions honoured:** weights aligned most-recent→oldest with length validation (Task 2/3); `start_year` derived from `base` year when unambiguous else `1..horizon` (Task 5); output excludes base year, with `rbind` shown in README/vignette (Task 7).
- **Type consistency:** ratio frames use `grade_from`/`grade_to`/`ratio` everywhere; projection output uses `year`/`grade`/`enrollment`; Leslie matrices carry grade dimnames in resolved low→high order throughout.
