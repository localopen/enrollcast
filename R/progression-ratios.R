check_enrollment_selectors <- function(
  data,
  year,
  grade,
  enrollment,
  call = rlang::caller_env()
) {
  selectors <- list(year = year, grade = grade, enrollment = enrollment)
  valid_selectors <- vapply(
    selectors,
    function(x) is.character(x) && length(x) == 1 && !is.na(x),
    logical(1)
  )
  if (!all(valid_selectors) || anyDuplicated(unlist(selectors))) {
    cli::cli_abort(
      c(
        "{.arg year}, {.arg grade}, and {.arg enrollment} must be distinct non-missing character scalars.",
        "x" = "Each argument must select exactly one different column in {.arg data}."
      ),
      class = "enrollcast_error_column_selector",
      call = call
    )
  }
  check_columns(data, c(year, grade, enrollment), "data", call = call)
}

check_enrollment_values <- function(
  data,
  enrollment,
  call = rlang::caller_env()
) {
  if (!is.numeric(data[[enrollment]])) {
    cli::cli_abort(
      c(
        "The {.field {enrollment}} column of {.arg data} must be numeric.",
        "x" = "{.field {enrollment}} is {.cls {class(data[[enrollment]])}}."
      ),
      class = "enrollcast_error_enrollment_type",
      call = call
    )
  }

  invalid_enrollment <- is.nan(data[[enrollment]]) |
    (!is.na(data[[enrollment]]) & !is.finite(data[[enrollment]]))
  if (any(invalid_enrollment)) {
    cli::cli_abort(
      c(
        "The {.field {enrollment}} column of {.arg data} must contain finite values or {.val {NA}}.",
        "x" = "Found {sum(invalid_enrollment)} non-finite value{?s}."
      ),
      class = "enrollcast_error_enrollment_nonfinite",
      call = call
    )
  }

  if (any(data[[enrollment]] < 0, na.rm = TRUE)) {
    cli::cli_abort(
      c(
        "The {.field {enrollment}} column of {.arg data} must be non-negative.",
        "x" = "Found {sum(data[[enrollment]] < 0, na.rm = TRUE)} negative value{?s}."
      ),
      class = "enrollcast_error_enrollment_negative",
      call = call
    )
  }
}

check_enrollment_grades <- function(data, grade, call = rlang::caller_env()) {
  if (anyNA(data[[grade]])) {
    cli::cli_abort(
      c(
        "The {.field {grade}} column of {.arg data} must not contain missing values.",
        "x" = "Found {sum(is.na(data[[grade]]))} missing value{?s}."
      ),
      class = "enrollcast_error_grade_na",
      call = call
    )
  }

  if (length(unique(as.character(data[[grade]]))) < 2) {
    cli::cli_abort(
      c(
        "{.arg data} must contain at least 2 grades to compute progression ratios.",
        "x" = "The {.field {grade}} column has {length(unique(as.character(data[[grade]])))} grade{?s}."
      ),
      class = "enrollcast_error_too_few_grades",
      call = call
    )
  }
}

coerce_enrollment_year <- function(data, year, call = rlang::caller_env()) {
  yr <- suppressWarnings(as.numeric(as.character(data[[year]])))
  invalid_year <- is.na(yr) |
    !is.finite(yr) |
    (is.finite(yr) & yr %% 1 != 0)
  if (any(invalid_year)) {
    cli::cli_abort(
      c(
        "The {.field {year}} column of {.arg data} must be coercible to finite integers.",
        "x" = "Found {sum(invalid_year)} invalid value{?s}."
      ),
      class = "enrollcast_error_year_type",
      call = call
    )
  }
  yr
}

# Validate inputs and return cleaned pieces (grades, enrollment, order, years).
prepare_enrollment <- function(
  data,
  year,
  grade,
  enrollment,
  grade_order,
  call = rlang::caller_env()
) {
  check_data_frame(
    data,
    "data",
    "enrollcast_error_data_type",
    call = call
  )
  check_enrollment_selectors(data, year, grade, enrollment, call = call)
  check_enrollment_values(data, enrollment, call = call)
  check_enrollment_grades(data, grade, call = call)
  data[[year]] <- coerce_enrollment_year(data, year, call = call)

  # Honour an explicit grade_order even for an already-ordered factor; otherwise
  # trust the ordered factor's levels (dropping any that are unused).
  if (!is.ordered(data[[grade]]) || !is.null(grade_order)) {
    go <- resolve_grade_order(data[[grade]], grade_order, call = call)
    data[[grade]] <- factor(
      as.character(data[[grade]]),
      levels = go,
      ordered = TRUE
    )
  } else {
    data[[grade]] <- droplevels(data[[grade]])
  }

  data
}

# Build a grade x year enrollment matrix from long records.
enrollment_matrix <- function(
  data,
  year,
  grade,
  enrollment,
  call = rlang::caller_env()
) {
  go <- levels(data[[grade]])
  years <- sort(unique(data[[year]]))

  if (anyDuplicated(data[, c(grade, year)]) > 0) {
    cli::cli_abort(
      c(
        "{.arg data} must have one row per grade per year.",
        "x" = "Found duplicate ({.field {grade}}, {.field {year}}) row{?s}.",
        "i" = "Aggregate or de-duplicate before calling {.fn progression_ratios}."
      ),
      class = "enrollcast_error_duplicate_rows",
      call = call
    )
  }

  # Fill in missing (grade, year) combinations with NA
  expand <- expand.grid(
    stats::setNames(list(years, go), c(year, grade))
  )

  data <- merge(expand, data, by = c(year, grade), all.x = TRUE)

  data <- data[order(data[[year]], data[[grade]]), ]

  w <- matrix(
    data[[enrollment]],
    nrow = length(go),
    ncol = length(years),
    dimnames = list(go, as.character(years))
  )
  w
}

# Per-transition ratios: destination grade at t+1 over feeder grade at t.
transition_ratios <- function(w, call = rlang::caller_env()) {
  years <- as.numeric(colnames(w))
  year_differences <- diff(years)
  trans <- which(year_differences == 1)
  if (length(trans) == 0) {
    cli::cli_abort(
      c(
        "Cannot compute progression ratios without consecutive years.",
        "x" = "{.arg data} has no adjacent year pair.",
        "i" = "Years present: {.val {as.numeric(colnames(w))}}."
      ),
      class = "enrollcast_error_no_transitions",
      call = call
    )
  }

  gaps <- which(year_differences > 1)
  if (length(gaps) > 0) {
    gap_pairs <- paste0(years[gaps], " -> ", years[gaps + 1])
    cli::cli_warn(
      c(
        "Historical years are not consecutive.",
        "i" = "Only adjacent-year transitions will be used.",
        "!" = "{cli::qty(length(gaps))}Gap{?s} between observed years: {.val {gap_pairs}}."
      ),
      class = "enrollcast_warning_year_gaps"
    )
  }

  w[-1, trans + 1, drop = FALSE] / w[-nrow(w), trans, drop = FALSE]
}

# Validate the optional n_years argument.
check_n_years <- function(n_years, call = rlang::caller_env()) {
  if (!is.null(n_years) && !is_count(n_years)) {
    cli::cli_abort(
      c(
        "{.arg n_years} must be a single positive integer.",
        "x" = "You supplied {.obj_type_friendly {n_years}}."
      ),
      class = "enrollcast_error_n_years",
      call = call
    )
  }
}

#' Compute grade progression ratios
#'
#' Calculates cohort survival / grade progression ratios from historical
#' grade-level enrollment. For each non-entry grade, the ratio is enrollment
#' in that grade divided by enrollment in the grade below one year earlier,
#' summarised across the available year-to-year transitions.
#'
#' Only transitions between observed consecutive calendar years are used. If
#' the history has one or more calendar-year gaps but still contains an adjacent
#' year pair, the gaps are reported in a warning and are not bridged. Histories
#' with no adjacent year pair are rejected.
#'
#' @param data A long data frame or data-frame subclass of historical enrollment
#'   with one row per grade per year. Enrollment may be `NA`, but non-missing
#'   values must be finite and non-negative; `NaN` and infinite values are
#'   rejected. Year values must be coercible to finite integers and must not be
#'   missing.
#' @param year,grade,enrollment Distinct, non-missing character scalars naming
#'   columns in `data`. Defaults are `"year"`, `"grade"`, and `"enrollment"`.
#' @param method How to summarise per-year ratios into one ratio per grade:
#'   `"mean"` (default), `"geometric"`, `"median"`, `"last"` (most recent
#'   transition only), or `"weighted"`.
#' @param n_years Optional. Use only the most recent `n_years` available
#'   adjacent-year transitions. If `n_years` exceeds the number of available
#'   transitions, all are used.
#' @param weights For `method = "weighted"`, a finite, non-missing,
#'   non-negative numeric vector aligned most-recent to oldest, with one weight
#'   per transition year used and a positive sum. Do not supply weights for
#'   other methods.
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
#'
#' # For method = "weighted", weights align most-recent to oldest: here the
#' # 2022->2023 transition gets weight 2 and 2021->2022 gets weight 1.
#' progression_ratios(history, method = "weighted", weights = c(2, 1))
#'
#' # The same K -> 1 ratio via stats::weighted.mean(). Unlike `weights`
#' # above, weighted.mean() pairs each weight with the value at the same
#' # position, and the per-year ratios run oldest to newest -- so the
#' # weights must be reversed to line up.
#' k_ratios <- c(95 / 100, 99 / 110) # 2021->2022, then 2022->2023
#' stats::weighted.mean(k_ratios, rev(c(2, 1)))
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
  w <- enrollment_matrix(clean, year, grade, enrollment)
  r <- transition_ratios(w)
  if (!is.null(n_years)) {
    r <- r[, utils::tail(seq_len(ncol(r)), n_years), drop = FALSE]
  }
  if (any(is.infinite(r)) || any(is.nan(r))) {
    cli::cli_warn(
      c(
        "{sum(is.infinite(r) | is.nan(r))} progression ratio{?s} {?is/are} infinite or {.val {NaN}}.",
        "!" = "A feeder grade had zero enrollment in at least one transition."
      ),
      class = "enrollcast_warning_undefined_ratios"
    )
  }
  ratio <- summarise_ratios(r, method = method, weights = weights)
  go <- levels(clean[[grade]])
  data.frame(
    grade_from = go[-length(go)],
    grade_to = go[-1],
    ratio = unname(ratio),
    row.names = NULL
  )
}
