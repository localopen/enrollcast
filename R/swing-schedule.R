# Recovery is expressed as annual school totals, not growth multipliers.
check_recovery <- function(recovery, call = rlang::caller_env()) {
  if (!is.numeric(recovery) || !is.null(dim(recovery))) {
    ec_abort(
      "{.arg recovery} must be a numeric vector of annual target totals.",
      class = "enrollcast_error_recovery_type",
      call = call
    )
  }
  if (anyNA(recovery) || !all(is.finite(recovery)) || any(recovery < 0)) {
    ec_abort(
      paste0(
        "{.arg recovery} totals must be finite, ",
        "non-missing, and non-negative."
      ),
      class = "enrollcast_error_recovery_values",
      call = call
    )
  }
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
        paste0(
          "{.arg swing_years} plus recovery ",
          "length must not exceed {.arg horizon}."
        ),
        "x" = "{swing_years} + {n_recovery} > {horizon}."
      ),
      class = "enrollcast_error_swing_too_long",
      call = call
    )
  }
  n_normal
}

# Convert one ratios table or a supplied projection matrix to a named matrix.
swing_matrix <- function(ratios, grade_order, call = rlang::caller_env()) {
  if (!is.matrix(ratios)) {
    return(progression_matrix(ratios, grade_order))
  }
  m <- check_step_matrix(list(matrix = ratios), call = call)
  go <- check_step_dimnames(m, call = call)
  if (!is.null(grade_order)) {
    grade_order <- as.character(grade_order)
    check_grade_order_arg(grade_order, call = call)
    if (!identical(go, grade_order)) {
      ec_abort(
        "Projection matrix dimnames must match {.arg grade_order} in order.",
        class = "enrollcast_error_schedule_inconsistent",
        call = call
      )
    }
  }
  m
}

# Resolve a single reusable input or one table/matrix for every projected year.
swing_matrices <- function(
  ratios,
  horizon,
  grade_order,
  call = rlang::caller_env()
) {
  if (is.data.frame(ratios) || is.matrix(ratios)) {
    return(rep(list(swing_matrix(ratios, grade_order, call = call)), horizon))
  }
  if (!is.list(ratios) || length(ratios) != horizon) {
    ec_abort(
      paste0(
        "{.arg ratios} must be a ratios table, a projection matrix, ",
        "or a list of {.arg horizon} tables or matrices."
      ),
      class = "enrollcast_error_swing_ratios",
      call = call
    )
  }
  matrices <- lapply(
    ratios,
    swing_matrix,
    grade_order = grade_order,
    call = call
  )
  orders <- lapply(matrices, rownames)
  check_schedule_orders(orders, call = call)
  matrices
}

#' Build a swing/recovery projection schedule
#'
#' Assembles a per-year [project_enrollment()] schedule for a school passing
#' through a temporary relocation ("swing"). Every year advances the normal
#' cohort projection with grade progression ratios and a new entry class.
#' The output grades are then rescaled to the base-year school total during
#' swing years and to the supplied annual totals during recovery.
#'
#' Rescaling affects the output only: the next year's cohort projection uses
#' the unadjusted grades. After the last swing or recovery year, its adjustment
#' factor continues to apply to all projected grades, including new entry
#' classes. This replaces the former freeze-then-multiply behavior.
#'
#' @inheritParams project_enrollment
#' @inheritParams progression_matrix
#' @param ratios A ratios table as accepted by [progression_matrix()], a square
#'   projection matrix with grade dimnames, or a list of `horizon` such tables
#'   or matrices (one per projected year, including swing and recovery).
#'   All matrices must use identical grade dimnames in the same order, matching
#'   `grade_order` when supplied. To open a grade later, include it in every
#'   year's matrix and use a zero destination row until it opens.
#' @param swing_years Number of leading swing years (a non-negative integer).
#'   Each year's school total is held at the total of `base` supplied to
#'   [project_enrollment()], while its grade mix progresses normally.
#' @param recovery Numeric vector of annual school target totals, one per year
#'   immediately after the swing. Values must be finite, non-missing, and
#'   non-negative. Use `numeric(0)` for no recovery window. These are totals,
#'   replacing the former year-over-year multipliers and grade-specific matrices.
#' @param entry Required exogenous entry-grade enrollment for every projected
#'   year, including swing and recovery: a numeric vector of length `horizon`,
#'   or a data frame with an `enrollment` or `value` column. Values must be
#'   finite, non-missing, and non-negative. These are the unadjusted entry
#'   values; output entry enrollment is rescaled along with the other grades.
#' @param grade_order Optional character vector giving the low-to-high grade
#'   order for every year. If omitted, each ratios table's order is reconstructed
#'   from its transition chain; supplied matrices retain their dimname order.
#'   All years must resolve to the same grade order.
#'
#' @return A list of `horizon` projection steps suitable for the `schedule`
#'   argument of [project_enrollment()]. Each step contains `matrix` and
#'   `entry`; swing steps also have `total = "base"` and recovery steps have
#'   a numeric `total`.
#' @export
#'
#' @examples
#' ratios <- data.frame(
#'   grade_from = c("K", "1"), grade_to = c("1", "2"), ratio = c(0.92, 0.97)
#' )
#' schedule <- swing_schedule(ratios,
#'   horizon = 6, swing_years = 2,
#'   recovery = c(225, 245, 260), entry = rep(90, 6)
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
  check_recovery(recovery)
  check_swing(swing_years, length(recovery), horizon)
  matrices <- swing_matrices(ratios, horizon, grade_order)
  if (is.null(entry)) {
    ec_abort(
      "{.arg entry} is required for all {horizon} projected year{?s}.",
      class = "enrollcast_error_entry_required"
    )
  }
  entry_vals <- as_entry_vector(entry, horizon)
  targets <- c(rep(list("base"), swing_years), as.list(recovery))
  lapply(seq_len(horizon), function(h) {
    step <- list(matrix = matrices[[h]], entry = entry_vals[[h]])
    if (h <= length(targets)) {
      step$total <- targets[[h]]
    }
    step
  })
}
