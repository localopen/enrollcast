# Swing/Recovery Regimes + `projection_matrix()` Rename — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename `leslie_matrix()` → `projection_matrix()`, generalize the projection engine to a per-year step sequence, and add a `swing_schedule()` constructor that models DC school-modernization swing → recovery → normal regimes.

**Architecture:** Five sequential, each-green tasks. (1) pure rename; (2) engine to a per-year *step* sequence (`list(matrix, entry)`), behavior-preserving; (3) `schedule` argument + `check_schedule()` validator on `project_enrollment()`; (4) `swing_schedule()` constructor + helpers; (5) vignette/docs + final CRAN check. Settled design decisions: recovery multipliers compound year-over-year (`diag(c_h)` on current state); the swing API is an optional `schedule` arg on `project_enrollment()` (mutually exclusive with `ratios`/`entry`); the rename is clean (no deprecated alias). Full rationale: `.claude/superpowers/specs/2026-06-20-swing-recovery-and-projection-matrix.md`.

**Tech Stack:** Base R only (Imports: `stats`, `utils`), testthat edition 3, roxygen2 markdown, air formatting.

---

## Invariants for every task

- Run from the package root `/Users/rory/repos/enrollcast` with pandoc exported, or `devtools` can't find it:
  ```bash
  export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
  ```
- After each code change: `Rscript -e "devtools::test()"` reports **FAIL 0**.
- `air format .` (`/Users/rory/.local/bin/air`) before every commit.
- Never hand-edit `man/` or `NAMESPACE`; run `Rscript -e 'devtools::document()'` after roxygen changes.
- Internal helpers: unexported, snake_case, one-line plain comment, cyclomatic complexity < 15 (`Rscript -e 'cyclocomp::cyclocomp_package_dir(".")'`).
- Validation errors use `stop(..., call. = FALSE)`; error/warning messages are snapshot-tested.
- Commit messages end with a blank line then: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- Work on a branch, not `main` (e.g. `git checkout -b swing-recovery`).

---

### Task 1: Rename `leslie_matrix()` → `projection_matrix()` (pure rename)

Behavior-preserving except one error message and the renamed snapshot file.

**Files:**
- Rename: `R/leslie-matrix.R` → `R/projection-matrix.R`
- Rename: `tests/testthat/test-leslie-matrix.R` → `tests/testthat/test-projection-matrix.R`
- Rename: `tests/testthat/_snaps/leslie-matrix.md` → `tests/testthat/_snaps/projection-matrix.md`
- Modify: `R/project-enrollment.R` (caller), `DESCRIPTION`, `vignettes/enrollcast.Rmd`, `README.md`, `CLAUDE.md`

- [ ] **Step 1: Rename source/test/snapshot files with git**

```bash
git mv R/leslie-matrix.R R/projection-matrix.R
git mv tests/testthat/test-leslie-matrix.R tests/testthat/test-projection-matrix.R
git mv tests/testthat/_snaps/leslie-matrix.md tests/testthat/_snaps/projection-matrix.md
```

- [ ] **Step 2: Rename the function, its roxygen, and the one embedded message**

In `R/projection-matrix.R`: change the roxygen title `#' Build the Leslie projection matrix` → `#' Build the projection matrix`; in the description replace `Assembles the Leslie matrix used to project enrollment.` → `Assembles the projection matrix used to advance enrollment.`; change the example call `leslie_matrix(ratios)` → `projection_matrix(ratios)`; rename the function `leslie_matrix <- function(...)` → `projection_matrix <- function(...)`; and change the one message:

```r
  if (G < 2) {
    stop("Need at least 2 grades to build a projection matrix.", call. = FALSE)
  }
```

(Everything else in the body — `chain_order`, `match`, the matrix assembly, the `setdiff` missing-feeder check — is unchanged.)

- [ ] **Step 3: Update the internal caller**

In `R/project-enrollment.R`, change `m <- leslie_matrix(ratios)` → `m <- projection_matrix(ratios)`.

- [ ] **Step 4: Update the test file calls**

In `tests/testthat/test-projection-matrix.R`, replace every `leslie_matrix(` with `projection_matrix(`. (The test titles still saying "leslie_matrix ..." may stay or be reworded; if reworded, snapshots regenerate — handle in Step 6.)

- [ ] **Step 5: Update docs/metadata**

- `DESCRIPTION` line 8: `implemented with a Leslie matrix` → `implemented as a matrix projection`.
- `vignettes/enrollcast.Rmd`: change the `leslie_matrix(ratios)` call to `projection_matrix(ratios)` and reword the surrounding sentence ("The ratios sit on the sub-diagonal of the projection matrix...").
- `README.md`: prose at lines 7 and 46 ("Leslie matrix" → "projection matrix"), and the **live code call at line 49** `leslie_matrix(ratios)` → `projection_matrix(ratios)`.
- `CLAUDE.md`: in "The method" step 2 rename `leslie_matrix()` → `projection_matrix()`; in the Layout block rename `R/leslie-matrix.R` → `R/projection-matrix.R`.

- [ ] **Step 6: Regenerate docs, run tests, accept the renamed snapshots**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e 'devtools::document()'
Rscript -e "devtools::test()"
```

The `projection-matrix.md` snapshot will mismatch because the echoed `Code` lines now read `projection_matrix(...)` and one message changed. Review then accept:

```bash
# Inspect NON-INTERACTIVELY: read tests/testthat/_snaps/projection-matrix.new.md (or git diff the _snaps dir)
# to confirm only Code echoes + the one 2-grade message changed. Do NOT run testthat::snapshot_review() (interactive, hangs headless).
Rscript -e 'testthat::snapshot_accept()'
Rscript -e "devtools::test()"              # expect FAIL 0
```

Verify exactly one *message text* changed (the 2-grade one); the other four error messages must be byte-identical:

```bash
grep -c "projection matrix" tests/testthat/_snaps/projection-matrix.md   # expect 1 message line (+ Code echoes)
grep -rn "leslie" R/ tests/ vignettes/ DESCRIPTION README.md CLAUDE.md    # expect no output
```

- [ ] **Step 7: Format and commit**

```bash
/Users/rory/.local/bin/air format .
git add -A
git commit -m "Rename leslie_matrix() to projection_matrix()"
```

---

### Task 2: Generalize the engine to a per-year step sequence

`run_projection()` advances through a list of steps `list(matrix, entry)`; `project_enrollment()` builds a constant schedule internally. Entry stays an **overwrite** (not additive) so `NA`/`NaN`/`Inf` behavior is byte-identical. Public signature unchanged this task.

**Files:**
- Modify: `R/project-enrollment.R:26-40` (`run_projection`), `R/project-enrollment.R:80-102` (`project_enrollment` internals)
- Test: `tests/testthat/test-project-enrollment.R`

- [ ] **Step 1: Write the failing NA-repair guard test**

Append to `tests/testthat/test-project-enrollment.R`:

```r
test_that("entry grade is overwritten even when base carries NA", {
  v <- c(K = NA_real_, `1` = 99, `2` = 91)
  p <- project_enrollment(v, proj_ratios(), horizon = 1, entry = 130)
  expect_equal(p$enrollment[p$grade == "K"], 130)
})
```

- [ ] **Step 2: Run it against the current engine to confirm it passes (preservation baseline)**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e "devtools::test(filter = 'project-enrollment')"
```

Expected: PASS (current overwrite engine already repairs entry). This test now *locks* that behavior so the refactor can't regress it.

- [ ] **Step 3: Replace `run_projection()` with the step-sequence form**

Replace the `run_projection` definition (`R/project-enrollment.R:25-40`, comment included) with:

```r
# Advance enrollment through a per-year sequence of projection steps.
run_projection <- function(steps, base_vec, out_years) {
  go <- names(base_vec)
  entry_grade <- go[1]
  n <- base_vec
  out <- matrix(NA_real_, nrow = length(go), ncol = length(out_years))
  for (h in seq_along(out_years)) {
    n <- drop(steps[[h]]$matrix %*% n)
    if (!is.null(steps[[h]]$entry)) {
      n[entry_grade] <- steps[[h]]$entry
    }
    out[, h] <- n
  }
  data.frame(
    year = rep(out_years, each = length(go)),
    grade = rep(go, times = length(out_years)),
    enrollment = as.vector(out)
  )
}
```

- [ ] **Step 4: Build a constant schedule in `project_enrollment()`**

In `project_enrollment()` (`R/project-enrollment.R`), replace the body from `entry_vals <- entry_values(...)` through the final `run_projection(...)` call with:

```r
  entry_vals <- entry_values(entry, horizon, n, entry_grade)
  steps <- lapply(seq_len(horizon), function(h) {
    list(matrix = m, entry = entry_vals[[h]])
  })
  out_years <- if (is.null(start_year)) {
    seq_len(horizon)
  } else {
    start_year + seq_len(horizon)
  }
  run_projection(steps, n, out_years)
```

(`n` is the named base vector from `as_base_vector(base, go)`; `entry_vals[[h]]` is a length-1 numeric, possibly `NA`, never `NULL`, so the GPR path always overwrites — identical to before.)

- [ ] **Step 5: Run the full suite**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e "devtools::test()"
```

Expected: FAIL 0, no snapshot changes (output and messages unchanged). The hand-computed projection test and the new NA-repair test both pass.

- [ ] **Step 6: Format and commit**

```bash
/Users/rory/.local/bin/air format .
git add R/project-enrollment.R tests/testthat/test-project-enrollment.R
git commit -m "Generalize projection engine to a per-year step sequence"
```

---

### Task 3: Add the `schedule` argument and `check_schedule()`

`project_enrollment()` becomes dual-mode: `ratios`/`entry` (default) or a prebuilt `schedule` (mutually exclusive).

**Files:**
- Modify: `R/project-enrollment.R` (add `check_step`, `check_schedule`; extend `project_enrollment`)
- Test: `tests/testthat/test-project-enrollment.R`, `tests/testthat/test-utils.R`

- [ ] **Step 1: Write failing tests for the schedule path**

Append to `tests/testthat/test-project-enrollment.R`:

```r
test_that("a constant schedule reproduces the ratios path", {
  r <- proj_ratios()
  m <- projection_matrix(r)
  entry <- c(130, 140)
  sched <- lapply(entry, function(e) list(matrix = m, entry = e))
  p_sched <- project_enrollment(proj_base(), schedule = sched, start_year = 2023)
  p_ratio <- project_enrollment(proj_base(), r, horizon = 2, entry = entry,
                                start_year = 2023)
  expect_equal(p_sched, p_ratio)
})

test_that("schedule path realigns a reordered base", {
  m <- projection_matrix(proj_ratios())
  sched <- list(list(matrix = m, entry = 130))
  reordered <- c(`2` = 91, K = 120, `1` = 99)
  p <- project_enrollment(reordered, schedule = sched, start_year = 2023)
  expect_equal(p$enrollment[p$grade == "1"], 111) # 0.925 * 120, correctly aligned
})

test_that("hand-built identity+diag schedule runs", {
  m <- projection_matrix(proj_ratios())
  ident <- diag(3)
  dimnames(ident) <- dimnames(m)
  scale <- diag(rep(1.1, 3))
  dimnames(scale) <- dimnames(m)
  sched <- list(
    list(matrix = ident, entry = NULL),
    list(matrix = scale, entry = NULL)
  )
  p <- project_enrollment(c(K = 80, `1` = 66, `2` = 60), schedule = sched)
  expect_equal(p$enrollment[p$year == 1 & p$grade == "K"], 80)
  expect_equal(p$enrollment[p$year == 2 & p$grade == "K"], 88)
})

test_that("schedule and ratios are mutually exclusive", {
  m <- projection_matrix(proj_ratios())
  sched <- list(list(matrix = m, entry = 130))
  expect_snapshot(
    project_enrollment(proj_base(), ratios = proj_ratios(), schedule = sched),
    error = TRUE
  )
})

test_that("project_enrollment needs ratios or a schedule", {
  expect_snapshot(project_enrollment(proj_base(), horizon = 2), error = TRUE)
})

test_that("horizon must match schedule length when both are given", {
  m <- projection_matrix(proj_ratios())
  sched <- list(list(matrix = m, entry = 130))
  expect_snapshot(
    project_enrollment(proj_base(), schedule = sched, horizon = 2),
    error = TRUE
  )
})
```

Append to `tests/testthat/test-utils.R`:

```r
test_that("check_schedule accepts a valid schedule and returns grade order", {
  m <- projection_matrix(
    data.frame(grade_from = "K", grade_to = "1", ratio = 0.9)
  )
  expect_identical(
    check_schedule(list(list(matrix = m, entry = 1), list(matrix = m, entry = NULL))),
    c("K", "1")
  )
})

test_that("check_schedule rejects malformed schedules", {
  m <- projection_matrix(
    data.frame(grade_from = "K", grade_to = "1", ratio = 0.9)
  )
  expect_snapshot(check_schedule(list()), error = TRUE)
  expect_snapshot(check_schedule(list(list(entry = 1))), error = TRUE)
  expect_snapshot(check_schedule(list(list(matrix = m[, 1, drop = FALSE]))), error = TRUE)
  bad <- m
  colnames(bad) <- c("X", "Y")
  expect_snapshot(check_schedule(list(list(matrix = bad))), error = TRUE)
  m2 <- m
  dimnames(m2) <- list(c("1", "K"), c("1", "K"))
  expect_snapshot(check_schedule(list(list(matrix = m), list(matrix = m2))), error = TRUE)
  expect_snapshot(check_schedule(list(list(matrix = m, entry = c(1, 2)))), error = TRUE)
})
```

- [ ] **Step 2: Run to confirm failure**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e "devtools::test()"
```

Expected: failures — `check_schedule` undefined and `schedule` arg unsupported.

- [ ] **Step 3: Add the schedule validators**

Add to `R/project-enrollment.R` (above `run_projection`):

```r
# Validate one projection step; return its grade order.
check_step <- function(step) {
  if (!is.list(step) || is.null(step$matrix)) {
    stop("Each `schedule` step must be a list with a `matrix` element.", call. = FALSE)
  }
  m <- step$matrix
  if (!is.matrix(m) || nrow(m) != ncol(m)) {
    stop("Each `schedule` step `matrix` must be square.", call. = FALSE)
  }
  if (is.null(rownames(m)) || !identical(rownames(m), colnames(m))) {
    stop(
      "Each `schedule` step `matrix` must have identical row and column dimnames.",
      call. = FALSE
    )
  }
  if (!is.null(step$entry) && !(is.numeric(step$entry) && length(step$entry) == 1)) {
    stop("Each `schedule` step `entry` must be NULL or a single number.", call. = FALSE)
  }
  rownames(m)
}

# Validate a user-supplied projection schedule; return its grade order.
check_schedule <- function(schedule) {
  if (!is.list(schedule) || length(schedule) == 0) {
    stop("`schedule` must be a non-empty list of projection steps.", call. = FALSE)
  }
  orders <- lapply(schedule, check_step)
  go <- orders[[1]]
  if (!all(vapply(orders, identical, logical(1), go))) {
    stop(
      "All `schedule` step matrices must share the same grade dimnames in the same order.",
      call. = FALSE
    )
  }
  go
}
```

- [ ] **Step 4: Make `project_enrollment()` dual-mode**

Replace the whole `project_enrollment` definition body (keep the roxygen for now; updated in Step 6) with:

```r
project_enrollment <- function(
  base,
  ratios = NULL,
  horizon = NULL,
  entry = NULL,
  schedule = NULL,
  start_year = NULL
) {
  if (!is.null(schedule)) {
    if (!is.null(ratios) || !is.null(entry)) {
      stop("Supply either `ratios`/`entry` or `schedule`, not both.", call. = FALSE)
    }
    go <- check_schedule(schedule)
    if (is.null(horizon)) {
      horizon <- length(schedule)
    } else if (horizon != length(schedule)) {
      stop(
        "`horizon` must equal the schedule length when `schedule` is supplied.",
        call. = FALSE
      )
    }
    n <- as_base_vector(base, go)
    steps <- schedule
  } else {
    if (is.null(ratios)) {
      stop("Supply `ratios` (or a `schedule`).", call. = FALSE)
    }
    horizon <- check_horizon(horizon)
    m <- projection_matrix(ratios)
    go <- rownames(m)
    n <- as_base_vector(base, go)
    entry_vals <- entry_values(entry, horizon, n, go[1])
    steps <- lapply(seq_len(horizon), function(h) {
      list(matrix = m, entry = entry_vals[[h]])
    })
  }
  if (is.null(start_year)) {
    start_year <- base_year(base)
  }
  out_years <- if (is.null(start_year)) {
    seq_len(horizon)
  } else {
    start_year + seq_len(horizon)
  }
  run_projection(steps, n, out_years)
}
```

- [ ] **Step 5: Run tests; accept new error snapshots**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e "devtools::test()"
# Inspect NON-INTERACTIVELY: read tests/testthat/_snaps/*.new.md (or git diff the _snaps dir) to confirm the
# new check_schedule / dual-mode messages. Do NOT run testthat::snapshot_review() (interactive, hangs headless).
Rscript -e 'testthat::snapshot_accept()'
Rscript -e "devtools::test()"              # FAIL 0
Rscript -e 'cyclocomp::cyclocomp_package_dir(".")'  # every fn < 15
```

- [ ] **Step 6: Update roxygen for the new argument**

In `R/project-enrollment.R` roxygen: mark `ratios` as optional, and add:

```r
#' @param schedule Optional prebuilt projection schedule: a list of per-year
#'   steps, each `list(matrix = <square projection matrix>, entry = <NULL or a
#'   single number>)`, as produced by [swing_schedule()]. When supplied,
#'   `ratios` and `entry` must be `NULL` and `horizon` defaults to the schedule
#'   length. Step matrices must share identical grade dimnames, which determine
#'   the grade order `base` is aligned to.
```

Then:

```bash
Rscript -e 'devtools::document()'
Rscript -e "devtools::test()"
```

- [ ] **Step 7: Format and commit**

```bash
/Users/rory/.local/bin/air format .
git add -A
git commit -m "Add schedule argument and validator to project_enrollment()"
```

---

### Task 4: Add the `swing_schedule()` constructor

**Files:**
- Create: `R/swing-schedule.R`
- Test: `tests/testthat/test-swing-schedule.R`

- [ ] **Step 1: Write the failing tests**

Create `tests/testthat/test-swing-schedule.R`:

```r
ss_ratios <- function() {
  data.frame(
    grade_from = c("K", "1"),
    grade_to = c("1", "2"),
    ratio = c(0.925, 0.96783626)
  )
}

test_that("swing_schedule lays out swing, recovery, and normal regimes", {
  s <- swing_schedule(ss_ratios(), horizon = 6, swing_years = 2,
                      recovery = c(1.10, 1.10, 1.05), entry = 130)
  expect_length(s, 6)
  expect_identical(s[[1]]$matrix, s[[2]]$matrix)          # identity, repeated
  expect_equal(diag(s[[1]]$matrix), c(K = 1, `1` = 1, `2` = 1))
  expect_null(s[[1]]$entry)
  expect_equal(diag(s[[3]]$matrix), c(K = 1.10, `1` = 1.10, `2` = 1.10))
  expect_null(s[[4]]$entry)
  expect_equal(s[[6]]$entry, 130)                          # normal year carries entry
})

test_that("swing_schedule reproduces the worked trajectory", {
  s <- swing_schedule(ss_ratios(), horizon = 6, swing_years = 2,
                      recovery = c(1.10, 1.10, 1.05), entry = 130)
  p <- project_enrollment(c(K = 80, `1` = 66, `2` = 60), schedule = s)
  k <- p$enrollment[p$grade == "K"]
  expect_equal(k, c(80, 80, 88, 96.8, 101.64, 130))
  expect_equal(p$enrollment[p$year == 6 & p$grade == "1"], 0.925 * 101.64)
})

test_that("grade-specific recovery uses a matrix of multipliers", {
  rec <- matrix(c(1.2, 1.1, 1.0), nrow = 3) # G x 1: one recovery year, per-grade
  s <- swing_schedule(ss_ratios(), horizon = 2, swing_years = 1,
                      recovery = rec, entry = NULL)
  expect_equal(diag(s[[2]]$matrix), c(K = 1.2, `1` = 1.1, `2` = 1.0))
})

test_that("zero normal years requires empty entry", {
  s <- swing_schedule(ss_ratios(), horizon = 3, swing_years = 1,
                      recovery = c(1.1, 1.05), entry = NULL)
  expect_length(s, 3)
  expect_null(s[[3]]$entry)
})

test_that("all-swing schedule is valid", {
  s <- swing_schedule(ss_ratios(), horizon = 2, swing_years = 2,
                      recovery = numeric(0), entry = NULL)
  expect_equal(diag(s[[2]]$matrix), c(K = 1, `1` = 1, `2` = 1))
})

test_that("swing_schedule rejects an over-long swing+recovery", {
  expect_snapshot(
    swing_schedule(ss_ratios(), horizon = 2, swing_years = 2,
                   recovery = c(1.1), entry = NULL),
    error = TRUE
  )
})

test_that("swing_schedule needs entry for normal years", {
  expect_snapshot(
    swing_schedule(ss_ratios(), horizon = 4, swing_years = 1,
                   recovery = c(1.1, 1.05), entry = NULL),
    error = TRUE
  )
})

test_that("entry length must match the number of normal years", {
  expect_snapshot(
    swing_schedule(ss_ratios(), horizon = 5, swing_years = 1,
                   recovery = c(1.1), entry = c(130, 140)),
    error = TRUE
  )
})

test_that("swing_years must be a non-negative integer", {
  expect_snapshot(
    swing_schedule(ss_ratios(), horizon = 3, swing_years = -1,
                   recovery = c(1.1), entry = 130),
    error = TRUE
  )
})
```

- [ ] **Step 2: Run to confirm failure**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e "devtools::test(filter = 'swing-schedule')"
```

Expected: failure — `swing_schedule` undefined.

- [ ] **Step 3: Implement the constructor and helpers**

Create `R/swing-schedule.R`:

```r
# Normalize recovery multipliers (scalar-per-year vector or grade-by-year
# matrix) to a per-year list of length-G diagonal vectors.
recovery_diagonals <- function(recovery, go) {
  G <- length(go)
  if (is.matrix(recovery)) {
    if (nrow(recovery) != G) {
      stop(
        sprintf("`recovery` matrix must have one row per grade (%d).", G),
        call. = FALSE
      )
    }
    return(lapply(seq_len(ncol(recovery)), function(j) {
      stats::setNames(recovery[, j], go)
    }))
  }
  if (!is.numeric(recovery)) {
    stop(
      "`recovery` must be a numeric vector or a grade-by-year matrix.",
      call. = FALSE
    )
  }
  lapply(recovery, function(mult) stats::setNames(rep(mult, G), go))
}

# Number of normal (GPR) years; errors if swing + recovery exceed the horizon.
check_swing <- function(swing_years, n_recovery, horizon) {
  if (
    length(swing_years) != 1 || !is.numeric(swing_years) ||
      swing_years < 0 || swing_years %% 1 != 0
  ) {
    stop("`swing_years` must be a non-negative integer.", call. = FALSE)
  }
  n_normal <- horizon - swing_years - n_recovery
  if (n_normal < 0) {
    stop(
      "`swing_years` plus recovery length must not exceed `horizon`.",
      call. = FALSE
    )
  }
  n_normal
}

# Validate exogenous entry for the normal years; return it as a numeric vector.
normal_entry <- function(entry, n_normal) {
  if (n_normal == 0) {
    if (length(entry) > 0) {
      stop("`entry` must be empty when there are no normal (GPR) years.", call. = FALSE)
    }
    return(numeric(0))
  }
  if (is.null(entry)) {
    stop(
      sprintf("`entry` is required for the %d normal year(s) after recovery.", n_normal),
      call. = FALSE
    )
  }
  as_entry_vector(entry, n_normal)
}

# A diagonal projection step with the given grade dimnames.
diag_step <- function(d, go) {
  m <- diag(d, nrow = length(go))
  dimnames(m) <- list(go, go)
  list(matrix = m, entry = NULL)
}

#' Build a swing/recovery projection schedule
#'
#' Assembles a per-year [project_enrollment()] schedule for a school passing
#' through a temporary relocation ("swing"): enrollment is held flat at the
#' depressed observed level during the swing (identity steps), scaled by
#' year-over-year recovery multipliers for the recovery window (diagonal steps),
#' then projected with the grade progression ratio method (the normal
#' projection matrix) for the remaining years.
#'
#' @param ratios A data frame of progression ratios from [progression_ratios()].
#' @param horizon Number of years to project (a positive integer).
#' @param swing_years Number of leading years the school is swinging (a
#'   non-negative integer); enrollment is held flat at `base`.
#' @param recovery Recovery multipliers applied for one year each, immediately
#'   after the swing and compounding on the prior year: a numeric vector
#'   (whole-school, one multiplier per recovery year) or a grade-by-year numeric
#'   matrix (one row per grade). Use `numeric(0)` for no recovery window.
#' @param entry Exogenous entry-grade enrollment for the normal (GPR) years only
#'   — the `horizon - swing_years - length(recovery)` years after recovery. Must
#'   be empty when there are no normal years.
#' @param grade_order Optional low-to-high grade order, passed to
#'   [projection_matrix()].
#'
#' @return A list of `horizon` projection steps suitable for the `schedule`
#'   argument of [project_enrollment()].
#' @export
#'
#' @examples
#' ratios <- data.frame(
#'   grade_from = c("K", "1"), grade_to = c("1", "2"), ratio = c(0.92, 0.97)
#' )
#' schedule <- swing_schedule(ratios,
#'   horizon = 6, swing_years = 2,
#'   recovery = c(1.10, 1.10, 1.05), entry = 130
#' )
#' project_enrollment(c(K = 80, `1` = 66, `2` = 60), schedule = schedule)
swing_schedule <- function(
  ratios,
  horizon,
  swing_years,
  recovery,
  entry = NULL,
  grade_order = NULL
) {
  horizon <- check_horizon(horizon)
  m <- projection_matrix(ratios, grade_order)
  go <- rownames(m)
  diags <- recovery_diagonals(recovery, go)
  n_normal <- check_swing(swing_years, length(diags), horizon)
  entry_vals <- normal_entry(entry, n_normal)

  ident <- diag(length(go))
  dimnames(ident) <- list(go, go)

  swing <- if (swing_years > 0) {
    rep(list(list(matrix = ident, entry = NULL)), swing_years)
  } else {
    list()
  }
  recov <- lapply(diags, diag_step, go = go)
  normal <- lapply(seq_len(n_normal), function(k) {
    list(matrix = m, entry = entry_vals[[k]])
  })
  c(swing, recov, normal)
}
```

- [ ] **Step 4: Run tests; accept snapshots; document**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e "devtools::test(filter = 'swing-schedule')"
# Inspect NON-INTERACTIVELY: read tests/testthat/_snaps/swing-schedule.new.md (or git diff the _snaps dir) to
# confirm the new error snapshots. Do NOT run testthat::snapshot_review() (interactive, hangs headless).
Rscript -e 'testthat::snapshot_accept()'
Rscript -e 'devtools::document()'           # exports swing_schedule, regenerates man/ + NAMESPACE
Rscript -e "devtools::test()"               # FAIL 0
Rscript -e 'cyclocomp::cyclocomp_package_dir(".")'  # every fn < 15
```

- [ ] **Step 5: Format and commit**

```bash
/Users/rory/.local/bin/air format .
git add -A
git commit -m "Add swing_schedule() constructor for swing/recovery regimes"
```

---

### Task 5: Vignette, CLAUDE.md, and final CRAN check

**Files:**
- Modify: `vignettes/enrollcast.Rmd`, `CLAUDE.md`

- [ ] **Step 1: Add a swing/recovery vignette section**

Append to `vignettes/enrollcast.Rmd`:

````markdown
## Modeling a school modernization swing

A school temporarily relocated during modernization typically sees depressed
enrollment that recovers after it returns. `swing_schedule()` builds a per-year
projection schedule: enrollment is held flat during the swing, scaled by
recovery multipliers for a few years, then projected normally.

```{r}
depressed <- c(K = 80, `1` = 66, `2` = 60)
schedule <- swing_schedule(ratios,
  horizon = 6, swing_years = 2,
  recovery = c(1.10, 1.10, 1.05), entry = 130
)
project_enrollment(depressed, schedule = schedule, start_year = 2023)
```
````

- [ ] **Step 2: Update CLAUDE.md for the new function and test count**

In `CLAUDE.md`: add `swing_schedule()` to the method/pipeline description and `R/swing-schedule.R` to the Layout block; note that `project_enrollment()` accepts a `schedule`; update the stated test count (run `devtools::test()` and use the new PASS number).

- [ ] **Step 3: Build vignette and run the full CRAN check**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e 'devtools::document()'
Rscript -e 'devtools::check(cran = TRUE)'
```

Expected: 0 errors, 0 warnings, 0 notes (vignette rebuilds clean).

- [ ] **Step 4: Confirm coverage, complexity, and no stale name**

```bash
Rscript -e 'covr::package_coverage(".")'             # 100%
Rscript -e 'cyclocomp::cyclocomp_package_dir(".")'   # every fn < 15
grep -rn "leslie" R/ tests/ vignettes/ DESCRIPTION README.md CLAUDE.md  # no output
```

- [ ] **Step 5: Format and commit**

```bash
/Users/rory/.local/bin/air format .
git add -A
git commit -m "Document swing/recovery schedule and finalize rename"
```

---

## Self-review notes (plan author)

- **Spec coverage:** rename (T1), engine generalization (T2), schedule arg + validator (T3), `swing_schedule()` + recovery normalization (T4), docs + final check (T5) — every spec section maps to a task.
- **Behavior preservation:** T2's NA-repair test and the unchanged snapshots are the guard that the engine refactor is byte-identical on the default path.
- **Type consistency:** a *step* is `list(matrix, entry)` throughout (T2 engine, T3 validator, T4 constructor); `entry` is `NULL` or a length-1 numeric everywhere; `recovery_diagonals()` always returns a list of named length-G vectors.
- **Open decisions deferred (not blocking):** scalar vs grade-specific recovery default (both supported), entry-during-swing (held flat), and the recovery→normal entry seam — documented in the spec, not the code.
