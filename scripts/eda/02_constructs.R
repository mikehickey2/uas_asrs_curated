# Construct derived dataset for EDA
# Builds analytic variables from cleaned ASRS data

library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)
library(purrr)

dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)

data_path <- "output/asrs_uas_reports_clean.csv"
asrs_data <- read_csv(data_path, show_col_types = FALSE) |>
  mutate(time__date = as.Date(time__date))

asrs_data <- asrs_data |>
  mutate(across(where(is.character), ~ if_else(.x == "", NA_character_, .x)))

phase_mapping <- tribble(
  ~phase_simple, ~keywords, ~precedence_rank,
  "Arrival", "Final Approach; Initial Approach; Descent; Landing", 1,
  "Departure", "Takeoff / Launch; Climb", 2,
  "Surface", "Taxi; Ground", 3,
  "Enroute", "Cruise", 4,
  "Unknown", "(default if no match)", 5
)

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

extract_airspace_class <- function(airspace) {
  if (is.na(airspace)) {
    return("Unknown")
  }
  match <- str_match(airspace, "Class\\s+([A-G])")
  if (is.na(match[1, 1])) {
    return("Unknown")
  }
  match[1, 2]
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

constructed <- asrs_data |>
  mutate(
    month = format(time__date, "%Y-%m"),
    time_block = time__local_time_of_day,
    reporter_org = person1__reporter_organization,
    phase_raw = ac1__flight_phase,
    phase_simple = sapply(phase_raw, map_phase),
    airspace_class = sapply(ac1__airspace, extract_airspace_class),
    flag_nmac = str_detect(
      events__anomaly,
      regex("\\bNMAC\\b", ignore_case = TRUE)
    ) %in% TRUE,
    flag_evasive = str_detect(
      events__result,
      regex("Evasive Action", ignore_case = TRUE)
    ) %in% TRUE,
    flag_atc = str_detect(
      events__result,
      regex("ATC Assistance|Clarification", ignore_case = TRUE)
    ) %in% TRUE,
    miss_horizontal_ft = sapply(events__miss_distance, parse_miss_horizontal),
    miss_vertical_ft = sapply(events__miss_distance, parse_miss_vertical)
  )

write_csv(phase_mapping, "output/tables/phase_mapping_used.csv")

saveRDS(constructed, "output/asrs_constructed.rds")

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
  tibble(field = "--- phase_simple breakdown ---",
         n_total = NA_integer_, n_available = NA_integer_,
         pct_available = NA_real_),
  phase_freq,
  tibble(field = "--- airspace_class breakdown ---",
         n_total = NA_integer_, n_available = NA_integer_,
         pct_available = NA_real_),
  airspace_freq,
  tibble(field = "--- time_block breakdown ---",
         n_total = NA_integer_, n_available = NA_integer_,
         pct_available = NA_real_),
  time_block_freq
)

write_csv(qc_summary, "output/tables/constructs_qc_summary.csv")

cat("Constructs complete. Outputs written to:\n")
cat("  - output/asrs_constructed.rds\n")
cat("  - output/tables/phase_mapping_used.csv\n")
cat("  - output/tables/constructs_qc_summary.csv\n")
