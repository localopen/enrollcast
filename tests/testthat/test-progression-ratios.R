test_that("mean is the default method", {
	r <- progression_ratios(gpr_fixture())
	expect_equal(r$grade_from, c("K", "1"))
	expect_equal(r$grade_to, c("1", "2"))
	expect_equal(r$ratio, c(0.925, (88 / 90 + 91 / 95) / 2))
})

test_that("geometric, median, and last methods work", {
	fx <- gpr_fixture()
	expect_equal(
		progression_ratios(fx, method = "geometric")$ratio[1],
		sqrt(0.95 * 0.9)
	)
	expect_equal(progression_ratios(fx, method = "median")$ratio[1], 0.925)
	expect_equal(progression_ratios(fx, method = "last")$ratio, c(0.9, 91 / 95))
})

test_that("weighted method uses most-recent-first weights", {
	r <- progression_ratios(gpr_fixture(), method = "weighted", weights = c(2, 1))
	expect_equal(r$ratio[1], (0.9 * 2 + 0.95 * 1) / 3)
})

test_that("n_years restricts to the most recent transitions", {
	r <- progression_ratios(gpr_fixture(), n_years = 1)
	expect_equal(r$ratio, c(0.9, 91 / 95))
})

test_that("column names are overridable", {
	fx <- gpr_fixture()
	names(fx) <- c("yr", "gr", "n")
	r <- progression_ratios(fx, year = "yr", grade = "gr", enrollment = "n")
	expect_equal(r$ratio[1], 0.925)
})

test_that("non-numeric enrollment is rejected", {
	fx <- gpr_fixture()
	fx$enrollment <- as.character(fx$enrollment)
	expect_snapshot(progression_ratios(fx), error = TRUE)
})

test_that("missing columns are reported", {
	expect_snapshot(progression_ratios(data.frame(a = 1)), error = TRUE)
})

test_that("non-consecutive years yield no transitions", {
	fx <- gpr_fixture()
	fx <- fx[fx$year != 2022, ]
	expect_snapshot(progression_ratios(fx), error = TRUE)
})

test_that("duplicate grade-year rows are rejected", {
	fx <- rbind(gpr_fixture(), gpr_fixture()[1, ])
	expect_snapshot(progression_ratios(fx), error = TRUE)
})

test_that("negative enrollment is rejected", {
	fx <- gpr_fixture()
	fx$enrollment[1] <- -5
	expect_snapshot(progression_ratios(fx), error = TRUE)
})

test_that("fewer than two grades is rejected", {
	fx <- gpr_fixture()
	fx <- fx[fx$grade == "K", ]
	expect_snapshot(progression_ratios(fx), error = TRUE)
})

test_that("non-numeric year is rejected", {
	fx <- gpr_fixture()
	fx$year <- as.character(fx$year)
	fx$year[1] <- "spring"
	expect_snapshot(progression_ratios(fx), error = TRUE)
})
