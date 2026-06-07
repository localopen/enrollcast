ratios_fixture <- function() {
	data.frame(
		grade_from = c("K", "1"),
		grade_to = c("1", "2"),
		ratio = c(0.925, 0.96783626)
	)
}

test_that("leslie_matrix builds the correct shape and sub-diagonal", {
	M <- leslie_matrix(ratios_fixture())
	expect_equal(dim(M), c(3, 3))
	expect_equal(rownames(M), c("K", "1", "2"))
	expect_equal(colnames(M), c("K", "1", "2"))
	expect_equal(M["1", "K"], 0.925)
	expect_equal(M["2", "1"], 0.96783626)
})

test_that("leslie_matrix zeroes the entry row and all non-feeder cells", {
	M <- leslie_matrix(ratios_fixture())
	expect_equal(unname(M["K", ]), c(0, 0, 0))
	expect_equal(sum(M != 0), 2)
})

test_that("leslie_matrix honours an explicit grade_order", {
	M <- leslie_matrix(ratios_fixture(), grade_order = c("K", "1", "2"))
	expect_equal(rownames(M), c("K", "1", "2"))
})

test_that("a ratio of zero is kept, not treated as missing", {
	r <- ratios_fixture()
	r$ratio[2] <- 0
	M <- leslie_matrix(r)
	expect_equal(M["2", "1"], 0)
})

test_that("explicit grade_order places ratio values correctly", {
	M <- leslie_matrix(ratios_fixture(), grade_order = c("K", "1", "2"))
	expect_equal(M["1", "K"], 0.925)
	expect_equal(M["2", "1"], 0.96783626)
})

test_that("leslie_matrix errors on a missing feeding ratio", {
	r <- ratios_fixture()
	r <- r[r$grade_to != "2", ]
	expect_snapshot(
		leslie_matrix(r, grade_order = c("K", "1", "2")),
		error = TRUE
	)
})

test_that("leslie_matrix errors on ambiguous entry grade", {
	r <- data.frame(
		grade_from = c("K", "9"),
		grade_to = c("1", "2"),
		ratio = c(0.9, 0.9)
	)
	expect_snapshot(leslie_matrix(r), error = TRUE)
})

test_that("leslie_matrix errors on duplicate feeding ratios", {
	r <- data.frame(
		grade_from = c("K", "K", "1"),
		grade_to = c("1", "1", "2"),
		ratio = c(0.9, 0.5, 0.95)
	)
	expect_snapshot(
		leslie_matrix(r, grade_order = c("K", "1", "2")),
		error = TRUE
	)
})
