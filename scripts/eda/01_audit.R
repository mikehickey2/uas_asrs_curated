# Audit script for ASRS UAS reports
# Generates overview, missingness, and domain completeness tables

library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)

source("R/paths.R")

asrs_data <- read_csv(PATHS$curated_csv, show_col_types = FALSE) |>
  mutate(time__date = as.Date(time__date))

n_rows <- nrow(asrs_data)
n_cols <- ncol(asrs_data)
date_min <- min(asrs_data$time__date, na.rm = TRUE)
date_max <- max(asrs_data$time__date, na.rm = TRUE)

overview <- tibble(
  metric = c("n_rows", "n_cols", "date_min", "date_max"),
  value = c(
    as.character(n_rows),
    as.character(n_cols),
    as.character(date_min),
    as.character(date_max)
  )
)

write_csv(overview, file.path(PATHS$output_tables, "overview.csv"))

is_present <- function(x) {
  if (is.character(x)) {
    !is.na(x) & x != ""
  } else {
    !is.na(x)
  }
}

missingness_by_var <- asrs_data |>
  summarise(across(everything(), ~ sum(is_present(.x)))) |>
  pivot_longer(
    everything(),
    names_to = "variable",
    values_to = "n_present"
  ) |>
  mutate(
    n_missing = n_rows - n_present,
    pct_present = round(n_present / n_rows * 100, 1),
    pct_missing = round(n_missing / n_rows * 100, 1)
  ) |>
  arrange(desc(pct_missing))

write_csv(missingness_by_var, file.path(PATHS$output_tables, "missingness_by_variable.csv"))

domain_map <- tribble(
  ~domain,          ~pattern,
  "Time",           "^time__",
  "Place",          "^place__",
  "Environment",    "^environment__",
  "Aircraft 1",     "^ac1__",
  "Aircraft 2",     "^ac2__",
  "Component",      "^component__",
  "Events",         "^events__",
  "Assessments",    "^assessments__",
  "Person",         "^person\\d+__",
  "Report text",    "^report\\d+__"
)

assign_domain <- function(variable) {
  for (i in seq_len(nrow(domain_map))) {
    if (str_detect(variable, domain_map$pattern[i])) {
      return(domain_map$domain[i])
    }
  }
  "Other"
}

missingness_by_domain <- missingness_by_var |>
  mutate(domain = sapply(variable, assign_domain)) |>
  group_by(domain) |>
  summarise(
    n_vars = n(),
    mean_pct_present = round(mean(pct_present), 1),
    median_pct_present = round(median(pct_present), 1),
    min_pct_present = round(min(pct_present), 1),
    max_pct_present = round(max(pct_present), 1),
    .groups = "drop"
  ) |>
  arrange(mean_pct_present)

write_csv(missingness_by_domain, file.path(PATHS$output_tables, "missingness_by_domain.csv"))

audit_notes <- c(
  "# Audit Notes",
  "",
  paste0("Generated: ", Sys.Date()),
  "",
  "## Dataset Overview",
  "",
  paste0("- ", n_rows, " reports spanning ", date_min, " to ", date_max),
  paste0("- ", n_cols, " variables"),
  "",
  "## Usability Summary",
  ""
)

high_complete <- missingness_by_domain |>
  filter(mean_pct_present >= 80)
moderate_complete <- missingness_by_domain |>
  filter(mean_pct_present >= 50, mean_pct_present < 80)
sparse <- missingness_by_domain |>
  filter(mean_pct_present < 50)

if (nrow(high_complete) > 0) {
  audit_notes <- c(
    audit_notes,
    "### Well-populated domains (>=80% mean present)",
    "",
    paste0(
      "- ",
      high_complete$domain,
      " (",
      high_complete$n_vars,
      " vars, ",
      high_complete$mean_pct_present,
      "% mean)"
    ),
    ""
  )
}

if (nrow(moderate_complete) > 0) {
  audit_notes <- c(
    audit_notes,
    "### Moderately populated domains (50-79% mean present)",
    "",
    paste0(
      "- ",
      moderate_complete$domain,
      " (",
      moderate_complete$n_vars,
      " vars, ",
      moderate_complete$mean_pct_present,
      "% mean)"
    ),
    ""
  )
}

if (nrow(sparse) > 0) {
  audit_notes <- c(
    audit_notes,
    "### Sparse domains (<50% mean present)",
    "",
    paste0(
      "- ",
      sparse$domain,
      " (",
      sparse$n_vars,
      " vars, ",
      sparse$mean_pct_present,
      "% mean)"
    ),
    ""
  )
}

audit_notes <- c(
  audit_notes,
  "## Important Notes",
  "",
  "- Denominators vary by field: some fields only apply to certain report",
  "  types (e.g., UAS-specific fields only relevant when UAS is Aircraft 1",
  "  or Aircraft 2)",
  "- Empty strings and NA values both treated as missing",
  "- Person and Report domains use numbered entity patterns (person1, person2,",
  "  report1, report2)"
)

writeLines(audit_notes, file.path(PATHS$output_notes, "audit_notes.md"))

cat("Audit complete. Outputs written to:\n")
cat("  -", file.path(PATHS$output_tables, "overview.csv"), "\n")
cat("  -", file.path(PATHS$output_tables, "missingness_by_variable.csv"), "\n")
cat("  -", file.path(PATHS$output_tables, "missingness_by_domain.csv"), "\n")
cat("  -", file.path(PATHS$output_notes, "audit_notes.md"), "\n")
