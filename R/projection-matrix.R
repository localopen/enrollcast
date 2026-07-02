# Validate from/to transitions against the resolved grade order.
check_projection_grades <- function(
  from,
  to,
  grade_order,
  call = rlang::caller_env()
) {
  G <- length(grade_order)
  if (G < 2) {
    cli::cli_abort(
      c(
        "A projection matrix needs at least 2 grades.",
        "x" = "Found {.val {G}} grade{?s}.",
        "i" = "Supply a longer series via {.arg ratios} or {.arg grade_order}."
      ),
      class = "enrollcast_error_too_few_grades",
      call = call
    )
  }

  ii <- match(to, grade_order)
  jj <- match(from, grade_order)
  if (anyNA(ii) || anyNA(jj)) {
    unknown <- setdiff(unique(c(from, to)), grade_order)
    cli::cli_abort(
      c(
        "{.arg ratios} references {cli::qty(unknown)} grade{?s} not in {.arg grade_order}.",
        "x" = "Unknown grade{?s}: {.field {unknown}}.",
        "i" = "Known grades: {.field {grade_order}}."
      ),
      class = "enrollcast_error_unknown_grade",
      call = call
    )
  }

  if (anyDuplicated(to)) {
    cli::cli_abort(
      c(
        "Each grade in {.arg ratios} may be fed by only one progression ratio.",
        "x" = "Grade{?s} fed more than once: {.field {unique(to[duplicated(to)])}}.",
        "i" = "Check {.field grade_to} in {.arg ratios} for duplicate rows."
      ),
      class = "enrollcast_error_duplicate_feeder",
      call = call
    )
  }

  missing_in <- setdiff(grade_order[-1], to)
  if (length(missing_in)) {
    cli::cli_abort(
      c(
        "Every non-entry grade must be fed by a progression ratio.",
        "x" = "Missing ratio{?s} feeding grade{?s}: {.field {missing_in}}.",
        "i" = "{cli::qty(missing_in)}Add row{?s} to {.arg ratios} with {.field grade_to} set to {?this/these} grade{?s}."
      ),
      class = "enrollcast_error_missing_ratio",
      call = call
    )
  }
  invisible(NULL)
}

#' Build the projection matrix
#'
#' Assembles the projection matrix used to advance enrollment. Progression ratios
#' are placed on the sub-diagonal (each non-entry grade is fed by the grade
#' below); the entry-grade row is left at zero because entry enrollment is
#' supplied exogenously to [project_enrollment()].
#'
#' @param ratios A data frame with columns `grade_from`, `grade_to`, and
#'   `ratio`, as returned by [progression_ratios()].
#' @param grade_order Optional character vector giving the low-to-high grade
#'   order. If omitted, the order is reconstructed from the transition chain.
#'   Every non-entry grade in `grade_order` must appear as a `grade_to` in
#'   `ratios`.
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
#' projection_matrix(ratios)
projection_matrix <- function(ratios, grade_order = NULL) {
  check_columns(ratios, c("grade_from", "grade_to", "ratio"), "ratios")
  from <- as.character(ratios$grade_from)
  to <- as.character(ratios$grade_to)

  if (is.null(grade_order)) {
    grade_order <- chain_order(from, to)
  } else {
    grade_order <- as.character(grade_order)
  }

  check_projection_grades(from, to, grade_order)

  M <- matrix(
    0,
    nrow = length(grade_order),
    ncol = length(grade_order),
    dimnames = list(grade_order, grade_order)
  )
  M[cbind(match(to, grade_order), match(from, grade_order))] <- ratios$ratio
  M
}
