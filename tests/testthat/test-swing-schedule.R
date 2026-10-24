test_that("swing_schedule matches issue #8's carried cohort trajectory", {
  grades <- c("K", "1", "2", "3", "4", "5")
  base <- c(K = 60, `1` = 58, `2` = 55, `3` = 60, `4` = 64, `5` = 30)
  ratios <- data.frame(
    grade_from = grades[-6],
    grade_to = grades[-1],
    ratio = c(0.98, 0.97, 0.98, 0.97, 0.95)
  )
  entry <- rep(62, 6)
  target <- c(345, 360, 368, 374)
  s <- swing_schedule(
    ratios,
    horizon = 6,
    swing_years = 0,
    recovery = target,
    entry = entry,
    grade_order = grades
  )
  p <- project_enrollment(base, schedule = s, start_year = 2026)
  expected <- reference_carry(
    base,
    rep(list(progression_matrix(ratios, grades)), 6),
    entry,
    target
  )

  expect_equal(p$enrollment, as.vector(expected))
  expect_equal(
    as.numeric(round(tapply(p$enrollment, p$year, sum))),
    c(345, 360, 368, 374, 370, 366)
  )
  expect_equal(round(p$enrollment[p$grade == "5"]), c(60, 58, 54, 56, 57, 59))
  expect_equal(round(p$enrollment[p$grade == "K"]), c(61, 66, 64, 63, 62, 62))
})

test_that("swing and recovery rescale the grades that move up next year", {
  entry <- c(85, 90, 95, 100, 105, 110)
  s <- swing_schedule(
    fixture_ratios(),
    horizon = 6,
    swing_years = 2,
    recovery = c(225, 245, 260),
    entry = entry
  )
  expect_length(s, 6)
  expect_identical(s[[1]]$matrix, progression_matrix(fixture_ratios()))
  expect_identical(s[[1]]$total, "base")
  expect_identical(s[[2]]$total, "base")
  expect_identical(s[[3]]$total, 225)
  expect_null(s[[6]]$total)
  expect_identical(vapply(s, function(step) step$entry, numeric(1)), entry)

  base <- c(K = 80, `1` = 66, `2` = 60)
  m <- progression_matrix(fixture_ratios())
  p <- project_enrollment(base, schedule = s)
  expect_equal(
    p$enrollment,
    as.vector(reference_carry(
      base,
      rep(list(m), 6),
      entry,
      c(206, 206, 225, 245, 260)
    ))
  )
  expect_equal(
    as.numeric(tapply(p$enrollment, p$year, sum)[1:5]),
    c(206, 206, 225, 245, 260)
  )

  # After the last target nothing is adjusted: the entry class is the supplied
  # value and the other grades are the ratios applied to the recovered grades.
  last <- p$enrollment[p$year == 5]
  after <- p$enrollment[p$year == 6]
  expect_equal(after[[1]], entry[[6]])
  expect_equal(after[-1], unname(drop(m %*% last))[-1])
})

test_that("all-swing and swing-only targets still advance the grade mix", {
  base <- c(K = 80, `1` = 66, `2` = 60)
  m <- progression_matrix(fixture_ratios())
  for (swing_years in c(1, 3)) {
    s <- swing_schedule(
      fixture_ratios(),
      horizon = 3,
      swing_years = swing_years,
      recovery = numeric(0),
      entry = c(85, 90, 95)
    )
    p <- project_enrollment(base, schedule = s)
    totals <- c(rep(206, swing_years), rep(NA, 3 - swing_years))
    expect_equal(
      p$enrollment,
      as.vector(reference_carry(base, rep(list(m), 3), c(85, 90, 95), totals))
    )
  }
})

test_that("no swing or recovery reproduces the normal ratios projection", {
  entry <- c(130, 140)
  s <- swing_schedule(
    fixture_ratios(),
    horizon = 2,
    swing_years = 0,
    recovery = numeric(0),
    entry = entry
  )
  expect_equal(
    project_enrollment(proj_base(), schedule = s),
    project_enrollment(
      proj_base(),
      fixture_ratios(),
      horizon = 2,
      entry = entry
    )
  )
})

test_that("swing targets resolve against the aligned base at projection time", {
  s <- swing_schedule(
    fixture_ratios(),
    horizon = 2,
    swing_years = 2,
    recovery = numeric(0),
    entry = c(85, 90)
  )
  for (base in list(
    c(K = 80, `1` = 66, `2` = 60),
    c(`2` = 20, K = 40, `1` = 30)
  )) {
    p <- project_enrollment(base, schedule = s)
    expect_equal(
      as.numeric(tapply(p$enrollment, p$year, sum)),
      rep(sum(base), 2)
    )
  }
})

test_that("per-year ratios and matrices support changing ratios and opening grades", {
  ratios <- fixture_ratios()
  closed <- progression_matrix(ratios)
  closed["2", ] <- 0
  changed <- ratios
  changed$ratio <- c(0.8, 1.1)
  s <- swing_schedule(
    list(closed, closed, changed, ratios),
    horizon = 4,
    swing_years = 1,
    recovery = c(200, 230),
    entry = c(80, 90, 100, 110),
    grade_order = c("K", "1", "2")
  )
  base <- c(K = 80, `1` = 60, `2` = 0)
  p <- project_enrollment(base, schedule = s)
  expected <- reference_carry(
    base,
    list(
      closed,
      closed,
      progression_matrix(changed),
      progression_matrix(ratios)
    ),
    c(80, 90, 100, 110),
    c(140, 200, 230)
  )
  expect_equal(p$enrollment, as.vector(expected))
  expect_equal(p$enrollment[p$grade == "2"][1:2], c(0, 0))
  expect_gt(p$enrollment[p$year == 3 & p$grade == "2"], 0)
})

test_that("one reusable projection matrix equals a reusable ratios table", {
  args <- list(
    horizon = 2,
    swing_years = 0,
    recovery = 350,
    entry = c(130, 140)
  )
  from_table <- do.call(
    swing_schedule,
    c(list(ratios = fixture_ratios()), args)
  )
  from_matrix <- do.call(
    swing_schedule,
    c(list(ratios = progression_matrix(fixture_ratios())), args)
  )
  expect_identical(from_matrix, from_table)
})

test_that("entry data frames cover all projected years", {
  entry <- data.frame(value = c(130, 140, 150))
  s <- swing_schedule(
    fixture_ratios(),
    horizon = 3,
    swing_years = 1,
    recovery = 350,
    entry = entry
  )
  expect_identical(
    vapply(s, function(step) step$entry, numeric(1)),
    entry$value
  )
})

test_that("swing_schedule rejects an over-long swing+recovery", {
  expect_enrollcast_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 2,
      swing_years = 2,
      recovery = 350,
      entry = c(130, 140)
    ),
    class = "enrollcast_error_swing_too_long"
  )
})

test_that("entry is required even without post-recovery years", {
  expect_enrollcast_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 2,
      swing_years = 1,
      recovery = 350
    ),
    class = "enrollcast_error_entry_required"
  )
  expect_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 2,
      swing_years = 2,
      recovery = numeric(0)
    ),
    class = "enrollcast_error_entry_required"
  )
})

test_that("entry length includes swing and recovery years", {
  expect_enrollcast_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 3,
      swing_years = 1,
      recovery = 350,
      entry = 130
    ),
    class = "enrollcast_error_entry_length"
  )
  for (entry in list(numeric(0), c(130, 140), rep(130, 4))) {
    expect_error(
      swing_schedule(
        fixture_ratios(),
        horizon = 3,
        swing_years = 1,
        recovery = 350,
        entry = entry
      ),
      class = "enrollcast_error_entry_length"
    )
  }
})

test_that("swing_years must be a non-negative integer", {
  expect_enrollcast_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 3,
      swing_years = -1,
      recovery = 350,
      entry = rep(130, 3)
    ),
    class = "enrollcast_error_swing_years"
  )
  for (swing_years in list(NA_real_, Inf, NaN, c(0, 1), "1", 0.5)) {
    expect_error(
      swing_schedule(
        fixture_ratios(),
        horizon = 3,
        swing_years = swing_years,
        recovery = 350,
        entry = rep(130, 3)
      ),
      class = "enrollcast_error_swing_years"
    )
  }
})

test_that("recovery must be a vector of target totals", {
  expect_enrollcast_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 3,
      swing_years = 1,
      recovery = "oops",
      entry = rep(130, 3)
    ),
    class = "enrollcast_error_recovery_type"
  )
  for (recovery in list(NULL, list(350), matrix(350, nrow = 3), TRUE)) {
    expect_error(
      swing_schedule(
        fixture_ratios(),
        horizon = 3,
        swing_years = 0,
        recovery = recovery,
        entry = rep(130, 3)
      ),
      class = "enrollcast_error_recovery_type"
    )
  }
})

test_that("recovery totals must be finite non-missing and non-negative", {
  expect_enrollcast_error(
    swing_schedule(
      fixture_ratios(),
      horizon = 3,
      swing_years = 0,
      recovery = c(350, Inf),
      entry = rep(130, 3)
    ),
    class = "enrollcast_error_recovery_values"
  )
  for (recovery in list(c(350, NA_real_), c(350, NaN), c(350, -1))) {
    expect_error(
      swing_schedule(
        fixture_ratios(),
        horizon = 3,
        swing_years = 0,
        recovery = recovery,
        entry = rep(130, 3)
      ),
      class = "enrollcast_error_recovery_values"
    )
  }
})

test_that("per-year ratios require one valid table or matrix per year", {
  expect_enrollcast_error(
    swing_schedule(
      list(fixture_ratios()),
      horizon = 2,
      swing_years = 0,
      recovery = 350,
      entry = c(130, 140)
    ),
    class = "enrollcast_error_swing_ratios"
  )
  expect_error(
    swing_schedule(
      list(fixture_ratios(), 42),
      horizon = 2,
      swing_years = 0,
      recovery = 350,
      entry = c(130, 140)
    ),
    class = "enrollcast_error_ratios_type"
  )
})

test_that("per-year matrices must share grade names and order", {
  m <- progression_matrix(fixture_ratios())
  reordered <- m[3:1, 3:1]
  expect_enrollcast_error(
    swing_schedule(
      list(m, reordered),
      horizon = 2,
      swing_years = 0,
      recovery = 350,
      entry = c(130, 140)
    ),
    class = "enrollcast_error_schedule_inconsistent"
  )
  expect_enrollcast_error(
    swing_schedule(
      reordered,
      horizon = 2,
      swing_years = 0,
      recovery = 350,
      entry = c(130, 140),
      grade_order = c("K", "1", "2")
    ),
    class = "enrollcast_error_schedule_inconsistent"
  )
  expect_enrollcast_error(
    swing_schedule(
      matrix(1:6, nrow = 2),
      horizon = 2,
      swing_years = 0,
      recovery = 350,
      entry = c(130, 140)
    ),
    class = "enrollcast_error_step_not_square"
  )
  expect_enrollcast_error(
    swing_schedule(
      unname(m),
      horizon = 2,
      swing_years = 0,
      recovery = 350,
      entry = c(130, 140)
    ),
    class = "enrollcast_error_step_dimnames"
  )
  m[1, 1] <- -1
  expect_enrollcast_error(
    swing_schedule(
      m,
      horizon = 2,
      swing_years = 0,
      recovery = 350,
      entry = c(130, 140)
    ),
    class = "enrollcast_error_step_values"
  )
})
