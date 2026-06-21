# Swing/Recovery Regimes + `projection_matrix()` Rename — Design

**Date:** 2026-06-20
**Status:** Reviewed; core decisions settled (recovery=compounding, API=schedule arg, clean rename); ready for implementation plan

## Purpose

Two coupled changes to `enrollcast`:

1. **Rename** the exported `leslie_matrix()` to **`projection_matrix()`** (and
   retire "Leslie matrix" from the package's vocabulary), because the operator
   is not a Leslie matrix by the standard definition and the name gets *more*
   wrong as the model grows.
2. **Generalize the projection engine** from a single fixed matrix applied every
   year to a **per-year sequence of matrices**, and add an ergonomic
   **`swing_schedule()`** constructor on top that builds the sequence for the DC
   school-modernization "swing → recovery → normal" case.

This is approach **C** from the design discussion: generalize the engine once
(small, general, backward-compatible), then layer the domain-specific
constructor on it.

## Background (why)

### Why the rename

A textbook **Leslie matrix** is defined by a *fecundity first row* plus a
survival sub-diagonal; its dominant eigenvalue is the asymptotic growth rate.
`enrollcast`'s operator has **no fecundity row** — the entry grade is supplied
exogenously — and only the sub-diagonal. In Caswell's standard `A = T + F`
decomposition it is the `T` (survival/transition) block alone, driven by
external recruitment (the open-population extension). With only a sub-diagonal it
is **strictly lower triangular, hence nilpotent** (all eigenvalues 0, `M^G = 0`),
so none of the Leslie/Perron–Frobenius machinery the name advertises applies
(verified empirically).

Calling it a "Leslie matrix" is loose-but-defensible today (the COMPADRE/COMADRE
`Rage::is_leslie_matrix()` admits a zero-fertility Leslie matrix; the enrollment
literature loosely says GPR is "expressed as a Leslie matrix"), but it degrades
along the roadmap:

- Adding **grade-retention** main-diagonal terms makes it a **Usher matrix**
  (1966) — explicitly *not* a Leslie matrix.
- The **swing model** returns identity and diagonal-recovery matrices, which are
  not Leslie matrices at all.

`(population) projection matrix` is the verified genus term that subsumes Leslie,
Usher, Lefkovitch, and time-varying products — the one name that stays correct
across the whole trajectory — and it harmonizes the pipeline:
`progression_ratios()` → `projection_matrix()` → `project_enrollment()`.
**Maintainer decision (settled): rename to `projection_matrix()`.**

### Why the engine generalization

The current `run_projection()` applies one fixed matrix `M` every year. The DC
modernization phenomenon needs **different dynamics in different years**:

| Regime | Behaviour | Operator `M_h` | Entry handling |
|--------|-----------|----------------|----------------|
| Swinging | Hold each grade flat at the depressed observed level | **Identity** `I` | none (matrix holds entry) |
| Recovery (`length(recovery)` yrs) | Scale enrollment by the recovery multiplier | **Diagonal** `diag(c_h)` | none (matrix scales entry) |
| Returned (normal) | Standard GPR | **Sub-diagonal** projection matrix `M` (zero entry row) | overwrite with exogenous `entry_h` |

All three are matrices, so the engine just needs to accept a **sequence** of
them. This is the standard time-varying ("periodic" / non-autonomous) matrix
population model — a *product* of per-year matrices rather than a power of one.

## Design

### The per-year step (engine core)

Generalize one projection year from a single fixed matrix to a per-year **step**,
a list `list(matrix = M_h, entry = <NULL | numeric>)`. The year advances as:

```
n_h = M_h · n_{h-1}                          (one matrix–vector product)
if step supplies entry: n_h[entry_grade] = entry_h   (overwrite, not add)
```

**Entry stays an explicit overwrite, deliberately not folded into the matrix.**
The current code repairs the entry position unconditionally
(`n[entry_grade] <- entry_vals[h]`), and that matters: `base` may carry `NA`
(`as_base_vector()` permits it — `R/utils.R` only rejects negatives under
`!is.na`) and `progression_ratios()` can emit `Inf`/`NaN` ratios that flow
downstream. Folding entry into an additive term `M·n + b` would let the zero
entry row's `0 * NA = NaN` **poison the entry position** (`NaN + entry = NaN`),
a silent regression versus today's unconditional repair (confirmed: `base =
c(K = NA, ...)`, `entry = 130` gives `K = 130` under overwrite but `K = NA` under
the additive form). Keeping overwrite preserves current behavior exactly.

The `entry` field is **`NULL`** for swing/recovery years (the matrix governs the
entry grade — identity holds it, diagonal scales it) and the exogenous value for
normal years. `NULL` is the *skip* sentinel and is distinct from a numeric `NA`,
so an explicit `NA` entry value still overwrites (matching today's
`as_entry_vector`, which permits `NA`).

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

The multiply `M %*% n` is **positional** (R ignores names in `%*%`), so the
engine relies on `base_vec` having been built in the step matrices' column
order — guaranteed by construction (next section). A future additive model
(returnee injection, migration) can add an optional `add` field to the step
without disturbing this; it is intentionally omitted now (YAGNI).

### Public surface

Keep **one** projector, `project_enrollment()`, gaining an optional `schedule`:

```r
project_enrollment(base, ratios = NULL, horizon = NULL, entry = NULL,
                   schedule = NULL, start_year = NULL)
```

**Argument resolution (explicit order):**

1. **If `schedule` is non-`NULL`:**
   - `ratios` and `entry` must be `NULL` (else `stop(call. = FALSE)`).
   - If `horizon` is `NULL`, set `horizon <- length(schedule)`; if supplied it
     must equal `length(schedule)` (else error). (Do not call `check_horizon` on
     `NULL` — `is_count(NULL)` is `FALSE` and would misfire.)
   - `check_schedule(schedule)` validates the schedule (below).
   - `go <- colnames(schedule[[1]]$matrix)`; `base_vec <- as_base_vector(base,
     go)` — **reuses** the existing missing-grade error and extra-grade warning,
     and reorders `base` into the matrices' column order, closing the
     name-vs-position alignment hazard.
   - `steps <- schedule`.
2. **Else (GPR path):**
   - `ratios` is required (else `stop(call. = FALSE)`: neither `ratios` nor
     `schedule` supplied).
   - `horizon <- check_horizon(horizon)`.
   - `m <- projection_matrix(ratios)`; `go <- rownames(m)`;
     `base_vec <- as_base_vector(base, go)`.
   - `entry_vals <- entry_values(entry, horizon, base_vec, go[1])` (unchanged,
     including the entry-not-supplied warning).
   - `steps <- lapply(seq_len(horizon), function(h) list(matrix = m, entry =
     entry_vals[h]))` — a constant schedule, byte-identical to today.
3. `start_year` resolution and `out_years` computation unchanged;
   `run_projection(steps, base_vec, out_years)`.

`check_schedule(schedule)` (new internal): non-empty list; every element a list
with a square numeric `$matrix` whose **row and column dimnames are identical as
an ordered vector**, all matrices sharing those dimnames, and an optional
`$entry` that is `NULL` or a length-1 numeric. Errors use `stop(call. = FALSE)`.

This preserves the package's constructor/engine split: `projection_matrix()`
builds one matrix, `swing_schedule()` builds a sequence, `project_enrollment()`
runs whatever it is given (including a hand-assembled schedule).

### The `swing_schedule()` constructor

```r
swing_schedule(ratios, horizon, swing_years, recovery,
               entry = NULL, grade_order = NULL)
```

Builds a length-`horizon` schedule encoding the three regimes:

- `swing_years` — integer ≥ 0, count of leading projected years the school is
  swinging (identity steps, `entry = NULL`; enrollment held flat at the depressed
  `base`).
- `recovery` — the recovery multipliers, applied for `length(recovery)` years
  immediately after the swing, each as a `diag()` step with `entry = NULL`.
  Accepted shapes: a **scalar-per-year** numeric vector `c(1.10, 1.10, 1.05)`
  (whole-school) → `diag(rep(c_h, G))`; or a **grade-specific** `G ×
  length(recovery)` numeric matrix → `diag(column_h)`. (No list form.) An
  internal `recovery_diagonals(recovery, go)` helper normalizes either shape to a
  per-year list of length-`G` diagonal vectors, keeping `swing_schedule()` itself
  thin (under cyclocomp 15).
- `entry` — exogenous entry values for the **normal (GPR) years only** — the
  `horizon - swing_years - length(recovery)` years after recovery; baked into
  those steps as `entry = entry[k]`. Must be `NULL`/length-0 when there are zero
  normal years, else length must equal the normal-year count.
- `grade_order` — passed to `projection_matrix()`.

Validity: `swing_years + length(recovery) <= horizon`. Degenerate cases are
**valid**: zero normal years (`swing_years + length(recovery) == horizon`, then
`entry` must be empty); all-swing (`swing_years == horizon`, `recovery` empty);
`horizon == 1`. The 2-grade minimum is inherited from `projection_matrix()`.

Regime layout for `horizon = 6, swing_years = 2, recovery = c(1.10,1.10,1.05)`:

```
step:   1     2      3          4          5          6
matrix: I     I      diag(1.10) diag(1.10) diag(1.05) M(GPR)
entry:  NULL  NULL   NULL       NULL       NULL       entry[1]
```

Worked trajectory from a depressed base `c(K=80, "1"=66, "2"=60)`, GPR ratios
`K→1 = 0.925`, `1→2 ≈ 0.968`, post-recovery `entry = 130` (verified):

```
   y1 y2   y3   y4    y5    y6
K  80 80 88.0 96.8 101.6 130.0   <- flat, then ×1.10,×1.10,×1.05, then entry OVERRIDE
1  66 66 72.6 79.9  83.9  94.0   <- y6 = 0.925 × 101.6
2  60 60 66.0 72.6  76.2  81.2   <- y6 = 0.968 × 83.9
```

**Note the entry-grade seam at the recovery→normal boundary** (y5 `K=101.6` →
y6 `K=130`, a ~28% jump): the recovery multipliers scale the depressed base's
entry value, whereas normal-year entry is the exogenous override — the two are
independent and need not meet continuously. This is intended, not a bug; an
implementer should not "smooth" it. The caller chooses `recovery` and `entry` so
they align if continuity matters (see Open decisions #1, #5, #6).

## Backward compatibility & behavior preservation

- `project_enrollment()` with no `schedule` is **byte-identical** to current
  output — same matrix multiply, same *unconditional* entry overwrite (including
  the `NA`/`NaN`/`Inf` entry-repair behavior, which the overwrite-not-add design
  preserves). Existing tests and non-renamed snapshots must pass unchanged.
- The rename is the only intentional breaking change. Package is `0.0.0.9000`,
  pre-CRAN, no external users — the cheap moment. **Decision flagged (#4):**
  clean rename vs. a thin soft-deprecated `leslie_matrix()` alias
  (`.Deprecated("projection_matrix")`). Recommendation: clean rename (matches how
  the simplification refactor removed rlang without a deprecation cycle), unless
  the maintainer's own downstream scripts call it.

## Files

**Rename (`leslie_matrix` → `projection_matrix`):**
- `R/leslie-matrix.R` → `R/projection-matrix.R`; function renamed; roxygen
  title/description/`@return`/example reworded ("Leslie matrix" → "projection
  matrix"); the one error message that embeds the name —
  `"Need at least 2 grades to build a Leslie matrix."` (currently
  `R/leslie-matrix.R:37`) → `"...projection matrix."`.
- `tests/testthat/test-leslie-matrix.R` → `test-projection-matrix.R`; its snapshot
  file `_snaps/leslie-matrix.md` → `_snaps/projection-matrix.md` (testthat derives
  the snap filename from the test file).
- Caller `R/project-enrollment.R:88` (`leslie_matrix(ratios)` →
  `projection_matrix(ratios)`).
- `R/enrollcast-package.R` needs **no source edit** — it is a bare `_PACKAGE`
  stub; the package-level `.Rd` Description is generated from `DESCRIPTION`
  (updated below). Re-document regenerates it.
- `devtools::document()` regenerates `man/*.Rd` + `NAMESPACE` (never hand-edit).

**Engine + constructor:**
- `R/project-enrollment.R` — `run_projection()` to the step-sequence form;
  `project_enrollment()` gains `schedule` with the resolution order above; new
  `check_schedule()` internal (here or `R/utils.R`).
- `R/swing-schedule.R` (new) — `swing_schedule()` + `recovery_diagonals()` +
  regime-assembly helper, each under cyclocomp 15.

**Docs/metadata:**
- `DESCRIPTION` Description (`DESCRIPTION:8`, "implemented with a Leslie matrix" →
  "implemented as a matrix projection").
- `vignettes/enrollcast.Rmd` — the `leslie_matrix(ratios)` call → `projection_matrix`,
  plus a new swing/recovery section demonstrating `swing_schedule()`.
- `README.md` — prose at lines 7 and 46, **and the live executable
  `leslie_matrix(ratios)` call at line 49** → `projection_matrix(ratios)`.
- `CLAUDE.md` — rename `leslie_matrix` → `projection_matrix` in the method
  pipeline (step 2); rename `R/leslie-matrix.R` → `R/projection-matrix.R` and add
  `R/swing-schedule.R` in the Layout block; add the `schedule` arg to the
  `project_enrollment` description; bump the stated test count once new tests
  land.
- `_pkgdown.yml` — **no edit required** (it has no curated `reference:` section;
  the renamed and new exports appear in the auto-generated reference index). The
  new vignette section is the site-level entry point for `swing_schedule()`.

## Test strategy

- **Behavior preservation:** existing `project_enrollment` tests pass unchanged;
  add a default-path test with an `NA` in `base` asserting the entry position
  equals the supplied `entry` (locks the no-regression that motivated the
  overwrite-not-add design).
- **Rename snapshots (scoped):** exactly **one** message text changes —
  `"Need at least 2 grades to build a projection matrix."`. The other four blocks
  in the renamed snapshot file change **only** via `test_that` titles and echoed
  `Code` lines (`projection_matrix(...)`); review the diff to confirm no other
  message text moved.
- **Affine/constant-schedule equivalence:** a schedule of all-GPR constant steps
  fed via `schedule=` equals the default `ratios=` path.
- **Schedule-path alignment:** a deliberately *reordered* (correctly-named)
  `base` on the schedule path yields correctly aligned, correctly labeled output
  (guards the positional-multiply hazard).
- **Hand-built schedule:** a schedule assembled by hand (not via
  `swing_schedule()`) fed directly to `project_enrollment()`, locking the
  documented contract.
- **`swing_schedule()`:** regime layout (correct matrix + `entry` per year);
  scalar vs grade-specific recovery; the worked trajectory above as an exact
  expectation; degenerate cases (zero normal years; all-swing; `horizon == 1`);
  error paths (`swing_years + length(recovery) > horizon`; `entry` length ≠
  normal-year count; malformed `recovery` shape).
- **Dual-mode errors:** both `ratios` and `schedule` supplied; neither supplied;
  `horizon` ≠ `length(schedule)` — each a `stop(call. = FALSE)` snapshot.
- **`check_schedule()`:** non-list, shape, dimname-order, and `$entry`-type
  mismatches as snapshots.
- Coverage target 100%; cyclocomp < 15 for every function.

## Open decisions (maintainer)

1. **Recovery multiplier semantics.** Modeled here as year-over-year on the
   current state (`diag(c_h)` applied to last year → compounding). Alternatives:
   cumulative-to-target, or relative to the undisrupted GPR trend. Which matches
   your observed recovery rates?
2. **Scalar vs grade-specific recovery.** Whole-school scalar preserves the
   depressed *shape* (just rescales); grade-specific can correct shape distortion
   from the swing. Both are supported; which do your data favour as the common
   case (affects docs/examples, not the code)?
3. **API surface.** Optional `schedule` arg on `project_enrollment()` (chosen
   here) vs. a separate `project_schedule()` function. The former keeps one
   projector but makes `ratios`/`entry` and `schedule` mutually exclusive.
4. **Rename migration.** Clean rename vs. soft-deprecated `leslie_matrix()`
   alias.
5. **Entry during swing.** Held flat (identity) per your description; confirm new
   entrants aren't modeled as trickling in during the swing.
6. **Entry seam at recovery→normal.** Whether to leave the entry-grade
   discontinuity as-is (caller aligns `recovery`/`entry`), or to offer a
   continuity option later. Out of scope for this design; flagged so it is a
   conscious choice.

## Non-goals (YAGNI)

- No grade-retention / Usher-diagonal terms yet (the engine and name now
  *accommodate* them; not implemented).
- No additive returnee/migration model yet (the step can gain an `add` field
  later).
- No automatic detection of swing periods from data; the caller specifies them.
- No grouped multi-school projection in one call (unchanged: map over `split()`).
