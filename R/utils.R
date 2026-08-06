# Internal helpers shared across the package. Not exported.

# TRUE if `x` is a single, non-missing whole number with `x >= min`.
is_whole_number <- function(x, min = -Inf) {
  is.numeric(x) && length(x) == 1 && is.finite(x) && x %% 1 == 0 && x >= min
}

# TRUE if `x` is a single, non-missing, positive integer value.
is_count <- function(x) {
  is_whole_number(x, min = 1)
}

check_data_frame <- function(
  x,
  arg,
  class,
  call = rlang::caller_env()
) {
  if (!is.data.frame(x)) {
    ec_abort(
      c(
        "{.arg {arg}} must be a data frame.",
        "x" = "You supplied {.obj_type_friendly {x}}."
      ),
      class = class,
      call = call
    )
  }
  invisible(x)
}

check_columns <- function(
  data,
  cols,
  arg = "data",
  call = rlang::caller_env()
) {
  missing <- setdiff(cols, names(data))
  if (length(missing)) {
    ec_abort(
      "{.arg {arg}} is missing required column{?s}: {.field {missing}}.",
      class = "enrollcast_error_missing_columns",
      call = call
    )
  }
  invisible(data)
}
