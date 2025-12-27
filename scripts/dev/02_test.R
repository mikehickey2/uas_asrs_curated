# Run testthat test suite
#
# Usage:
#   Rscript scripts/dev/02_test.R           # Run all tests
#   Rscript scripts/dev/02_test.R --filter eda  # Run tests matching "eda"

library(testthat)

args <- commandArgs(trailingOnly = TRUE)

filter_pattern <- NULL
filter_idx <- which(args == "--filter")
if (length(filter_idx) > 0 && filter_idx < length(args)) {
  filter_pattern <- args[filter_idx + 1]
}

cat("==============================================\n")
cat("Running testthat test suite\n")
cat("==============================================\n\n")

if (!is.null(filter_pattern)) {
  cat("Filter:", filter_pattern, "\n\n")
}

results <- test_dir(
  "tests/testthat",
  filter = filter_pattern,
  stop_on_failure = FALSE,
  reporter = "progress"
)

cat("\n")
cat("==============================================\n")
cat("Summary\n")
cat("==============================================\n")

summary_df <- as.data.frame(results)

n_pass <- sum(summary_df$passed, na.rm = TRUE)
n_fail <- sum(summary_df$failed, na.rm = TRUE)
n_skip <- sum(summary_df$skipped, na.rm = TRUE)
n_warn <- sum(summary_df$warning, na.rm = TRUE)

cat("Passed: ", n_pass, "\n")
cat("Failed: ", n_fail, "\n")
cat("Skipped:", n_skip, "\n")
cat("Warnings:", n_warn, "\n")

if (n_fail > 0) {
  cat("\nTests FAILED\n")
  quit(status = 1)
} else {
  cat("\nAll tests passed.\n")
}
