# Validate horizon and return it as an integer.
check_horizon <- function(horizon) {
  if (!is_count(horizon)) {
    stop("`horizon` must be a single positive integer.", call. = FALSE)
  }
  as.integer(horizon)
}

# Resolve exogenous entry-grade values for each projected year.
entry_values <- function(entry, horizon, base_vec, entry_grade) {
  if (is.null(entry)) {
    warning(
      sprintf(
        "`entry` not supplied; holding entry grade '%s' constant at %g.",
        entry_grade,
        base_vec[[entry_grade]]
      ),
      call. = FALSE
    )
    return(rep(base_vec[[entry_grade]], horizon))
  }
  as_entry_vector(entry, horizon)
}

# Advance enrollment one year at a time, overwriting the entry grade.
run_projection <- function(m, base_vec, entry_grade, entry_vals, out_years) {
  go <- rownames(m)
  n <- base_vec
  out <- matrix(NA_real_, nrow = length(go), ncol = length(out_years))
  for (h in seq_along(out_years)) {
    n <- drop(m %*% n)
    n[entry_grade] <- entry_vals[h]
    out[, h] <- n
  }
  data.frame(
    year = rep(out_years, each = length(go)),
    grade = rep(go, times = length(out_years)),
    enrollment = as.vector(out)
  )
}

#' Project enrollment forward
#'
#' Projects grade-level enrollment forward an arbitrary horizon using the grade
#' progression ratio method. Internally builds a projection matrix from `ratios`
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
  horizon <- check_horizon(horizon)
  m <- projection_matrix(ratios)
  go <- rownames(m)
  entry_grade <- go[1]
  n <- as_base_vector(base, go)
  if (is.null(start_year)) {
    start_year <- base_year(base)
  }
  entry_vals <- entry_values(entry, horizon, n, entry_grade)
  out_years <- if (is.null(start_year)) {
    seq_len(horizon)
  } else {
    start_year + seq_len(horizon)
  }
  run_projection(m, n, entry_grade, entry_vals, out_years)
}
