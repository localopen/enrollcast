# Validate horizon and return it as an integer.
check_horizon <- function(horizon, call = rlang::caller_env()) {
  if (!is_count(horizon) || horizon > .Machine$integer.max) {
    ec_abort(
      c(
        "{.arg horizon} must be a single positive integer.",
        "x" = paste0(
          "You supplied {.obj_type_friendly {horizon}} ",
          "of length {length(horizon)}."
        )
      ),
      class = "enrollcast_error_horizon",
      call = call
    )
  }
  as.integer(horizon)
}

check_start_year <- function(start_year, call = rlang::caller_env()) {
  if (!is_whole_number(start_year)) {
    ec_abort(
      "{.arg start_year} must be one finite integer.",
      class = "enrollcast_error_start_year",
      call = call
    )
  }
  if (abs(start_year) > .Machine$integer.max) {
    ec_abort(
      "{.arg start_year} must be within the R integer range.",
      class = "enrollcast_error_start_year",
      call = call
    )
  }
  start_year
}

# Resolve exogenous entry-grade values for each projected year.
entry_values <- function(
  entry,
  horizon,
  base_vec,
  entry_grade,
  call = rlang::caller_env()
) {
  if (is.null(entry)) {
    ec_warn(
      c(
        "{.arg entry} not supplied.",
        "i" = paste0(
          "Holding entry grade {.field {entry_grade}} constant at ",
          "{.val {base_vec[[entry_grade]]}} for all {horizon} ",
          "projected year{?s}."
        )
      ),
      class = "enrollcast_warning_entry_missing"
    )
    return(rep(base_vec[[entry_grade]], horizon))
  }
  as_entry_vector(entry, horizon, call = call)
}

# Validate one step's entry value (NULL or one finite, non-negative number).
check_step_entry <- function(entry, call = rlang::caller_env()) {
  if (
    !is.null(entry) &&
      !(is.numeric(entry) &&
        length(entry) == 1 &&
        is.finite(entry) &&
        entry >= 0)
  ) {
    ec_abort(
      c(
        paste0(
          "Each {.arg schedule} step {.field entry} must be ",
          "{.code NULL} or one finite, non-negative number."
        ),
        "x" = "Got {.obj_type_friendly {entry}} of length {length(entry)}."
      ),
      class = "enrollcast_error_step_entry",
      call = call
    )
  }
}

check_step_matrix <- function(step, call = rlang::caller_env()) {
  if (!is.list(step) || is.null(step$matrix)) {
    ec_abort(
      c(
        paste0(
          "Each {.arg schedule} step must be a ",
          "{.cls list} with a {.field matrix} element."
        ),
        "x" = "Got {.obj_type_friendly {step}}."
      ),
      class = "enrollcast_error_step_shape",
      call = call
    )
  }
  m <- step$matrix
  if (!is.matrix(m) || nrow(m) != ncol(m)) {
    ec_abort(
      c(
        "Each {.arg schedule} step {.field matrix} must be square.",
        "x" = "This matrix is {nrow(m)}x{ncol(m)}."
      ),
      class = "enrollcast_error_step_not_square",
      call = call
    )
  }
  if (
    !is.numeric(m) ||
      any(is.infinite(m)) ||
      any(m < 0, na.rm = TRUE)
  ) {
    ec_abort(
      paste0(
        "Each {.arg schedule} step {.field matrix} must contain non-negative ",
        "numeric values or {.val {NA}}/{.val {NaN}}, without infinite values."
      ),
      class = "enrollcast_error_step_values",
      call = call
    )
  }
  m
}

check_step_dimnames <- function(m, call = rlang::caller_env()) {
  rn <- rownames(m)
  cn <- colnames(m)
  if (is.null(rn) || is.null(cn)) {
    ec_abort(
      c(
        paste0(
          "Each {.arg schedule} step {.field matrix} must have present, ",
          "unique, identical row and column names in the same order."
        ),
        "x" = "This matrix is missing row or column names."
      ),
      class = "enrollcast_error_step_dimnames",
      call = call
    )
  }
  if (
    anyNA(rn) || !all(nzchar(rn)) || anyDuplicated(rn) || !identical(rn, cn)
  ) {
    ec_abort(
      c(
        paste0(
          "Each {.arg schedule} step {.field matrix} must have present, ",
          "unique, identical row and column names in the same order."
        ),
        "x" = paste0(
          "Row names {.val {rn}} and column names ",
          "{.val {cn}} are invalid or do not match."
        )
      ),
      class = "enrollcast_error_step_dimnames",
      call = call
    )
  }
  rn
}

# Validate one projection step; return its grade order.
check_step <- function(step, call = rlang::caller_env()) {
  m <- check_step_matrix(step, call = call)
  go <- check_step_dimnames(m, call = call)
  check_step_entry(step$entry, call = call)
  go
}

# Validate a user-supplied projection schedule; return its grade order.
check_schedule <- function(schedule, call = rlang::caller_env()) {
  if (!is.list(schedule) || length(schedule) == 0) {
    ec_abort(
      c(
        "{.arg schedule} must be a non-empty {.cls list} of projection steps.",
        "x" = if (is.list(schedule)) {
          "You supplied an empty list."
        } else {
          "You supplied {.obj_type_friendly {schedule}}."
        }
      ),
      class = "enrollcast_error_schedule_shape",
      call = call
    )
  }
  orders <- lapply(schedule, check_step, call = call)
  go <- orders[[1]]
  differing <- which(!vapply(orders, identical, logical(1), go))
  if (length(differing) > 0) {
    ec_abort(
      c(
        paste0(
          "All {.arg schedule} step matrices must share ",
          "the same grade dimnames in the same order."
        ),
        "i" = "Step 1 grades: {.val {go}}.",
        "x" = paste0(
          "{cli::qty(length(differing))}Differing ",
          "step{?s}: {.val {differing}}."
        )
      ),
      class = "enrollcast_error_schedule_inconsistent",
      call = call
    )
  }

  missing_by_step <- vapply(
    schedule,
    function(step) sum(is.na(step$matrix)),
    numeric(1)
  )
  affected <- which(missing_by_step > 0)
  n_missing <- sum(missing_by_step)
  if (n_missing > 0) {
    ec_warn(
      c(
        paste0(
          "{n_missing} missing matrix ",
          "coefficient{?s} {?was/were} found in {.arg schedule}."
        ),
        "!" = paste0(
          "{cli::qty(length(affected))}Affected ",
          "step{?s}: {.val {affected}}."
        ),
        "i" = paste0(
          "Missing coefficients are preserved and may ",
          "propagate into later grades and years."
        )
      ),
      class = "enrollcast_warning_schedule_na"
    )
  }
  go
}

# Resolve the per-year steps, base vector, and horizon for a schedule call.
prepare_schedule_projection <- function(
  base,
  ratios,
  entry,
  schedule,
  horizon,
  call = rlang::caller_env()
) {
  if (!is.null(ratios) || !is.null(entry)) {
    ec_abort(
      c(
        paste0(
          "Supply either {.arg ratios}/{.arg entry} ",
          "or {.arg schedule}, not both."
        ),
        "x" = paste0(
          "You also supplied ",
          "{.arg {c('ratios', 'entry')[c(!is.null(ratios), !is.null(entry))]}}."
        )
      ),
      class = "enrollcast_error_conflicting_args",
      call = call
    )
  }
  go <- check_schedule(schedule, call = call)
  if (is.null(horizon)) {
    horizon <- length(schedule)
  } else {
    horizon <- check_horizon(horizon, call = call)
  }
  if (horizon != length(schedule)) {
    ec_abort(
      c(
        "{.arg horizon} must equal the {.arg schedule} length.",
        "x" = paste0(
          "{.arg horizon} is {.val {horizon}} but ",
          "{.arg schedule} has {length(schedule)} step{?s}."
        )
      ),
      class = "enrollcast_error_horizon_schedule_mismatch",
      call = call
    )
  }
  list(
    steps = schedule,
    n = as_base_vector(base, go, call = call),
    horizon = horizon
  )
}

# Resolve the per-year steps, base vector, and horizon for a ratios call.
prepare_ratio_projection <- function(
  base,
  ratios,
  entry,
  horizon,
  call = rlang::caller_env()
) {
  if (is.null(ratios)) {
    ec_abort(
      c(
        "Supply {.arg ratios} (or a {.arg schedule}).",
        "i" = "{.arg ratios} comes from {.fn progression_ratios}."
      ),
      class = "enrollcast_error_missing_input",
      call = call
    )
  }
  horizon <- check_horizon(horizon, call = call)
  m <- progression_matrix(ratios)
  go <- rownames(m)
  n <- as_base_vector(base, go, call = call)
  entry_vals <- entry_values(entry, horizon, n, go[1], call = call)
  steps <- lapply(seq_len(horizon), function(h) {
    list(matrix = m, entry = entry_vals[[h]])
  })
  list(steps = steps, n = n, horizon = horizon)
}

# Output-year labels: derived from start_year or base$year, else 1..horizon.
resolve_out_years <- function(
  base,
  start_year,
  horizon,
  call = rlang::caller_env()
) {
  derived_year <- is.null(start_year)
  if (derived_year) {
    start_year <- base_year(base, call = call)
  } else {
    start_year <- check_start_year(start_year, call = call)
  }
  if (!is.null(start_year) && start_year > .Machine$integer.max - horizon) {
    if (derived_year) {
      ec_abort(
        paste0(
          "{.arg base} year and {.arg horizon} must ",
          "produce years within the R integer range."
        ),
        class = "enrollcast_error_base_year",
        call = call
      )
    }
    ec_abort(
      paste0(
        "{.arg start_year} and {.arg horizon} must ",
        "produce years within the R integer range."
      ),
      class = "enrollcast_error_start_year",
      call = call
    )
  }
  if (is.null(start_year)) seq_len(horizon) else start_year + seq_len(horizon)
}

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

#' Project enrollment forward
#'
#' Projects grade-level enrollment forward an arbitrary horizon using the grade
#' progression ratio method. Internally builds a projection matrix from `ratios`
#' and advances enrollment one year at a time (one matrix-vector product per
#' projected year), overwriting the entry grade with the supplied exogenous
#' value each year. `ratios` is optional when a `schedule` is supplied.
#'
#' @inheritParams progression_matrix
#' @param base Most recent observed enrollment: either a data frame with
#'   columns `grade` and `enrollment` (optionally `year`), or a named numeric
#'   vector. Grade values or vector names must be present and unique. Enrollment
#'   must be finite, non-missing, and non-negative.
#' @param horizon Number of years to project (a positive integer).
#' @param entry Exogenous entry-grade enrollment for each projected year: a
#'   numeric vector of length `horizon`, or a data frame with an `enrollment`
#'   or `value` column. Values must be finite, non-missing, and non-negative. If
#'   `NULL`, the entry grade is held constant at its base value and a warning is
#'   issued.
#' @param schedule Optional prebuilt projection schedule: a list of per-year
#'   steps, each `list(matrix = <square projection matrix>, entry = <NULL or a
#'   single number>)`, as produced by [swing_schedule()]. When supplied,
#'   `ratios` and `entry` must be `NULL` and `horizon` defaults to the schedule
#'   length. Each matrix must be numeric and square; non-missing coefficients
#'   must be finite and non-negative. `NA`/`NaN` coefficients are preserved and
#'   trigger a warning. A missing coefficient can make its output row missing.
#'   If that missing enrollment remains after entry replacement, the next
#'   matrix multiplication spreads missingness to all grade results because zero
#'   times a missing value is still missing. A non-`NULL` entry value then
#'   restores only the entry grade. Matrix row and column names must be unique
#'   and identical in the same order; all steps must use the same names. A
#'   step's `entry` must be `NULL` or one finite, non-negative number.
#' @param start_year Optional integer label for the base year; output years run
#'   from `start_year + 1`. An explicit value and all resulting years must be
#'   within the R integer range. If `NULL`, the year is derived from `base$year`
#'   when present; that column must contain one unambiguous integer within the
#'   same range. With no year column, output years are `1..horizon`.
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
#' project_enrollment(base, ratios,
#'   horizon = 3, entry = c(125, 130, 128),
#'   start_year = 2023
#' )
project_enrollment <- function(
  base,
  ratios = NULL,
  horizon = NULL,
  entry = NULL,
  schedule = NULL,
  start_year = NULL
) {
  prep <- if (!is.null(schedule)) {
    prepare_schedule_projection(base, ratios, entry, schedule, horizon)
  } else {
    prepare_ratio_projection(base, ratios, entry, horizon)
  }
  out_years <- resolve_out_years(base, start_year, prep$horizon)
  run_projection(prep$steps, prep$n, out_years)
}
