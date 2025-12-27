# Build inventory and APA captions for EDA outputs
# Scans existing outputs and creates manifest and caption files

library(readr)
library(dplyr)
library(stringr)
library(glue)
library(fs)
library(lubridate)

dir.create("output/notes", showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# Define assets
# =============================================================================

tables <- tribble(
  ~number, ~id,       ~filename,                          ~title,
  "1",     "table1",  "table1_overview_completeness.csv",
           "Dataset overview and completeness",
  "2",     "table2",  "table2_operational_context.csv",
           "Operational context of encounters",
  "2a",    "table2a", "table2_optional_crosstabs.csv",
           "Optional cross-tabulations (detector by phase; reporter by time)",
  "3",     "table3",  "table3_severity_markers.csv",
           "Safety significance markers with Wilson 95% intervals",
  "4",     "table4",  "table4_nmac_by_context.csv",
           "NMAC prevalence by operational context with Wilson 95% intervals"
)

figures <- tribble(
  ~number, ~id,    ~filename,                        ~title,
  "1",     "fig1", "fig1_detector_by_phase.png",
           "Event detection by flight phase",
  "2",     "fig2", "fig2_severity_markers_ci.png",
           "Severity marker prevalence with Wilson 95% intervals",
  "3",     "fig3", "fig3_top_tags.png",
           "Dominant tags in UAS encounter reports",
  "4",     "fig4", "fig4_nmac_by_phase_ci.png",
           "NMAC prevalence by flight phase with Wilson 95% intervals",
  "5",     "fig5", "fig5_nmac_by_detector_ci.png",
           "NMAC prevalence by detector with Wilson 95% intervals",
  "6",     "fig6", "fig6_nmac_by_timeblock_ci.png",
           "NMAC prevalence by time of day with Wilson 95% intervals"
)

# =============================================================================
# Build assets manifest
# =============================================================================

get_file_info <- function(path) {
  if (file.exists(path)) {
    info <- fs::file_info(path)
    list(
      exists = TRUE,
      file_size_kb = round(info$size / 1024, 1),
      last_modified = format(info$modification_time, "%Y-%m-%d %H:%M:%S")
    )
  } else {
    list(exists = FALSE, file_size_kb = NA_real_, last_modified = NA_character_)
  }
}

table_manifest <- tables |>
  mutate(
    type = "Table",
    path = paste0("output/tables/", filename)
  ) |>
 rowwise() |>
  mutate(
    info = list(get_file_info(path)),
    exists = info$exists,
    file_size_kb = info$file_size_kb,
    last_modified = info$last_modified
  ) |>
  ungroup() |>
  select(type, number, id, filename, path, exists, file_size_kb, last_modified)

figure_manifest <- figures |>
  mutate(
    type = "Figure",
    path = paste0("output/figures/", filename)
  ) |>
  rowwise() |>
  mutate(
    info = list(get_file_info(path)),
    exists = info$exists,
    file_size_kb = info$file_size_kb,
    last_modified = info$last_modified
  ) |>
  ungroup() |>
  select(type, number, id, filename, path, exists, file_size_kb, last_modified)

manifest <- bind_rows(table_manifest, figure_manifest)

write_csv(manifest, "output/notes/assets_manifest.csv")
cat("Written: output/notes/assets_manifest.csv\n")

# =============================================================================
# Define captions and denominator notes
# =============================================================================

table_captions <- list(
  table1 = list(
    caption = paste0(
      "Summarizes dataset dimensions, date range, and field-level ",
      "completeness across 125 coded variables."
    ),
    denom = paste0(
      "N = 50 reports. Denominators vary by field; n available is reported ",
      "per variable."
    )
  ),
  table2 = list(
    caption = paste0(
      "Frequency distributions for operational context variables including ",
      "time of day, flight phase, airspace class, and light conditions."
    ),
    denom = paste0(
      "N = 50 reports. n available varies by field due to missing data; ",
      "percentages computed against both N total and n available."
    )
  ),
  table2a = list(
    caption = paste0(
      "Cross-tabulations of detector by flight phase and reporter ",
      "organization by time block."
    ),
    denom = paste0(
      "N = 50 reports. Row and column percentages reported; n available ",
      "varies by variable pair."
    )
  ),
  table3 = list(
    caption = paste0(
      "Prevalence of NMAC tags, evasive action, and ATC assistance markers ",
      "with Wilson 95% confidence intervals."
    ),
    denom = "N = 50 reports with complete data for all markers."
  ),
  table4 = list(
    caption = paste0(
      "NMAC tag prevalence stratified by detector, flight phase, and time ",
      "of day with Wilson 95% confidence intervals."
    ),
    denom = paste0(
      "N = 50 reports. Groups with n < 5 flagged (plot_included = FALSE) ",
      "but retained in table for transparency."
    )
  )
)

figure_captions <- list(
  fig1 = list(
    caption = "Who detects UAS encounters, and during which flight phases?",
    denom = paste0(
      "N = 50 reports. Detector available for n = 47 reports; phase ",
      "available for n = 47 reports. Unknown indicates missing/not reported."
    )
  ),
  fig2 = list(
    caption = paste0(
      "How frequently do NMAC, evasive action, and ATC assistance markers ",
      "appear in reports?"
    ),
    denom = "N = 50 reports. Wilson 95% confidence intervals shown."
  ),
  fig3 = list(
    caption = paste0(
      "What anomaly types and contributing factors are most frequently ",
      "tagged?"
    ),
    denom = paste0(
      "N = 50 reports. Counts are report-level (each tag counted once per ",
      "report regardless of repetition)."
    )
  ),
  fig4 = list(
    caption = "How does NMAC prevalence vary by flight phase?",
    denom = paste0(
      "N = 50 reports. Groups with n >= 5 included in plot. Wilson 95% ",
      "confidence intervals shown."
    )
  ),
  fig5 = list(
    caption = "How does NMAC prevalence vary by detection source?",
    denom = paste0(
      "N = 50 reports. Groups with n >= 5 included in plot. Wilson 95% ",
      "confidence intervals shown."
    )
  ),
  fig6 = list(
    caption = "How does NMAC prevalence vary by time of day?",
    denom = paste0(
      "N = 50 reports. Groups with n >= 5 included in plot. Wilson 95% ",
      "confidence intervals shown."
    )
  )
)

# =============================================================================
# Build APA inventory markdown
# =============================================================================

inventory_lines <- c(
  "# APA Inventory: Tables and Figures",
  "",
  glue("*Generated: {Sys.Date()}*"),
  "",
 "This document provides standardized titles, captions, and denominator",
  "notes for all tables and figures produced by the exploratory data analysis.",
  "",
  "---",
  "",
  "## Tables",
  ""
)

for (i in seq_len(nrow(tables))) {
  row <- tables[i, ]
  cap_info <- table_captions[[row$id]]
  path <- paste0("output/tables/", row$filename)

  inventory_lines <- c(
    inventory_lines,
    glue("### Table {row$number}. {row$title}"),
    "",
    glue("**Caption**: {cap_info$caption}"),
    "",
    glue("**Denominator note**: {cap_info$denom}"),
    "",
    glue("**Source file**: `{path}`"),
    "",
    "---",
    ""
  )
}

inventory_lines <- c(
  inventory_lines,
  "## Figures",
  ""
)

for (i in seq_len(nrow(figures))) {
  row <- figures[i, ]
  cap_info <- figure_captions[[row$id]]
  path <- paste0("output/figures/", row$filename)

  inventory_lines <- c(
    inventory_lines,
    glue("### Figure {row$number}. {row$title}"),
    "",
    glue("**Caption**: {cap_info$caption}"),
    "",
    glue("**Denominator note**: {cap_info$denom}"),
    "",
    glue("**File**: `{path}`"),
    "",
    "---",
    ""
  )
}

inventory_lines <- c(
  inventory_lines,
  "## Notes",
  "",
  "- All confidence intervals use the Wilson method.",
  "- Unknown categories indicate missing or not reported data.",
  "- Groups with n < 5 were excluded from figures but retained in tables.",
  "- Counts are report-level unless otherwise noted.",
  ""
)

writeLines(inventory_lines, "output/notes/apa_inventory.md")
cat("Written: output/notes/apa_inventory.md\n")

n_tables <- sum(table_manifest$exists)
n_figures <- sum(figure_manifest$exists)
cat(glue("\nInventory complete: {n_tables} tables, {n_figures} figures.\n"))
