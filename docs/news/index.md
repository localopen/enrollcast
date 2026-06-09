# Changelog

## enrollcast 0.0.0.9000

- Initial development version.
- [`progression_ratios()`](../reference/progression_ratios.md) computes
  grade progression ratios from historical grade-level enrollment, with
  configurable averaging (`mean`, `geometric`, `median`, `last`,
  `weighted`).
- [`leslie_matrix()`](../reference/leslie_matrix.md) assembles the
  Leslie projection matrix from progression ratios.
- [`project_enrollment()`](../reference/project_enrollment.md) projects
  enrollment forward an arbitrary horizon, taking the entry grade
  exogenously.
