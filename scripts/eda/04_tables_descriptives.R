# Descriptive tables for ASRS UAS reports
# Produces APA-ready CSV tables with explicit denominators

library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)
library(forcats)
library(purrr)
library(binom)

dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)
dir.create("output/notes", showWarnings = FALSE, recursive = TRUE)

asrs <- readRDS("output/asrs_constructed.rds")
overview <- read_csv("output/tables/overview.csv", show_col_types = FALSE)
missingness_domain <- read_csv(
  "output/tables/missingness_by_domain.csv",
  show_col_types = FALSE
)
missingness_var <- read_csv(
  "output/tables/missingness_by_variable.csv",
  show_col_types = FALSE
)

n_total <- nrow(asrs)

# =============================================================================
# Table 1: Dataset overview and completeness
# =============================================================================

overview_wide <- overview |>
  pivot_wider(names_from = metric, values_from = value)

section_a <- tribble(
  ~section, ~item,           ~value,                      ~n_total, ~n_available, ~notes,
  "A",      "N reports",     as.character(n_total),       n_total,  n_total,      "",
  "A",      "Date range min", overview_wide$date_min,     n_total,  n_total,      "",
  "A",      "Date range max", overview_wide$date_max,     n_total,  n_total,      "",
  "A",      "Number of fields", overview_wide$n_cols,     n_total,  n_total,      ""
)

section_b <- missingness_domain |>
  filter(!is.na(mean_pct_present)) |>
  mutate(
    section = "B",
    n_vars_keep = n_vars
  ) |>
  pivot_longer(
    cols = c(n_vars, mean_pct_present, median_pct_present,
             min_pct_present, max_pct_present),
    names_to = "metric",
    values_to = "value"
  ) |>
  mutate(
    item = paste0(domain, " - ", metric),
    value = as.character(value),
    n_total = n_total,
    n_available = n_vars_keep,
    notes = ""
  ) |>
  select(section, item, value, n_total, n_available, notes)

key_fields <- c(
  "time__date", "time_block", "phase_raw", "phase_simple",
  "ac1__airspace", "airspace_class",
  "environment__light", "environment__flight_conditions",
  "events__anomaly", "events__result",
  "assessments__contributing_factors_situations",
  "assessments__primary_problem",
  "events__miss_distance", "miss_horizontal_ft", "miss_vertical_ft",
  "events__detector"
)

key_fields <- key_fields[key_fields %in% names(asrs)]

compute_availability <- function(data, col) {
  vals <- data[[col]]
  if (is.character(vals)) {
    n_avail <- sum(!is.na(vals) & vals != "")
  } else if (is.logical(vals)) {
    n_avail <- sum(!is.na(vals))
  } else {
    n_avail <- sum(!is.na(vals))
  }
  n_avail
}

section_c <- tibble(
  section = "C",
  item = key_fields,
  n_available = sapply(key_fields, function(f) compute_availability(asrs, f)),
  n_total = n_total,
  value = paste0(n_available, "/", n_total),
  pct_available = round(n_available / n_total * 100, 1),
  notes = ""
) |>
  mutate(value = paste0(n_available, " (", pct_available, "%)")) |>
  select(section, item, value, n_total, n_available, notes)

table1 <- bind_rows(section_a, section_b, section_c)
write_csv(table1, "output/tables/table1_overview_completeness.csv")
cat("Written: table1_overview_completeness.csv\n")

# =============================================================================
# Table 2: Operational context
# =============================================================================

context_vars <- c(
  "time_block", "phase_simple", "airspace_class",
  "environment__light", "environment__flight_conditions",
  "events__detector", "reporter_org"
)
context_vars <- context_vars[context_vars %in% names(asrs)]

build_freq_table <- function(data, var_name, n_total) {
  vals <- data[[var_name]]

  if (is.character(vals)) {
    n_available <- sum(!is.na(vals) & vals != "")
    vals_clean <- if_else(is.na(vals) | vals == "", "Unknown", vals)
  } else {
    n_available <- sum(!is.na(vals))
    vals_clean <- if_else(is.na(vals), "Unknown", as.character(vals))
  }

  tibble(level = vals_clean) |>
    count(level, name = "n") |>
    mutate(
      variable = var_name,
      n_total = n_total,
      n_available = n_available,
      pct_of_all = round(n / n_total * 100, 1),
      pct_of_available = round(n / n_available * 100, 1)
    ) |>
    arrange(desc(n)) |>
    select(variable, level, n_total, n_available, n, pct_of_all, pct_of_available)
}

table2 <- map_dfr(context_vars, ~ build_freq_table(asrs, .x, n_total))
write_csv(table2, "output/tables/table2_operational_context.csv")
cat("Written: table2_operational_context.csv\n")

# =============================================================================
# Table 2 optional cross-tabs
# =============================================================================

build_crosstab <- function(data, row_var, col_var, crosstab_name, n_total) {
  if (!row_var %in% names(data) || !col_var %in% names(data)) {
    return(NULL)
  }

  row_vals <- data[[row_var]]
  col_vals <- data[[col_var]]

  if (is.character(row_vals)) {
    n_available_rows <- sum(!is.na(row_vals) & row_vals != "")
    row_clean <- if_else(is.na(row_vals) | row_vals == "", "Unknown", row_vals)
  } else {
    n_available_rows <- sum(!is.na(row_vals))
    row_clean <- if_else(is.na(row_vals), "Unknown", as.character(row_vals))
  }

  if (is.character(col_vals)) {
    n_available_cols <- sum(!is.na(col_vals) & col_vals != "")
    col_clean <- if_else(is.na(col_vals) | col_vals == "", "Unknown", col_vals)
  } else {
    n_available_cols <- sum(!is.na(col_vals))
    col_clean <- if_else(is.na(col_vals), "Unknown", as.character(col_vals))
  }

  ct_data <- tibble(row_level = row_clean, col_level = col_clean) |>
    count(row_level, col_level, name = "n")

  row_totals <- ct_data |>
    group_by(row_level) |>
    summarise(row_total = sum(n), .groups = "drop")

  col_totals <- ct_data |>
    group_by(col_level) |>
    summarise(col_total = sum(n), .groups = "drop")

  ct_data |>
    left_join(row_totals, by = "row_level") |>
    left_join(col_totals, by = "col_level") |>
    mutate(
      crosstab_name = crosstab_name,
      row_var = row_var,
      col_var = col_var,
      n_total = n_total,
      n_available_rows = n_available_rows,
      n_available_cols = n_available_cols,
      row_pct = round(n / row_total * 100, 1),
      col_pct = round(n / col_total * 100, 1)
    ) |>
    select(
      crosstab_name, row_var, row_level, col_var, col_level,
      n_total, n_available_rows, n_available_cols, n, row_pct, col_pct
    )
}

crosstabs <- list()
crosstab_notes <- c()

if ("reporter_org" %in% names(asrs) && "time_block" %in% names(asrs)) {
  ct1 <- build_crosstab(
    asrs, "reporter_org", "time_block",
    "reporter_org_by_time_block", n_total
  )
  if (!is.null(ct1)) crosstabs <- c(crosstabs, list(ct1))
} else {
  crosstab_notes <- c(
    crosstab_notes,
    "reporter_org_by_time_block: Could not produce (missing variables)"
  )
}

if ("events__detector" %in% names(asrs) && "phase_simple" %in% names(asrs)) {
  ct2 <- build_crosstab(
    asrs, "events__detector", "phase_simple",
    "detector_by_phase_simple", n_total
  )
  if (!is.null(ct2)) crosstabs <- c(crosstabs, list(ct2))
} else {
  crosstab_notes <- c(
    crosstab_notes,
    "detector_by_phase_simple: Could not produce (missing variables)"
  )
}

if (length(crosstabs) > 0) {
  table2_crosstabs <- bind_rows(crosstabs)
} else {
  table2_crosstabs <- tibble(
    crosstab_name = character(), row_var = character(), row_level = character(),
    col_var = character(), col_level = character(), n_total = integer(),
    n_available_rows = integer(), n_available_cols = integer(),
    n = integer(), row_pct = numeric(), col_pct = numeric()
  )
}

write_csv(table2_crosstabs, "output/tables/table2_optional_crosstabs.csv")
cat("Written: table2_optional_crosstabs.csv\n")

# =============================================================================
# Table 3: Severity markers with Wilson intervals
# =============================================================================

compute_marker_row <- function(data, marker_col, marker_name, definition, n_total) {
  if (!marker_col %in% names(data)) {
    return(NULL)
  }

  vals <- data[[marker_col]]
  n_available <- sum(!is.na(vals))
  x_yes <- sum(vals == TRUE, na.rm = TRUE)

  if (n_available > 0) {
    ci <- binom.confint(x_yes, n_available, methods = "wilson")
    p_hat <- round(ci$mean, 3)
    ci_low <- round(ci$lower, 3)
    ci_high <- round(ci$upper, 3)
  } else {
    p_hat <- NA_real_
    ci_low <- NA_real_
    ci_high <- NA_real_
  }

  tibble(
    marker = marker_name,
    definition = definition,
    n_total = n_total,
    n_available = n_available,
    x_yes = x_yes,
    p_hat = p_hat,
    ci_low = ci_low,
    ci_high = ci_high
  )
}

table3 <- bind_rows(
  compute_marker_row(
    asrs, "flag_nmac", "NMAC",
    "NMAC tag present in events__anomaly", n_total
  ),
  compute_marker_row(
    asrs, "flag_evasive", "Evasive action",
    "Evasive Action in events__result", n_total
  ),
  compute_marker_row(
    asrs, "flag_atc", "ATC assistance",
    "ATC Assistance or Clarification in events__result", n_total
  )
)

write_csv(table3, "output/tables/table3_severity_markers.csv")
cat("Written: table3_severity_markers.csv\n")

# =============================================================================
# Notes markdown
# =============================================================================

notes_content <- c(
  "# Descriptive Table Notes",
  "",
  paste0("Generated: ", Sys.Date()),
  "",
  "## Denominator Notes",
  "",
  paste0("- **N total**: ", n_total, " UAS encounter reports"),
  "",
  "- **Variable-level availability (n_available)** differs across fields due to",
  "  missingness in the original ASRS data and parsing limitations for derived",
  "  variables (e.g., miss distance extraction depends on string format).",
  "",
  "- **Tag and flag variables** reflect report-coded presence, not population",
  "  incidence rates. These are descriptive frequencies from a curated sample,",
  "  not inferential estimates.",
  "",
  "- **Miss distance findings** are based on the subset of reports where",
  "  horizontal and/or vertical distance values could be parsed from the",
  "  events__miss_distance field. Findings may not generalize to reports",
  "  without parseable distance information.",
  "",
  "- **Confidence intervals** (Wilson method) reflect uncertainty from small",
  "  sample size and should be interpreted cautiously. They do not account for",
  "  potential selection bias in the curated sample.",
  ""
)

if (length(crosstab_notes) > 0) {
  notes_content <- c(
    notes_content,
    "## Cross-tabulation Notes",
    "",
    paste0("- ", crosstab_notes),
    ""
  )
}

writeLines(notes_content, "output/notes/descriptive_table_notes.md")
cat("Written: descriptive_table_notes.md\n")

cat("\nDescriptive tables complete. Outputs:\n")
cat("  - output/tables/table1_overview_completeness.csv\n")
cat("  - output/tables/table2_operational_context.csv\n")
cat("  - output/tables/table2_optional_crosstabs.csv\n")
cat("  - output/tables/table3_severity_markers.csv\n")
cat("  - output/notes/descriptive_table_notes.md\n")
