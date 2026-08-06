# Internal condition constructors. `class` is the full stable condition class
# (e.g. "enrollcast_error_horizon") so call sites stay greppable. `.envir`
# forwards the caller's frame so `{}` interpolations resolve there.

ec_abort <- function(
  message,
  class,
  call = rlang::caller_env(),
  .envir = parent.frame()
) {
  cli::cli_abort(message, class = class, call = call, .envir = .envir)
}

ec_warn <- function(message, class, .envir = parent.frame()) {
  cli::cli_warn(message, class = class, .envir = .envir)
}
