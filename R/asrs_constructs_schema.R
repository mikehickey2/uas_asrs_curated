# Schema definitions and validation for derived analytical columns
#
# Purpose: Documents and validates the 11 derived columns produced by
# scripts/eda/02_constructs.R. This file is the single source of truth for
# the constructed dataset schema, analogous to R/asrs_schema.R for raw imports.
#
# Usage in pipeline:
#   - Step 2 (02_constructs.R) produces output/asrs_constructed.rds
#   - Steps 3-7 read from RDS and depend on these columns
#   - validate_constructed_schema() can be called after loading RDS to
#     assert expected structure before downstream analysis
#
# See also:
#   - R/asrs_schema.R for raw import schema
#   - doc/adr/ADR-004-structure-governance.md for file organization
#   - .temp/rds_governance_analysis.md for governance context

# -----------------------------------------------------------------------------
# Schema Definition
# -----------------------------------------------------------------------------

#' Schema for derived analytical columns
#'
#' Tibble defining the 11 columns added by scripts/eda/02_constructs.R.
#' Each row documents: name, expected R type, definition, source columns,
#' and optional notes.
asrs_constructs_schema <- tibble::tibble(
  name = c(
    "month", "time_block", "reporter_org", "phase_raw", "phase_simple",
    "airspace_class", "flag_nmac", "flag_evasive", "flag_atc",
    "miss_horizontal_ft", "miss_vertical_ft"
  ),
  type = c(
    "character", "character", "character", "character", "character",
    "character", "logical", "logical", "logical", "numeric", "numeric"
  ),
  definition = c(
    "Year-month string (YYYY-MM format)",
    "Time of day block (direct alias)",
    "Reporter organization (direct alias)",
    "Raw flight phase string (direct alias)",
    "Simplified flight phase category",
    "Airspace class extracted from text",
    "TRUE if NMAC mentioned in anomaly",
    "TRUE if evasive action taken",
    "TRUE if ATC assistance/clarification",
    "Horizontal miss distance in feet",
    "Vertical miss distance in feet"
  ),
  source_columns = c(
    "time__date",
    "time__local_time_of_day",
    "person1__reporter_organization",
    "ac1__flight_phase",
    "ac1__flight_phase",
    "ac1__airspace",
    "events__anomaly",
    "events__result",
    "events__result",
    "events__miss_distance",
    "events__miss_distance"
  ),
  notes = c(
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_,
    "5 levels: Arrival, Departure, Surface, Enroute, Unknown",
    "Values A-G or Unknown; regex: Class\\s+([A-G])",
    "regex: \\bNMAC\\b (case-insensitive)",
    "regex: Evasive Action",
    "regex: ATC Assistance|Clarification",
    "Parsed from 'Horizontal NNN' pattern",
    "Parsed from 'Vertical NNN' pattern"
  )
)

#' Expected column names for constructed dataset
asrs_constructs_cols <- asrs_constructs_schema$name

#' Valid levels for phase_simple categorical column
asrs_phase_simple_levels <- c("Arrival", "Departure", "Surface", "Enroute", "Unknown")

#' Valid levels for airspace_class categorical column
#' Includes Unknown for cases where class cannot be extracted
asrs_airspace_class_levels <- c("A", "B", "C", "D", "E", "G", "Unknown")

# -----------------------------------------------------------------------------
# Validation Function
# -----------------------------------------------------------------------------

#' Validate constructed dataset schema
#'
#' Asserts that a data frame contains all 11 derived columns with correct types.
#' For categorical columns with defined levels (phase_simple, airspace_class),
#' validates that all values are in the allowed set.
#'
#' @param df A data frame, typically loaded from output/asrs_constructed.rds
#' @return invisible(TRUE) if all checks pass
#' @examples
#' \dontrun{
#' asrs <- readRDS("output/asrs_constructed.rds")
#' validate_constructed_schema(asrs)
#' }
validate_constructed_schema <- function(df) {
  if (!is.data.frame(df)) {
    stop("Input must be a data frame")
  }

  # Check all required columns exist
  missing_cols <- setdiff(asrs_constructs_cols, names(df))
  if (length(missing_cols) > 0) {
    stop(
      "Missing required columns: ",
      paste(missing_cols, collapse = ", ")
    )
  }

  # Type checks for each column
  # Character columns
  char_cols <- c(
    "month", "time_block", "reporter_org", "phase_raw",
    "phase_simple", "airspace_class"
  )
  for (col in char_cols) {
    if (!is.character(df[[col]])) {
      stop(
        "Column '", col, "' must be character, got ",
        class(df[[col]])[1]
      )
    }
  }

  # Logical columns
  logical_cols <- c("flag_nmac", "flag_evasive", "flag_atc")
  for (col in logical_cols) {
    if (!is.logical(df[[col]])) {
      stop(
        "Column '", col, "' must be logical, got ",
        class(df[[col]])[1]
      )
    }
  }

  # Numeric columns
  numeric_cols <- c("miss_horizontal_ft", "miss_vertical_ft")
  for (col in numeric_cols) {
    if (!is.numeric(df[[col]])) {
      stop(
        "Column '", col, "' must be numeric, got ",
        class(df[[col]])[1]
      )
    }
  }

  # Categorical value checks
  # phase_simple: must be one of the defined levels
  invalid_phase <- setdiff(
    unique(df$phase_simple[!is.na(df$phase_simple)]),
    asrs_phase_simple_levels
  )
  if (length(invalid_phase) > 0) {
    stop(
      "Column 'phase_simple' contains invalid values: ",
      paste(invalid_phase, collapse = ", "),
      ". Allowed: ", paste(asrs_phase_simple_levels, collapse = ", ")
    )
  }

  # airspace_class: must be one of the defined levels
  invalid_airspace <- setdiff(
    unique(df$airspace_class[!is.na(df$airspace_class)]),
    asrs_airspace_class_levels
  )
  if (length(invalid_airspace) > 0) {
    stop(
      "Column 'airspace_class' contains invalid values: ",
      paste(invalid_airspace, collapse = ", "),
      ". Allowed: ", paste(asrs_airspace_class_levels, collapse = ", ")
    )
  }

  invisible(TRUE)
}
