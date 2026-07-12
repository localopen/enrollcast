test_that("resolve_grade_order uses factor levels", {
  g <- factor(c("1", "K", "2"), levels = c("K", "1", "2"))
  expect_identical(resolve_grade_order(g), c("K", "1", "2"))
})

test_that("resolve_grade_order sorts numeric grades numerically", {
  expect_identical(resolve_grade_order(c(10, 2, 1)), c("1", "2", "10"))
})

test_that("resolve_grade_order honours explicit grade_order", {
  expect_identical(
    resolve_grade_order(c("1", "K", "2"), grade_order = c("K", "1", "2")),
    c("K", "1", "2")
  )
})

test_that("summarise_ratios computes each method", {
  R <- matrix(c(0.95, 0.9), nrow = 1, dimnames = list("1", c("2022", "2023")))
  expect_equal(summarise_ratios(R, "mean"), c("1" = 0.925))
  expect_equal(summarise_ratios(R, "last"), c("1" = 0.9))
  expect_equal(summarise_ratios(R, "median"), c("1" = 0.925))
  expect_equal(summarise_ratios(R, "geometric"), c("1" = sqrt(0.855)))
  expect_equal(
    summarise_ratios(R, "weighted", weights = c(2, 1)),
    c("1" = (0.9 * 2 + 0.95 * 1) / 3)
  )
})

test_that("summarise_ratios returns NA_real_ for all-NA rows", {
  R <- matrix(NA_real_, nrow = 1, ncol = 2, dimnames = list("1", NULL))
  methods <- c("mean", "median", "geometric", "last", "weighted")
  for (method in methods) {
    weights <- if (method == "weighted") c(1, 1) else NULL
    expect_identical(
      summarise_ratios(R, method, weights),
      c("1" = NA_real_)
    )
  }
})

test_that("weighted summaries return NA when observations have zero weight", {
  R <- matrix(c(NA_real_, 0.9), nrow = 1, dimnames = list("1", NULL))
  expect_identical(
    summarise_ratios(R, "weighted", weights = c(0, 1)),
    c("1" = NA_real_)
  )
})

test_that("as_base_vector aligns a data frame to the grade order", {
  df <- data.frame(
    year = 2023,
    grade = c("2", "K", "1"),
    enrollment = c(91, 120, 99)
  )
  expect_identical(
    as_base_vector(df, c("K", "1", "2")),
    c(K = 120, `1` = 99, `2` = 91)
  )
})

test_that("as_base_vector accepts a named numeric vector", {
  v <- c(K = 120, `1` = 99, `2` = 91)
  expect_identical(as_base_vector(v, c("K", "1", "2")), v)
})

test_that("base_year derives the year from a single-year base data frame", {
  df <- data.frame(year = 2023, grade = "K", enrollment = 120)
  expect_identical(base_year(df), 2023)
})

test_that("base_year returns NULL when base has no year column", {
  expect_null(base_year(c(K = 120))) # not a data frame
  expect_null(base_year(data.frame(grade = "K", enrollment = 120))) # no column
})

test_that("base_year rejects invalid years", {
  invalid <- list(c(2022, 2023), "spring", NA_real_, Inf, 2023.5)
  for (year in invalid) {
    base <- data.frame(
      year = year,
      grade = rep("K", length(year)),
      enrollment = rep(120, length(year))
    )
    expect_error(base_year(base), class = "enrollcast_error_base_year")
  }
  expect_snapshot(
    base_year(data.frame(
      year = c(2022, 2023),
      grade = c("K", "1"),
      enrollment = c(1, 2)
    )),
    error = TRUE
  )
})

test_that("as_entry_vector returns a validated numeric vector", {
  expect_identical(as_entry_vector(c(130, 140), 2), c(130, 140))
})

test_that("as_entry_vector accepts a data frame value column", {
  expect_identical(
    as_entry_vector(data.frame(enrollment = c(130, 140)), 2),
    c(130, 140)
  )
  expect_identical(
    as_entry_vector(data.frame(value = c(130, 140)), 2),
    c(130, 140)
  )
})

test_that("check_columns errors on missing columns", {
  df <- data.frame(a = 1, b = 2)
  expect_snapshot(check_columns(df, c("a", "c"), "df"), error = TRUE)
  expect_error(
    check_columns(df, c("a", "c"), "df"),
    class = "enrollcast_error_missing_columns"
  )
})

test_that("resolve_grade_order errors when grade_order omits a grade", {
  expect_snapshot(
    resolve_grade_order(c("K", "1", "2"), grade_order = c("K", "1")),
    error = TRUE
  )
  expect_error(
    resolve_grade_order(c("K", "1", "2"), grade_order = c("K", "1")),
    class = "enrollcast_error_grade_order_incomplete"
  )
})

test_that("resolve_grade_order warns when guessing character order", {
  expect_snapshot(resolve_grade_order(c("K", "1", "2")))
  expect_warning(
    resolve_grade_order(c("K", "1", "2")),
    class = "enrollcast_warning_grade_order_guessed"
  )
})

test_that("resolve_grade_order warns when grade_order has grades absent from data", {
  expect_snapshot(
    res <- resolve_grade_order(
      c("K", "1", "2"),
      grade_order = c("K", "1", "2", "3")
    )
  )
  expect_identical(res, c("K", "1", "2"))
  expect_warning(
    resolve_grade_order(c("K", "1", "2"), grade_order = c("K", "1", "2", "3")),
    class = "enrollcast_warning_grade_order_extra"
  )
})

test_that("summarise_ratios weighted errors on length mismatch", {
  R <- matrix(c(0.95, 0.9), nrow = 1, dimnames = list("1", c("2022", "2023")))
  expect_snapshot(
    summarise_ratios(R, "weighted", weights = c(1, 2, 3)),
    error = TRUE
  )
  expect_error(
    summarise_ratios(R, "weighted", weights = c(1, 2, 3)),
    class = "enrollcast_error_weights_length"
  )
})

test_that("as_base_vector errors on missing grade", {
  expect_snapshot(
    as_base_vector(c(K = 120, `1` = 99), c("K", "1", "2")),
    error = TRUE
  )
  expect_error(
    as_base_vector(c(K = 120, `1` = 99), c("K", "1", "2")),
    class = "enrollcast_error_base_incomplete"
  )
})

test_that("as_entry_vector errors on length mismatch", {
  expect_snapshot(as_entry_vector(c(130, 140), 3), error = TRUE)
  expect_error(
    as_entry_vector(c(130, 140), 3),
    class = "enrollcast_error_entry_length"
  )
})

test_that("as_base_vector warns on extra grades", {
  v <- c(K = 120, `1` = 99, `2` = 91, `3` = 50)
  expect_snapshot(res <- as_base_vector(v, c("K", "1", "2")))
  expect_warning(
    as_base_vector(v, c("K", "1", "2")),
    class = "enrollcast_warning_base_extra"
  )
})

test_that("as_base_vector errors on negative enrollment", {
  expect_snapshot(
    as_base_vector(c(K = -1, `1` = 99, `2` = 91), c("K", "1", "2")),
    error = TRUE
  )
  expect_error(
    as_base_vector(c(K = -1, `1` = 99, `2` = 91), c("K", "1", "2")),
    class = "enrollcast_error_base_negative"
  )
})

test_that("as_base_vector rejects invalid enrollment values", {
  invalid <- list(
    c(K = NA_real_, `1` = 99, `2` = 91),
    c(K = Inf, `1` = 99, `2` = 91),
    data.frame(grade = c("K", "1", "2"), enrollment = c("120", "99", "91"))
  )
  for (base in invalid) {
    expect_error(
      as_base_vector(base, c("K", "1", "2")),
      class = "enrollcast_error_base_values"
    )
  }
  expect_snapshot(
    as_base_vector(c(K = NA_real_, `1` = 99, `2` = 91), c("K", "1", "2")),
    error = TRUE
  )
})

test_that("as_base_vector validates enrollment on extra grades", {
  base <- c(K = 120, `1` = 99, `2` = 91, extra = Inf)
  expect_error(
    as_base_vector(base, c("K", "1", "2")),
    class = "enrollcast_error_base_values"
  )
})

test_that("as_base_vector rejects duplicate or missing grade names", {
  invalid <- list(
    data.frame(grade = c("K", "K", "2"), enrollment = c(120, 99, 91)),
    data.frame(grade = c("K", NA, "2"), enrollment = c(120, 99, 91)),
    setNames(c(120, 99, 91), c("K", "K", "2")),
    setNames(c(120, 99, 91), c("K", NA, "2"))
  )
  for (base in invalid) {
    expect_error(
      as_base_vector(base, c("K", "1", "2")),
      class = "enrollcast_error_base_grade_names"
    )
  }
  expect_snapshot(
    as_base_vector(
      setNames(c(120, 99, 91), c("K", "K", "2")),
      c("K", "1", "2")
    ),
    error = TRUE
  )
})

test_that("as_entry_vector errors on negative values", {
  expect_snapshot(as_entry_vector(c(130, -5), 2), error = TRUE)
  expect_error(
    as_entry_vector(c(130, -5), 2),
    class = "enrollcast_error_entry_negative"
  )
})

test_that("as_entry_vector rejects invalid values without coercion", {
  invalid <- list(
    c(130, NA_real_),
    c(130, Inf),
    data.frame(enrollment = c("130", "140")),
    data.frame(value = c(130, NA_real_))
  )
  for (entry in invalid) {
    expect_error(
      as_entry_vector(entry, 2),
      class = "enrollcast_error_entry_values"
    )
  }
  expect_snapshot(as_entry_vector(c(130, NA_real_), 2), error = TRUE)
})

test_that("summarise_ratios last returns NA when all transitions are NA", {
  R <- matrix(NA_real_, nrow = 1, dimnames = list("1", "2023"))
  expect_identical(summarise_ratios(R, "last"), c("1" = NA_real_))
})

test_that("summarise_ratios weighted errors when weights are missing", {
  R <- matrix(c(0.95, 0.9), nrow = 1, dimnames = list("1", c("2022", "2023")))
  expect_snapshot(summarise_ratios(R, "weighted"), error = TRUE)
  expect_error(
    summarise_ratios(R, "weighted"),
    class = "enrollcast_error_weights_missing"
  )
})

test_that("as_base_vector errors on an invalid base type", {
  expect_snapshot(as_base_vector(c(1, 2, 3), c("K", "1", "2")), error = TRUE)
  expect_error(
    as_base_vector(c(1, 2, 3), c("K", "1", "2")),
    class = "enrollcast_error_base_type"
  )
})

test_that("as_entry_vector errors on a data frame without a value column", {
  expect_snapshot(as_entry_vector(data.frame(x = 1:2), 2), error = TRUE)
  expect_error(
    as_entry_vector(data.frame(x = 1:2), 2),
    class = "enrollcast_error_entry_no_value_col"
  )
})

test_that("as_entry_vector errors on an unsupported entry type", {
  expect_snapshot(as_entry_vector("oops", 2), error = TRUE)
  expect_error(
    as_entry_vector("oops", 2),
    class = "enrollcast_error_entry_type"
  )
})
