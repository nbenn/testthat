#' Run all tests in an installed package
#'
#' Test are run in an environment that inherits from the package's namespace
#' environment, so that tests can access non-exported functions and variables.
#' Tests should be placed in either \code{inst/tests}, or (better)
#' \code{tests/testthat}.
#'
#' @section R CMD check:
#' Use \code{test_package} to test an installed package, or in
#' \code{tests/test-all.R}if you're using the older \code{inst/tests}
#' convention.
#'
#' If your tests live in \code{tests/testthat} (preferred) use \code{test_check}
#' in \code{tests/test-all.R}.  You still use \code{test_package} when testing
#' the installed package.
#'
#' @param package   package name
#' @param parallel  whether to run the tests in parallel using 
#'  \code{\link{parallel_test_dir}}
#' @inheritParams test_dir
#' @param ...  additional arguments forwarded to \code{\link{parallel_test_dir}}
#' @return the results as a "testthat_results" (list)
#' @export
#' @examples
#' \dontrun{test_package("testthat")}
test_package <- function(package, parallel = FALSE, filter = NULL,  
  reporter = "summary", ...) {
  # Ensure that test package returns silently if called recursively - this
  # will occur if test-all.R ends up in the same directory as all the other
  # tests.
  if (env_test$in_test) return(invisible())
  env_test$in_test <- TRUE
  on.exit(env_test$in_test <- FALSE)

  test_path <- system.file("tests", package = package)
  if (test_path == "") stop("No tests found for ", package, call. = FALSE)

  # If testthat subdir exists, use that
  test_path2 <- file.path(test_path, "testthat")
  if (file.exists(test_path2)) test_path <- test_path2

  reporter <- find_reporter(reporter)

  res <- if (!parallel) {
    env <- new.env(parent = getNamespace(package))
    test_dir(test_path, reporter = reporter, env = env, filter = filter)
  } else {
    parallel_test_dir(test_path, filter = filter, ...)
  }

  if (!all_passed.testthat_results(res)) {
    warning("Test failures")
  }
  invisible(res)
}

#' @export
#' @rdname test_package
test_check <- function(package, filter = NULL, reporter = "summary") {
  require(package, character.only = TRUE)

  test_path <- "testthat"
  if (!file_test('-d', test_path)) {
    stop("No tests found for ", package, call. = FALSE)
  }

  reporter <- find_reporter(reporter)
  env <- new.env(parent = getNamespace(package))
  res <- test_dir(test_path, reporter = reporter, env = env, filter = filter)

  if (!all_passed.testthat_results(res)) {
    warning("Test failures")
  }
  invisible(res)
}


env_test <- new.env(parent = emptyenv())
env_test$in_test <- FALSE
