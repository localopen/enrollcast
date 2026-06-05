# Canonical K-2, 2021-2023 fixture used across tests. Grade is a factor so
# ordering is unambiguous.
gpr_fixture <- function() {
	data.frame(
		year = rep(c(2021, 2022, 2023), each = 3),
		grade = factor(
			rep(c("K", "1", "2"), times = 3),
			levels = c("K", "1", "2")
		),
		enrollment = c(100, 90, 80, 110, 95, 88, 120, 99, 91)
	)
}
