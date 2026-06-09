# Internal helpers. Not exported.

# TRUE if `x` is a single, non-missing, positive integer value.
is_count <- function(x) {
	rlang::is_scalar_integerish(x, finite = TRUE) && x >= 1
}

check_columns <- function(data, cols, arg = "data") {
	missing <- setdiff(cols, names(data))
	if (length(missing)) {
		stop(
			sprintf(
				"`%s` is missing required column(s): %s",
				arg,
				toString(missing)
			),
			call. = FALSE
		)
	}
	invisible(data)
}

# Resolve grades to a low -> high character ordering.
resolve_grade_order <- function(grade, grade_order = NULL) {
	u <- unique(as.character(grade))
	if (!is.null(grade_order)) {
		grade_order <- as.character(grade_order)
		missing <- setdiff(u, grade_order)
		if (length(missing)) {
			stop(
				"`grade_order` is missing grade(s): ",
				toString(missing),
				call. = FALSE
			)
		}
		return(grade_order[grade_order %in% u])
	}
	if (is.factor(grade)) {
		lev <- levels(grade)
		return(lev[lev %in% u])
	}
	num <- suppressWarnings(as.numeric(u))
	if (!anyNA(num)) {
		return(u[order(num)])
	}
	# Mixed alpha/numeric labels (e.g. "K", "1", "2") always reach this path.
	warning(
		"Grade order guessed by sorting labels alphabetically; ",
		"pass `grade_order` or a factor `grade` to set it explicitly.",
		call. = FALSE
	)
	sort(u)
}

# Reconstruct grade order from from/to transition pairs (linear chain).
chain_order <- function(from, to) {
	from <- as.character(from)
	to <- as.character(to)
	if (anyDuplicated(from)) {
		stop(
			"A grade feeds more than one grade in `ratios` (branching ",
			"transitions); pass `grade_order` explicitly.",
			call. = FALSE
		)
	}
	entry <- setdiff(from, to)
	if (length(entry) != 1) {
		stop(
			"Could not determine a unique entry grade from `ratios`; ",
			"pass `grade_order` explicitly.",
			call. = FALSE
		)
	}
	nxt <- stats::setNames(to, from)
	order <- entry
	cur <- entry
	visited <- character(0)
	while (cur %in% names(nxt)) {
		if (cur %in% visited) {
			stop(
				"Cycle detected in grade transitions in `ratios`; ",
				"pass `grade_order` explicitly.",
				call. = FALSE
			)
		}
		visited <- c(visited, cur)
		cur <- nxt[[cur]]
		order <- c(order, cur)
	}
	order
}

# Collapse a (grades x transition-years) ratio matrix to one ratio per grade.
summarise_ratios <- function(R, method, weights = NULL) {
	if (method == "weighted") {
		if (is.null(weights)) {
			stop("`weights` is required for method = 'weighted'.", call. = FALSE)
		}
		if (length(weights) != ncol(R)) {
			stop(
				sprintf(
					paste0(
						"`weights` length (%d) must equal number of transition ",
						"years used (%d)."
					),
					length(weights),
					ncol(R)
				),
				call. = FALSE
			)
		}
	}
	apply(R, 1, function(x) {
		switch(
			method,
			mean = mean(x, na.rm = TRUE),
			median = stats::median(x, na.rm = TRUE),
			geometric = exp(mean(log(x), na.rm = TRUE)),
			last = {
				nn <- x[!is.na(x)]
				if (length(nn)) nn[[length(nn)]] else NA_real_
			},
			weighted = stats::weighted.mean(x, w = rev(weights), na.rm = TRUE)
		)
	})
}

# Coerce `base` to a named numeric vector ordered by `go`; derive the year
# when present.
as_base_vector <- function(base, go) {
	year <- NULL
	if (is.data.frame(base)) {
		check_columns(base, c("grade", "enrollment"), "base")
		if ("year" %in% names(base)) {
			uy <- unique(base$year)
			if (length(uy) == 1) {
				y <- suppressWarnings(as.numeric(as.character(uy)))
				if (!is.na(y)) year <- y
			}
		}
		v <- stats::setNames(as.numeric(base$enrollment), as.character(base$grade))
	} else if (is.numeric(base) && !is.null(names(base))) {
		v <- base
	} else {
		stop(
			"`base` must be a data frame (grade, enrollment) or a named ",
			"numeric vector.",
			call. = FALSE
		)
	}
	missing <- setdiff(go, names(v))
	if (length(missing)) {
		stop(
			"`base` is missing enrollment for grade(s): ",
			toString(missing),
			call. = FALSE
		)
	}
	extra <- setdiff(names(v), go)
	if (length(extra)) {
		warning(
			"`base` contains grade(s) not in `ratios` that will be ignored: ",
			toString(extra),
			call. = FALSE
		)
	}
	vv <- v[go]
	if (any(!is.na(vv) & vv < 0)) {
		stop("`base` enrollment must be non-negative.", call. = FALSE)
	}
	list(vector = vv, year = year)
}

# Coerce `entry` to a numeric vector of length `horizon`.
as_entry_vector <- function(entry, horizon) {
	if (is.data.frame(entry)) {
		valcol <- intersect(c("enrollment", "value"), names(entry))
		if (length(valcol) == 0) {
			stop(
				"`entry` data frame must have an 'enrollment' or 'value' column.",
				call. = FALSE
			)
		}
		vals <- as.numeric(entry[[valcol[1]]])
	} else if (is.numeric(entry)) {
		vals <- entry
	} else {
		stop(
			"`entry` must be a numeric vector or a data frame with a value column.",
			call. = FALSE
		)
	}
	if (length(vals) != horizon) {
		stop(
			sprintf(
				"`entry` length (%d) must equal `horizon` (%d).",
				length(vals),
				horizon
			),
			call. = FALSE
		)
	}
	if (any(!is.na(vals) & vals < 0)) {
		stop("`entry` values must be non-negative.", call. = FALSE)
	}
	vals
}
