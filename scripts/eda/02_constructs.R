# Construct derived dataset for EDA
# Builds analytic variables from cleaned ASRS data
#
# This script orchestrates the construction of derived columns using
# helper functions from R/construct_helpers.R and validates the output
# against the schema in R/asrs_constructs_schema.R.

library(readr)
library(dplyr)
library(tibble)

source("R/paths.R")
source("R/construct_helpers.R")
source("R/asrs_constructs_schema.R")

dir.create(PATHS$output_tables, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------------
# Load and prepare data
# -----------------------------------------------------------------------------

asrs_data <- read_csv(PATHS$curated_csv, show_col_types = FALSE) |>
  mutate(time__date = as.Date(time__date))

asrs_data <- asrs_data |>
  mutate(across(where(is.character), ~ if_else(.x == "", NA_character_, .x)))

# -----------------------------------------------------------------------------
# Derive all analytical columns
# -----------------------------------------------------------------------------

constructed <- derive_all_constructs(asrs_data)

# -----------------------------------------------------------------------------
# Validate constructed schema before writing
# -----------------------------------------------------------------------------

validate_constructed_schema(constructed)

# -----------------------------------------------------------------------------
# Write outputs
# -----------------------------------------------------------------------------

write_csv(phase_mapping_table, file.path(PATHS$output_tables, "phase_mapping_used.csv"))
saveRDS(constructed, PATHS$constructed_rds)

# -----------------------------------------------------------------------------
# QC Summary
# -----------------------------------------------------------------------------

n_total <- nrow(constructed)
calc_pct <- function(n) round(n / n_total * 100, 1)

n_month <- sum(!is.na(constructed$month))
n_time <- sum(!is.na(constructed$time_block))
n_org <- sum(!is.na(constructed$reporter_org))
n_phase_raw <- sum(!is.na(constructed$phase_raw))
n_phase <- sum(constructed$phase_simple != "Unknown")
n_airspace <- sum(constructed$airspace_class != "Unknown")
n_nmac <- sum(constructed$flag_nmac)
n_evasive <- sum(constructed$flag_evasive)
n_atc <- sum(constructed$flag_atc)
n_horiz <- sum(!is.na(constructed$miss_horizontal_ft))
n_vert <- sum(!is.na(constructed$miss_vertical_ft))

derived_qc <- tribble(
  ~field, ~n_total, ~n_available, ~pct_available,
  "month", n_total, n_month, calc_pct(n_month),
  "time_block", n_total, n_time, calc_pct(n_time),
  "reporter_org", n_total, n_org, calc_pct(n_org),
  "phase_raw", n_total, n_phase_raw, calc_pct(n_phase_raw),
  "phase_simple", n_total, n_phase, calc_pct(n_phase),
  "airspace_class", n_total, n_airspace, calc_pct(n_airspace),
  "flag_nmac", n_total, n_nmac, calc_pct(n_nmac),
  "flag_evasive", n_total, n_evasive, calc_pct(n_evasive),
  "flag_atc", n_total, n_atc, calc_pct(n_atc),
  "miss_horizontal_ft", n_total, n_horiz, calc_pct(n_horiz),
  "miss_vertical_ft", n_total, n_vert, calc_pct(n_vert)
)

phase_freq <- constructed |>
  count(phase_simple, name = "n") |>
  mutate(
    field = "phase_simple",
    n_total = n_total,
    n_available = n,
    pct_available = round(n / n_total * 100, 1)
  ) |>
  transmute(
    field = paste0("  ", phase_simple), n_total, n_available, pct_available
  )

airspace_freq <- constructed |>
  count(airspace_class, name = "n") |>
  mutate(
    field = "airspace_class",
    n_total = n_total,
    n_available = n,
    pct_available = round(n / n_total * 100, 1)
  ) |>
  transmute(
    field = paste0("  ", airspace_class), n_total, n_available, pct_available
  )

time_block_freq <- constructed |>
  count(time_block, name = "n") |>
  mutate(
    field = "time_block",
    n_total = n_total,
    n_available = n,
    pct_available = round(n / n_total * 100, 1)
  ) |>
  transmute(
    field = paste0("  ", if_else(is.na(time_block), "(NA)", time_block)),
    n_total,
    n_available,
    pct_available
  )

qc_summary <- bind_rows(
  derived_qc,
  tibble(
    field = "--- phase_simple breakdown ---",
    n_total = NA_integer_, n_available = NA_integer_, pct_available = NA_real_
  ),
  phase_freq,
  tibble(
    field = "--- airspace_class breakdown ---",
    n_total = NA_integer_, n_available = NA_integer_, pct_available = NA_real_
  ),
  airspace_freq,
  tibble(
    field = "--- time_block breakdown ---",
    n_total = NA_integer_, n_available = NA_integer_, pct_available = NA_real_
  ),
  time_block_freq
)

write_csv(qc_summary, file.path(PATHS$output_tables, "constructs_qc_summary.csv"))

cat("Constructs complete. Outputs written to:\n")
cat("  -", PATHS$constructed_rds, "\n")
cat("  -", file.path(PATHS$output_tables, "phase_mapping_used.csv"), "\n")
cat("  -", file.path(PATHS$output_tables, "constructs_qc_summary.csv"), "\n")
