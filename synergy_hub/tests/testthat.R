# Test runner for Synergy Hub
# This file orchestrates all unit tests

library(testthat)

# Set working directory to the project root
setwd("../..")

# Run all tests
test_results <- test_dir("tests/testthat", reporter = "summary")

# Print results
print(test_results)

# Exit with appropriate code
if (any(test_results$failed > 0 | test_results$error)) {
  quit(status = 1)
} else {
  message("\n✓ All tests passed successfully!")
  quit(status = 0)
}
