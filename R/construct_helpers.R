# Helper functions for constructing derived analytical columns
#
# These functions extract reusable transformation logic from
# scripts/eda/02_constructs.R. All functions are vectorized and
# follow fail-loud principles (no tryCatch or suppression).
#
# See also:
#   - R/asrs_constructs_schema.R for schema validation
#   - scripts/eda/02_constructs.R for orchestration

# Alias for rlang .data pronoun used in dplyr pipelines
.data <- rlang::.data

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

#' Phase mapping table for reference/documentation
#' Maps raw flight phase values to simplified categories
phase_mapping_table <- tibble::tribble(
  ~phase_simple, ~keywords, ~precedence_rank,
  "Arrival", "Final Approach; Initial Approach; Descent; Landing", 1L,
  "Departure", "Takeoff / Launch; Climb", 2L,
  "Surface", "Taxi; Ground", 3L,
  "Enroute", "Cruise", 4L,
  "Unknown", "(default if no match)", 5L
)

# Precompiled regex patterns for phase mapping
.arrival_pattern <- stringr::regex(
  "Final Approach|Initial Approach|Descent|Landing",
  ignore_case = TRUE
)
.departure_pattern <- stringr::regex("Takeoff|Launch|Climb", ignore_case = TRUE)
.surface_pattern <- stringr::regex("Taxi|Ground", ignore_case = TRUE)
.enroute_pattern <- stringr::regex("Cruise", ignore_case = TRUE)

# -----------------------------------------------------------------------------
# Airspace Class Extraction
# -----------------------------------------------------------------------------

#' Extract airspace class from airspace text
#'
#' Parses airspace descriptions to extract the FAA class letter (A-G).
#' Returns "Unknown" when class cannot be determined.
#'
#' @param x Character vector of airspace descriptions
#' @return Character vector of class letters or "Unknown"
#' @examples
#' extract_airspace_class(c("Class B", "Class G", "Special Use", NA))
#' # Returns: c("B", "G", "Unknown", "Unknown")
extract_airspace_class <- function(x) {
  if (!is.character(x) && !all(is.na(x))) {
    stop("extract_airspace_class: input must be a character vector")
  }
  matches <- stringr::str_match(x, "Class\\s+([A-G])")
  result <- matches[, 2]
  result[is.na(result)] <- "Unknown"
  result
}

# -----------------------------------------------------------------------------
# Phase Mapping
# -----------------------------------------------------------------------------

#' Map single raw phase value to simplified category (internal)
#'
#' @param phase_raw Single character value
#' @return Single character value: Arrival, Departure, Surface, Enroute, Unknown
.map_phase_single <- function(phase_raw) {
  if (is.na(phase_raw)) {
    return("Unknown")
  }
  tokens <- stringr::str_split(phase_raw, ";")[[1]] |>
    stringr::str_trim() |>
    purrr::discard(~ .x == "")
  if (length(tokens) == 0) {
    return("Unknown")
  }
  combined <- paste(tokens, collapse = " ")
  if (stringr::str_detect(combined, .arrival_pattern)) {
    return("Arrival")
  }
  if (stringr::str_detect(combined, .departure_pattern)) {
    return("Departure")
  }
  if (stringr::str_detect(combined, .surface_pattern)) {
    return("Surface")
  }
  if (stringr::str_detect(combined, .enroute_pattern)) {
    return("Enroute")
  }
  "Unknown"
}

#' Map raw flight phase to simplified category
#'
#' Maps semicolon-delimited flight phase strings to one of five categories:
#' Arrival, Departure, Surface, Enroute, or Unknown.
#'
#' Precedence order: Arrival > Departure > Surface > Enroute > Unknown
#'
#' @param x Character vector of raw flight phase values
#' @return Character vector of simplified phase categories
#' @examples
#' map_phase_simple(c("Final Approach", "Cruise", "Taxi", NA))
#' # Returns: c("Arrival", "Enroute", "Surface", "Unknown")
map_phase_simple <- function(x) {
  if (!is.character(x) && !all(is.na(x))) {
    stop("map_phase_simple: input must be a character vector")
  }

  vapply(x, .map_phase_single, character(1), USE.NAMES = FALSE)
}

# -----------------------------------------------------------------------------
# Miss Distance Parsing
# -----------------------------------------------------------------------------

#' Parse horizontal miss distance from text
#'
#' Extracts numeric horizontal distance in feet from miss distance text.
#'
#' @param x Character vector of miss distance descriptions
#' @return Numeric vector of horizontal distances in feet (NA if not found)
#' @examples
#' parse_miss_horizontal(c("Horizontal 500; Vertical 100", "Vertical 200", NA))
#' # Returns: c(500, NA, NA)
parse_miss_horizontal <- function(x) {
  if (!is.character(x) && !all(is.na(x))) {
    stop("parse_miss_horizontal: input must be a character vector")
  }
  pattern <- stringr::regex("Horizontal\\s+(\\d+)", ignore_case = TRUE)
  matches <- stringr::str_match(x, pattern)
  as.numeric(matches[, 2])
}

#' Parse vertical miss distance from text
#'
#' Extracts numeric vertical distance in feet from miss distance text.
#'
#' @param x Character vector of miss distance descriptions
#' @return Numeric vector of vertical distances in feet (NA if not found)
#' @examples
#' parse_miss_vertical(c("Horizontal 500; Vertical 100", "Horizontal 200", NA))
#' # Returns: c(100, NA, NA)
parse_miss_vertical <- function(x) {
  if (!is.character(x) && !all(is.na(x))) {
    stop("parse_miss_vertical: input must be a character vector")
  }
  pattern <- stringr::regex("Vertical\\s+(\\d+)", ignore_case = TRUE)
  matches <- stringr::str_match(x, pattern)
  as.numeric(matches[, 2])
}

# -----------------------------------------------------------------------------
# Severity Flag Derivation
# -----------------------------------------------------------------------------

#' Derive severity indicator flags from event data
#'
#' Adds three logical flag columns to indicate severity indicators:
#' - flag_nmac: Near Mid-Air Collision mentioned in anomaly
#' - flag_evasive: Evasive action taken
#' - flag_atc: ATC assistance or clarification requested
#'
#' @param df Data frame with columns events__anomaly and events__result
#' @return Data frame with flag_nmac, flag_evasive, flag_atc columns added
#' @examples
#' \dontrun{
#' df <- derive_severity_flags(asrs_data)
#' }
derive_severity_flags <- function(df) {
  if (!is.data.frame(df)) {
    stop("derive_severity_flags: input must be a data frame")
  }
  required_cols <- c("events__anomaly", "events__result")
  missing <- setdiff(required_cols, names(df))
  if (length(missing) > 0) {
    stop(
      "derive_severity_flags: missing required columns: ",
      paste(missing, collapse = ", ")
    )
  }

  df |>
    dplyr::mutate(
      flag_nmac = stringr::str_detect(
        .data$events__anomaly,
        stringr::regex("\\bNMAC\\b", ignore_case = TRUE)
      ) %in% TRUE,
      flag_evasive = stringr::str_detect(
        .data$events__result,
        stringr::regex("Evasive Action", ignore_case = TRUE)
      ) %in% TRUE,
      flag_atc = stringr::str_detect(
        .data$events__result,
        stringr::regex("ATC Assistance|Clarification", ignore_case = TRUE)
      ) %in% TRUE
    )
}

# -----------------------------------------------------------------------------
# Alias Column Derivation
# -----------------------------------------------------------------------------

#' Derive alias columns for cleaner analysis names
#'
#' Creates shortened alias columns from source columns:
#' - month: from time__date (YYYY-MM format)
#' - time_block: alias for time__local_time_of_day
#' - reporter_org: alias for person1__reporter_organization
#' - phase_raw: alias for ac1__flight_phase
#'
#' @param df Data frame with required source columns
#' @return Data frame with alias columns added
derive_alias_columns <- function(df) {
  if (!is.data.frame(df)) {
    stop("derive_alias_columns: input must be a data frame")
  }
  required_cols <- c(
    "time__date", "time__local_time_of_day",
    "person1__reporter_organization", "ac1__flight_phase"
  )
  missing <- setdiff(required_cols, names(df))
  if (length(missing) > 0) {
    stop(
      "derive_alias_columns: missing required columns: ",
      paste(missing, collapse = ", ")
    )
  }

  df |>
    dplyr::mutate(
      month = format(.data$time__date, "%Y-%m"),
      time_block = .data$time__local_time_of_day,
      reporter_org = .data$person1__reporter_organization,
      phase_raw = .data$ac1__flight_phase
    )
}

# -----------------------------------------------------------------------------
# Miss Distance Derivation
# -----------------------------------------------------------------------------

#' Derive miss distance columns from event text
#'
#' Parses events__miss_distance to extract horizontal and vertical distances.
#'
#' @param df Data frame with events__miss_distance column
#' @return Data frame with miss_horizontal_ft and miss_vertical_ft added
derive_miss_distance <- function(df) {
  if (!is.data.frame(df)) {
    stop("derive_miss_distance: input must be a data frame")
  }
  if (!"events__miss_distance" %in% names(df)) {
    stop("derive_miss_distance: missing required column: events__miss_distance")
  }

  df |>
    dplyr::mutate(
      miss_horizontal_ft = parse_miss_horizontal(.data$events__miss_distance),
      miss_vertical_ft = parse_miss_vertical(.data$events__miss_distance)
    )
}

# -----------------------------------------------------------------------------
# Full Construction Pipeline
# -----------------------------------------------------------------------------

#' Derive all analytical columns from cleaned ASRS data
#'
#' Applies all construct transformations in sequence:
#' 1. Alias columns (month, time_block, reporter_org, phase_raw)
#' 2. Phase mapping (phase_simple)
#' 3. Airspace extraction (airspace_class)
#' 4. Severity flags (flag_nmac, flag_evasive, flag_atc)
#' 5. Miss distances (miss_horizontal_ft, miss_vertical_ft)
#'
#' @param df Data frame of cleaned ASRS data
#' @return Data frame with all 11 derived columns added
derive_all_constructs <- function(df) {
  if (!is.data.frame(df)) {
    stop("derive_all_constructs: input must be a data frame")
  }

  df |>
    derive_alias_columns() |>
    dplyr::mutate(
      phase_simple = map_phase_simple(.data$phase_raw),
      airspace_class = extract_airspace_class(.data$ac1__airspace)
    ) |>
    derive_severity_flags() |>
    derive_miss_distance()
}
