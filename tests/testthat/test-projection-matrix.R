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

test_that("projection_matrix reports duplicate feeders when grade_order is omitted", {
  r <- data.frame(
    grade_from = c("K", "1"),
    grade_to = c("1", "1"),
    ratio = c(0.9, 0.9)
  )
  expect_snapshot(projection_matrix(r), error = TRUE)
  expect_error(
    projection_matrix(r),
    class = "enrollcast_error_duplicate_feeder"
  )
})

test_that("projection_matrix rejects a grade_order containing missing values", {
  expect_snapshot(
    projection_matrix(ratios_fixture(), grade_order = c("K", "1", "2", NA)),
    error = TRUE
  )
  expect_error(
    projection_matrix(ratios_fixture(), grade_order = c("K", "1", "2", NA)),
    class = "enrollcast_error_grade_order_na"
  )
})

test_that("projection_matrix rejects a grade_order containing duplicates", {
  expect_snapshot(
    projection_matrix(ratios_fixture(), grade_order = c("K", "1", "2", "2")),
    error = TRUE
  )
  expect_error(
    projection_matrix(ratios_fixture(), grade_order = c("K", "1", "2", "2")),
    class = "enrollcast_error_grade_order_duplicate"
  )
})

test_that("projection_matrix rejects missing grade labels on the inferred path", {
  r <- data.frame(
    grade_from = c("K", "1"),
    grade_to = c("1", NA),
    ratio = c(0.9, 0.9)
  )
  expect_snapshot(projection_matrix(r), error = TRUE)
  expect_error(projection_matrix(r), class = "enrollcast_error_grade_na")
})

test_that("projection_matrix rejects a non-numeric ratio column", {
  r <- ratios_fixture()
  r$ratio <- as.character(r$ratio)
  expect_snapshot(projection_matrix(r), error = TRUE)
  expect_error(projection_matrix(r), class = "enrollcast_error_ratio_type")
})

test_that("projection_matrix rejects negative ratios", {
  r <- ratios_fixture()
  r$ratio[1] <- -0.5
  expect_snapshot(projection_matrix(r), error = TRUE)
  expect_error(projection_matrix(r), class = "enrollcast_error_ratio_negative")
})

test_that("projection_matrix warns on NA ratios and keeps them in the matrix", {
  r <- ratios_fixture()
  r$ratio[2] <- NA
  expect_snapshot(M <- projection_matrix(r))
  expect_warning(projection_matrix(r), class = "enrollcast_warning_ratio_na")
  M <- suppressWarnings(projection_matrix(r))
  expect_identical(M["2", "1"], NA_real_)
  expect_equal(M["1", "K"], 0.925)
})

test_that("projection_matrix warns on NaN ratios from sparse history", {
  r <- ratios_fixture()
  r$ratio[2] <- NaN
  expect_warning(projection_matrix(r), class = "enrollcast_warning_ratio_na")
  M <- suppressWarnings(projection_matrix(r))
  expect_identical(M["2", "1"], NaN)
})

test_that("projection_matrix rejects a transition feeding the entry grade", {
  r <- data.frame(
    grade_from = c("K", "1", "2"),
    grade_to = c("1", "2", "K"),
    ratio = c(0.9, 0.9, 0.5)
  )
  expect_snapshot(
    projection_matrix(r, grade_order = c("K", "1", "2")),
    error = TRUE
  )
  expect_error(
    projection_matrix(r, grade_order = c("K", "1", "2")),
    class = "enrollcast_error_nonadjacent_transition"
  )
})

test_that("projection_matrix rejects skipped and backward transitions", {
  r <- data.frame(
    grade_from = c("K", "2"),
    grade_to = c("2", "1"),
    ratio = c(0.9, 0.9)
  )
  expect_snapshot(
    projection_matrix(r, grade_order = c("K", "1", "2")),
    error = TRUE
  )
  expect_error(
    projection_matrix(r, grade_order = c("K", "1", "2")),
    class = "enrollcast_error_nonadjacent_transition"
  )
})

test_that("projection_matrix rejects branching transitions under an explicit grade_order", {
  r <- data.frame(
    grade_from = c("K", "K"),
    grade_to = c("1", "2"),
    ratio = c(0.9, 0.8)
  )
  expect_snapshot(
    projection_matrix(r, grade_order = c("K", "1", "2")),
    error = TRUE
  )
  expect_error(
    projection_matrix(r, grade_order = c("K", "1", "2")),
    class = "enrollcast_error_nonadjacent_transition"
  )
})

test_that("chain_order reconstructs the grade sequence", {
  expect_identical(chain_order(c("K", "1"), c("1", "2")), c("K", "1", "2"))
})

test_that("chain_order handles a single transition pair", {
  expect_identical(chain_order("K", "1"), c("K", "1"))
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
