# Canonical K-2, 2021-2023 fixture used across tests. Grade is a factor so
# ordering is unambiguous.
enrollcast_fixture <- function() {
  data.frame(
    year = rep(c(2021, 2022, 2023), each = 3),
    grade = factor(
      rep(c("K", "1", "2"), times = 3),
      levels = c("K", "1", "2")
    ),
    enrollment = c(100, 90, 80, 110, 95, 88, 120, 99, 91)
  )
}

# House-style pair: snapshot the rendered condition AND assert its stable
# class. `bquote()` injection keeps the real call in the snapshot Code lines.
expect_enrollcast_error <- function(expr, class) {
  expr <- substitute(expr)
  eval.parent(bquote(testthat::expect_error(.(expr), class = .(class))))
  eval.parent(bquote(testthat::expect_snapshot(.(expr), error = TRUE)))
}

expect_enrollcast_warning <- function(expr, class) {
  expr <- substitute(expr)
  eval.parent(bquote(testthat::expect_warning(.(expr), class = .(class))))
  eval.parent(bquote(testthat::expect_snapshot(.(expr))))
}

# Canonical K-2 ratios (literal): the rounded ratios of enrollcast_fixture().
fixture_ratios <- function() {
  data.frame(
    grade_from = c("K", "1"),
    grade_to = c("1", "2"),
    ratio = c(0.925, 0.96783626)
  )
}

# Ratios computed from the shared fixture (exact floating-point values).
proj_ratios <- function() progression_ratios(enrollcast_fixture())

# The 2023 base-year enrollment of enrollcast_fixture().
proj_base <- function() {
  data.frame(
    grade = c("K", "1", "2"),
    enrollment = c(120, 99, 91)
  )
}
