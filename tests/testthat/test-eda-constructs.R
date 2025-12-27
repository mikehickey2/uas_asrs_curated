# Tests for EDA construct derivation functions
# Tests: phase mapping, miss distance parsing

library(stringr)
library(purrr)

# Replicate functions from 02_constructs.R for testing
arrival_pattern <- regex(
  "Final Approach|Initial Approach|Descent|Landing",
  ignore_case = TRUE
)
departure_pattern <- regex("Takeoff|Launch|Climb", ignore_case = TRUE)
surface_pattern <- regex("Taxi|Ground", ignore_case = TRUE)
enroute_pattern <- regex("Cruise", ignore_case = TRUE)

map_phase <- function(phase_raw) {
  if (is.na(phase_raw)) {
    return("Unknown")
  }
  tokens <- str_split(phase_raw, ";")[[1]] |>
    str_trim() |>
    discard(~ .x == "")
  if (length(tokens) == 0) {
    return("Unknown")
  }
  combined <- paste(tokens, collapse = " ")
  if (str_detect(combined, arrival_pattern)) {
    return("Arrival")
  }
  if (str_detect(combined, departure_pattern)) {
    return("Departure")
  }
  if (str_detect(combined, surface_pattern)) {
    return("Surface")
  }
  if (str_detect(combined, enroute_pattern)) {
    return("Enroute")
  }
  "Unknown"
}

parse_miss_horizontal <- function(x) {
  if (is.na(x)) {
    return(NA_real_)
  }
  match <- str_match(x, regex("Horizontal\\s+(\\d+)", ignore_case = TRUE))
  if (is.na(match[1, 1])) {
    return(NA_real_)
  }
  as.numeric(match[1, 2])
}

parse_miss_vertical <- function(x) {
  if (is.na(x)) {
    return(NA_real_)
  }
  match <- str_match(x, regex("Vertical\\s+(\\d+)", ignore_case = TRUE))
  if (is.na(match[1, 1])) {
    return(NA_real_)
  }
  as.numeric(match[1, 2])
}

# =============================================================================
# Phase mapping tests
# =============================================================================

test_that("map_phase returns Arrival for arrival-related keywords", {
  expect_equal(map_phase("Final Approach"), "Arrival")
  expect_equal(map_phase("Initial Approach"), "Arrival")
  expect_equal(map_phase("Descent"), "Arrival")
  expect_equal(map_phase("Landing"), "Arrival")
  expect_equal(map_phase("Descent; Landing"), "Arrival")
})

test_that("map_phase returns Departure for departure-related keywords", {
  expect_equal(map_phase("Takeoff / Launch"), "Departure")
  expect_equal(map_phase("Climb"), "Departure")
  expect_equal(map_phase("Takeoff"), "Departure")
})

test_that("map_phase returns Surface for surface-related keywords", {
  expect_equal(map_phase("Taxi"), "Surface")
  expect_equal(map_phase("Ground"), "Surface")
})

test_that("map_phase returns Enroute for cruise", {
  expect_equal(map_phase("Cruise"), "Enroute")
})

test_that("map_phase returns Unknown for NA, empty, or unrecognized", {
  expect_equal(map_phase(NA_character_), "Unknown")
  expect_equal(map_phase(""), "Unknown")
  expect_equal(map_phase("   "), "Unknown")
  expect_equal(map_phase("Holding"), "Unknown")
})
test_that("map_phase precedence: Arrival > Departure > Surface > Enroute", {
  expect_equal(map_phase("Descent; Climb"), "Arrival")
  expect_equal(map_phase("Cruise; Final Approach"), "Arrival")
})

# =============================================================================
# Miss distance parsing tests
# =============================================================================

test_that("parse_miss_horizontal extracts horizontal distance", {
  expect_equal(parse_miss_horizontal("Horizontal 500"), 500)
  expect_equal(parse_miss_horizontal("horizontal 100"), 100)
  expect_equal(parse_miss_horizontal("Horizontal 0"), 0)
})

test_that("parse_miss_horizontal returns NA for missing/invalid", {
  expect_true(is.na(parse_miss_horizontal(NA_character_)))
  expect_true(is.na(parse_miss_horizontal("")))
  expect_true(is.na(parse_miss_horizontal("Vertical 500")))
  expect_true(is.na(parse_miss_horizontal("No distance")))
})

test_that("parse_miss_vertical extracts vertical distance", {
  expect_equal(parse_miss_vertical("Vertical 200"), 200)
  expect_equal(parse_miss_vertical("vertical 50"), 50)
  expect_equal(parse_miss_vertical("Vertical 0"), 0)
})

test_that("parse_miss_vertical returns NA for missing/invalid", {
  expect_true(is.na(parse_miss_vertical(NA_character_)))
  expect_true(is.na(parse_miss_vertical("")))
  expect_true(is.na(parse_miss_vertical("Horizontal 500")))
})

test_that("miss distance parsing works with combined strings", {
  combined <- "Horizontal 500; Vertical 200"
  expect_equal(parse_miss_horizontal(combined), 500)
  expect_equal(parse_miss_vertical(combined), 200)
})
