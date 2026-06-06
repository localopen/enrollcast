# Generate synthetic district enrollment data for the gpr package.
#
# Two sectors (Traditional Public, Charter), three school years
# (SY23-24, SY24-25, SY25-26), grades PK3 through 12 coded numerically starting
# at -2 (PK3 = -2, PK4 = -1, K = 0, 1..12). The two projected years are produced
# from the base year with a cohort / grade-progression model plus mild noise, so
# the data is internally consistent with the method gpr implements.

set.seed(42)

grade_codes <- -2:12
grade_labels <- c("PK3", "PK4", "K", as.character(1:12))

years <- c(2023, 2024, 2025) # school-year START year
school_years <- c("SY23-24", "SY24-25", "SY25-26")

# Base-year (SY23-24) enrollment by grade code, lowest -> highest grade.
base <- list(
  "Traditional Public" = c(
    320, 380, 450, 460, 455, 450, 445, 440,
    430, 420, 410, 480, 420, 390, 370
  ),
  "Charter" = c(
    60, 90, 140, 145, 150, 150, 148, 145,
    160, 165, 160, 180, 150, 130, 115
  )
)

# Progression ratios feeding each grade from the grade below (length 14, for
# destination grades PK4 (-1) .. 12). Traditional public shows a 9th-grade
# bump (return from charter/private for high school) then upper-grade attrition;
# charter is a growing sector with strong K and middle-school intake.
ratios <- list(
  "Traditional Public" = c(
    1.05, 1.10, 0.99, 0.99, 0.99, 0.98, 0.98,
    0.98, 0.99, 0.98, 1.12, 0.90, 0.93, 0.95
  ),
  "Charter" = c(
    1.30, 1.40, 1.02, 1.02, 1.01, 1.01, 1.00,
    1.08, 1.02, 1.01, 1.05, 0.96, 0.97, 0.98
  )
)

# Exogenous PK3 entry for the two projected years (SY24-25, SY25-26).
entry <- list(
  "Traditional Public" = c(315, 311),
  "Charter" = c(70, 83)
)

generate_sector <- function(sector) {
  n_grades <- length(grade_codes)
  m <- matrix(NA_real_, nrow = n_grades, ncol = length(years))
  m[, 1] <- base[[sector]]
  for (j in 2:length(years)) {
    m[1, j] <- entry[[sector]][j - 1] # PK3 entry (exogenous)
    for (i in 2:n_grades) {
      r <- ratios[[sector]][i - 1] * rnorm(1, mean = 1, sd = 0.015)
      m[i, j] <- m[i - 1, j - 1] * r
    }
  }
  round(m)
}

rows <- do.call(rbind, lapply(names(base), function(sector) {
  m <- generate_sector(sector)
  data.frame(
    school_year = rep(school_years, each = length(grade_codes)),
    year = rep(years, each = length(grade_codes)),
    sector = sector,
    grade = rep(grade_codes, times = length(years)),
    grade_label = rep(grade_labels, times = length(years)),
    enrollment = as.integer(as.vector(m)),
    stringsAsFactors = FALSE
  )
}))

out_dir <- "inst/extdata"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_file <- file.path(out_dir, "synthetic_enrollment.csv")
write.csv(rows, out_file, row.names = FALSE)
message("Wrote ", nrow(rows), " rows to ", out_file)
