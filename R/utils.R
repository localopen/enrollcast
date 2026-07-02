# Internal helpers. Not exported.

# TRUE if `x` is a single, non-missing, positive integer value.
is_count <- function(x) {
  is.numeric(x) && length(x) == 1 && is.finite(x) && x %% 1 == 0 && x >= 1
}

check_columns <- function(
  data,
  cols,
  arg = "data",
  call = rlang::caller_env()
) {
  missing <- setdiff(cols, names(data))
  if (length(missing)) {
    cli::cli_abort(
      c(
        "{.arg {arg}} is missing required column{?s}: {.field {missing}}."
      ),
      class = "enrollcast_error_missing_columns",
      call = call
    )
  }
  invisible(data)
}

# Resolve grades to a low -> high character ordering.
resolve_grade_order <- function(
  grade,
  grade_order = NULL,
  call = rlang::caller_env()
) {
  u <- unique(as.character(grade))
  if (!is.null(grade_order)) {
    grade_order <- as.character(grade_order)
    missing_g <- setdiff(u, grade_order)
    if (length(missing_g)) {
      cli::cli_abort(
        "{.arg grade_order} is missing grade{?s}: {.field {missing_g}}.",
        class = "enrollcast_error_grade_order_incomplete",
        call = call
      )
    }

    missing_go <- setdiff(grade_order, u)
    if (length(missing_go)) {
      cli::cli_warn(
        "{.arg grade_order} contains grade{?s} missing from data: {.field {missing_go}}.",
        class = "enrollcast_warning_grade_order_extra"
      )
    }
    return(grade_order[grade_order %in% u])
  }

  if (is.factor(grade)) {
    lev <- levels(grade)
    return(lev[lev %in% u])
  }

  num <- suppressWarnings(as.numeric(u))
  if (!anyNA(num)) {
    return(u[order(num)])
  }
  # Mixed alpha/numeric labels (e.g. "K", "1", "2") always reach this path.
  cli::cli_warn(
    c(
      "Grade order guessed by sorting labels alphabetically.",
      "i" = "Pass {.arg grade_order} or a factor {.arg grade} to set it explicitly."
    ),
    class = "enrollcast_warning_grade_order_guessed"
  )
  sort(u)
}

# Collapse a (grades x transition-years) ratio matrix to one ratio per grade.
summarise_ratios <- function(
  R,
  method,
  weights = NULL,
  call = rlang::caller_env()
) {
  if (method == "weighted") {
    if (is.null(weights)) {
      cli::cli_abort(
        "{.arg weights} is required for {.code method = \"weighted\"}.",
        class = "enrollcast_error_weights_missing",
        call = call
      )
    }
    if (length(weights) != ncol(R)) {
      cli::cli_abort(
        c(
          "{.arg weights} length must equal the number of transition years used.",
          "x" = "{.arg weights} has length {length(weights)}.",
          "i" = "There {cli::qty(ncol(R))}{?is/are} {ncol(R)} transition year{?s}."
        ),
        class = "enrollcast_error_weights_length",
        call = call
      )
    }
  }
  apply(R, 1, function(x) {
    switch(
      method,
      mean = mean(x, na.rm = TRUE),
      median = stats::median(x, na.rm = TRUE),
      geometric = exp(mean(log(x), na.rm = TRUE)),
      last = {
        nn <- x[!is.na(x)]
        if (length(nn)) nn[[length(nn)]] else NA_real_
      },
      weighted = stats::weighted.mean(x, w = rev(weights), na.rm = TRUE)
    )
  })
}

# Coerce `base` to a named numeric vector ordered by `go`.
as_base_vector <- function(base, go, call = rlang::caller_env()) {
  if (is.data.frame(base)) {
    check_columns(base, c("grade", "enrollment"), "base", call = call)
    v <- stats::setNames(as.numeric(base$enrollment), as.character(base$grade))
  } else if (is.numeric(base) && !is.null(names(base))) {
    v <- base
  } else {
    cli::cli_abort(
      c(
        "{.arg base} must be a data frame (grade, enrollment) or a named numeric vector.",
        "x" = "You supplied {.obj_type_friendly {base}}."
      ),
      class = "enrollcast_error_base_type",
      call = call
    )
  }
  missing <- setdiff(go, names(v))
  if (length(missing)) {
    cli::cli_abort(
      "{.arg base} is missing enrollment for grade{?s}: {.field {missing}}.",
      class = "enrollcast_error_base_incomplete",
      call = call
    )
  }
  extra <- setdiff(names(v), go)
  if (length(extra)) {
    cli::cli_warn(
      "{.arg base} contains grade{?s} not in {.arg ratios} that will be ignored: {.field {extra}}.",
      class = "enrollcast_warning_base_extra"
    )
  }
  vv <- v[go]
  if (any(!is.na(vv) & vv < 0)) {
    cli::cli_abort(
      "{.arg base} enrollment must be non-negative.",
      class = "enrollcast_error_base_negative",
      call = call
    )
  }
  vv
}

# Year label derived from `base`: the single numeric-coercible value of a
# `year` column when `base` is a data frame, else NULL.
base_year <- function(base) {
  if (!is.data.frame(base) || !"year" %in% names(base)) {
    return(NULL)
  }
  uy <- unique(base$year)
  if (length(uy) != 1) {
    return(NULL)
  }
  y <- suppressWarnings(as.numeric(as.character(uy)))
  if (is.na(y)) NULL else y
}

# Coerce `entry` to a numeric vector of length `horizon`.
as_entry_vector <- function(entry, horizon, call = rlang::caller_env()) {
  if (is.data.frame(entry)) {
    valcol <- intersect(c("enrollment", "value"), names(entry))
    if (length(valcol) == 0) {
      cli::cli_abort(
        "{.arg entry} data frame must have an {.field enrollment} or {.field value} column.",
        class = "enrollcast_error_entry_no_value_col",
        call = call
      )
    }
    vals <- as.numeric(entry[[valcol[1]]])
  } else if (is.numeric(entry)) {
    vals <- entry
  } else {
    cli::cli_abort(
      c(
        "{.arg entry} must be a numeric vector or a data frame with a value column.",
        "x" = "You supplied {.obj_type_friendly {entry}}."
      ),
      class = "enrollcast_error_entry_type",
      call = call
    )
  }
  if (length(vals) != horizon) {
    cli::cli_abort(
      c(
        "{.arg entry} length must equal {.arg horizon}.",
        "x" = "{.arg entry} has length {length(vals)} but {.arg horizon} is {horizon}."
      ),
      class = "enrollcast_error_entry_length",
      call = call
    )
  }
  if (any(!is.na(vals) & vals < 0)) {
    cli::cli_abort(
      "{.arg entry} values must be non-negative.",
      class = "enrollcast_error_entry_negative",
      call = call
    )
  }
  vals
}
