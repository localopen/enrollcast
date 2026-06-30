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

test_that("chain_order reconstructs the grade sequence", {
  expect_identical(chain_order(c("K", "1"), c("1", "2")), c("K", "1", "2"))
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

test_that("base_year returns NULL when no year can be derived", {
  expect_null(base_year(c(K = 120))) # not a data frame
  expect_null(base_year(data.frame(grade = "K", enrollment = 120))) # no column
  expect_null(base_year(
    data.frame(year = c(2022, 2023), grade = c("K", "1"), enrollment = c(1, 2))
  )) # ambiguous
  expect_null(base_year(
    data.frame(year = "spring", grade = "K", enrollment = 120)
  )) # not numeric-coercible
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

test_that("chain_order handles a single transition pair", {
  expect_identical(chain_order("K", "1"), c("K", "1"))
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

test_that("chain_order errors on ambiguous entry grade", {
  expect_snapshot(chain_order(c("K", "9"), c("1", "2")), error = TRUE)
  expect_error(
    chain_order(c("K", "9"), c("1", "2")),
    class = "enrollcast_error_ambiguous_entry"
  )
})

test_that("chain_order errors on branching transitions", {
  expect_snapshot(chain_order(c("K", "K", "1"), c("1", "2", "2")), error = TRUE)
  expect_error(
    chain_order(c("K", "K", "1"), c("1", "2", "2")),
    class = "enrollcast_error_branching_transitions"
  )
})

test_that("chain_order errors on a cycle", {
  expect_snapshot(chain_order(c("Z", "a", "b"), c("a", "b", "a")), error = TRUE)
  expect_error(
    chain_order(c("Z", "a", "b"), c("a", "b", "a")),
    class = "enrollcast_error_cyclic_transitions"
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

test_that("as_entry_vector errors on negative values", {
  expect_snapshot(as_entry_vector(c(130, -5), 2), error = TRUE)
  expect_error(
    as_entry_vector(c(130, -5), 2),
    class = "enrollcast_error_entry_negative"
  )
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

test_that("check_schedule accepts a valid schedule and returns grade order", {
  m <- projection_matrix(
    data.frame(grade_from = "K", grade_to = "1", ratio = 0.9)
  )
  expect_identical(
    check_schedule(list(
      list(matrix = m, entry = 1),
      list(matrix = m, entry = NULL)
    )),
    c("K", "1")
  )
})

test_that("check_schedule rejects malformed schedules", {
  m <- projection_matrix(
    data.frame(grade_from = "K", grade_to = "1", ratio = 0.9)
  )
  expect_snapshot(check_schedule(list()), error = TRUE)
  expect_error(
    check_schedule(list()),
    class = "enrollcast_error_schedule_shape"
  )
  expect_snapshot(check_schedule(list(list(entry = 1))), error = TRUE)
  expect_error(
    check_schedule(list(list(entry = 1))),
    class = "enrollcast_error_step_shape"
  )
  expect_snapshot(
    check_schedule(list(list(matrix = m[, 1, drop = FALSE]))),
    error = TRUE
  )
  expect_error(
    check_schedule(list(list(matrix = m[, 1, drop = FALSE]))),
    class = "enrollcast_error_step_not_square"
  )
  bad <- m
  colnames(bad) <- c("X", "Y")
  expect_snapshot(check_schedule(list(list(matrix = bad))), error = TRUE)
  expect_error(
    check_schedule(list(list(matrix = bad))),
    class = "enrollcast_error_step_dimnames"
  )
  m2 <- m
  dimnames(m2) <- list(c("1", "K"), c("1", "K"))
  expect_snapshot(
    check_schedule(list(list(matrix = m), list(matrix = m2))),
    error = TRUE
  )
  expect_error(
    check_schedule(list(list(matrix = m), list(matrix = m2))),
    class = "enrollcast_error_schedule_inconsistent"
  )
  expect_snapshot(
    check_schedule(list(list(matrix = m, entry = c(1, 2)))),
    error = TRUE
  )
  expect_error(
    check_schedule(list(list(matrix = m, entry = c(1, 2)))),
    class = "enrollcast_error_step_entry"
  )
})
