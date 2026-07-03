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

# Validate ratio values: must be numeric and non-negative.
check_ratio_values <- function(ratio, call = rlang::caller_env()) {
  if (!is.numeric(ratio)) {
    cli::cli_abort(
      c(
        "The {.field ratio} column of {.arg ratios} must be numeric.",
        "x" = "{.field ratio} is {.cls {class(ratio)}}."
      ),
      class = "enrollcast_error_ratio_type",
      call = call
    )
  }
  if (any(ratio < 0, na.rm = TRUE)) {
    cli::cli_abort(
      c(
        "The {.field ratio} column of {.arg ratios} must be non-negative.",
        "x" = "Found {sum(ratio < 0, na.rm = TRUE)} negative value{?s}."
      ),
      class = "enrollcast_error_ratio_negative",
      call = call
    )
  }
  if (any(ratio == Inf, na.rm = TRUE)) {
    cli::cli_abort(
      c(
        "The {.field ratio} column of {.arg ratios} must be finite.",
        "x" = "Found {sum(ratio == Inf, na.rm = TRUE)} infinite value{?s}.",
        "i" = "An infinite ratio comes from a zero-enrollment feeder grade; drop or adjust it before building the matrix."
      ),
      class = "enrollcast_error_ratio_infinite",
      call = call
    )
  }
  invisible(ratio)
}

# Grade labels in `ratios` must not be missing.
check_grade_labels <- function(from, to, call = rlang::caller_env()) {
  n_na <- sum(is.na(from)) + sum(is.na(to))
  if (n_na > 0) {
    cli::cli_abort(
      c(
        "{.field grade_from} and {.field grade_to} in {.arg ratios} must not be missing.",
        "x" = "Found {n_na} missing grade label{?s}."
      ),
      class = "enrollcast_error_grade_na",
      call = call
    )
  }
  invisible(NULL)
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

# Every transition must feed the grade immediately above it in grade_order.
check_subdiagonal <- function(
  from,
  to,
  grade_order,
  call = rlang::caller_env()
) {
  bad <- which(match(to, grade_order) != match(from, grade_order) + 1L)
  if (length(bad)) {
    pairs <- paste0(from[bad], " -> ", to[bad])
    cli::cli_abort(
      c(
        "Each ratio in {.arg ratios} must feed the next grade up in {.arg grade_order}.",
        "x" = "Non-adjacent transition{?s}: {.val {pairs}}.",
        "i" = "Grade order: {.field {grade_order}}."
      ),
      class = "enrollcast_error_nonadjacent_transition",
      call = call
    )
  }
  invisible(NULL)
}

# Warn when ratios contain NA/NaN; they propagate into the projection.
warn_na_ratios <- function(ratio) {
  n_na <- sum(is.na(ratio))
  if (n_na > 0) {
    cli::cli_warn(
      c(
        "{n_na} ratio{?s} in {.arg ratios} {?is/are} {.val {NA}} or {.val {NaN}}.",
        "!" = "{cli::qty(n_na)}Grade{?s} fed by {?this/these} ratio{?s} will project as {.val {NA}}."
      ),
      class = "enrollcast_warning_ratio_na"
    )
  }
  invisible(ratio)
}

#' Build the projection matrix
#'
#' Assembles the projection matrix used to advance enrollment. Progression ratios
#' are placed on the sub-diagonal (each non-entry grade is fed by the grade
#' below); the entry-grade row is left at zero because entry enrollment is
#' supplied exogenously to [project_enrollment()]. The ratios must form a single
#' low-to-high chain: each `grade_to` must be the grade immediately above its
#' `grade_from` in the resolved order.
#'
#' @param ratios A data frame with columns `grade_from`, `grade_to`, and
#'   `ratio`, as returned by [progression_ratios()]. `grade_from` and `grade_to`
#'   must not be missing. `ratio` must be numeric, non-negative, and finite; an
#'   infinite ratio (from a zero-enrollment feeder) is rejected, while `NA`/`NaN`
#'   ratios (e.g. from sparse history) are kept in the matrix with a warning.
#' @param grade_order Optional character vector giving the low-to-high grade
#'   order. If omitted, the order is reconstructed from the transition chain.
#'   Every non-entry grade in `grade_order` must appear as a `grade_to` in
#'   `ratios`. Must not contain duplicates or missing values.
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
  check_ratio_values(ratios$ratio)
  from <- as.character(ratios$grade_from)
  to <- as.character(ratios$grade_to)
  check_grade_labels(from, to)
  check_duplicate_feeder(to)

  if (is.null(grade_order)) {
    grade_order <- chain_order(from, to)
  } else {
    grade_order <- as.character(grade_order)
    check_grade_order_arg(grade_order)
  }

  check_projection_grades(from, to, grade_order)
  check_subdiagonal(from, to, grade_order)
  warn_na_ratios(ratios$ratio)

  M <- matrix(
    0,
    nrow = length(grade_order),
    ncol = length(grade_order),
    dimnames = list(grade_order, grade_order)
  )
  M[cbind(match(to, grade_order), match(from, grade_order))] <- ratios$ratio
  M
}
