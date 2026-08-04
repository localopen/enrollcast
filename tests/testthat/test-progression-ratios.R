test_that("progression_ratios returns the canonical ordered structure", {
  fx <- enrollcast_fixture()
  r <- progression_ratios(fx[c(9, 2, 7, 1, 5, 3, 8, 4, 6), ])

  expect_named(r, c("grade_from", "grade_to", "ratio"))
  expect_identical(
    r[c("grade_from", "grade_to")],
    data.frame(
      grade_from = c("K", "1"),
      grade_to = c("1", "2")
    )
  )
  expect_type(r$ratio, "double")
  expect_equal(r$ratio, c(0.925, (88 / 90 + 91 / 95) / 2))
})

test_that("data must be a data frame or subclass", {
  fx <- enrollcast_fixture()
  invalid <- list(
    as.list(fx),
    as.matrix(fx),
    c(year = 2021, grade = 1, enrollment = 100),
    NULL
  )
  for (data in invalid) {
    expect_error(
      progression_ratios(data),
      class = "enrollcast_error_data_type"
    )
  }
  expect_snapshot(progression_ratios(as.list(fx)), error = TRUE)

  subclass <- structure(fx, class = c("enrollcast_test_df", "data.frame"))
  expect_equal(
    progression_ratios(subclass),
    progression_ratios(fx)
  )
})

test_that("geometric, median, and last methods work", {
  fx <- enrollcast_fixture()
  expect_equal(
    progression_ratios(fx, method = "geometric")$ratio[1],
    sqrt(0.95 * 0.9)
  )
  expect_equal(progression_ratios(fx, method = "median")$ratio[1], 0.925)
  expect_equal(progression_ratios(fx, method = "last")$ratio, c(0.9, 91 / 95))
})

test_that("weighted method uses most-recent-first weights", {
  r <- progression_ratios(
    enrollcast_fixture(),
    method = "weighted",
    weights = c(2, 1)
  )
  expect_equal(r$ratio[1], (0.9 * 2 + 0.95 * 1) / 3)
})

test_that("n_years restricts to the most recent transitions", {
  r <- progression_ratios(enrollcast_fixture(), n_years = 1)
  expect_equal(r$ratio, c(0.9, 91 / 95))
})

test_that("column names are overridable", {
  fx <- enrollcast_fixture()
  names(fx) <- c("yr", "gr", "n")
  r <- progression_ratios(fx, year = "yr", grade = "gr", enrollment = "n")
  expect_equal(r$ratio[1], 0.925)
})

test_that("column selectors are distinct non-missing character scalars", {
  fx <- enrollcast_fixture()
  invalid <- list(
    list(year = NA_character_, grade = "grade", enrollment = "enrollment"),
    list(year = c("year", "yr"), grade = "grade", enrollment = "enrollment"),
    list(year = 1, grade = "grade", enrollment = "enrollment"),
    list(year = "year", grade = "year", enrollment = "enrollment")
  )
  for (args in invalid) {
    expect_error(
      do.call(progression_ratios, c(list(data = fx), args)),
      class = "enrollcast_error_column_selector"
    )
  }
  expect_snapshot(
    progression_ratios(fx, year = "year", grade = "year"),
    error = TRUE
  )
})

test_that("non-numeric enrollment is rejected", {
  fx <- enrollcast_fixture()
  fx$enrollment <- as.character(fx$enrollment)
  expect_snapshot(progression_ratios(fx), error = TRUE)
  expect_error(
    progression_ratios(fx),
    class = "enrollcast_error_enrollment_type"
  )
})

test_that("missing columns are reported", {
  expect_snapshot(progression_ratios(data.frame(a = 1)), error = TRUE)
  expect_error(
    progression_ratios(data.frame(a = 1)),
    class = "enrollcast_error_missing_columns"
  )
})

test_that("non-consecutive years yield no transitions", {
  fx <- enrollcast_fixture()
  fx <- fx[fx$year != 2022, ]
  expect_snapshot(progression_ratios(fx), error = TRUE)
  expect_error(
    progression_ratios(fx),
    class = "enrollcast_error_no_transitions"
  )
})

test_that("partial year gaps warn and use only adjacent transitions", {
  history <- data.frame(
    year = rep(c(2020, 2021, 2023, 2024), each = 3),
    grade = factor(
      rep(c("K", "1", "2"), times = 4),
      levels = c("K", "1", "2")
    ),
    enrollment = c(
      100,
      80,
      60,
      110,
      90,
      70,
      200,
      150,
      100,
      220,
      165,
      120
    )
  )

  expect_snapshot(invisible(progression_ratios(history)))
  expect_warning(
    ratios <- progression_ratios(history),
    class = "enrollcast_warning_year_gaps"
  )
  expect_equal(ratios$ratio, c((0.9 + 0.825) / 2, (0.875 + 0.8) / 2))

  recent <- suppressWarnings(progression_ratios(history, n_years = 1))
  expect_equal(recent$ratio, c(0.825, 0.8))
  expect_no_warning(progression_ratios(enrollcast_fixture()))
})

test_that("multiple year gaps are reported in one warning", {
  history <- data.frame(
    year = rep(c(2020, 2022, 2023, 2025, 2026), each = 3),
    grade = factor(
      rep(c("K", "1", "2"), times = 5),
      levels = c("K", "1", "2")
    ),
    enrollment = seq_len(15) + 100
  )

  warnings <- list()
  withCallingHandlers(
    progression_ratios(history),
    warning = function(cnd) {
      warnings[[length(warnings) + 1]] <<- cnd
      invokeRestart("muffleWarning")
    }
  )
  expect_length(warnings, 1)
  expect_s3_class(warnings[[1]], "enrollcast_warning_year_gaps")
  expect_snapshot(invisible(progression_ratios(history)))
})

test_that("duplicate grade-year rows are rejected", {
  fx <- rbind(enrollcast_fixture(), enrollcast_fixture()[1, ])
  expect_snapshot(progression_ratios(fx), error = TRUE)
  expect_error(
    progression_ratios(fx),
    class = "enrollcast_error_duplicate_rows"
  )
})

test_that("negative enrollment is rejected", {
  fx <- enrollcast_fixture()
  fx$enrollment[1] <- -5
  expect_snapshot(progression_ratios(fx), error = TRUE)
  expect_error(
    progression_ratios(fx),
    class = "enrollcast_error_enrollment_negative"
  )
})

test_that("non-finite historical enrollment is rejected but NA is allowed", {
  for (value in c(NaN, Inf, -Inf)) {
    fx <- enrollcast_fixture()
    fx$enrollment[1] <- value
    expect_error(
      progression_ratios(fx),
      class = "enrollcast_error_enrollment_nonfinite"
    )
  }
  fx <- enrollcast_fixture()
  fx$enrollment[1] <- Inf
  expect_snapshot(progression_ratios(fx), error = TRUE)

  fx$enrollment[1] <- NA_real_
  expect_no_error(progression_ratios(fx))
})

test_that("fewer than two grades is rejected", {
  fx <- enrollcast_fixture()
  fx <- fx[fx$grade == "K", ]
  expect_snapshot(progression_ratios(fx), error = TRUE)
  expect_error(
    progression_ratios(fx),
    class = "enrollcast_error_too_few_grades"
  )
})

test_that("all-missing grades are rejected as missing", {
  fx <- enrollcast_fixture()
  fx$grade <- NA_character_
  expect_snapshot(progression_ratios(fx), error = TRUE)
  expect_error(progression_ratios(fx), class = "enrollcast_error_grade_na")
})

test_that("non-numeric year is rejected", {
  fx <- enrollcast_fixture()
  fx$year <- as.character(fx$year)
  fx$year[1] <- "spring"
  expect_snapshot(progression_ratios(fx), error = TRUE)
  expect_error(progression_ratios(fx), class = "enrollcast_error_year_type")
})

test_that("years must coerce to finite integers", {
  for (value in c(NA_character_, "Inf", "-Inf", "2021.5")) {
    fx <- enrollcast_fixture()
    fx$year <- as.character(fx$year)
    fx$year[1] <- value
    expect_error(progression_ratios(fx), class = "enrollcast_error_year_type")
  }
  fx <- enrollcast_fixture()
  fx$year <- as.character(fx$year)
  fx$year[1] <- "2021.5"
  expect_snapshot(progression_ratios(fx), error = TRUE)
})

test_that("duplicate grade-year rows are detected after year coercion", {
  fx <- enrollcast_fixture()
  extra <- fx[1, ]
  fx$year <- as.character(fx$year)
  extra$year <- "02021"
  expect_error(
    progression_ratios(rbind(fx, extra)),
    class = "enrollcast_error_duplicate_rows"
  )
})

test_that("grade_order overrides factor levels", {
  fx <- enrollcast_fixture()
  fx$grade <- as.character(fx$grade)
  r <- progression_ratios(fx, grade_order = c("K", "1", "2"))
  expect_identical(r$grade_from, c("K", "1"))
  expect_equal(r$ratio[1], 0.925)
})

test_that("grade_order rejects missing and duplicate grades", {
  expect_error(
    progression_ratios(enrollcast_fixture(), grade_order = c("K", "1", NA)),
    class = "enrollcast_error_grade_order_na"
  )
  expect_error(
    progression_ratios(
      enrollcast_fixture(),
      grade_order = c("K", "1", "2", "2")
    ),
    class = "enrollcast_error_grade_order_duplicate"
  )
})

test_that("weights are accepted only by the weighted method", {
  expect_snapshot(
    progression_ratios(enrollcast_fixture(), method = "mean", weights = 1:2),
    error = TRUE
  )
  expect_error(
    progression_ratios(enrollcast_fixture(), method = "mean", weights = 1:2),
    class = "enrollcast_error_weights_unused"
  )
})

test_that("weighted method validates weight values", {
  invalid <- list("weights", c(1, NA), c(1, Inf), c(1, -1))
  for (weights in invalid) {
    expect_error(
      progression_ratios(
        enrollcast_fixture(),
        method = "weighted",
        weights = weights
      ),
      class = "enrollcast_error_weights_values",
      info = sprintf("weights: %s", toString(weights))
    )
  }
  expect_snapshot(
    progression_ratios(
      enrollcast_fixture(),
      method = "weighted",
      weights = c(1, -1)
    ),
    error = TRUE
  )
})

test_that("weighted method requires a positive weight sum", {
  expect_snapshot(
    progression_ratios(
      enrollcast_fixture(),
      method = "weighted",
      weights = c(0, 0)
    ),
    error = TRUE
  )
  expect_error(
    progression_ratios(
      enrollcast_fixture(),
      method = "weighted",
      weights = c(0, 0)
    ),
    class = "enrollcast_error_weights_sum"
  )
})

test_that("missing transitions are dropped for averaging methods", {
  fx <- enrollcast_fixture()
  fx <- fx[!(fx$grade == "1" & fx$year == 2022), ]
  r <- progression_ratios(fx)
  expect_equal(r$ratio[1], 99 / 110)
  expect_equal(r$ratio[2], 88 / 90)
})

test_that("last method skips a missing most-recent transition", {
  fx <- enrollcast_fixture()
  fx <- fx[!(fx$grade == "1" & fx$year == 2023), ]
  r <- progression_ratios(fx, method = "last")
  expect_equal(r$ratio[1], 95 / 100)
  expect_equal(r$ratio[2], 91 / 95)
})

test_that("n_years must be a positive integer", {
  expect_snapshot(
    progression_ratios(enrollcast_fixture(), n_years = 0),
    error = TRUE
  )
  expect_error(
    progression_ratios(enrollcast_fixture(), n_years = 0),
    class = "enrollcast_error_n_years"
  )
})

test_that("zero feeder enrollment warns about non-finite ratios", {
  fx <- enrollcast_fixture()
  fx$enrollment[fx$grade == "K" & fx$year == 2022] <- 0
  expect_snapshot(progression_ratios(fx))
  expect_warning(
    progression_ratios(fx),
    class = "enrollcast_warning_undefined_ratios"
  )
})

test_that("progression_ratios errors on an unmatched (NA) grade", {
  fx <- enrollcast_fixture()
  fx$grade <- as.character(fx$grade)
  fx$grade[1] <- NA
  expect_snapshot(progression_ratios(fx), error = TRUE)
  expect_error(progression_ratios(fx), class = "enrollcast_error_grade_na")
})

test_that("year is ordered numerically, not lexically, for character/factor years", {
  ref <- progression_ratios(enrollcast_fixture())$ratio
  # Relabel years so lexical order ("10", "11", "9") differs from numeric order.
  remap <- c("2021" = "9", "2022" = "10", "2023" = "11")

  fx_chr <- enrollcast_fixture()
  fx_chr$year <- unname(remap[as.character(fx_chr$year)])
  expect_equal(progression_ratios(fx_chr)$ratio, ref)

  fx_fac <- enrollcast_fixture()
  fx_fac$year <- factor(
    unname(remap[as.character(fx_fac$year)]),
    levels = c("11", "9", "10")
  )
  expect_equal(progression_ratios(fx_fac)$ratio, ref)
})

test_that("an ordered grade factor is honoured without re-resolving order", {
  fx <- enrollcast_fixture()
  fx$grade <- ordered(as.character(fx$grade), levels = c("K", "1", "2"))
  expect_no_warning(r <- progression_ratios(fx))
  expect_identical(r$grade_from, c("K", "1"))
  expect_equal(r$ratio[1], 0.925)
})

test_that("grade_order overrides ordered factor levels", {
  fx <- enrollcast_fixture()
  fx$grade <- ordered(as.character(fx$grade), levels = c("K", "1", "2"))
  r <- progression_ratios(fx, grade_order = c("2", "1", "K"))
  expect_identical(r$grade_from, c("2", "1"))
  expect_identical(r$grade_to, c("1", "K"))
})

test_that("unused levels in an ordered grade factor are dropped", {
  fx <- enrollcast_fixture()
  fx$grade <- ordered(
    as.character(fx$grade),
    levels = c("K", "1", "2", "3", "4")
  )
  expect_no_warning(r <- progression_ratios(fx))
  expect_identical(r$grade_from, c("K", "1"))
  expect_identical(r$grade_to, c("1", "2"))
})

test_that("sparse history does not warn about missing grade-year cells", {
  fx <- enrollcast_fixture()
  fx <- fx[!(fx$grade == "1" & fx$year == 2022), ]
  expect_no_warning(progression_ratios(fx))
})
