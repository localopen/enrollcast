# Ratio-summary helpers for progression_ratios(). Not exported.

check_weights_supplied <- function(
  method,
  weights,
  call = rlang::caller_env()
) {
  if (method != "weighted" && !is.null(weights)) {
    ec_abort(
      "{.arg weights} may only be supplied for {.code method = \"weighted\"}.",
      class = "enrollcast_error_weights_unused",
      call = call
    )
  }
  if (method == "weighted" && is.null(weights)) {
    ec_abort(
      "{.arg weights} is required for {.code method = \"weighted\"}.",
      class = "enrollcast_error_weights_missing",
      call = call
    )
  }
}

check_weights_values <- function(weights, call = rlang::caller_env()) {
  bad <- !is.numeric(weights) ||
    anyNA(weights) ||
    !all(is.finite(weights)) ||
    any(weights < 0)
  if (bad) {
    ec_abort(
      "{.arg weights} must be numeric, finite, non-missing, and non-negative.",
      class = "enrollcast_error_weights_values",
      call = call
    )
  }
}

check_weights_shape <- function(weights, R, call = rlang::caller_env()) {
  if (length(weights) != ncol(R)) {
    ec_abort(
      c(
        "{.arg weights} length must equal the number of transition years used.",
        "x" = "{.arg weights} has length {length(weights)}.",
        "i" = "There {?is/are} {ncol(R)} transition year{?s}."
      ),
      class = "enrollcast_error_weights_length",
      call = call
    )
  }
  if (sum(weights) <= 0) {
    ec_abort(
      "{.arg weights} must have a positive sum.",
      class = "enrollcast_error_weights_sum",
      call = call
    )
  }
}

check_ratio_weights <- function(
  R,
  method,
  weights,
  call = rlang::caller_env()
) {
  check_weights_supplied(method, weights, call = call)
  if (method != "weighted") {
    return(invisible())
  }
  check_weights_values(weights, call = call)
  check_weights_shape(weights, R, call = call)
}

summarise_ratio_row <- function(x, method, weights) {
  if (all(is.na(x))) {
    return(NA_real_)
  }
  if (method == "weighted" && sum(weights[!is.na(x)]) == 0) {
    return(NA_real_)
  }
  switch(
    method,
    mean = mean(x, na.rm = TRUE),
    median = stats::median(x, na.rm = TRUE),
    geometric = exp(mean(log(x), na.rm = TRUE)),
    last = {
      nn <- x[!is.na(x)]
      nn[[length(nn)]]
    },
    weighted = stats::weighted.mean(x, w = weights, na.rm = TRUE)
  )
}

# Collapse a (grades x transition-years) ratio matrix to one ratio per grade.
summarise_ratios <- function(
  R,
  method,
  weights = NULL,
  call = rlang::caller_env()
) {
  check_ratio_weights(R, method, weights, call = call)
  # `weights` is aligned most-recent -> oldest; rows of R run oldest ->
  # newest, so reverse to line the weights up with the columns.
  weights <- rev(weights)
  apply(R, 1, summarise_ratio_row, method = method, weights = weights)
}
