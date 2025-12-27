# Governance test: enforce script size limits for EDA scripts
#
# SOFT limit: 300 lines (informational via testthat::inform)
# HARD limit: 500 lines (test fails)
#
# See ADR-005-quality-gates-fail-loud.md for rationale.
#
# Note: Uses root_dir from tests/testthat/helper.R

# =============================================================================
# Helper: count lines in a file
# =============================================================================

count_script_lines <- function(file_path) {

  lines <- readLines(file_path, warn = FALSE)
  # Remove trailing blank lines

  while (length(lines) > 0 && trimws(lines[length(lines)]) == "") {
    lines <- lines[-length(lines)]
  }
  length(lines)
}

# =============================================================================
# Tests
# =============================================================================

test_that("EDA scripts do not exceed hard limit (500 lines)", {
  eda_dir <- file.path(root_dir, "scripts", "eda")
  eda_scripts <- list.files(eda_dir, pattern = "\\.R$", full.names = TRUE)

  expect_gt(length(eda_scripts), 0, label = "EDA scripts found")

  soft_limit <- 300
  hard_limit <- 500

  soft_violations <- character(0)
  hard_violations <- character(0)

  for (script in eda_scripts) {
    line_count <- count_script_lines(script)
    script_name <- basename(script)

    if (line_count > hard_limit) {
      msg <- sprintf(
        "%s: %d lines (exceeds hard limit of %d)",
        script_name, line_count, hard_limit
      )
      hard_violations <- c(hard_violations, msg)
    } else if (line_count > soft_limit) {
      msg <- sprintf(
        "%s: %d lines (exceeds soft limit of %d)",
        script_name, line_count, soft_limit
      )
      soft_violations <- c(soft_violations, msg)
    }
  }

  # Informational: report soft limit violations
  if (length(soft_violations) > 0) {
    message(paste0(
      "Note: Scripts exceeding soft limit (300 lines):\n",
      paste("  ", soft_violations, collapse = "\n")
    ))
  }

  # Fail: hard limit violations

  if (length(hard_violations) > 0) {
    fail(paste0(
      "Found ", length(hard_violations),
      " script(s) exceeding hard limit (500 lines).\n",
      "Refactor these scripts before merge.\n\n",
      "Violations:\n",
      paste("  ", hard_violations, collapse = "\n")
    ))
  }

  expect_length(hard_violations, 0)
})
