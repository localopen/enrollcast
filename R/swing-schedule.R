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

# Validate swing_years and that swing + recovery years fit within the horizon.
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
  if (swing_years + n_recovery > horizon) {
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
}

# Convert one ratios table or a supplied projection matrix to a named matrix.
swing_matrix <- function(ratios, grade_order, call = rlang::caller_env()) {
  if (!is.matrix(ratios)) {
    return(progression_matrix(ratios, grade_order))
  }
  what <- "Each {.arg ratios} matrix"
  m <- check_step_matrix(list(matrix = ratios), what = what, call = call)
  go <- check_step_dimnames(m, what = what, call = call)
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
  check_schedule_orders(
    orders,
    what = "All {.arg ratios} matrices",
    call = call
  )
  matrices
}

#' Build a swing/recovery projection schedule
#'
#' Builds a per-year [project_enrollment()] schedule for a school that moves to
#' temporary space ("swing") and then recovers. Every year, classes move up by
#' the grade progression ratios and a new entry class arrives. The grades are
#' then rescaled to the base-year school total in swing years, and to the annual
#' totals you supply in recovery years.
#'
#' The rescaled grades are the students who move up the next year. After the
#' last swing or recovery year, nothing is rescaled: the projection continues
#' from the recovered grades using the progression ratios and the supplied
#' `entry` values. If the final target is far from the level the ratios and
#' entry values can sustain, later totals drift toward that level. Recovery
#' growth can also inflate a school's own ratios; in that case, pass `ratios` as
#' a list and use ordinary ratios for the years after recovery.
#'
#' To update calls written for enrollcast 0.1.0, see `vignette("enrollcast")`.
#'
#' @inheritParams project_enrollment
#' @inheritParams progression_matrix
#' @param ratios A ratios table as accepted by [progression_matrix()], a square
#'   projection matrix with grade dimnames, or a list of `horizon` such tables
#'   or matrices, one per projected year including swing and recovery years.
#'   All matrices must have identical grade dimnames in the same order, matching
#'   `grade_order` if supplied. To open a grade later, include it in every
#'   year's matrix and give it a zero row until it opens.
#' @param swing_years Number of swing years at the start (a non-negative
#'   integer). In these years the school total stays at the total of the `base`
#'   passed to [project_enrollment()], while the grade mix progresses normally.
#' @param recovery Annual school target totals for the years right after the
#'   swing, one value per year. Values must be finite, non-missing, and
#'   non-negative. Use `numeric(0)` for no recovery years. These are totals,
#'   not year-over-year multipliers.
#' @param entry Required exogenous entry-grade enrollment for every projected
#'   year, including swing and recovery: a numeric vector of length `horizon`,
#'   or a data frame with an `enrollment` or `value` column. Values must be
#'   finite, non-missing, and non-negative. In swing and recovery years the
#'   entry grade is rescaled with the other grades, so reported entry enrollment
#'   is the supplied value times that year's rescaling factor. A larger entry
#'   class still gives a larger reported one. In later years the supplied values
#'   are used as given.
#' @param grade_order Optional character vector giving the low-to-high grade
#'   order for every year. If omitted, each ratios table's order is rebuilt from
#'   its chain of transitions, and supplied matrices keep their dimname order.
#'   Every year must end up with the same grade order.
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
