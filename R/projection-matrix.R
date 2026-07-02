# Reconstruct grade order from from/to transition pairs (linear chain).
chain_order <- function(from, to, call = rlang::caller_env()) {
  from <- as.character(from)
  to <- as.character(to)
  if (anyDuplicated(from)) {
    cli::cli_abort(
      c(
        "A grade feeds more than one grade in {.arg ratios} (branching transitions).",
        "i" = "Pass {.arg grade_order} explicitly."
      ),
      class = "enrollcast_error_branching_transitions",
      call = call
    )
  }
  entry <- setdiff(from, to)
  if (length(entry) != 1) {
    cli::cli_abort(
      c(
        "Could not determine a unique entry grade from {.arg ratios}.",
        "i" = "Pass {.arg grade_order} explicitly."
      ),
      class = "enrollcast_error_ambiguous_entry",
      call = call
    )
  }
  nxt <- stats::setNames(to, from)
  order <- entry
  cur <- entry
  steps <- 0L
  while (cur %in% names(nxt)) {
    steps <- steps + 1L
    if (steps > length(from)) {
      cli::cli_abort(
        c(
          "Cycle detected in grade transitions in {.arg ratios}.",
          "i" = "Pass {.arg grade_order} explicitly."
        ),
        class = "enrollcast_error_cyclic_transitions",
        call = call
      )
    }
    cur <- nxt[[cur]]
    order <- c(order, cur)
  }
  order
}

# Abort when any grade is fed by more than one ratio row.
check_duplicate_feeder <- function(to, call = rlang::caller_env()) {
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
  invisible(to)
}

# Validate an explicit grade_order argument (no missing values, no duplicates).
check_grade_order_arg <- function(grade_order, call = rlang::caller_env()) {
  if (anyNA(grade_order)) {
    cli::cli_abort(
      c(
        "{.arg grade_order} must not contain missing values.",
        "x" = "Found {sum(is.na(grade_order))} missing value{?s}."
      ),
      class = "enrollcast_error_grade_order_na",
      call = call
    )
  }
  if (anyDuplicated(grade_order)) {
    cli::cli_abort(
      c(
        "{.arg grade_order} must not contain duplicate grades.",
        "x" = "Duplicated grade{?s}: {.field {unique(grade_order[duplicated(grade_order)])}}."
      ),
      class = "enrollcast_error_grade_order_duplicate",
      call = call
    )
  }
  invisible(grade_order)
}

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
  check_duplicate_feeder(to)

  if (is.null(grade_order)) {
    grade_order <- chain_order(from, to)
  } else {
    grade_order <- as.character(grade_order)
    check_grade_order_arg(grade_order)
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
