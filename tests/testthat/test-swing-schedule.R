test_that("swing_schedule lays out swing, recovery, and normal regimes", {
  s <- swing_schedule(
    fixture_ratios(),
    horizon = 6,
    swing_years = 2,
    recovery = c(1.10, 1.10, 1.05),
    entry = 130
  )
  expect_length(s, 6)
  expect_identical(s[[1]]$matrix, s[[2]]$matrix) # identity, repeated
  expect_identical(diag(s[[1]]$matrix), c(K = 1, `1` = 1, `2` = 1))
  expect_null(s[[1]]$entry)
  expect_equal(diag(s[[3]]$matrix), c(K = 1.10, `1` = 1.10, `2` = 1.10))
  expect_null(s[[4]]$entry)
  expect_identical(s[[6]]$entry, 130) # normal year carries entry
})

test_that("swing_schedule reproduces the worked trajectory", {
  s <- swing_schedule(
    fixture_ratios(),
    horizon = 6,
    swing_years = 2,
    recovery = c(1.10, 1.10, 1.05),
    entry = 130
  )
  p <- project_enrollment(c(K = 80, `1` = 66, `2` = 60), schedule = s)
  k <- p$enrollment[p$grade == "K"]
  expect_equal(k, c(80, 80, 88, 96.8, 101.64, 130))
  expect_equal(p$enrollment[p$year == 6 & p$grade == "1"], 0.925 * 101.64)
})

test_that("grade-specific recovery uses a matrix of multipliers", {
  # G x 1: one recovery year, per-grade
  rec <- matrix(c(1.2, 1.1, 1.0), nrow = 3)
  s <- swing_schedule(
    fixture_ratios(),
    horizon = 2,
    swing_years = 1,
    recovery = rec,
    entry = NULL
  )
  expect_equal(diag(s[[2]]$matrix), c(K = 1.2, `1` = 1.1, `2` = 1.0))
})

test_that("named recovery matrices are aligned to projection grade order", {
  rec <- matrix(
    c(1.0, 1.2, 1.1),
    ncol = 1,
    dimnames = list(c("2", "K", "1"), "year1")
  )
  s <- swing_schedule(
    fixture_ratios(),
    horizon = 1,
    swing_years = 0,
    recovery = rec
  )
  expect_equal(diag(s[[1]]$matrix), c(K = 1.2, `1` = 1.1, `2` = 1.0))
})

test_that("zero normal years requires empty entry", {
  s <- swing_schedule(
    fixture_ratios(),
    horizon = 3,
    swing_years = 1,
    recovery = c(1.1, 1.05),
    entry = NULL
  )
  expect_length(s, 3)
  expect_null(s[[3]]$entry)
})

test_that("all-swing schedule is valid", {
  s <- swing_schedule(
    fixture_ratios(),
    horizon = 2,
    swing_years = 2,
    recovery = numeric(0),
    entry = NULL
  )
  expect_identical(diag(s[[2]]$matrix), c(K = 1, `1` = 1, `2` = 1))
})

test_that("zero swing years starts with the recovery diagonal", {
  s <- swing_schedule(
    fixture_ratios(),
    horizon = 2,
    swing_years = 0,
    recovery = 1.1,
    entry = 130
  )
  expect_length(s, 2)
  expect_equal(diag(s[[1]]$matrix), c(K = 1.1, `1` = 1.1, `2` = 1.1))
  expect_null(s[[1]]$entry)
  expect_identical(s[[2]]$entry, 130)
})

test_that("swing_schedule rejects an over-long swing+recovery", {
  expect_enrollcast_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 2,
      swing_years = 2,
      recovery = 1.1,
      entry = NULL
    ),
    class = "enrollcast_error_swing_too_long"
  )
})

test_that("swing_schedule needs entry for normal years", {
  expect_enrollcast_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 4,
      swing_years = 1,
      recovery = c(1.1, 1.05),
      entry = NULL
    ),
    class = "enrollcast_error_entry_required"
  )
})

test_that("entry length matches the number of normal years", {
  expect_enrollcast_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 5,
      swing_years = 1,
      recovery = 1.1,
      entry = c(130, 140)
    ),
    class = "enrollcast_error_entry_length"
  )
})

test_that("swing_years must be a non-negative integer", {
  expect_enrollcast_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 3,
      swing_years = -1,
      recovery = 1.1,
      entry = 130
    ),
    class = "enrollcast_error_swing_years"
  )
})

test_that("swing_years rejects non-finite and missing values cleanly", {
  for (swing_years in list(NA_real_, Inf, NaN, c(0, 1), "1")) {
    expect_error(
      swing_schedule(
        fixture_ratios(),
        horizon = 3,
        swing_years = swing_years,
        recovery = 1.1,
        entry = 130
      ),
      class = "enrollcast_error_swing_years"
    )
  }
})

test_that("recovery matrix must have one row per grade", {
  expect_enrollcast_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 2,
      swing_years = 1,
      recovery = matrix(c(1.1, 1.2), nrow = 2),
      entry = NULL
    ),
    class = "enrollcast_error_recovery_dim"
  )
  expect_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 2,
      swing_years = 1,
      recovery = matrix(c(Inf, 1.2), nrow = 2),
      entry = NULL
    ),
    class = "enrollcast_error_recovery_dim"
  )
})

test_that("recovery must be numeric or a matrix", {
  expect_enrollcast_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 3,
      swing_years = 1,
      recovery = "oops",
      entry = 130
    ),
    class = "enrollcast_error_recovery_type"
  )
})

test_that("recovery values must be finite non-missing and non-negative", {
  expect_snapshot(
    swing_schedule(
      fixture_ratios(),
      horizon = 3,
      swing_years = 0,
      recovery = c(1.1, Inf),
      entry = 130
    ),
    error = TRUE
  )
  invalid <- list(
    c(1, NA_real_),
    c(1, Inf),
    c(1, -1),
    matrix(TRUE, nrow = 3),
    matrix("1", nrow = 3),
    matrix(c(1, NA_real_, 1), nrow = 3),
    matrix(c(1, Inf, 1), nrow = 3),
    matrix(c(1, -1, 1), nrow = 3)
  )
  for (recovery in invalid) {
    expect_error(
      swing_schedule(
        fixture_ratios(),
        horizon = 3,
        swing_years = 0,
        recovery = recovery,
        entry = 130
      ),
      class = "enrollcast_error_recovery_values"
    )
  }
})

test_that("named recovery grades must uniquely match projection grades", {
  expect_snapshot(
    swing_schedule(
      fixture_ratios(),
      horizon = 1,
      swing_years = 0,
      recovery = matrix(
        1.1,
        nrow = 3,
        dimnames = list(c("K", "K", "2"), NULL)
      )
    ),
    error = TRUE
  )
  invalid_names <- list(
    c("K", "K", "2"),
    c("K", "1", "3"),
    c("K", NA, "2"),
    c("K", "", "2")
  )
  for (grade_names in invalid_names) {
    recovery <- matrix(
      c(1.1, 1.1, 1.1),
      ncol = 1,
      dimnames = list(grade_names, NULL)
    )
    expect_error(
      swing_schedule(
        fixture_ratios(),
        horizon = 1,
        swing_years = 0,
        recovery = recovery
      ),
      class = "enrollcast_error_recovery_names"
    )
  }
})

test_that("entry must be empty when there are no normal years", {
  expect_enrollcast_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 3,
      swing_years = 1,
      recovery = c(1.1, 1.05),
      entry = 130
    ),
    class = "enrollcast_error_entry_unexpected"
  )
})
