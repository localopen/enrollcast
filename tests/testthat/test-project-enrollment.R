proj_ratios <- function() progression_ratios(enrollcast_fixture())
proj_base <- function() {
  data.frame(
    grade = c("K", "1", "2"),
    enrollment = c(120, 99, 91)
  )
}

test_that("project_enrollment returns the canonical ordered projection", {
  base <- proj_base()[c(3, 1, 2), ]
  p <- project_enrollment(
    base,
    proj_ratios(),
    horizon = 2,
    entry = c(130, 140),
    start_year = 2023
  )
  expect_named(p, c("year", "grade", "enrollment"))
  expect_identical(
    p[c("year", "grade")],
    data.frame(
      year = rep(c(2024, 2025), each = 3),
      grade = rep(c("K", "1", "2"), times = 2)
    )
  )
  expect_type(p$enrollment, "double")
  expect_equal(
    p$enrollment,
    c(130, 111, 0.96783626 * 99, 140, 120.25, 0.96783626 * 111),
    tolerance = 1e-6
  )
})

test_that("omitting entry holds the entry grade constant", {
  p <- suppressWarnings(
    project_enrollment(proj_base(), proj_ratios(), horizon = 2)
  )
  expect_identical(p$enrollment[p$grade == "K"], c(120, 120))
})

test_that("start_year is derived from a base data frame carrying a year", {
  base <- data.frame(
    year = 2023,
    grade = c("K", "1", "2"),
    enrollment = c(120, 99, 91)
  )
  p <- project_enrollment(base, proj_ratios(), horizon = 1, entry = 130)
  expect_identical(unique(p$year), 2024)
})

test_that("without any year, output years are 1..horizon", {
  p <- project_enrollment(
    proj_base(),
    proj_ratios(),
    horizon = 2,
    entry = c(130, 140)
  )
  expect_identical(unique(p$year), 1:2)
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
  expect_warning(
    project_enrollment(proj_base(), proj_ratios(), horizon = 2),
    class = "enrollcast_warning_entry_missing"
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
  expect_error(
    project_enrollment(
      proj_base(),
      proj_ratios(),
      horizon = 3,
      entry = c(130, 140)
    ),
    class = "enrollcast_error_entry_length"
  )
})

test_that("horizon must be a positive integer", {
  expect_snapshot(
    project_enrollment(proj_base(), proj_ratios(), horizon = 0, entry = 1),
    error = TRUE
  )
  expect_error(
    project_enrollment(proj_base(), proj_ratios(), horizon = 0, entry = 1),
    class = "enrollcast_error_horizon"
  )
  expect_snapshot(
    project_enrollment(proj_base(), proj_ratios(), horizon = 1.5, entry = 1),
    error = TRUE
  )
  expect_error(
    project_enrollment(proj_base(), proj_ratios(), horizon = 1.5, entry = 1),
    class = "enrollcast_error_horizon"
  )
  expect_error(
    project_enrollment(
      proj_base(),
      proj_ratios(),
      horizon = .Machine$integer.max + 1,
      entry = 1
    ),
    class = "enrollcast_error_horizon"
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
  expect_identical(p$enrollment[p$year == 2024 & p$grade == "K"], 130)
  expect_identical(p$enrollment[p$year == 2025 & p$grade == "K"], 140)
})

test_that("projection carries state across three years", {
  p <- project_enrollment(
    proj_base(),
    proj_ratios(),
    horizon = 3,
    entry = c(130, 140, 150),
    start_year = 2023
  )
  expect_identical(unique(p$year), c(2024, 2025, 2026))
  expect_equal(p$enrollment[p$year == 2026 & p$grade == "1"], 0.925 * 140)
})

test_that("base enrollment cannot contain NA", {
  v <- c(K = NA_real_, `1` = 99, `2` = 91)
  expect_snapshot(
    project_enrollment(v, proj_ratios(), horizon = 1, entry = 130),
    error = TRUE
  )
  expect_error(
    project_enrollment(v, proj_ratios(), horizon = 1, entry = 130),
    class = "enrollcast_error_base_values"
  )
})

test_that("start_year must be one finite integer", {
  invalid <- list(c(2022, 2023), "2023", NA_real_, Inf, 2023.5)
  for (start_year in invalid) {
    expect_error(
      project_enrollment(
        proj_base(),
        proj_ratios(),
        horizon = 1,
        entry = 130,
        start_year = start_year
      ),
      class = "enrollcast_error_start_year",
      info = sprintf("start_year: %s", toString(start_year))
    )
  }
  expect_snapshot(
    project_enrollment(
      proj_base(),
      proj_ratios(),
      horizon = 1,
      entry = 130,
      start_year = 2023.5
    ),
    error = TRUE
  )
})

test_that("start_year must be within the R integer range", {
  expect_snapshot(
    project_enrollment(
      proj_base(),
      proj_ratios(),
      horizon = 1,
      entry = 130,
      start_year = .Machine$integer.max + 1
    ),
    error = TRUE
  )
  expect_error(
    project_enrollment(
      proj_base(),
      proj_ratios(),
      horizon = 1,
      entry = 130,
      start_year = .Machine$integer.max + 1
    ),
    class = "enrollcast_error_start_year"
  )

  expect_error(
    project_enrollment(
      proj_base(),
      proj_ratios(),
      horizon = 1,
      entry = 130,
      start_year = .Machine$integer.max
    ),
    class = "enrollcast_error_start_year"
  )

  base <- transform(proj_base(), year = .Machine$integer.max + 1)
  expect_error(
    project_enrollment(base, proj_ratios(), horizon = 1, entry = 130),
    class = "enrollcast_error_base_year"
  )

  base <- transform(proj_base(), year = .Machine$integer.max)
  expect_snapshot(
    project_enrollment(base, proj_ratios(), horizon = 1, entry = 130),
    error = TRUE
  )
  expect_error(
    project_enrollment(base, proj_ratios(), horizon = 1, entry = 130),
    class = "enrollcast_error_base_year"
  )
})

test_that("invalid base years do not fall back to relative years", {
  base <- transform(proj_base(), year = "spring")
  expect_snapshot(
    project_enrollment(base, proj_ratios(), horizon = 1, entry = 130),
    error = TRUE
  )
  expect_error(
    project_enrollment(base, proj_ratios(), horizon = 1, entry = 130),
    class = "enrollcast_error_base_year"
  )
})

test_that("a constant schedule reproduces the ratios path", {
  r <- proj_ratios()
  m <- projection_matrix(r)
  entry <- c(130, 140)
  sched <- lapply(entry, function(e) list(matrix = m, entry = e))
  p_sched <- project_enrollment(
    proj_base(),
    schedule = sched,
    start_year = 2023
  )
  p_ratio <- project_enrollment(
    proj_base(),
    r,
    horizon = 2,
    entry = entry,
    start_year = 2023
  )
  expect_identical(p_sched, p_ratio)
})

test_that("schedule path realigns a reordered base", {
  m <- projection_matrix(proj_ratios())
  sched <- list(list(matrix = m, entry = 130))
  reordered <- c(`2` = 91, K = 120, `1` = 99)
  p <- project_enrollment(reordered, schedule = sched, start_year = 2023)
  expect_equal(p$enrollment[p$grade == "1"], 111) # 0.925 * 120, correctly aligned
})

test_that("hand-built identity+diag schedule runs", {
  m <- projection_matrix(proj_ratios())
  ident <- diag(3)
  dimnames(ident) <- dimnames(m)
  scale <- diag(rep(1.1, 3))
  dimnames(scale) <- dimnames(m)
  sched <- list(
    list(matrix = ident, entry = NULL),
    list(matrix = scale, entry = NULL)
  )
  p <- project_enrollment(c(K = 80, `1` = 66, `2` = 60), schedule = sched)
  expect_identical(p$enrollment[p$year == 1 & p$grade == "K"], 80)
  expect_equal(p$enrollment[p$year == 2 & p$grade == "K"], 88)
})

test_that("schedule and ratios are mutually exclusive", {
  m <- projection_matrix(proj_ratios())
  sched <- list(list(matrix = m, entry = 130))
  expect_snapshot(
    project_enrollment(proj_base(), ratios = proj_ratios(), schedule = sched),
    error = TRUE
  )
  expect_error(
    project_enrollment(proj_base(), ratios = proj_ratios(), schedule = sched),
    class = "enrollcast_error_conflicting_args"
  )
})

test_that("project_enrollment needs ratios or a schedule", {
  expect_snapshot(project_enrollment(proj_base(), horizon = 2), error = TRUE)
  expect_error(
    project_enrollment(proj_base(), horizon = 2),
    class = "enrollcast_error_missing_input"
  )
})

test_that("horizon must match schedule length when both are given", {
  m <- projection_matrix(proj_ratios())
  sched <- list(list(matrix = m, entry = 130))
  expect_snapshot(
    project_enrollment(proj_base(), schedule = sched, horizon = 2),
    error = TRUE
  )
  expect_error(
    project_enrollment(proj_base(), schedule = sched, horizon = 2),
    class = "enrollcast_error_horizon_schedule_mismatch"
  )
})

test_that("explicit schedule horizon is validated before comparison", {
  m <- projection_matrix(proj_ratios())
  sched <- list(list(matrix = m, entry = 130))
  for (horizon in list(NA_real_, Inf, 1.5, "1")) {
    expect_error(
      project_enrollment(proj_base(), schedule = sched, horizon = horizon),
      class = "enrollcast_error_horizon"
    )
  }
})

test_that("schedule matrices must contain valid numeric values", {
  valid <- projection_matrix(proj_ratios())
  expect_snapshot(
    project_enrollment(
      proj_base(),
      schedule = list(list(matrix = replace(valid, 1, Inf)))
    ),
    error = TRUE
  )
  invalid <- list(
    matrix(TRUE, 3, 3, dimnames = dimnames(valid)),
    matrix("1", 3, 3, dimnames = dimnames(valid)),
    replace(valid, 1, NA_real_),
    replace(valid, 1, Inf),
    replace(valid, 1, -1)
  )
  for (m in invalid) {
    expect_error(
      project_enrollment(proj_base(), schedule = list(list(matrix = m))),
      class = "enrollcast_error_step_values"
    )
  }
})

test_that("schedule matrix grade names must be present and unique", {
  valid <- projection_matrix(proj_ratios())
  missing_colnames <- valid
  colnames(missing_colnames) <- NULL
  duplicate <- valid
  dimnames(duplicate) <- list(c("K", "K", "2"), c("K", "K", "2"))
  empty <- valid
  dimnames(empty) <- list(c("K", "", "2"), c("K", "", "2"))
  for (m in list(missing_colnames, duplicate, empty)) {
    expect_error(
      project_enrollment(proj_base(), schedule = list(list(matrix = m))),
      class = "enrollcast_error_step_dimnames"
    )
  }
})

test_that("schedule accepts list subclasses", {
  m <- projection_matrix(proj_ratios())
  ordinary <- list(list(matrix = m, entry = 130))
  subclassed <- structure(
    list(structure(list(matrix = m, entry = 130), class = "schedule_step")),
    class = "projection_schedule"
  )
  expect_identical(
    project_enrollment(proj_base(), schedule = subclassed),
    project_enrollment(proj_base(), schedule = ordinary)
  )
})

# --- Internal helper tests ---

test_that("check_step rejects a non-list step", {
  expect_snapshot(check_step("not a list"), error = TRUE)
  expect_error(check_step("not a list"), class = "enrollcast_error_step_shape")
})

test_that("check_step rejects a non-square matrix", {
  m <- projection_matrix(proj_ratios())
  expect_snapshot(
    check_step(list(matrix = m[, 1, drop = FALSE])),
    error = TRUE
  )
  expect_error(
    check_step(list(matrix = m[, 1, drop = FALSE])),
    class = "enrollcast_error_step_not_square"
  )
})

test_that("check_step rejects a matrix with no row names", {
  m <- matrix(c(1, 0, 0.9, 0), nrow = 2, ncol = 2)
  colnames(m) <- c("K", "1")
  expect_snapshot(check_step(list(matrix = m)), error = TRUE)
  expect_error(
    check_step(list(matrix = m)),
    class = "enrollcast_error_step_dimnames"
  )
})

test_that("check_step rejects a matrix with mismatched row and col names", {
  m <- matrix(c(1, 0, 0.9, 0), nrow = 2, ncol = 2)
  rownames(m) <- c("K", "1")
  colnames(m) <- c("K", "2")
  expect_snapshot(check_step(list(matrix = m)), error = TRUE)
  expect_error(
    check_step(list(matrix = m)),
    class = "enrollcast_error_step_dimnames"
  )
})

test_that("check_step rejects an invalid step entry", {
  m <- projection_matrix(proj_ratios())
  expect_snapshot(
    check_step(list(matrix = m, entry = c(1, 2))),
    error = TRUE
  )
  expect_error(
    check_step(list(matrix = m, entry = c(1, 2))),
    class = "enrollcast_error_step_entry"
  )
  for (entry in list(NA_real_, Inf, -1)) {
    expect_error(
      check_step(list(matrix = m, entry = entry)),
      class = "enrollcast_error_step_entry"
    )
  }
})

test_that("check_schedule rejects a non-list schedule", {
  expect_snapshot(check_schedule(42), error = TRUE)
  expect_error(check_schedule(42), class = "enrollcast_error_schedule_shape")
})

test_that("check_schedule rejects an empty list", {
  expect_snapshot(check_schedule(list()), error = TRUE)
  expect_error(
    check_schedule(list()),
    class = "enrollcast_error_schedule_shape"
  )
})

test_that("check_schedule rejects inconsistent grade dimnames", {
  m1 <- projection_matrix(proj_ratios())
  m2 <- matrix(
    c(0, 0, 0.9, 0, 0, 0.95, 0, 0, 0),
    nrow = 3,
    ncol = 3
  )
  rownames(m2) <- c("PK", "K", "1")
  colnames(m2) <- c("PK", "K", "1")
  sched <- list(
    list(matrix = m1, entry = NULL),
    list(matrix = m2, entry = NULL)
  )
  expect_snapshot(check_schedule(sched), error = TRUE)
  expect_error(
    check_schedule(sched),
    class = "enrollcast_error_schedule_inconsistent"
  )
})
