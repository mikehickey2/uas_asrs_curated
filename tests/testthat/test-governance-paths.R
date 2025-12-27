# Governance test: enforce R/paths.R as the single source of path literals
#
# This test scans scripts/eda/*.R and fails if hardcoded path prefixes
# or specific data filenames appear outside of allowed patterns.
#
# Allowed:
#   - source("R/paths.R")
#   - PATHS$... usage
#
# Forbidden:
#   - Literal "data/", "output/", "assets/" prefixes
#   - Specific filenames: asrs_constructed.rds, asrs_uas_reports_clean.csv
#
# Note: Uses root_dir from tests/testthat/helper.R

# =============================================================================
# Helper: scan file for forbidden path patterns
# =============================================================================

scan_file_for_forbidden_paths <- function(file_path) {
  lines <- readLines(file_path, warn = FALSE)

  # Forbidden patterns: path prefixes and specific filenames
  forbidden_patterns <- c(
    '"data/',
    '"output/',
    '"assets/',
    "asrs_constructed\\.rds",
    "asrs_uas_reports_clean\\.csv",
    "asrs_curated_drone_reports\\.csv"
  )

  # Allowed patterns that override forbidden matches
  allowed_patterns <- c(
    'source\\("R/paths\\.R"\\)',
    "PATHS\\$"
  )

  violations <- character(0)

  for (i in seq_along(lines)) {
    line <- lines[i]

    # Skip if line contains an allowed pattern
    is_allowed <- any(vapply(
      allowed_patterns,
      function(p) grepl(p, line),
      logical(1)
    ))
    if (is_allowed) next

    # Check for forbidden patterns
    for (pattern in forbidden_patterns) {
      if (grepl(pattern, line)) {
        violations <- c(
          violations,
          sprintf("%s:%d: %s", basename(file_path), i, trimws(line))
        )
        break
      }
    }
  }

  violations
}

# =============================================================================
# Tests
# =============================================================================

test_that("EDA scripts use PATHS$ constants, not hardcoded paths", {
  eda_dir <- file.path(root_dir, "scripts", "eda")
  eda_scripts <- list.files(eda_dir, pattern = "\\.R$", full.names = TRUE)

  # Sanity check: we should have EDA scripts to scan
  expect_gt(length(eda_scripts), 0, label = "EDA scripts found")

  all_violations <- character(0)

  for (script in eda_scripts) {
    violations <- scan_file_for_forbidden_paths(script)
    all_violations <- c(all_violations, violations)
  }

  if (length(all_violations) > 0) {
    fail(paste0(
      "Found ", length(all_violations), " hardcoded path(s) in EDA scripts.\n",
      "Use PATHS$ constants from R/paths.R instead.\n\n",
      "Violations:\n",
      paste("  ", all_violations, collapse = "\n")
    ))
  }

  expect_length(all_violations, 0)
})

test_that("R/paths.R exists and defines PATHS", {
  paths_file <- file.path(root_dir, "R", "paths.R")
  expect_true(file.exists(paths_file))

  # Source and verify PATHS is defined
  local_env <- new.env()
  source(paths_file, local = local_env)
  expect_true(exists("PATHS", envir = local_env))
  PATHS <- local_env$PATHS
  expect_type(PATHS, "list")

  # Verify required path constants exist
  required_keys <- c(
    "raw_csv",
    "curated_csv",
    "constructed_rds",
    "output_tables",
    "output_figures",
    "output_notes",
    "output_reports",
    "apa_reference_doc"
  )

  for (key in required_keys) {
    expect_true(
      key %in% names(PATHS),
      label = paste("PATHS$", key, " is defined", sep = "")
    )
  }
})
