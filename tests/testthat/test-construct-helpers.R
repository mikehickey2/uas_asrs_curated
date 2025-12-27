# Tests for R/construct_helpers.R

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

# Source the helper file
source(file.path(.test_root, "R", "construct_helpers.R"), local = FALSE)

# -----------------------------------------------------------------------------
# extract_airspace_class tests
# -----------------------------------------------------------------------------

test_that("extract_airspace_class extracts class letters correctly", {
  input <- c("Class B", "Class C", "Class D", "Class E", "Class G", "Class A")
  expected <- c("B", "C", "D", "E", "G", "A")
  expect_equal(extract_airspace_class(input), expected)
})

test_that("extract_airspace_class handles variations in text", {
  input <- c(
    "Class B; Special Use",
    "Class  C",
    "Some text Class D more text"
  )
  expected <- c("B", "C", "D")
  expect_equal(extract_airspace_class(input), expected)
})

test_that("extract_airspace_class returns Unknown for non-matches", {
  input <- c("Special Use", "TFR", "Restricted", "", "No class info")
  expected <- rep("Unknown", 5)
  expect_equal(extract_airspace_class(input), expected)
})

test_that("extract_airspace_class handles NA values", {
  input <- c("Class B", NA, "Class C", NA)
  expected <- c("B", "Unknown", "C", "Unknown")
  expect_equal(extract_airspace_class(input), expected)
})

test_that("extract_airspace_class rejects non-character input", {
  expect_error(
    extract_airspace_class(c(1, 2, 3)),
    "must be a character vector"
  )
})

# -----------------------------------------------------------------------------
# map_phase_simple tests
# -----------------------------------------------------------------------------

test_that("map_phase_simple maps arrival phases", {
  input <- c("Final Approach", "Initial Approach", "Descent", "Landing")
  expect_equal(unique(map_phase_simple(input)), "Arrival")
})

test_that("map_phase_simple maps departure phases", {
  input <- c("Takeoff / Launch", "Climb", "Initial Climb", "Takeoff")
  expect_equal(unique(map_phase_simple(input)), "Departure")
})

test_that("map_phase_simple maps surface phases", {
  input <- c("Taxi", "Ground")
  expect_equal(unique(map_phase_simple(input)), "Surface")
})
test_that("map_phase_simple maps enroute phases", {
  input <- c("Cruise")
  expect_equal(map_phase_simple(input), "Enroute")
})

test_that("map_phase_simple returns Unknown for unmapped values", {
  input <- c("Hovering", "Unknown Phase", "Refueling", "")
  expect_equal(unique(map_phase_simple(input)), "Unknown")
})

test_that("map_phase_simple handles NA values", {
  input <- c("Cruise", NA, "Taxi", NA)
  expected <- c("Enroute", "Unknown", "Surface", "Unknown")
  expect_equal(map_phase_simple(input), expected)
})

test_that("map_phase_simple handles semicolon-delimited values", {
  input <- "Final Approach; Landing"
  expect_equal(map_phase_simple(input), "Arrival")
})

test_that("map_phase_simple follows precedence (Arrival > Departure)", {
  input <- "Climb; Final Approach"
  expect_equal(map_phase_simple(input), "Arrival")
})

test_that("map_phase_simple rejects non-character input", {
  expect_error(
    map_phase_simple(c(1, 2, 3)),
    "must be a character vector"
  )
})

# -----------------------------------------------------------------------------
# parse_miss_horizontal tests
# -----------------------------------------------------------------------------

test_that("parse_miss_horizontal extracts horizontal distance", {
  input <- c(
    "Horizontal 500; Vertical 100",
    "Horizontal 1000",
    "Horizontal 50 feet"
  )
  expected <- c(500, 1000, 50)
  expect_equal(parse_miss_horizontal(input), expected)
})

test_that("parse_miss_horizontal returns NA when not found", {
  input <- c("Vertical 100", "No distance", "", NA)
  expect_true(all(is.na(parse_miss_horizontal(input))))
})

test_that("parse_miss_horizontal is case insensitive", {
  input <- c("HORIZONTAL 200", "horizontal 300")
  expected <- c(200, 300)
  expect_equal(parse_miss_horizontal(input), expected)
})

# -----------------------------------------------------------------------------
# parse_miss_vertical tests
# -----------------------------------------------------------------------------

test_that("parse_miss_vertical extracts vertical distance", {
  input <- c(
    "Horizontal 500; Vertical 100",
    "Vertical 200",
    "Vertical 75 feet"
  )
  expected <- c(100, 200, 75)
  expect_equal(parse_miss_vertical(input), expected)
})

test_that("parse_miss_vertical returns NA when not found", {
  input <- c("Horizontal 100", "No distance", "", NA)
  expect_true(all(is.na(parse_miss_vertical(input))))
})

# -----------------------------------------------------------------------------
# derive_severity_flags tests
# -----------------------------------------------------------------------------

test_that("derive_severity_flags adds correct columns", {
  df <- data.frame(
    events__anomaly = c("NMAC", "Airborne Conflict", NA),
    events__result = c("Took Evasive Action", "ATC Assistance", "None"),
    stringsAsFactors = FALSE
  )
  result <- derive_severity_flags(df)

  expect_true("flag_nmac" %in% names(result))
  expect_true("flag_evasive" %in% names(result))
  expect_true("flag_atc" %in% names(result))
})

test_that("derive_severity_flags sets flag_nmac correctly", {
  df <- data.frame(
    events__anomaly = c("NMAC", "Near NMAC event", "Airborne Conflict", NA),
    events__result = c("None", "None", "None", "None"),
    stringsAsFactors = FALSE
  )
  result <- derive_severity_flags(df)

  expect_equal(result$flag_nmac, c(TRUE, TRUE, FALSE, FALSE))
})

test_that("derive_severity_flags sets flag_evasive correctly", {
  df <- data.frame(
    events__anomaly = c("NMAC", "NMAC", "NMAC"),
    events__result = c("Took Evasive Action", "Evasive Action taken", "None"),
    stringsAsFactors = FALSE
  )
  result <- derive_severity_flags(df)

  expect_equal(result$flag_evasive, c(TRUE, TRUE, FALSE))
})

test_that("derive_severity_flags sets flag_atc correctly", {
  df <- data.frame(
    events__anomaly = c("NMAC", "NMAC", "NMAC", "NMAC"),
    events__result = c(
      "Requested ATC Assistance",
      "Clarification received",
      "ATC Assistance/Clarification",
      "None"
    ),
    stringsAsFactors = FALSE
  )
  result <- derive_severity_flags(df)

  expect_equal(result$flag_atc, c(TRUE, TRUE, TRUE, FALSE))
})

test_that("derive_severity_flags preserves other columns", {
  df <- data.frame(
    acn = c("1234567", "2345678"),
    events__anomaly = c("NMAC", "None"),
    events__result = c("None", "None"),
    other_col = c("a", "b"),
    stringsAsFactors = FALSE
  )
  result <- derive_severity_flags(df)

  expect_true("acn" %in% names(result))
  expect_true("other_col" %in% names(result))
  expect_equal(result$acn, c("1234567", "2345678"))
  expect_equal(result$other_col, c("a", "b"))
})

test_that("derive_severity_flags rejects missing required columns", {
  df <- data.frame(events__anomaly = "NMAC", stringsAsFactors = FALSE)
  expect_error(
    derive_severity_flags(df),
    "missing required columns"
  )
})

test_that("derive_severity_flags rejects non-data-frame input", {
  expect_error(
    derive_severity_flags("not a dataframe"),
    "must be a data frame"
  )
})

# -----------------------------------------------------------------------------
# derive_alias_columns tests
# -----------------------------------------------------------------------------

test_that("derive_alias_columns creates expected columns", {
  df <- data.frame(
    time__date = as.Date(c("2024-01-15", "2024-06-20")),
    time__local_time_of_day = c("0601-1200", "1201-1800"),
    person1__reporter_organization = c("Air Carrier", "Personal"),
    ac1__flight_phase = c("Cruise", "Final Approach"),
    stringsAsFactors = FALSE
  )
  result <- derive_alias_columns(df)

  expect_equal(result$month, c("2024-01", "2024-06"))
  expect_equal(result$time_block, c("0601-1200", "1201-1800"))
  expect_equal(result$reporter_org, c("Air Carrier", "Personal"))
  expect_equal(result$phase_raw, c("Cruise", "Final Approach"))
})

test_that("derive_alias_columns handles NA values", {
  df <- data.frame(
    time__date = as.Date(c("2024-01-15", NA)),
    time__local_time_of_day = c(NA, "1201-1800"),
    person1__reporter_organization = c("Air Carrier", NA),
    ac1__flight_phase = c(NA, "Cruise"),
    stringsAsFactors = FALSE
  )
  result <- derive_alias_columns(df)

  expect_equal(result$month, c("2024-01", NA))
  expect_equal(result$time_block, c(NA, "1201-1800"))
  expect_equal(result$reporter_org, c("Air Carrier", NA))
  expect_equal(result$phase_raw, c(NA, "Cruise"))
})

# -----------------------------------------------------------------------------
# derive_all_constructs tests
# -----------------------------------------------------------------------------

test_that("derive_all_constructs adds all 11 derived columns", {
  df <- data.frame(
    time__date = as.Date("2024-01-15"),
    time__local_time_of_day = "0601-1200",
    person1__reporter_organization = "Air Carrier",
    ac1__flight_phase = "Cruise",
    ac1__airspace = "Class B",
    events__anomaly = "NMAC",
    events__result = "Took Evasive Action",
    events__miss_distance = "Horizontal 500; Vertical 100",
    stringsAsFactors = FALSE
  )
  result <- derive_all_constructs(df)

  expected_cols <- c(
    "month", "time_block", "reporter_org", "phase_raw", "phase_simple",
    "airspace_class", "flag_nmac", "flag_evasive", "flag_atc",
    "miss_horizontal_ft", "miss_vertical_ft"
  )
  expect_true(all(expected_cols %in% names(result)))
})

test_that("derive_all_constructs produces correct values", {
  df <- data.frame(
    time__date = as.Date("2024-03-15"),
    time__local_time_of_day = "1201-1800",
    person1__reporter_organization = "Personal",
    ac1__flight_phase = "Final Approach; Landing",
    ac1__airspace = "Class D",
    events__anomaly = "NMAC; Airborne Conflict",
    events__result = "Requested ATC Assistance/Clarification",
    events__miss_distance = "Horizontal 200; Vertical 50",
    stringsAsFactors = FALSE
  )
  result <- derive_all_constructs(df)

  expect_equal(result$month, "2024-03")
  expect_equal(result$time_block, "1201-1800")
  expect_equal(result$reporter_org, "Personal")
  expect_equal(result$phase_raw, "Final Approach; Landing")
  expect_equal(result$phase_simple, "Arrival")
  expect_equal(result$airspace_class, "D")
  expect_true(result$flag_nmac)
  expect_false(result$flag_evasive)
  expect_true(result$flag_atc)
  expect_equal(result$miss_horizontal_ft, 200)
  expect_equal(result$miss_vertical_ft, 50)
})

# -----------------------------------------------------------------------------
# phase_mapping_table constant tests
# -----------------------------------------------------------------------------

test_that("phase_mapping_table has expected structure", {
  expect_s3_class(phase_mapping_table, "tbl_df")
  expect_equal(nrow(phase_mapping_table), 5)
  expect_named(
    phase_mapping_table,
    c("phase_simple", "keywords", "precedence_rank")
  )
})

test_that("phase_mapping_table contains all phase levels", {
  expected_phases <- c("Arrival", "Departure", "Surface", "Enroute", "Unknown")
  expect_setequal(phase_mapping_table$phase_simple, expected_phases)
})
