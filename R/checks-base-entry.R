# Validators for `base` and `entry` inputs. Not exported.

coerce_base_vector <- function(base, call = rlang::caller_env()) {
  if (is.data.frame(base)) {
    check_columns(base, c("grade", "enrollment"), "base", call = call)
    grade <- as.character(base$grade)
    if (!is.numeric(base$enrollment)) {
      ec_abort(
        "{.arg base} enrollment must be numeric, finite, and non-missing.",
        class = "enrollcast_error_base_values",
        call = call
      )
    }
    v <- stats::setNames(base$enrollment, grade)
  } else if (is.numeric(base) && !is.null(names(base))) {
    v <- base
  } else {
    ec_abort(
      c(
        paste0(
          "{.arg base} must be a data frame (grade, ",
          "enrollment) or a named numeric vector."
        ),
        "x" = "You supplied {.obj_type_friendly {base}}."
      ),
      class = "enrollcast_error_base_type",
      call = call
    )
  }
  v
}

check_base_values <- function(v, call = rlang::caller_env()) {
  if (anyNA(v) || !all(is.finite(v))) {
    ec_abort(
      "{.arg base} enrollment must be numeric, finite, and non-missing.",
      class = "enrollcast_error_base_values",
      call = call
    )
  }
  if (any(v < 0)) {
    ec_abort(
      "{.arg base} enrollment must be non-negative.",
      class = "enrollcast_error_base_negative",
      call = call
    )
  }
}

align_base_grades <- function(v, go, call = rlang::caller_env()) {
  if (anyNA(names(v)) || !all(nzchar(names(v))) || anyDuplicated(names(v))) {
    ec_abort(
      "{.arg base} grade names must be present and unique.",
      class = "enrollcast_error_base_grade_names",
      call = call
    )
  }
  missing <- setdiff(go, names(v))
  if (length(missing)) {
    ec_abort(
      "{.arg base} is missing enrollment for grade{?s}: {.field {missing}}.",
      class = "enrollcast_error_base_incomplete",
      call = call
    )
  }
  extra <- setdiff(names(v), go)
  if (length(extra)) {
    ec_warn(
      paste0(
        "{.arg base} contains grade{?s} not in {.arg ratios} ",
        "that will be ignored: {.field {extra}}."
      ),
      class = "enrollcast_warning_base_extra"
    )
  }
  v[go]
}

# Coerce `base` to a named numeric vector ordered by `go`.
as_base_vector <- function(base, go, call = rlang::caller_env()) {
  v <- coerce_base_vector(base, call = call)
  check_base_values(v, call = call)
  align_base_grades(v, go, call = call)
}

# Year label derived from `base`: the single integer-like value of a `year`
# column when `base` is a data frame, else NULL.
base_year <- function(base, call = rlang::caller_env()) {
  if (!is.data.frame(base) || !"year" %in% names(base)) {
    return(NULL)
  }
  uy <- unique(base$year)
  y <- suppressWarnings(as.numeric(as.character(uy)))
  if (!is_whole_number(y)) {
    ec_abort(
      "{.arg base} year must contain one finite integer value.",
      class = "enrollcast_error_base_year",
      call = call
    )
  }
  if (abs(y) > .Machine$integer.max) {
    ec_abort(
      "{.arg base} year must be within the R integer range.",
      class = "enrollcast_error_base_year",
      call = call
    )
  }
  y
}

# Extract and validate `entry` as a numeric vector of length `horizon`.
as_entry_vector <- function(entry, horizon, call = rlang::caller_env()) {
  if (is.data.frame(entry)) {
    valcol <- intersect(c("enrollment", "value"), names(entry))
    if (length(valcol) == 0) {
      ec_abort(
        paste0(
          "{.arg entry} data frame must have an ",
          "{.field enrollment} or {.field value} column."
        ),
        class = "enrollcast_error_entry_no_value_col",
        call = call
      )
    }
    vals <- entry[[valcol[1]]]
  } else if (is.numeric(entry)) {
    vals <- entry
  } else {
    ec_abort(
      c(
        paste0(
          "{.arg entry} must be a numeric vector ",
          "or a data frame with a value column."
        ),
        "x" = "You supplied {.obj_type_friendly {entry}}."
      ),
      class = "enrollcast_error_entry_type",
      call = call
    )
  }
  if (!is.numeric(vals) || anyNA(vals) || !all(is.finite(vals))) {
    ec_abort(
      "{.arg entry} values must be numeric, finite, and non-missing.",
      class = "enrollcast_error_entry_values",
      call = call
    )
  }
  if (length(vals) != horizon) {
    ec_abort(
      c(
        "{.arg entry} length must equal {.arg horizon}.",
        "x" = paste0(
          "{.arg entry} has length {length(vals)} ",
          "but {.arg horizon} is {horizon}."
        )
      ),
      class = "enrollcast_error_entry_length",
      call = call
    )
  }
  if (any(vals < 0)) {
    ec_abort(
      "{.arg entry} values must be non-negative.",
      class = "enrollcast_error_entry_negative",
      call = call
    )
  }
  vals
}
