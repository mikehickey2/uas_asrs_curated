# Tests for R/asrs_constructs_schema.R

# Find project root (same pattern as helper.R)
.find_root <- function() {
  cur <- normalizePath(getwd())
  repeat {
    candidate <- file.path(cur, "R", "asrs_schema.R")
    if (file.exists(candidate)) return(cur)
    parent <- dirname(cur)
    if (parent == cur) stop("Project root not found")
    cur <- parent
  }
}
.test_root <- .find_root()

# Source the schema file into global environment
source(file.path(.test_root, "R", "asrs_constructs_schema.R"), local = FALSE)

# -----------------------------------------------------------------------------
# Schema object tests
# -----------------------------------------------------------------------------

test_that("asrs_constructs_schema has expected structure", {
  expect_s3_class(asrs_constructs_schema, "tbl_df")
  expect_equal(nrow(asrs_constructs_schema), 11)
  expect_named(
    asrs_constructs_schema,
    c("name", "type", "definition", "source_columns", "notes")
  )
})

test_that("asrs_constructs_cols contains 11 column names", {
  expect_length(asrs_constructs_cols, 11)
  expect_type(asrs_constructs_cols, "character")
  expect_true(all(nchar(asrs_constructs_cols) > 0))
})

test_that("asrs_phase_simple_levels contains expected values", {
  expect_equal(
    sort(asrs_phase_simple_levels),
    sort(c("Arrival", "Departure", "Surface", "Enroute", "Unknown"))
  )
})

test_that("asrs_airspace_class_levels contains expected values", {
  expect_equal(
    sort(asrs_airspace_class_levels),
    sort(c("A", "B", "C", "D", "E", "G", "Unknown"))
  )
})

# -----------------------------------------------------------------------------
# Validation function tests - using constructed RDS if available
# -----------------------------------------------------------------------------

test_that("validate_constructed_schema passes on real RDS", {
  rds_path <- file.path(.test_root, "data", "asrs_constructed.rds")
  skip_if_not(file.exists(rds_path), "constructed dataset not available")

  asrs <- readRDS(rds_path)
  result <- validate_constructed_schema(asrs)
  expect_true(result)
})

# -----------------------------------------------------------------------------
# Validation function tests - synthetic data
# -----------------------------------------------------------------------------

test_that("validate_constructed_schema rejects non-data-frame input", {
  expect_error(
    validate_constructed_schema("not a data frame"),
    "Input must be a data frame"
  )
  expect_error(
    validate_constructed_schema(list(a = 1)),
    "Input must be a data frame"
  )
})

test_that("validate_constructed_schema rejects missing columns", {
  df <- data.frame(month = "2024-01")
  expect_error(
    validate_constructed_schema(df),
    "Missing required columns"
  )
})

test_that("validate_constructed_schema rejects wrong types", {
  # Create minimal valid structure with one wrong type
  df <- data.frame(
    month = "2024-01",
    time_block = "0601-1200",
    reporter_org = "Air Carrier",
    phase_raw = "Cruise",
    phase_simple = "Enroute",
    airspace_class = "B",
    flag_nmac = "TRUE",
    flag_evasive = FALSE,
    flag_atc = FALSE,
    miss_horizontal_ft = 100,
    miss_vertical_ft = 50,
    stringsAsFactors = FALSE
  )
  expect_error(
    validate_constructed_schema(df),
    "Column 'flag_nmac' must be logical"
  )
})

test_that("validate_constructed_schema rejects invalid phase_simple values", {
  df <- data.frame(
    month = "2024-01",
    time_block = "0601-1200",
    reporter_org = "Air Carrier",
    phase_raw = "Cruise",
    phase_simple = "InvalidPhase",
    airspace_class = "B",
    flag_nmac = TRUE,
    flag_evasive = FALSE,
    flag_atc = FALSE,
    miss_horizontal_ft = 100,
    miss_vertical_ft = 50,
    stringsAsFactors = FALSE
  )
  expect_error(
    validate_constructed_schema(df),
    "Column 'phase_simple' contains invalid values"
  )
})

test_that("validate_constructed_schema rejects invalid airspace_class values", {
  df <- data.frame(
    month = "2024-01",
    time_block = "0601-1200",
    reporter_org = "Air Carrier",
    phase_raw = "Cruise",
    phase_simple = "Enroute",
    airspace_class = "Z",
    flag_nmac = TRUE,
    flag_evasive = FALSE,
    flag_atc = FALSE,
    miss_horizontal_ft = 100,
    miss_vertical_ft = 50,
    stringsAsFactors = FALSE
  )
  expect_error(
    validate_constructed_schema(df),
    "Column 'airspace_class' contains invalid values"
  )
})

test_that("validate_constructed_schema accepts valid synthetic data", {
  df <- data.frame(
    month = "2024-01",
    time_block = "0601-1200",
    reporter_org = "Air Carrier",
    phase_raw = "Cruise",
    phase_simple = "Enroute",
    airspace_class = "B",
    flag_nmac = TRUE,
    flag_evasive = FALSE,
    flag_atc = FALSE,
    miss_horizontal_ft = 100,
    miss_vertical_ft = 50,
    stringsAsFactors = FALSE
  )
  result <- validate_constructed_schema(df)
  expect_true(result)
})

test_that("validate_constructed_schema handles NA values correctly", {
  df <- data.frame(
    month = NA_character_,
    time_block = NA_character_,
    reporter_org = NA_character_,
    phase_raw = NA_character_,
    phase_simple = "Unknown",
    airspace_class = "Unknown",
    flag_nmac = FALSE,
    flag_evasive = FALSE,
    flag_atc = FALSE,
    miss_horizontal_ft = NA_real_,
    miss_vertical_ft = NA_real_,
    stringsAsFactors = FALSE
  )
  result <- validate_constructed_schema(df)
  expect_true(result)
})
