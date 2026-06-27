test_that("mean is the default method", {
  r <- progression_ratios(enrollcast_fixture())
  expect_identical(r$grade_from, c("K", "1"))
  expect_identical(r$grade_to, c("1", "2"))
  expect_equal(r$ratio, c(0.925, (88 / 90 + 91 / 95) / 2))
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

test_that("non-numeric enrollment is rejected", {
  fx <- enrollcast_fixture()
  fx$enrollment <- as.character(fx$enrollment)
  expect_snapshot(progression_ratios(fx), error = TRUE)
})

test_that("missing columns are reported", {
  expect_snapshot(progression_ratios(data.frame(a = 1)), error = TRUE)
})

test_that("non-consecutive years yield no transitions", {
  fx <- enrollcast_fixture()
  fx <- fx[fx$year != 2022, ]
  expect_snapshot(progression_ratios(fx), error = TRUE)
})

test_that("duplicate grade-year rows are rejected", {
  fx <- rbind(enrollcast_fixture(), enrollcast_fixture()[1, ])
  expect_snapshot(progression_ratios(fx), error = TRUE)
})

test_that("negative enrollment is rejected", {
  fx <- enrollcast_fixture()
  fx$enrollment[1] <- -5
  expect_snapshot(progression_ratios(fx), error = TRUE)
})

test_that("fewer than two grades is rejected", {
  fx <- enrollcast_fixture()
  fx <- fx[fx$grade == "K", ]
  expect_snapshot(progression_ratios(fx), error = TRUE)
})

test_that("non-numeric year is rejected", {
  fx <- enrollcast_fixture()
  fx$year <- as.character(fx$year)
  fx$year[1] <- "spring"
  expect_snapshot(progression_ratios(fx), error = TRUE)
})

test_that("grade_order overrides factor levels", {
  fx <- enrollcast_fixture()
  fx$grade <- as.character(fx$grade)
  r <- progression_ratios(fx, grade_order = c("K", "1", "2"))
  expect_identical(r$grade_from, c("K", "1"))
  expect_equal(r$ratio[1], 0.925)
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
})

test_that("zero feeder enrollment warns about non-finite ratios", {
  fx <- enrollcast_fixture()
  fx$enrollment[fx$grade == "K" & fx$year == 2022] <- 0
  expect_snapshot(progression_ratios(fx))
})

test_that("progression_ratios errors on an unmatched (NA) grade", {
  fx <- enrollcast_fixture()
  fx$grade <- as.character(fx$grade)
  fx$grade[1] <- NA
  expect_snapshot(progression_ratios(fx), error = TRUE)
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
