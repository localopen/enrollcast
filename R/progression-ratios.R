#' Compute grade progression ratios
#'
#' Calculates cohort survival / grade progression ratios from historical
#' grade-level enrollment. For each non-entry grade, the ratio is enrollment
#' in that grade divided by enrollment in the grade below one year earlier,
#' summarised across the available year-to-year transitions.
#'
#' @param data A long data frame of historical enrollment with one row per
#'   grade per year.
#' @param year,grade,enrollment Column names in `data` (character scalars).
#'   Defaults are `"year"`, `"grade"`, `"enrollment"`.
#' @param method How to summarise per-year ratios into one ratio per grade:
#'   `"mean"` (default), `"geometric"`, `"median"`, `"last"` (most recent
#'   transition only), or `"weighted"`.
#' @param n_years Optional. Use only the most recent `n_years` transitions.
#' @param weights For `method = "weighted"`, a numeric vector aligned
#'   most-recent to oldest, with one weight per transition year used.
#' @param grade_order Optional character vector giving the low-to-high grade
#'   order. If omitted, factor levels, numeric ordering, or (with a warning)
#'   alphabetical ordering is used.
#'
#' @return A data frame with columns `grade_from`, `grade_to`, and `ratio`,
#'   one row per non-entry grade.
#' @export
#'
#' @examples
#' history <- data.frame(
#'   year = rep(2021:2023, each = 3),
#'   grade = factor(rep(c("K", "1", "2"), 3), levels = c("K", "1", "2")),
#'   enrollment = c(100, 90, 80, 110, 95, 88, 120, 99, 91)
#' )
#' progression_ratios(history)
progression_ratios <- function(
	data,
	year = "year",
	grade = "grade",
	enrollment = "enrollment",
	method = c(
		"mean",
		"geometric",
		"median",
		"last",
		"weighted"
	),
	n_years = NULL,
	weights = NULL,
	grade_order = NULL
) {
	method <- match.arg(method)
	check_columns(data, c(year, grade, enrollment), "data")

	gr_raw <- data[[grade]]
	gr <- as.character(gr_raw)
	en <- data[[enrollment]]

	if (!is.numeric(en)) {
		stop("`enrollment` column must be numeric.", call. = FALSE)
	}
	if (any(en < 0, na.rm = TRUE)) {
		stop("`enrollment` must be non-negative.", call. = FALSE)
	}

	go <- resolve_grade_order(gr_raw, grade_order)
	G <- length(go)
	if (G < 2) {
		stop("Need at least 2 grades to compute progression ratios.", call. = FALSE)
	}

	yr_num <- suppressWarnings(as.numeric(as.character(data[[year]])))
	if (any(is.na(yr_num))) {
		stop("`year` must be numeric or coercible to numeric.", call. = FALSE)
	}

	years <- sort(unique(yr_num))
	ri <- match(gr, go)
	ci <- match(yr_num, years)
	if (any(is.na(ri))) {
		stop("Some grades are not in the resolved grade order.", call. = FALSE)
	}
	if (anyDuplicated(cbind(ri, ci))) {
		stop("Duplicate (grade, year) rows in `data`.", call. = FALSE)
	}

	W <- matrix(
		NA_real_,
		nrow = G,
		ncol = length(years),
		dimnames = list(go, as.character(years))
	)
	W[cbind(ri, ci)] <- en

	trans <- which(diff(years) == 1)
	if (length(trans) == 0) {
		stop("No consecutive year pairs found to form transitions.", call. = FALSE)
	}
	trans_years <- years[trans + 1]

	R <- matrix(
		NA_real_,
		nrow = G - 1,
		ncol = length(trans),
		dimnames = list(go[-1], as.character(trans_years))
	)
	for (j in seq_along(trans)) {
		t0 <- trans[j]
		t1 <- trans[j] + 1
		R[, j] <- W[2:G, t1] / W[1:(G - 1), t0]
	}

	if (!is.null(n_years)) {
		keep <- utils::tail(seq_len(ncol(R)), n_years)
		R <- R[, keep, drop = FALSE]
	}

	ratio <- summarise_ratios(R, method = method, weights = weights)

	data.frame(
		grade_from = go[-G],
		grade_to = go[-1],
		ratio = unname(ratio),
		stringsAsFactors = FALSE,
		row.names = NULL
	)
}
