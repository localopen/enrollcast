#' Project enrollment forward
#'
#' Projects grade-level enrollment forward an arbitrary horizon using the grade
#' progression ratio method. Internally builds a Leslie matrix from `ratios`
#' and advances enrollment one year at a time (one matrix-vector product per
#' projected year), overwriting the entry grade with the supplied exogenous
#' value each year.
#'
#' @param base Most recent observed enrollment: either a data frame with
#'   columns `grade` and `enrollment` (optionally `year`), or a named numeric
#'   vector (names are grades).
#' @param ratios A data frame of progression ratios from
#'   [progression_ratios()].
#' @param horizon Number of years to project (a positive integer).
#' @param entry Exogenous entry-grade enrollment for each projected year: a
#'   numeric vector of length `horizon`, or a data frame with an `enrollment`
#'   or `value` column. If `NULL`, the entry grade is held constant at its base
#'   value and a warning is issued.
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
	ratios,
	horizon,
	entry = NULL,
	start_year = NULL
) {
	if (
		!is.numeric(horizon) ||
			length(horizon) != 1 ||
			is.na(horizon) ||
			horizon < 1 ||
			horizon != as.integer(horizon)
	) {
		stop("`horizon` must be a single positive integer.", call. = FALSE)
	}
	horizon <- as.integer(horizon)

	M <- leslie_matrix(ratios)
	go <- rownames(M)
	entry_grade <- go[1]

	base_info <- as_base_vector(base, go)
	n <- base_info$vector
	if (is.null(start_year)) {
		start_year <- base_info$year
	}

	if (is.null(entry)) {
		warning(
			sprintf(
				"`entry` not supplied; holding entry grade '%s' constant at %g.",
				entry_grade,
				n[[entry_grade]]
			),
			call. = FALSE
		)
		entry_vals <- rep(n[[entry_grade]], horizon)
	} else {
		entry_vals <- as_entry_vector(entry, horizon)
	}

	out_years <- if (is.null(start_year)) {
		seq_len(horizon)
	} else {
		start_year + seq_len(horizon)
	}

	result <- vector("list", horizon)
	for (h in seq_len(horizon)) {
		n <- as.vector(M %*% n)
		names(n) <- go
		n[entry_grade] <- entry_vals[h]
		result[[h]] <- data.frame(
			year = out_years[h],
			grade = go,
			enrollment = unname(n),
			row.names = NULL
		)
	}
	do.call(rbind, result)
}
