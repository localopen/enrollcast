# Validate inputs and return cleaned pieces (grades, enrollment, order, years).
prepare_enrollment <- function(data, year, grade, enrollment, grade_order) {
  check_columns(data, c(year, grade, enrollment), "data")
  gr_raw <- data[[grade]]
  en <- data[[enrollment]]
  if (!is.numeric(en)) {
    stop("`enrollment` column must be numeric.", call. = FALSE)
  }
  if (any(en < 0, na.rm = TRUE)) {
    stop("`enrollment` must be non-negative.", call. = FALSE)
  }
  go <- resolve_grade_order(gr_raw, grade_order)
  if (length(go) < 2) {
    stop("Need at least 2 grades to compute progression ratios.", call. = FALSE)
  }
  yr_num <- suppressWarnings(as.numeric(as.character(data[[year]])))
  if (anyNA(yr_num)) {
    stop("`year` must be numeric or coercible to numeric.", call. = FALSE)
  }
  list(grade = as.character(gr_raw), enrollment = en, go = go, year = yr_num)
}

# Build a grade x year enrollment matrix from long records.
enrollment_matrix <- function(grade, year, enrollment, go) {
  years <- sort(unique(year))
  ri <- match(grade, go)
  ci <- match(year, years)
  if (anyNA(ri)) {
    stop("Some grades are not in the resolved grade order.", call. = FALSE)
  }
  if (anyDuplicated(cbind(ri, ci))) {
    stop("Duplicate (grade, year) rows in `data`.", call. = FALSE)
  }
  w <- matrix(
    NA_real_,
    nrow = length(go),
    ncol = length(years),
    dimnames = list(go, as.character(years))
  )
  w[cbind(ri, ci)] <- enrollment
  w
}

# Per-transition ratios: destination grade at t+1 over feeder grade at t.
transition_ratios <- function(w) {
  years <- as.numeric(colnames(w))
  trans <- which(diff(years) == 1)
  if (length(trans) == 0) {
    stop("No consecutive year pairs found to form transitions.", call. = FALSE)
  }
  w[-1, trans + 1, drop = FALSE] / w[-nrow(w), trans, drop = FALSE]
}

# Validate the optional n_years argument.
check_n_years <- function(n_years) {
  if (!is.null(n_years) && !is_count(n_years)) {
    stop("`n_years` must be a positive integer.", call. = FALSE)
  }
}

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
#' @param n_years Optional. Use only the most recent `n_years` transitions. If
#'   `n_years` exceeds the number of available transitions, all are used.
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
  check_n_years(n_years)
  clean <- prepare_enrollment(data, year, grade, enrollment, grade_order)
  w <- enrollment_matrix(clean$grade, clean$year, clean$enrollment, clean$go)
  r <- transition_ratios(w)
  if (!is.null(n_years)) {
    r <- r[, utils::tail(seq_len(ncol(r)), n_years), drop = FALSE]
  }
  if (any(is.infinite(r)) || any(is.nan(r))) {
    warning(
      "Some progression ratios are infinite or NaN because a feeder grade ",
      "had zero enrollment in at least one transition.",
      call. = FALSE
    )
  }
  ratio <- summarise_ratios(r, method = method, weights = weights)
  go <- clean$go
  data.frame(
    grade_from = go[-length(go)],
    grade_to = go[-1],
    ratio = unname(ratio),
    row.names = NULL
  )
}
