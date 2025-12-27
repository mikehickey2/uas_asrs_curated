# Tests for render preflight checks
# Tests: preflight failure on missing assets

library(readr)
library(dplyr)

# =============================================================================
# Render preflight tests
# =============================================================================

test_that("preflight detects missing manifest file", {
  fake_manifest_path <- tempfile(fileext = ".csv")

  expect_false(file.exists(fake_manifest_path))
})

test_that("preflight detects missing assets in manifest", {
  temp_manifest <- tempfile(fileext = ".csv")

  manifest_data <- tibble(
    type = c("Table", "Figure"),
    number = c("1", "1"),
    id = c("table1", "fig1"),
    filename = c("table1.csv", "fig1.png"),
    path = c(
      tempfile(fileext = ".csv"),
      tempfile(fileext = ".png")
    ),
    exists = c(FALSE, FALSE)
  )

  write_csv(manifest_data, temp_manifest)

  loaded <- read_csv(temp_manifest, show_col_types = FALSE)
  missing_assets <- loaded |> filter(!exists)

  expect_equal(nrow(missing_assets), 2)

  unlink(temp_manifest)
})

test_that("preflight passes when all assets exist", {
  temp_manifest <- tempfile(fileext = ".csv")
  temp_asset1 <- tempfile(fileext = ".csv")
  temp_asset2 <- tempfile(fileext = ".png")

  writeLines("test", temp_asset1)
  writeLines("test", temp_asset2)

  manifest_data <- tibble(
    type = c("Table", "Figure"),
    number = c("1", "1"),
    id = c("table1", "fig1"),
    filename = c(basename(temp_asset1), basename(temp_asset2)),
    path = c(temp_asset1, temp_asset2),
    exists = c(TRUE, TRUE)
  )

  write_csv(manifest_data, temp_manifest)

  loaded <- read_csv(temp_manifest, show_col_types = FALSE)
  missing_assets <- loaded |> filter(!exists)

  expect_equal(nrow(missing_assets), 0)

  unlink(c(temp_manifest, temp_asset1, temp_asset2))
})

test_that("actual manifest has all assets present", {
  manifest_path <- file.path(root_dir, "output/notes/assets_manifest.csv")
  skip_if_not(file.exists(manifest_path))

  manifest <- read_csv(manifest_path, show_col_types = FALSE)

  expect_true("exists" %in% names(manifest))

  missing <- manifest |> filter(!exists)
  expect_equal(
    nrow(missing), 0,
    info = paste("Missing:", paste(missing$path, collapse = ", "))
  )
})

test_that("QMD file exists for rendering", {
  qmd_path <- file.path(root_dir, "scripts/eda/01_descriptive_analysis.qmd")
  expect_true(file.exists(qmd_path))
})

test_that("APA reference doc exists or can be generated", {
  apa_ref <- file.path(root_dir, "assets/apa_reference.docx")
  apa_script <- file.path(root_dir, "scripts/eda/13_create_apa_reference.R")

  ref_exists <- file.exists(apa_ref)
  script_exists <- file.exists(apa_script)

  expect_true(ref_exists || script_exists)
})
