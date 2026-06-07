proj_ratios <- function() progression_ratios(gpr_fixture())
proj_base <- function() {
	data.frame(
		grade = c("K", "1", "2"),
		enrollment = c(120, 99, 91)
	)
}

test_that("project_enrollment reproduces a hand-computed projection", {
	p <- project_enrollment(
		proj_base(),
		proj_ratios(),
		horizon = 2,
		entry = c(130, 140),
		start_year = 2023
	)
	expect_equal(nrow(p), 6)
	expect_equal(unique(p$year), c(2024, 2025))

	y24 <- p[p$year == 2024, ]
	expect_equal(y24$enrollment[y24$grade == "K"], 130)
	expect_equal(y24$enrollment[y24$grade == "1"], 111)
	expect_equal(
		y24$enrollment[y24$grade == "2"],
		0.96783626 * 99,
		tolerance = 1e-6
	)

	y25 <- p[p$year == 2025, ]
	expect_equal(y25$enrollment[y25$grade == "K"], 140)
	expect_equal(y25$enrollment[y25$grade == "1"], 120.25)
	expect_equal(
		y25$enrollment[y25$grade == "2"],
		0.96783626 * 111,
		tolerance = 1e-6
	)
})

test_that("omitting entry holds the entry grade constant", {
	p <- suppressWarnings(
		project_enrollment(proj_base(), proj_ratios(), horizon = 2)
	)
	expect_equal(p$enrollment[p$grade == "K"], c(120, 120))
})

test_that("start_year is derived from a base data frame carrying a year", {
	base <- data.frame(
		year = 2023,
		grade = c("K", "1", "2"),
		enrollment = c(120, 99, 91)
	)
	p <- project_enrollment(base, proj_ratios(), horizon = 1, entry = 130)
	expect_equal(unique(p$year), 2024)
})

test_that("without any year, output years are 1..horizon", {
	p <- project_enrollment(
		proj_base(),
		proj_ratios(),
		horizon = 2,
		entry = c(130, 140)
	)
	expect_equal(unique(p$year), c(1, 2))
})

test_that("a named numeric vector works as base", {
	v <- c(K = 120, `1` = 99, `2` = 91)
	p <- project_enrollment(
		v,
		proj_ratios(),
		horizon = 1,
		entry = 130,
		start_year = 2023
	)
	expect_equal(p$enrollment[p$grade == "1"], 111)
})

test_that("omitting entry warns", {
	expect_snapshot(
		invisible(project_enrollment(proj_base(), proj_ratios(), horizon = 2))
	)
})

test_that("entry length must equal horizon", {
	expect_snapshot(
		project_enrollment(
			proj_base(),
			proj_ratios(),
			horizon = 3,
			entry = c(130, 140)
		),
		error = TRUE
	)
})

test_that("horizon must be a positive integer", {
	expect_snapshot(
		project_enrollment(proj_base(), proj_ratios(), horizon = 0, entry = 1),
		error = TRUE
	)
	expect_snapshot(
		project_enrollment(proj_base(), proj_ratios(), horizon = 1.5, entry = 1),
		error = TRUE
	)
})

test_that("entry accepts a data frame", {
	p <- project_enrollment(
		proj_base(),
		proj_ratios(),
		horizon = 2,
		entry = data.frame(enrollment = c(130, 140)),
		start_year = 2023
	)
	expect_equal(p$enrollment[p$year == 2024 & p$grade == "K"], 130)
	expect_equal(p$enrollment[p$year == 2025 & p$grade == "K"], 140)
})

test_that("projection carries state across three years", {
	p <- project_enrollment(
		proj_base(),
		proj_ratios(),
		horizon = 3,
		entry = c(130, 140, 150),
		start_year = 2023
	)
	expect_equal(unique(p$year), c(2024, 2025, 2026))
	expect_equal(p$enrollment[p$year == 2026 & p$grade == "1"], 0.925 * 140)
})
