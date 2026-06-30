ratios_fixture <- function() {
  data.frame(
    grade_from = c("K", "1"),
    grade_to = c("1", "2"),
    ratio = c(0.925, 0.96783626)
  )
}

test_that("projection_matrix builds the correct shape and sub-diagonal", {
  M <- projection_matrix(ratios_fixture())
  expect_identical(dim(M), c(3L, 3L))
  expect_identical(rownames(M), c("K", "1", "2"))
  expect_identical(colnames(M), c("K", "1", "2"))
  expect_equal(M["1", "K"], 0.925)
  expect_equal(M["2", "1"], 0.96783626)
})

test_that("projection_matrix zeroes the entry row and all non-feeder cells", {
  M <- projection_matrix(ratios_fixture())
  expect_identical(unname(M["K", ]), c(0, 0, 0))
  expect_identical(sum(M != 0), 2L)
})

test_that("projection_matrix honours an explicit grade_order", {
  M <- projection_matrix(ratios_fixture(), grade_order = c("K", "1", "2"))
  expect_identical(rownames(M), c("K", "1", "2"))
})

test_that("a ratio of zero is kept, not treated as missing", {
  r <- ratios_fixture()
  r$ratio[2] <- 0
  M <- projection_matrix(r)
  expect_equal(M["2", "1"], 0)
})

test_that("explicit grade_order places ratio values correctly", {
  M <- projection_matrix(ratios_fixture(), grade_order = c("K", "1", "2"))
  expect_equal(M["1", "K"], 0.925)
  expect_equal(M["2", "1"], 0.96783626)
})

test_that("projection_matrix errors on a missing feeding ratio", {
  r <- ratios_fixture()
  r <- r[r$grade_to != "2", ]
  expect_snapshot(
    projection_matrix(r, grade_order = c("K", "1", "2")),
    error = TRUE
  )
  expect_error(
    projection_matrix(r, grade_order = c("K", "1", "2")),
    class = "enrollcast_error_missing_ratio"
  )
})

test_that("projection_matrix errors with fewer than two grades", {
  expect_snapshot(
    projection_matrix(ratios_fixture(), grade_order = "K"),
    error = TRUE
  )
  expect_error(
    projection_matrix(ratios_fixture(), grade_order = "K"),
    class = "enrollcast_error_too_few_grades"
  )
})

test_that("projection_matrix errors when ratios reference an unknown grade", {
  expect_snapshot(
    projection_matrix(ratios_fixture(), grade_order = c("K", "1")),
    error = TRUE
  )
  expect_error(
    projection_matrix(ratios_fixture(), grade_order = c("K", "1")),
    class = "enrollcast_error_unknown_grade"
  )
})

test_that("projection_matrix errors on ambiguous entry grade", {
  r <- data.frame(
    grade_from = c("K", "9"),
    grade_to = c("1", "2"),
    ratio = c(0.9, 0.9)
  )
  expect_snapshot(projection_matrix(r), error = TRUE)
  expect_error(projection_matrix(r), class = "enrollcast_error_ambiguous_entry")
})

test_that("projection_matrix errors on duplicate feeding ratios", {
  r <- data.frame(
    grade_from = c("K", "K", "1"),
    grade_to = c("1", "1", "2"),
    ratio = c(0.9, 0.5, 0.95)
  )
  expect_snapshot(
    projection_matrix(r, grade_order = c("K", "1", "2")),
    error = TRUE
  )
  expect_error(
    projection_matrix(r, grade_order = c("K", "1", "2")),
    class = "enrollcast_error_duplicate_feeder"
  )
})
