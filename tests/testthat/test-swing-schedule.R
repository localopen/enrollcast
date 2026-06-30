ss_ratios <- function() {
  data.frame(
    grade_from = c("K", "1"),
    grade_to = c("1", "2"),
    ratio = c(0.925, 0.96783626)
  )
}

test_that("swing_schedule lays out swing, recovery, and normal regimes", {
  s <- swing_schedule(
    ss_ratios(),
    horizon = 6,
    swing_years = 2,
    recovery = c(1.10, 1.10, 1.05),
    entry = 130
  )
  expect_length(s, 6)
  expect_identical(s[[1]]$matrix, s[[2]]$matrix) # identity, repeated
  expect_equal(diag(s[[1]]$matrix), c(K = 1, `1` = 1, `2` = 1))
  expect_null(s[[1]]$entry)
  expect_equal(diag(s[[3]]$matrix), c(K = 1.10, `1` = 1.10, `2` = 1.10))
  expect_null(s[[4]]$entry)
  expect_equal(s[[6]]$entry, 130) # normal year carries entry
})

test_that("swing_schedule reproduces the worked trajectory", {
  s <- swing_schedule(
    ss_ratios(),
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
  rec <- matrix(c(1.2, 1.1, 1.0), nrow = 3) # G x 1: one recovery year, per-grade
  s <- swing_schedule(
    ss_ratios(),
    horizon = 2,
    swing_years = 1,
    recovery = rec,
    entry = NULL
  )
  expect_equal(diag(s[[2]]$matrix), c(K = 1.2, `1` = 1.1, `2` = 1.0))
})

test_that("zero normal years requires empty entry", {
  s <- swing_schedule(
    ss_ratios(),
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
    ss_ratios(),
    horizon = 2,
    swing_years = 2,
    recovery = numeric(0),
    entry = NULL
  )
  expect_equal(diag(s[[2]]$matrix), c(K = 1, `1` = 1, `2` = 1))
})

test_that("zero swing years starts with the recovery diagonal", {
  s <- swing_schedule(
    ss_ratios(),
    horizon = 2,
    swing_years = 0,
    recovery = c(1.1),
    entry = 130
  )
  expect_length(s, 2)
  expect_equal(diag(s[[1]]$matrix), c(K = 1.1, `1` = 1.1, `2` = 1.1))
  expect_null(s[[1]]$entry)
  expect_equal(s[[2]]$entry, 130)
})

test_that("swing_schedule rejects an over-long swing+recovery", {
  expect_snapshot(
    swing_schedule(
      ss_ratios(),
      horizon = 2,
      swing_years = 2,
      recovery = c(1.1),
      entry = NULL
    ),
    error = TRUE
  )
  expect_error(
    swing_schedule(
      ss_ratios(),
      horizon = 2,
      swing_years = 2,
      recovery = c(1.1),
      entry = NULL
    ),
    class = "enrollcast_error_swing_too_long"
  )
})

test_that("swing_schedule needs entry for normal years", {
  expect_snapshot(
    swing_schedule(
      ss_ratios(),
      horizon = 4,
      swing_years = 1,
      recovery = c(1.1, 1.05),
      entry = NULL
    ),
    error = TRUE
  )
  expect_error(
    swing_schedule(
      ss_ratios(),
      horizon = 4,
      swing_years = 1,
      recovery = c(1.1, 1.05),
      entry = NULL
    ),
    class = "enrollcast_error_entry_required"
  )
})

test_that("entry length must match the number of normal years", {
  expect_snapshot(
    swing_schedule(
      ss_ratios(),
      horizon = 5,
      swing_years = 1,
      recovery = c(1.1),
      entry = c(130, 140)
    ),
    error = TRUE
  )
  expect_error(
    swing_schedule(
      ss_ratios(),
      horizon = 5,
      swing_years = 1,
      recovery = c(1.1),
      entry = c(130, 140)
    ),
    class = "enrollcast_error_entry_length"
  )
})

test_that("swing_years must be a non-negative integer", {
  expect_snapshot(
    swing_schedule(
      ss_ratios(),
      horizon = 3,
      swing_years = -1,
      recovery = c(1.1),
      entry = 130
    ),
    error = TRUE
  )
  expect_error(
    swing_schedule(
      ss_ratios(),
      horizon = 3,
      swing_years = -1,
      recovery = c(1.1),
      entry = 130
    ),
    class = "enrollcast_error_swing_years"
  )
})

test_that("recovery matrix must have one row per grade", {
  expect_snapshot(
    swing_schedule(
      ss_ratios(),
      horizon = 2,
      swing_years = 1,
      recovery = matrix(c(1.1, 1.2), nrow = 2),
      entry = NULL
    ),
    error = TRUE
  )
  expect_error(
    swing_schedule(
      ss_ratios(),
      horizon = 2,
      swing_years = 1,
      recovery = matrix(c(1.1, 1.2), nrow = 2),
      entry = NULL
    ),
    class = "enrollcast_error_recovery_dim"
  )
})

test_that("recovery must be numeric or a matrix", {
  expect_snapshot(
    swing_schedule(
      ss_ratios(),
      horizon = 3,
      swing_years = 1,
      recovery = "oops",
      entry = 130
    ),
    error = TRUE
  )
  expect_error(
    swing_schedule(
      ss_ratios(),
      horizon = 3,
      swing_years = 1,
      recovery = "oops",
      entry = 130
    ),
    class = "enrollcast_error_recovery_type"
  )
})

test_that("entry must be empty when there are no normal years", {
  expect_snapshot(
    swing_schedule(
      ss_ratios(),
      horizon = 3,
      swing_years = 1,
      recovery = c(1.1, 1.05),
      entry = 130
    ),
    error = TRUE
  )
  expect_error(
    swing_schedule(
      ss_ratios(),
      horizon = 3,
      swing_years = 1,
      recovery = c(1.1, 1.05),
      entry = 130
    ),
    class = "enrollcast_error_entry_unexpected"
  )
})
