test_that("progression_matrix builds the canonical sub-diagonal matrix", {
  M <- progression_matrix(fixture_ratios()[2:1, ])
  expect_identical(dim(M), c(3L, 3L))
  expect_identical(rownames(M), c("K", "1", "2"))
  expect_identical(colnames(M), c("K", "1", "2"))
  expect_equal(
    unname(M),
    matrix(c(0, 0.925, 0, 0, 0, 0.96783626, 0, 0, 0), nrow = 3)
  )
})

test_that("ratios must be a data frame or subclass", {
  ratios <- fixture_ratios()
  invalid <- list(
    as.list(ratios),
    as.matrix(ratios),
    c(grade_from = "K", grade_to = "1", ratio = 0.9),
    NULL
  )
  for (x in invalid) {
    expect_error(
      progression_matrix(x),
      class = "enrollcast_error_ratios_type"
    )
  }
  expect_snapshot(progression_matrix(as.list(ratios)), error = TRUE)

  subclass <- structure(
    ratios,
    class = c("enrollcast_test_df", "data.frame")
  )
  expect_equal(progression_matrix(subclass), progression_matrix(ratios))
})

test_that("a ratio of zero is kept, not treated as missing", {
  r <- fixture_ratios()
  r$ratio[2] <- 0
  M <- progression_matrix(r)
  expect_identical(M["2", "1"], 0)
})

test_that("explicit grade_order controls dimnames and ratio placement", {
  M <- progression_matrix(
    fixture_ratios()[2:1, ],
    grade_order = c("K", "1", "2")
  )
  expect_identical(dimnames(M), list(c("K", "1", "2"), c("K", "1", "2")))
  expect_equal(M["1", "K"], 0.925)
  expect_equal(M["2", "1"], 0.96783626)
})

test_that("progression_matrix errors on a missing feeding ratio", {
  r <- fixture_ratios()
  r <- r[r$grade_to != "2", ]
  expect_enrollcast_error(
    progression_matrix(r, grade_order = c("K", "1", "2")),
    class = "enrollcast_error_missing_ratio"
  )
})

test_that("progression_matrix errors with fewer than two grades", {
  expect_enrollcast_error(
    progression_matrix(fixture_ratios(), grade_order = "K"),
    class = "enrollcast_error_too_few_grades"
  )
})

test_that("progression_matrix errors when ratios reference an unknown grade", {
  expect_enrollcast_error(
    progression_matrix(fixture_ratios(), grade_order = c("K", "1")),
    class = "enrollcast_error_unknown_grade"
  )
})

test_that("progression_matrix errors on ambiguous entry grade", {
  r <- data.frame(
    grade_from = c("K", "9"),
    grade_to = c("1", "2"),
    ratio = c(0.9, 0.9)
  )
  expect_enrollcast_error(
    progression_matrix(r),
    class = "enrollcast_error_ambiguous_entry"
  )
})

test_that("progression_matrix errors on duplicate feeding ratios", {
  r <- data.frame(
    grade_from = c("K", "K", "1"),
    grade_to = c("1", "1", "2"),
    ratio = c(0.9, 0.5, 0.95)
  )
  expect_enrollcast_error(
    progression_matrix(r, grade_order = c("K", "1", "2")),
    class = "enrollcast_error_duplicate_feeder"
  )
})

test_that("duplicate feeders are reported when grade_order is omitted", {
  r <- data.frame(
    grade_from = c("K", "1"),
    grade_to = c("1", "1"),
    ratio = c(0.9, 0.9)
  )
  expect_enrollcast_error(
    progression_matrix(r),
    class = "enrollcast_error_duplicate_feeder"
  )
})

test_that("progression_matrix validates explicit grade_order", {
  expect_enrollcast_error(
    progression_matrix(
      fixture_ratios(),
      grade_order = c("K", "1", "2", NA)
    ),
    class = "enrollcast_error_grade_order_na"
  )
  expect_enrollcast_error(
    progression_matrix(
      fixture_ratios(),
      grade_order = c("K", "1", "2", "2")
    ),
    class = "enrollcast_error_grade_order_duplicate"
  )
})

test_that("missing grade labels are rejected on the inferred path", {
  r <- data.frame(
    grade_from = c("K", "1"),
    grade_to = c("1", NA),
    ratio = c(0.9, 0.9)
  )
  expect_enrollcast_error(
    progression_matrix(r),
    class = "enrollcast_error_grade_na"
  )
})

test_that("progression_matrix rejects a non-numeric ratio column", {
  r <- fixture_ratios()
  r$ratio <- as.character(r$ratio)
  expect_enrollcast_error(
    progression_matrix(r),
    class = "enrollcast_error_ratio_type"
  )
})

test_that("an all-NA (logical) ratio column is rejected as non-numeric", {
  r <- fixture_ratios()
  r$ratio <- c(NA, NA)
  expect_enrollcast_error(
    progression_matrix(r),
    class = "enrollcast_error_ratio_type"
  )
})

test_that("a structural error pre-empts the NA-ratio warning", {
  r <- data.frame(
    grade_from = c("K", "1"),
    grade_to = c("2", "3"),
    ratio = c(NA, 0.9)
  )
  expect_no_warning(expect_error(
    progression_matrix(r, grade_order = c("K", "1", "2", "3")),
    class = "enrollcast_error_missing_ratio"
  ))
})

test_that("progression_matrix rejects negative ratios", {
  r <- fixture_ratios()
  r$ratio[1] <- -0.5
  expect_enrollcast_error(
    progression_matrix(r),
    class = "enrollcast_error_ratio_negative"
  )
})

test_that("progression_matrix rejects an infinite ratio", {
  r <- fixture_ratios()
  r$ratio[1] <- Inf
  expect_enrollcast_error(
    progression_matrix(r),
    class = "enrollcast_error_ratio_infinite"
  )
})

test_that("progression_matrix warns on NA ratios and keeps them in the matrix", {
  r <- fixture_ratios()
  r$ratio[2] <- NA
  expect_snapshot(invisible(progression_matrix(r)))
  expect_warning(progression_matrix(r), class = "enrollcast_warning_ratio_na")
  M <- suppressWarnings(progression_matrix(r))
  expect_identical(M["2", "1"], NA_real_)
  expect_equal(M["1", "K"], 0.925)
})

test_that("progression_matrix warns on NaN ratios from sparse history", {
  r <- fixture_ratios()
  r$ratio[2] <- NaN
  expect_warning(progression_matrix(r), class = "enrollcast_warning_ratio_na")
  M <- suppressWarnings(progression_matrix(r))
  expect_identical(M["2", "1"], NaN)
})

test_that("progression_matrix rejects a transition feeding the entry grade", {
  r <- data.frame(
    grade_from = c("K", "1", "2"),
    grade_to = c("1", "2", "K"),
    ratio = c(0.9, 0.9, 0.5)
  )
  expect_enrollcast_error(
    progression_matrix(r, grade_order = c("K", "1", "2")),
    class = "enrollcast_error_nonadjacent_transition"
  )
})

test_that("progression_matrix rejects skipped and backward transitions", {
  r <- data.frame(
    grade_from = c("K", "2"),
    grade_to = c("2", "1"),
    ratio = c(0.9, 0.9)
  )
  expect_enrollcast_error(
    progression_matrix(r, grade_order = c("K", "1", "2")),
    class = "enrollcast_error_nonadjacent_transition"
  )
})

test_that("branching transitions are rejected with explicit grade_order", {
  r <- data.frame(
    grade_from = c("K", "K"),
    grade_to = c("1", "2"),
    ratio = c(0.9, 0.8)
  )
  expect_enrollcast_error(
    progression_matrix(r, grade_order = c("K", "1", "2")),
    class = "enrollcast_error_nonadjacent_transition"
  )
})

test_that("chain_order reports branching transitions", {
  from <- c("K", "K", "1")
  to <- c("1", "2", "3")
  expect_enrollcast_error(
    chain_order(from, to),
    class = "enrollcast_error_branching_transitions"
  )
})

test_that("chain_order reports cyclic transitions", {
  from <- c("K", "1", "2", "3")
  to <- c("1", "2", "3", "2")
  expect_enrollcast_error(
    chain_order(from, to),
    class = "enrollcast_error_cyclic_transitions"
  )
})
