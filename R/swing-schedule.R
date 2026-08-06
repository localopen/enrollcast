check_recovery_values <- function(recovery, call = rlang::caller_env()) {
  bad <- !is.numeric(recovery) ||
    anyNA(recovery) ||
    !all(is.finite(recovery)) ||
    any(recovery < 0)
  if (bad) {
    ec_abort(
      "{.arg recovery} values must be numeric, finite, non-missing, and non-negative.",
      class = "enrollcast_error_recovery_values",
      call = call
    )
  }
}

align_recovery_matrix <- function(recovery, go, call = rlang::caller_env()) {
  G <- length(go)
  if (nrow(recovery) != G) {
    ec_abort(
      c(
        "{.arg recovery} matrix must have one row per grade.",
        "x" = "Expected {G} row{?s} but got {nrow(recovery)}."
      ),
      class = "enrollcast_error_recovery_dim",
      call = call
    )
  }
  rn <- rownames(recovery)
  if (is.null(rn)) {
    return(recovery)
  }
  if (anyNA(rn) || !all(nzchar(rn)) || anyDuplicated(rn) || !setequal(rn, go)) {
    ec_abort(
      "Named {.arg recovery} matrix rows must be unique and exactly match the projection grades.",
      class = "enrollcast_error_recovery_names",
      call = call
    )
  }
  recovery[go, , drop = FALSE]
}

# Normalize recovery multipliers (scalar-per-year vector or grade-by-year
# matrix) to a per-year list of length-G diagonal vectors.
recovery_diagonals <- function(recovery, go, call = rlang::caller_env()) {
  G <- length(go)
  if (is.matrix(recovery)) {
    recovery <- align_recovery_matrix(recovery, go, call = call)
    check_recovery_values(recovery, call = call)
    return(lapply(seq_len(ncol(recovery)), function(j) {
      stats::setNames(recovery[, j], go)
    }))
  }
  if (!is.numeric(recovery)) {
    ec_abort(
      c(
        "{.arg recovery} must be a numeric vector or a grade-by-year matrix.",
        "x" = "You supplied {.obj_type_friendly {recovery}}."
      ),
      class = "enrollcast_error_recovery_type",
      call = call
    )
  }
  check_recovery_values(recovery, call = call)
  lapply(recovery, function(mult) stats::setNames(rep(mult, G), go))
}

# Number of normal (GPR) years; errors if swing + recovery exceed the horizon.
check_swing <- function(
  swing_years,
  n_recovery,
  horizon,
  call = rlang::caller_env()
) {
  if (!is_whole_number(swing_years, min = 0)) {
    ec_abort(
      "{.arg swing_years} must be a non-negative integer.",
      class = "enrollcast_error_swing_years",
      call = call
    )
  }
  n_normal <- horizon - swing_years - n_recovery
  if (n_normal < 0) {
    ec_abort(
      c(
        "{.arg swing_years} plus recovery length must not exceed {.arg horizon}.",
        "x" = "{swing_years} + {n_recovery} > {horizon}."
      ),
      class = "enrollcast_error_swing_too_long",
      call = call
    )
  }
  n_normal
}

# Validate exogenous entry for the normal years; return it as a numeric vector.
normal_entry <- function(entry, n_normal, call = rlang::caller_env()) {
  if (n_normal == 0) {
    if (length(entry) > 0) {
      ec_abort(
        "{.arg entry} must be empty when there are no normal (GPR) years.",
        class = "enrollcast_error_entry_unexpected",
        call = call
      )
    }
    return(numeric(0))
  }
  if (is.null(entry)) {
    ec_abort(
      "{.arg entry} is required for the {n_normal} normal year{?s} after recovery.",
      class = "enrollcast_error_entry_required",
      call = call
    )
  }
  as_entry_vector(entry, n_normal, call = call)
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
#' @inheritParams project_enrollment
#' @inheritParams projection_matrix
#' @param swing_years Number of leading years the school is swinging (a
#'   non-negative integer); enrollment is held flat at `base`.
#' @param recovery Recovery multipliers applied for one year each, immediately
#'   after the swing and compounding on the prior year: a numeric vector
#'   (whole-school, one multiplier per recovery year) or a grade-by-year numeric
#'   matrix (one row per grade). Values must be finite, non-missing, and
#'   non-negative. Named matrix rows are matched and reordered by grade;
#'   unnamed rows are interpreted in projection grade order. Use `numeric(0)`
#'   for no recovery window.
#' @param entry Exogenous entry-grade enrollment for the normal (GPR) years only
#'   — one finite, non-missing, non-negative numeric value for each of the
#'   `horizon - swing_years - length(recovery)` years after recovery. Must be
#'   empty when there are no normal years.
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
