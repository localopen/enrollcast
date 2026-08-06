# Grade-order validation and resolution helpers. Not exported.

# Validate an explicit grade_order argument (no missing values, no duplicates).
check_grade_order_arg <- function(grade_order, call = rlang::caller_env()) {
  if (anyNA(grade_order)) {
    ec_abort(
      c(
        "{.arg grade_order} must not contain missing values.",
        "x" = "Found {sum(is.na(grade_order))} missing value{?s}."
      ),
      class = "enrollcast_error_grade_order_na",
      call = call
    )
  }
  if (anyDuplicated(grade_order)) {
    ec_abort(
      c(
        "{.arg grade_order} must not contain duplicate grades.",
        "x" = paste0(
          "Duplicated grade{?s}: ",
          "{.field {unique(grade_order[duplicated(grade_order)])}}."
        )
      ),
      class = "enrollcast_error_grade_order_duplicate",
      call = call
    )
  }
  invisible(grade_order)
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
    check_grade_order_arg(grade_order, call = call)
    missing_g <- setdiff(u, grade_order)
    if (length(missing_g)) {
      ec_abort(
        "{.arg grade_order} is missing grade{?s}: {.field {missing_g}}.",
        class = "enrollcast_error_grade_order_incomplete",
        call = call
      )
    }

    missing_go <- setdiff(grade_order, u)
    if (length(missing_go)) {
      ec_warn(
        paste0(
          "{.arg grade_order} contains grade{?s} ",
          "missing from data: {.field {missing_go}}."
        ),
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
  ec_warn(
    c(
      "Grade order guessed by sorting labels alphabetically.",
      "i" = paste0(
        "Pass {.arg grade_order} or a factor ",
        "{.arg grade} to set it explicitly."
      )
    ),
    class = "enrollcast_warning_grade_order_guessed"
  )
  sort(u)
}
