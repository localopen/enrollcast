# cli Adoption Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace every base-R `stop()`/`warning()` in enrollcast with `cli::cli_abort()`/`cli::cli_warn()`, giving each guard a stable condition class, attributing errors to the user-facing function via rlang call-context, and interpolating the actual offending values.

**Architecture:** All 47 messaging sites migrate. Errors become `cli::cli_abort()` with a `class =` and `call = call`; internal helpers gain a `call = rlang::caller_env()` parameter that is forwarded down the call chain so the error is reported from the exported function the user actually called. Warnings become `cli::cli_warn()` with a `class =`, kept call-free (matching today's `call. = FALSE`). Tests gain a class-based `expect_error(..., class=)`/`expect_warning(..., class=)` guard alongside each existing snapshot, so future wording changes only re-accept snapshots without weakening the contract.

**Tech Stack:** R (>= 4.0), cli (>= 3.4.0), rlang (>= 1.0.0), testthat 3e (snapshot tests), roxygen2, air (formatter).

## Global Constraints

- **2-space indentation, enforced by `air`.** Run `air format .` (binary at `/Users/rory/.local/bin/air`) before every commit. No tabs.
- **Namespacing: `cli::` and `rlang::` at every call site. No `@importFrom`, no `library()`.** NAMESPACE currently has only `export()` lines and must stay that way; the DESCRIPTION `Imports` entries alone satisfy `R CMD check`. Do not run `devtools::document()` expecting NAMESPACE changes — there are none.
- **`export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64` before any `devtools::test()`/`check()`** or pandoc won't be found on this machine.
- **Errors:** `cli::cli_abort(msg, class = "<class>", call = call)` in internal helpers; `cli::cli_abort(msg, class = "<class>")` (default call) in exported-function bodies.
- **Warnings:** `cli::cli_warn(msg, class = "<class>")` — no `call` argument (stay call-free, as today).
- **Snapshots:** testthat 3e's `expect_snapshot()` already runs in a reproducible-output context (width 80, color off, ASCII bullets `x`/`i`/`!`), so NO `local_reproducible_output()` wrapper is needed. Re-accept via the headless workflow only (never `snapshot_review()`): run `devtools::test()` to write `.new.md`, inspect with `git diff`/the `.new.md` files, then `testthat::snapshot_accept()`.
- **Quality gate (Task 8):** `devtools::test()` (expect FAIL 0), `devtools::check(cran = TRUE)` (0/0/0), `covr::package_coverage(".")` (100%), `cyclocomp::cyclocomp_package_dir(".")` (every fn < 15).
- **Commit cadence:** one commit per task. End commit messages with the Co-Authored-By trailer.

---

## Reference A — Condition class registry (all 47 sites)

Use these exact class strings. `error` → `cli_abort`, `warning` → `cli_warn`.

### R/utils.R (14 errors, 3 warnings)

| Line | Function | Type | Class |
|---|---|---|---|
| 11 | `check_columns` | error | `enrollcast_error_missing_columns` |
| 30 | `resolve_grade_order` | error | `enrollcast_error_grade_order_incomplete` |
| 39 | `resolve_grade_order` | warning | `enrollcast_warning_grade_order_extra` |
| 58 | `resolve_grade_order` | warning | `enrollcast_warning_grade_order_guessed` |
| 71 | `chain_order` | error | `enrollcast_error_branching_transitions` |
| 79 | `chain_order` | error | `enrollcast_error_ambiguous_entry` |
| 91 | `chain_order` | error | `enrollcast_error_cyclic_transitions` |
| 108 | `summarise_ratios` | error | `enrollcast_error_weights_missing` |
| 111 | `summarise_ratios` | error | `enrollcast_error_weights_length` |
| 147 | `as_base_vector` | error | `enrollcast_error_base_type` |
| 155 | `as_base_vector` | error | `enrollcast_error_base_incomplete` |
| 163 | `as_base_vector` | warning | `enrollcast_warning_base_extra` |
| 171 | `as_base_vector` | error | `enrollcast_error_base_negative` |
| 195 | `as_entry_vector` | error | `enrollcast_error_entry_no_value_col` |
| 204 | `as_entry_vector` | error | `enrollcast_error_entry_type` |
| 210 | `as_entry_vector` | error | `enrollcast_error_entry_length` |
| 220 | `as_entry_vector` | error | `enrollcast_error_entry_negative` |

### R/progression-ratios.R (8 errors, 1 warning)

| Line | Function | Type | Class |
|---|---|---|---|
| 5 | `prepare_enrollment` | error | `enrollcast_error_enrollment_type` |
| 9 | `prepare_enrollment` | error | `enrollcast_error_enrollment_negative` |
| 13 | `prepare_enrollment` | error | `enrollcast_error_too_few_grades` |
| 18 | `prepare_enrollment` | error | `enrollcast_error_year_type` |
| 23 | `prepare_enrollment` | error | `enrollcast_error_grade_na` |
| 48 | `enrollment_matrix` | error | `enrollcast_error_duplicate_rows` |
| 74 | `transition_ratios` | error | `enrollcast_error_no_transitions` |
| 83 | `check_n_years` | error | `enrollcast_error_n_years` |
| 145 | `progression_ratios` | warning | `enrollcast_warning_undefined_ratios` |

### R/projection-matrix.R (4 errors)

| Line | Function | Type | Class |
|---|---|---|---|
| 37 | `projection_matrix` | error | `enrollcast_error_too_few_grades` (shared with above) |
| 43 | `projection_matrix` | error | `enrollcast_error_unknown_grade` |
| 47 | `projection_matrix` | error | `enrollcast_error_duplicate_feeder` |
| 64 | `projection_matrix` | error | `enrollcast_error_missing_ratio` |

### R/swing-schedule.R (6 errors)

| Line | Function | Type | Class |
|---|---|---|---|
| 7 | `recovery_diagonals` | error | `enrollcast_error_recovery_dim` |
| 17 | `recovery_diagonals` | error | `enrollcast_error_recovery_type` |
| 33 | `check_swing` | error | `enrollcast_error_swing_years` |
| 37 | `check_swing` | error | `enrollcast_error_swing_too_long` |
| 49 | `normal_entry` | error | `enrollcast_error_entry_unexpected` |
| 57 | `normal_entry` | error | `enrollcast_error_entry_required` |

### R/project-enrollment.R (10 errors, 1 warning)

| Line | Function | Type | Class |
|---|---|---|---|
| 4 | `check_horizon` | error | `enrollcast_error_horizon` |
| 12 | `entry_values` | warning | `enrollcast_warning_entry_missing` |
| 28 | `check_step_entry` | error | `enrollcast_error_step_entry` |
| 38 | `check_step` | error | `enrollcast_error_step_shape` |
| 45 | `check_step` | error | `enrollcast_error_step_not_square` |
| 48 | `check_step` | error | `enrollcast_error_step_dimnames` |
| 60 | `check_schedule` | error | `enrollcast_error_schedule_shape` |
| 68 | `check_schedule` | error | `enrollcast_error_schedule_inconsistent` |
| 150 | `project_enrollment` | error | `enrollcast_error_conflicting_args` |
| 159 | `project_enrollment` | error | `enrollcast_error_horizon_schedule_mismatch` |
| 168 | `project_enrollment` | error | `enrollcast_error_missing_input` |

---

## Reference B — Call-context threading map

Add `call = rlang::caller_env()` as the **last parameter** of each internal helper below, pass `call = call` into every `cli_abort()` it emits, and forward `call` into any nested helper it invokes. Exported functions (`progression_ratios`, `projection_matrix`, `project_enrollment`, `swing_schedule`) are **not** modified — their own `cli_abort()` calls use the default (which captures the exported frame), and the helpers' `caller_env()` defaults resolve to the exported function automatically.

| Helper (file) | Add `call=` param | Forwards `call` into |
|---|---|---|
| `check_columns` (utils.R) | yes | — |
| `resolve_grade_order` (utils.R) | yes | — (warnings stay call-free) |
| `chain_order` (utils.R) | yes | — |
| `summarise_ratios` (utils.R) | yes | — |
| `as_base_vector` (utils.R) | yes | `check_columns(..., call = call)` |
| `as_entry_vector` (utils.R) | yes | — |
| `prepare_enrollment` (progression-ratios.R) | yes | `check_columns(..., call = call)`, `resolve_grade_order(..., call = call)` |
| `enrollment_matrix` (progression-ratios.R) | yes | — |
| `transition_ratios` (progression-ratios.R) | yes | — |
| `check_n_years` (progression-ratios.R) | yes | — |
| `recovery_diagonals` (swing-schedule.R) | yes | — |
| `check_swing` (swing-schedule.R) | yes | — |
| `normal_entry` (swing-schedule.R) | yes | `as_entry_vector(..., call = call)` |
| `check_horizon` (project-enrollment.R) | yes | — |
| `entry_values` (project-enrollment.R) | yes | `as_entry_vector(..., call = call)` (warning stays call-free) |
| `check_step_entry` (project-enrollment.R) | yes | — |
| `check_step` (project-enrollment.R) | yes | `check_step_entry(step$entry, call = call)` |
| `check_schedule` (project-enrollment.R) | yes | `lapply(schedule, check_step, call = call)` |

**Deliberate exception:** `projection_matrix()` is exported *and* called internally by `project_enrollment()`/`swing_schedule()`. Its errors attribute to `projection_matrix()` itself (default `cli_abort` behavior), not the outer caller. This is acceptable (it is a public function) and avoids adding a `call` argument to a public signature.

---

## Reference C — The repeating per-site pattern

Every site follows the same shape. Example (the `check_step` square check):

```r
# BEFORE
check_step <- function(step) {
  ...
  if (!is.matrix(m) || nrow(m) != ncol(m)) {
    stop("Each `schedule` step `matrix` must be square.", call. = FALSE)
  }
  ...
}

# AFTER
check_step <- function(step, call = rlang::caller_env()) {
  ...
  if (!is.matrix(m) || nrow(m) != ncol(m)) {
    cli::cli_abort(
      c(
        "Each {.arg schedule} step {.field matrix} must be square.",
        "x" = "This matrix is {nrow(m)}x{ncol(m)}."
      ),
      class = "enrollcast_error_step_not_square",
      call = call
    )
  }
  ...
}
```

And the matching test gains one line beside the existing snapshot:

```r
test_that("check_step rejects a non-square matrix", {
  expect_snapshot(check_step(list(matrix = m[, 1, drop = FALSE])), error = TRUE)
  expect_error(
    check_step(list(matrix = m[, 1, drop = FALSE])),
    class = "enrollcast_error_step_not_square"
  )
})
```

---

## Task 1: Add cli + rlang to Imports

**Files:**
- Modify: `DESCRIPTION:18-20`

- [ ] **Step 1: Edit DESCRIPTION `Imports`**

```
Imports:
    cli (>= 3.4.0),
    rlang (>= 1.0.0),
    stats,
    utils
```

- [ ] **Step 2: Confirm no NAMESPACE change is required**

Run: `Rscript -e 'devtools::document()'`
Expected: NAMESPACE unchanged (still only `export()` lines); `git diff NAMESPACE` shows nothing. (We use `cli::`/`rlang::` fully qualified, so there is no import to add.)

- [ ] **Step 3: Sanity-check the package still loads**

Run: `export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64 && Rscript -e 'devtools::load_all(".")'`
Expected: loads with no error.

- [ ] **Step 4: Commit**

```bash
air format .
git add DESCRIPTION
git commit -m "Add cli and rlang to Imports"
```

---

## Task 2: Migrate R/utils.R (17 sites)

**Files:**
- Modify: `R/utils.R`
- Test: `tests/testthat/test-utils.R`
- Snapshot: `tests/testthat/_snaps/utils.md`

**Interfaces:**
- Produces: helper signatures gain trailing `call = rlang::caller_env()`: `check_columns(data, cols, arg = "data", call = rlang::caller_env())`, `resolve_grade_order(grade, grade_order = NULL, call = rlang::caller_env())`, `chain_order(from, to, call = rlang::caller_env())`, `summarise_ratios(R, method, weights = NULL, call = rlang::caller_env())`, `as_base_vector(base, go, call = rlang::caller_env())`, `as_entry_vector(entry, horizon, call = rlang::caller_env())`. Later tasks forward `call` into `check_columns` and `as_entry_vector`.

- [ ] **Step 1: Rewrite the six helper signatures and all 17 sites.** Apply these site rewrites (each replaces the existing `stop()`/`warning()`), and add `call = rlang::caller_env()` to each helper signature per Reference B.

`check_columns` (L11):
```r
cli::cli_abort(
  c(
    "{.arg {arg}} is missing required column{?s}: {.field {missing}}."
  ),
  class = "enrollcast_error_missing_columns",
  call = call
)
```

`resolve_grade_order` missing grade_order entries (L30):
```r
cli::cli_abort(
  "{.arg grade_order} is missing grade{?s}: {.field {missing_g}}.",
  class = "enrollcast_error_grade_order_incomplete",
  call = call
)
```

`resolve_grade_order` extra grades warning (L39, call-free):
```r
cli::cli_warn(
  "{.arg grade_order} contains grade{?s} missing from data: {.field {missing_go}}.",
  class = "enrollcast_warning_grade_order_extra"
)
```

`resolve_grade_order` alphabetical fallback warning (L58, call-free):
```r
cli::cli_warn(
  c(
    "Grade order guessed by sorting labels alphabetically.",
    "i" = "Pass {.arg grade_order} or a factor {.arg grade} to set it explicitly."
  ),
  class = "enrollcast_warning_grade_order_guessed"
)
```

`chain_order` branching (L71):
```r
cli::cli_abort(
  c(
    "A grade feeds more than one grade in {.arg ratios} (branching transitions).",
    "i" = "Pass {.arg grade_order} explicitly."
  ),
  class = "enrollcast_error_branching_transitions",
  call = call
)
```

`chain_order` ambiguous entry (L79):
```r
cli::cli_abort(
  c(
    "Could not determine a unique entry grade from {.arg ratios}.",
    "i" = "Pass {.arg grade_order} explicitly."
  ),
  class = "enrollcast_error_ambiguous_entry",
  call = call
)
```

`chain_order` cycle (L91):
```r
cli::cli_abort(
  c(
    "Cycle detected in grade transitions in {.arg ratios}.",
    "i" = "Pass {.arg grade_order} explicitly."
  ),
  class = "enrollcast_error_cyclic_transitions",
  call = call
)
```

`summarise_ratios` weights missing (L108):
```r
cli::cli_abort(
  "{.arg weights} is required for {.code method = \"weighted\"}.",
  class = "enrollcast_error_weights_missing",
  call = call
)
```

`summarise_ratios` weights length (L111):
```r
cli::cli_abort(
  c(
    "{.arg weights} length must equal the number of transition years used.",
    "x" = "{.arg weights} has length {length(weights)}.",
    "i" = "There {qty(ncol(R))}{?is/are} {ncol(R)} transition year{?s}."
  ),
  class = "enrollcast_error_weights_length",
  call = call
)
```

`as_base_vector` invalid type (L147):
```r
cli::cli_abort(
  c(
    "{.arg base} must be a data frame (grade, enrollment) or a named numeric vector.",
    "x" = "You supplied {.obj_type_friendly {base}}."
  ),
  class = "enrollcast_error_base_type",
  call = call
)
```

`as_base_vector` missing grade (L155):
```r
cli::cli_abort(
  "{.arg base} is missing enrollment for grade{?s}: {.field {missing}}.",
  class = "enrollcast_error_base_incomplete",
  call = call
)
```

`as_base_vector` extra grades warning (L163, call-free):
```r
cli::cli_warn(
  "{.arg base} contains grade{?s} not in {.arg ratios} that will be ignored: {.field {extra}}.",
  class = "enrollcast_warning_base_extra"
)
```

`as_base_vector` negative (L171):
```r
cli::cli_abort(
  "{.arg base} enrollment must be non-negative.",
  class = "enrollcast_error_base_negative",
  call = call
)
```

Also forward `call` at the `check_columns` call inside `as_base_vector`:
```r
check_columns(base, c("grade", "enrollment"), "base", call = call)
```

`as_entry_vector` no value column (L195):
```r
cli::cli_abort(
  "{.arg entry} data frame must have an {.field enrollment} or {.field value} column.",
  class = "enrollcast_error_entry_no_value_col",
  call = call
)
```

`as_entry_vector` invalid type (L204):
```r
cli::cli_abort(
  c(
    "{.arg entry} must be a numeric vector or a data frame with a value column.",
    "x" = "You supplied {.obj_type_friendly {entry}}."
  ),
  class = "enrollcast_error_entry_type",
  call = call
)
```

`as_entry_vector` length (L210):
```r
cli::cli_abort(
  c(
    "{.arg entry} length must equal {.arg horizon}.",
    "x" = "{.arg entry} has length {length(vals)} but {.arg horizon} is {horizon}."
  ),
  class = "enrollcast_error_entry_length",
  call = call
)
```

`as_entry_vector` negative (L220):
```r
cli::cli_abort(
  "{.arg entry} values must be non-negative.",
  class = "enrollcast_error_entry_negative",
  call = call
)
```

- [ ] **Step 2: Add class-based assertions to `tests/testthat/test-utils.R`.** For each existing `expect_snapshot(<expr>, error = TRUE)`, add a sibling `expect_error(<expr>, class = "<class>")`; for each warning snapshot add `expect_warning(<expr>, class = "<class>")`. Map each test to its class via Reference A (utils.R section).

- [ ] **Step 3: Regenerate snapshots**

Run: `export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64 && Rscript -e 'devtools::test(filter = "utils")'`
Expected: warnings about changed snapshots; `.new.md` written under `tests/testthat/_snaps/`.

- [ ] **Step 4: Inspect the snapshot diff, then accept**

Run: `git diff --no-index tests/testthat/_snaps/utils.md tests/testthat/_snaps/utils.new.md` (or read the `.new.md`).
Expected change shape per block: `Error:` → `Error in \`<exported_fn>()\`:`, `(s)` resolved to correct singular/plural, bare values now `field`-styled. Then:
Run: `Rscript -e 'testthat::snapshot_accept("utils")'`

- [ ] **Step 5: Re-run to confirm green**

Run: `export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64 && Rscript -e 'devtools::test(filter = "utils")'`
Expected: PASS, 0 failures, no snapshot warnings.

- [ ] **Step 6: Commit**

```bash
air format .
git add R/utils.R tests/testthat/test-utils.R tests/testthat/_snaps/utils.md
git commit -m "Migrate utils.R messages to cli with condition classes"
```

---

## Task 3: Migrate R/progression-ratios.R (9 sites)

**Files:**
- Modify: `R/progression-ratios.R`
- Test: `tests/testthat/test-progression-ratios.R`
- Snapshot: `tests/testthat/_snaps/progression-ratios.md`

**Interfaces:**
- Consumes: `check_columns(..., call=)`, `resolve_grade_order(..., call=)` from Task 2.
- Produces: `prepare_enrollment(data, year, grade, enrollment, grade_order, call = rlang::caller_env())`, `enrollment_matrix(data, year, grade, enrollment, call = rlang::caller_env())`, `transition_ratios(w, call = rlang::caller_env())`, `check_n_years(n_years, call = rlang::caller_env())`.

- [ ] **Step 1: Add `call=` params and forward into `prepare_enrollment`'s nested helpers.** In `prepare_enrollment`, change the two helper calls to forward `call`:
```r
check_columns(data, c(year, grade, enrollment), "data", call = call)
go <- resolve_grade_order(data[[grade]], grade_order, call = call)
```

- [ ] **Step 2: Rewrite all 9 sites.**

`prepare_enrollment` enrollment type (L5):
```r
cli::cli_abort(
  c(
    "The {.field {enrollment}} column of {.arg data} must be numeric.",
    "x" = "{.field {enrollment}} is {.cls {class(data[[enrollment]])}}."
  ),
  class = "enrollcast_error_enrollment_type",
  call = call
)
```

`prepare_enrollment` enrollment negative (L9):
```r
cli::cli_abort(
  c(
    "The {.field {enrollment}} column of {.arg data} must be non-negative.",
    "x" = "Found {sum(data[[enrollment]] < 0, na.rm = TRUE)} negative value{?s}."
  ),
  class = "enrollcast_error_enrollment_negative",
  call = call
)
```

`prepare_enrollment` too few grades (L13):
```r
cli::cli_abort(
  c(
    "{.arg data} must contain at least 2 grades to compute progression ratios.",
    "x" = "The {.field {grade}} column has {length(unique(as.character(data[[grade]])))} grade{?s}."
  ),
  class = "enrollcast_error_too_few_grades",
  call = call
)
```

`prepare_enrollment` year type (L18):
```r
cli::cli_abort(
  c(
    "The {.field {year}} column of {.arg data} must be numeric or coercible to numeric.",
    "x" = "{sum(is.na(yr) & !is.na(data[[year]]))} value{?s} could not be coerced."
  ),
  class = "enrollcast_error_year_type",
  call = call
)
```

`prepare_enrollment` grade NA (L23):
```r
cli::cli_abort(
  c(
    "The {.field {grade}} column of {.arg data} must not contain missing values.",
    "x" = "Found {sum(is.na(data[[grade]]))} missing value{?s}."
  ),
  class = "enrollcast_error_grade_na",
  call = call
)
```

`enrollment_matrix` duplicate rows (L48):
```r
cli::cli_abort(
  c(
    "{.arg data} must have one row per grade per year.",
    "x" = "Found duplicate ({.field {grade}}, {.field {year}}) row{?s}.",
    "i" = "Aggregate or de-duplicate before calling {.fn progression_ratios}."
  ),
  class = "enrollcast_error_duplicate_rows",
  call = call
)
```

`transition_ratios` no transitions (L74):
```r
cli::cli_abort(
  c(
    "Cannot compute progression ratios without consecutive years.",
    "x" = "{.arg data} has no adjacent year pair.",
    "i" = "Years present: {.val {as.numeric(colnames(w))}}."
  ),
  class = "enrollcast_error_no_transitions",
  call = call
)
```

`check_n_years` (L83):
```r
cli::cli_abort(
  c(
    "{.arg n_years} must be a single positive integer.",
    "x" = "You supplied {.obj_type_friendly {n_years}}."
  ),
  class = "enrollcast_error_n_years",
  call = call
)
```

`progression_ratios` undefined-ratios warning (L145, call-free):
```r
cli::cli_warn(
  c(
    "{sum(is.infinite(r) | is.nan(r))} progression ratio{?s} {?is/are} infinite or {.val {NaN}}.",
    "!" = "A feeder grade had zero enrollment in at least one transition."
  ),
  class = "enrollcast_warning_undefined_ratios"
)
```

- [ ] **Step 3: Add class assertions to `tests/testthat/test-progression-ratios.R`** (sibling `expect_error`/`expect_warning` per Reference A). Note the 3 existing `expect_no_warning()` calls (L143, L162, L170) need no change — they keep passing.

- [ ] **Step 4: Regenerate, inspect, accept**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e 'devtools::test(filter = "progression-ratios")'
# inspect tests/testthat/_snaps/progression-ratios.new.md, then:
Rscript -e 'testthat::snapshot_accept("progression-ratios")'
```

- [ ] **Step 5: Re-run to confirm green**

Run: `Rscript -e 'devtools::test(filter = "progression-ratios")'`
Expected: PASS, 0 failures.

- [ ] **Step 6: Commit**

```bash
air format .
git add R/progression-ratios.R tests/testthat/test-progression-ratios.R tests/testthat/_snaps/progression-ratios.md
git commit -m "Migrate progression-ratios.R messages to cli with condition classes"
```

---

## Task 4: Migrate R/projection-matrix.R (4 sites)

**Files:**
- Modify: `R/projection-matrix.R`
- Test: `tests/testthat/test-projection-matrix.R`
- Snapshot: `tests/testthat/_snaps/projection-matrix.md`

**Interfaces:**
- Consumes: `check_columns(..., call=)` and `chain_order(..., call=)` from Task 2. `projection_matrix` is exported and unchanged in signature; its `cli_abort` calls use the default call (attribute to `projection_matrix`).

- [ ] **Step 1: Rewrite the 4 sites** (exported-function body — no `call` argument; default call captures `projection_matrix`).

Too few grades (L37):
```r
cli::cli_abort(
  c(
    "A projection matrix needs at least 2 grades.",
    "x" = "Found {.val {G}} grade{?s}.",
    "i" = "Supply a longer series via {.arg ratios} or {.arg grade_order}."
  ),
  class = "enrollcast_error_too_few_grades"
)
```

Unknown grade (L43):
```r
cli::cli_abort(
  c(
    "{.arg ratios} references grade{?s} not in {.arg grade_order}.",
    "x" = "Unknown grade{?s}: {.field {setdiff(unique(c(from, to)), grade_order)}}.",
    "i" = "Known grades: {.field {grade_order}}."
  ),
  class = "enrollcast_error_unknown_grade"
)
```

Duplicate feeder (L47):
```r
cli::cli_abort(
  c(
    "Each grade in {.arg ratios} may be fed by only one progression ratio.",
    "x" = "Grade{?s} fed more than once: {.field {unique(to[duplicated(to)])}}.",
    "i" = "Check {.field grade_to} in {.arg ratios} for duplicate rows."
  ),
  class = "enrollcast_error_duplicate_feeder"
)
```

Missing ratio (L64):
```r
cli::cli_abort(
  c(
    "Every non-entry grade must be fed by a progression ratio.",
    "x" = "Missing ratio{?s} feeding grade{?s}: {.field {missing_in}}.",
    "i" = "Add row{?s} to {.arg ratios} with {.field grade_to} set to {?this/these} grade{?s}."
  ),
  class = "enrollcast_error_missing_ratio"
)
```

- [ ] **Step 2: Add class assertions to `tests/testthat/test-projection-matrix.R`** (Reference A). Note L37 shares `enrollcast_error_too_few_grades` with `prepare_enrollment`; the snapshot text still differs, so both layers are exercised.

- [ ] **Step 3: Regenerate, inspect, accept**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e 'devtools::test(filter = "projection-matrix")'
# inspect .new.md, then:
Rscript -e 'testthat::snapshot_accept("projection-matrix")'
```

- [ ] **Step 4: Re-run to confirm green**

Run: `Rscript -e 'devtools::test(filter = "projection-matrix")'`
Expected: PASS, 0 failures.

- [ ] **Step 5: Commit**

```bash
air format .
git add R/projection-matrix.R tests/testthat/test-projection-matrix.R tests/testthat/_snaps/projection-matrix.md
git commit -m "Migrate projection-matrix.R messages to cli with condition classes"
```

---

## Task 5: Migrate R/swing-schedule.R (6 sites)

**Files:**
- Modify: `R/swing-schedule.R`
- Test: `tests/testthat/test-swing-schedule.R`
- Snapshot: `tests/testthat/_snaps/swing-schedule.md`

**Interfaces:**
- Consumes: `as_entry_vector(..., call=)` from Task 2.
- Produces: `recovery_diagonals(recovery, go, call = rlang::caller_env())`, `check_swing(swing_years, n_recovery, horizon, call = rlang::caller_env())`, `normal_entry(entry, n_normal, call = rlang::caller_env())`.

- [ ] **Step 1: Add `call=` params; forward into `normal_entry`'s `as_entry_vector` call:**
```r
as_entry_vector(entry, n_normal, call = call)
```

- [ ] **Step 2: Rewrite the 6 sites.**

`recovery_diagonals` matrix rows (L7):
```r
cli::cli_abort(
  c(
    "{.arg recovery} matrix must have one row per grade.",
    "x" = "Expected {G} row{?s} but got {nrow(recovery)}."
  ),
  class = "enrollcast_error_recovery_dim",
  call = call
)
```

`recovery_diagonals` type (L17):
```r
cli::cli_abort(
  c(
    "{.arg recovery} must be a numeric vector or a grade-by-year matrix.",
    "x" = "You supplied {.obj_type_friendly {recovery}}."
  ),
  class = "enrollcast_error_recovery_type",
  call = call
)
```

`check_swing` swing_years (L33):
```r
cli::cli_abort(
  "{.arg swing_years} must be a non-negative integer.",
  class = "enrollcast_error_swing_years",
  call = call
)
```

`check_swing` too long (L37):
```r
cli::cli_abort(
  c(
    "{.arg swing_years} plus recovery length must not exceed {.arg horizon}.",
    "x" = "{swing_years} + {n_recovery} > {horizon}."
  ),
  class = "enrollcast_error_swing_too_long",
  call = call
)
```

`normal_entry` unexpected entry (L49):
```r
cli::cli_abort(
  "{.arg entry} must be empty when there are no normal (GPR) years.",
  class = "enrollcast_error_entry_unexpected",
  call = call
)
```

`normal_entry` entry required (L57):
```r
cli::cli_abort(
  "{.arg entry} is required for the {n_normal} normal year{?s} after recovery.",
  class = "enrollcast_error_entry_required",
  call = call
)
```

- [ ] **Step 3: Add class assertions to `tests/testthat/test-swing-schedule.R`** (Reference A).

- [ ] **Step 4: Regenerate, inspect, accept**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e 'devtools::test(filter = "swing-schedule")'
# inspect .new.md, then:
Rscript -e 'testthat::snapshot_accept("swing-schedule")'
```

- [ ] **Step 5: Re-run to confirm green**

Run: `Rscript -e 'devtools::test(filter = "swing-schedule")'`
Expected: PASS, 0 failures.

- [ ] **Step 6: Commit**

```bash
air format .
git add R/swing-schedule.R tests/testthat/test-swing-schedule.R tests/testthat/_snaps/swing-schedule.md
git commit -m "Migrate swing-schedule.R messages to cli with condition classes"
```

---

## Task 6: Migrate R/project-enrollment.R (11 sites)

**Files:**
- Modify: `R/project-enrollment.R`
- Test: `tests/testthat/test-project-enrollment.R`
- Snapshot: `tests/testthat/_snaps/project-enrollment.md`

**Interfaces:**
- Consumes: `as_entry_vector(..., call=)`, `as_base_vector(..., call=)` from Task 2.
- Produces: `check_horizon(horizon, call = rlang::caller_env())`, `entry_values(entry, horizon, base_vec, entry_grade, call = rlang::caller_env())`, `check_step_entry(entry, call = rlang::caller_env())`, `check_step(step, call = rlang::caller_env())`, `check_schedule(schedule, call = rlang::caller_env())`.

- [ ] **Step 1: Add `call=` params and forward into nested helpers.**
  - In `entry_values`: `as_entry_vector(entry, horizon, call = call)`
  - In `check_step`: `check_step_entry(step$entry, call = call)`
  - In `check_schedule`: `orders <- lapply(schedule, check_step, call = call)`

- [ ] **Step 2: Rewrite the 11 sites.**

`check_horizon` (L4):
```r
cli::cli_abort(
  c(
    "{.arg horizon} must be a single positive integer.",
    "x" = "You supplied {.obj_type_friendly {horizon}} of length {length(horizon)}."
  ),
  class = "enrollcast_error_horizon",
  call = call
)
```

`entry_values` warning (L12, call-free):
```r
cli::cli_warn(
  c(
    "{.arg entry} not supplied.",
    "i" = "Holding entry grade {.field {entry_grade}} constant at {.val {base_vec[[entry_grade]]}} for all {horizon} projected year{?s}."
  ),
  class = "enrollcast_warning_entry_missing"
)
```

`check_step_entry` (L28):
```r
cli::cli_abort(
  c(
    "Each {.arg schedule} step {.field entry} must be {.code NULL} or a single number.",
    "x" = "Got {.obj_type_friendly {entry}} of length {length(entry)}."
  ),
  class = "enrollcast_error_step_entry",
  call = call
)
```

`check_step` shape (L38):
```r
cli::cli_abort(
  c(
    "Each {.arg schedule} step must be a {.cls list} with a {.field matrix} element.",
    "x" = "Got {.obj_type_friendly {step}}."
  ),
  class = "enrollcast_error_step_shape",
  call = call
)
```

`check_step` not square (L45):
```r
cli::cli_abort(
  c(
    "Each {.arg schedule} step {.field matrix} must be square.",
    "x" = "This matrix is {nrow(m)}x{ncol(m)}."
  ),
  class = "enrollcast_error_step_not_square",
  call = call
)
```

`check_step` dimnames (L48):
```r
cli::cli_abort(
  c(
    "Each {.arg schedule} step {.field matrix} must have identical row and column dimnames.",
    "x" = if (is.null(rownames(m))) {
      "This matrix has no row names."
    } else {
      "Row names {.val {rownames(m)}} do not match column names {.val {colnames(m)}}."
    }
  ),
  class = "enrollcast_error_step_dimnames",
  call = call
)
```

`check_schedule` shape (L60):
```r
cli::cli_abort(
  c(
    "{.arg schedule} must be a non-empty {.cls list} of projection steps.",
    "x" = if (!is.list(schedule)) {
      "You supplied {.obj_type_friendly {schedule}}."
    } else {
      "You supplied an empty list."
    }
  ),
  class = "enrollcast_error_schedule_shape",
  call = call
)
```

`check_schedule` inconsistent (L68):
```r
cli::cli_abort(
  c(
    "All {.arg schedule} step matrices must share the same grade dimnames in the same order.",
    "i" = "Step 1 grades: {.val {go}}.",
    "x" = "Differing step{?s}: {.val {which(!vapply(orders, identical, logical(1), go))}}."
  ),
  class = "enrollcast_error_schedule_inconsistent",
  call = call
)
```

`project_enrollment` conflicting args (L150, exported body — no `call`):
```r
cli::cli_abort(
  c(
    "Supply either {.arg ratios}/{.arg entry} or {.arg schedule}, not both.",
    "x" = "You also supplied {.arg {c('ratios', 'entry')[c(!is.null(ratios), !is.null(entry))]}}."
  ),
  class = "enrollcast_error_conflicting_args"
)
```

`project_enrollment` horizon/schedule mismatch (L159, exported body — no `call`):
```r
cli::cli_abort(
  c(
    "{.arg horizon} must equal the {.arg schedule} length.",
    "x" = "{.arg horizon} is {.val {horizon}} but {.arg schedule} has {length(schedule)} step{?s}."
  ),
  class = "enrollcast_error_horizon_schedule_mismatch"
)
```

`project_enrollment` missing input (L168, exported body — no `call`):
```r
cli::cli_abort(
  c(
    "Supply {.arg ratios} (or a {.arg schedule}).",
    "i" = "{.arg ratios} comes from {.fn progression_ratios}."
  ),
  class = "enrollcast_error_missing_input"
)
```

- [ ] **Step 3: Add class assertions to `tests/testthat/test-project-enrollment.R`** (Reference A).

- [ ] **Step 4: Regenerate, inspect, accept**

```bash
export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64
Rscript -e 'devtools::test(filter = "project-enrollment")'
# inspect .new.md, then:
Rscript -e 'testthat::snapshot_accept("project-enrollment")'
```

- [ ] **Step 5: Re-run to confirm green**

Run: `Rscript -e 'devtools::test(filter = "project-enrollment")'`
Expected: PASS, 0 failures.

- [ ] **Step 6: Commit**

```bash
air format .
git add R/project-enrollment.R tests/testthat/test-project-enrollment.R tests/testthat/_snaps/project-enrollment.md
git commit -m "Migrate project-enrollment.R messages to cli with condition classes"
```

---

## Task 7 (optional): Document the many-units progress idiom

Only if you want the documented batch workflow to show progress. This adds **no** runtime dependency on cli for the user (it is example code in a Suggests-gated chunk).

**Files:**
- Modify: `README.Rmd` (and `vignettes/enrollcast.Rmd` if the same example appears there)

- [ ] **Step 1: Add a "Projecting many units" subsection** after the existing `split()` example, showing user-side progress:

````markdown
### Projecting many units

For a large run (hundreds of schools or LEAs), wrap the per-unit projection in
a cli progress bar:

```r
splits <- split(history, history$school)
results <- cli::cli_progress_along(splits, "Projecting units") |>
  lapply(\(i) project_enrollment(splits[[i]], ratios_by_school[[i]], horizon = 5))
```
````

- [ ] **Step 2: Re-knit the README**

Run: `export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64 && Rscript -e 'devtools::build_readme()'`
Expected: `README.md` regenerated, no errors.

- [ ] **Step 3: Commit**

```bash
git add README.Rmd README.md
git commit -m "Document cli progress bar for many-units projection"
```

---

## Task 8: Full quality gate

**Files:** none (verification only).

- [ ] **Step 1: Full test suite**

Run: `export RSTUDIO_PANDOC=/Applications/quarto/bin/tools/aarch64 && Rscript -e 'devtools::test()'`
Expected: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS <n> ]` with `<n>` ≥ 130 + the new class assertions.

- [ ] **Step 2: R CMD check (CRAN mode)**

Run: `Rscript -e 'devtools::check(cran = TRUE)'`
Expected: `0 errors | 0 warnings | 0 notes`. (cli/rlang now appear under Imports; no "undeclared import" note.)

- [ ] **Step 3: Coverage**

Run: `Rscript -e 'covr::package_coverage(".")'`
Expected: 100%. (Every new `cli_abort`/`cli_warn` branch is exercised by an existing snapshot test plus the new class assertion. If a conditional `x` bullet — e.g. `check_step` dimnames or `check_schedule` shape — has an unhit branch, add the missing case to the test file.)

- [ ] **Step 4: Cyclomatic complexity**

Run: `Rscript -e 'cyclocomp::cyclocomp_package_dir(".")'`
Expected: every function < 15. (The `if (...) "..." else "..."` bullets add 1 each; confirm `check_step`/`check_schedule` stay under budget.)

- [ ] **Step 5: Final format check**

Run: `air format . && git diff --exit-code`
Expected: no diff (already formatted).

---

## Self-Review

**Spec coverage:** All four decisions are encoded — cli **+ rlang** (Task 1 Imports; `call = rlang::caller_env()` threading in Reference B and every helper task), **classes + snapshots** (Reference A registry; Step "add class assertions" in each task), **all 47 sites** (Reference A lists all 47; Tasks 2–6 cover 17 + 9 + 4 + 6 + 11 = 47), **plan-only** (this document; no code written yet).

**Count check:** utils 17 + progression-ratios 9 + projection-matrix 4 + swing-schedule 6 + project-enrollment 11 = **47**. ✔ (42 errors + 5 warnings.)

**Type/name consistency:** Class strings in the per-site rewrites match Reference A exactly. `call` parameter added to every helper in Reference B and forwarded at the call sites named there. Warnings (`enrollcast_warning_*`, 5 of them: grade_order_extra, grade_order_guessed, base_extra, undefined_ratios, entry_missing) use `cli_warn` with `class` only, no `call`.

**Known follow-ups (out of scope, noted intentionally):**
- `projection_matrix()` errors attribute to itself even when called internally (Reference B exception). If desired later, add an internal `error_call` argument.
- Line numbers in this plan reference the pre-migration source; after each task the following sites in the same file shift. Work top-to-bottom within a file, or match on the message text rather than the line number.
