#' Build the Leslie projection matrix
#'
#' Assembles the Leslie matrix used to project enrollment. Progression ratios
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
#' leslie_matrix(ratios)
leslie_matrix <- function(ratios, grade_order = NULL) {
	check_columns(ratios, c("grade_from", "grade_to", "ratio"), "ratios")
	from <- as.character(ratios$grade_from)
	to <- as.character(ratios$grade_to)

	if (is.null(grade_order)) {
		grade_order <- chain_order(from, to)
	} else {
		grade_order <- as.character(grade_order)
	}
	G <- length(grade_order)
	if (G < 2) {
		stop("Need at least 2 grades to build a Leslie matrix.", call. = FALSE)
	}

	ii <- match(to, grade_order)
	jj <- match(from, grade_order)
	if (anyNA(ii) || anyNA(jj)) {
		stop("`ratios` references a grade not in `grade_order`.", call. = FALSE)
	}

	if (anyDuplicated(to)) {
		stop(
			"`ratios` has more than one ratio feeding the same grade; ",
			"each grade may be fed only once.",
			call. = FALSE
		)
	}

	M <- matrix(
		0,
		nrow = G,
		ncol = G,
		dimnames = list(grade_order, grade_order)
	)
	M[cbind(ii, jj)] <- ratios$ratio

	missing_in <- grade_order[-1][!grade_order[-1] %in% to]
	if (length(missing_in)) {
		stop(
			"Missing progression ratio(s) feeding grade(s): ",
			toString(missing_in),
			call. = FALSE
		)
	}
	M
}
