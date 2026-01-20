#!/usr/bin/env Rscript
# Test Runner Script for Synergy Hub

# Check if testthat is installed
if (!require("testthat", quietly = TRUE)) {
  message("Installing testthat package...")
  install.packages("testthat", repos = "https://cloud.r-project.org")
}

# Check if required packages are installed
required_packages <- c("dplyr", "readr", "arrow", "lubridate", "shiny",
                       "shinydashboard", "plotly")

missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) > 0) {
  message("Warning: The following packages are not installed: ",
          paste(missing_packages, collapse = ", "))
  message("Some tests may fail. Install with:")
  message('install.packages(c("', paste(missing_packages, collapse = '", "'), '"))')
}

library(testthat)

# Set working directory to script location
setwd(dirname(sys.frame(1)$ofile))

message("\n===============================================")
message("Running Synergy Hub Unit Tests")
message("===============================================\n")

# Run all tests
test_results <- test_dir("tests/testthat", reporter = "summary")

message("\n===============================================")
message("Test Summary")
message("===============================================")

# Print summary
if (length(test_results) > 0) {
  total_tests <- sum(sapply(test_results, function(x) x$nb))
  failed_tests <- sum(sapply(test_results, function(x) x$failed))
  error_tests <- sum(sapply(test_results, function(x) x$error))

  message("Total Tests: ", total_tests)
  message("Failed: ", failed_tests)
  message("Errors: ", error_tests)

  if (failed_tests > 0 || error_tests > 0) {
    message("\n❌ Some tests failed!")
    quit(status = 1)
  } else {
    message("\n✓ All tests passed successfully!")
    quit(status = 0)
  }
} else {
  message("No test results available")
  quit(status = 1)
}
