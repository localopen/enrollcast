# Validate horizon and return it as an integer.
check_horizon <- function(horizon, call = rlang::caller_env()) {
  if (!is_count(horizon)) {
    cli::cli_abort(
      c(
        "{.arg horizon} must be a single positive integer.",
        "x" = "You supplied {.obj_type_friendly {horizon}} of length {length(horizon)}."
      ),
      class = "enrollcast_error_horizon",
      call = call
    )
  }
  as.integer(horizon)
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
    cli::cli_warn(
      c(
        "{.arg entry} not supplied.",
        "i" = "Holding entry grade {.field {entry_grade}} constant at {.val {base_vec[[entry_grade]]}} for all {horizon} projected year{?s}."
      ),
      class = "enrollcast_warning_entry_missing"
    )
    return(rep(base_vec[[entry_grade]], horizon))
  }
  as_entry_vector(entry, horizon, call = call)
}

# Validate one projection step's entry value (NULL or a single number).
check_step_entry <- function(entry, call = rlang::caller_env()) {
  if (!is.null(entry) && !(is.numeric(entry) && length(entry) == 1)) {
    cli::cli_abort(
      c(
        "Each {.arg schedule} step {.field entry} must be {.code NULL} or a single number.",
        "x" = "Got {.obj_type_friendly {entry}} of length {length(entry)}."
      ),
      class = "enrollcast_error_step_entry",
      call = call
    )
  }
}

# Validate one projection step; return its grade order.
check_step <- function(step, call = rlang::caller_env()) {
  if (!is.list(step) || is.null(step$matrix)) {
    cli::cli_abort(
      c(
        "Each {.arg schedule} step must be a {.cls list} with a {.field matrix} element.",
        "x" = "Got {.obj_type_friendly {step}}."
      ),
      class = "enrollcast_error_step_shape",
      call = call
    )
  }
  m <- step$matrix
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
  if (is.null(rownames(m)) || !identical(rownames(m), colnames(m))) {
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
  }
  check_step_entry(step$entry, call = call)
  rownames(m)
}

# Validate a user-supplied projection schedule; return its grade order.
check_schedule <- function(schedule, call = rlang::caller_env()) {
  if (!is.list(schedule) || length(schedule) == 0) {
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
  }
  orders <- lapply(schedule, check_step, call = call)
  go <- orders[[1]]
  differing <- which(!vapply(orders, identical, logical(1), go))
  if (length(differing) > 0) {
    cli::cli_abort(
      c(
        "All {.arg schedule} step matrices must share the same grade dimnames in the same order.",
        "i" = "Step 1 grades: {.val {go}}.",
        "x" = "{cli::qty(length(differing))}Differing step{?s}: {.val {differing}}."
      ),
      class = "enrollcast_error_schedule_inconsistent",
      call = call
    )
  }
  go
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
#' value each year.
#'
#' @param base Most recent observed enrollment: either a data frame with
#'   columns `grade` and `enrollment` (optionally `year`), or a named numeric
#'   vector (names are grades).
#' @param ratios A data frame of progression ratios from
#'   [progression_ratios()]. Optional when a `schedule` is supplied.
#' @param horizon Number of years to project (a positive integer).
#' @param entry Exogenous entry-grade enrollment for each projected year: a
#'   numeric vector of length `horizon`, or a data frame with an `enrollment`
#'   or `value` column. If `NULL`, the entry grade is held constant at its base
#'   value and a warning is issued.
#' @param schedule Optional prebuilt projection schedule: a list of per-year
#'   steps, each `list(matrix = <square projection matrix>, entry = <NULL or a
#'   single number>)`, as produced by [swing_schedule()]. When supplied,
#'   `ratios` and `entry` must be `NULL` and `horizon` defaults to the schedule
#'   length. Step matrices must share identical grade dimnames, which determine
#'   the grade order `base` is aligned to.
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
  if (!is.null(schedule)) {
    if (!is.null(ratios) || !is.null(entry)) {
      cli::cli_abort(
        c(
          "Supply either {.arg ratios}/{.arg entry} or {.arg schedule}, not both.",
          "x" = "You also supplied {.arg {c('ratios', 'entry')[c(!is.null(ratios), !is.null(entry))]}}."
        ),
        class = "enrollcast_error_conflicting_args"
      )
    }
    go <- check_schedule(schedule)
    if (is.null(horizon)) {
      horizon <- length(schedule)
    } else if (horizon != length(schedule)) {
      cli::cli_abort(
        c(
          "{.arg horizon} must equal the {.arg schedule} length.",
          "x" = "{.arg horizon} is {.val {horizon}} but {.arg schedule} has {length(schedule)} step{?s}."
        ),
        class = "enrollcast_error_horizon_schedule_mismatch"
      )
    }
    n <- as_base_vector(base, go)
    steps <- schedule
  } else {
    if (is.null(ratios)) {
      cli::cli_abort(
        c(
          "Supply {.arg ratios} (or a {.arg schedule}).",
          "i" = "{.arg ratios} comes from {.fn progression_ratios}."
        ),
        class = "enrollcast_error_missing_input"
      )
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
