# Append NMAC context section to descriptive findings draft
# Reads table4 and inserts new section with APA-safe sentences

library(readr)
library(dplyr)
library(stringr)
library(glue)
library(scales)

dir.create("output/notes", showWarnings = FALSE, recursive = TRUE)

table4 <- read_csv("output/tables/table4_nmac_by_context.csv", show_col_types = FALSE)
draft_path <- "output/notes/descriptive_findings_draft.md"
draft_lines <- readLines(draft_path)

n_total <- table4$n_total[1]
caution <- paste0(

  "These patterns describe this sample of reports and should not be ",
  "interpreted as population rates or causal effects."
)

# =============================================================================
# Helper: format a single context level as APA sentence
# =============================================================================

format_nmac_sentence <- function(row, context_label) {
  p_pct <- round(row$p_hat * 100, 1)
  ci_low_pct <- round(row$ci_low * 100, 1)
  ci_high_pct <- round(row$ci_high * 100, 1)

  glue(
    "Among reports with {context_label} = {row$context_level}, NMAC was ",
    "present in {row$x_nmac} of {row$n_group} reports ",
    "({p_pct}%, Wilson 95% CI [{ci_low_pct}%, {ci_high_pct}%])."
  )
}

# =============================================================================
# Build detector subsection
# =============================================================================

detector_data <- table4 |>
  filter(context_var == "events__detector", plot_included) |>
  arrange(desc(p_hat))

detector_sentences <- character()
for (i in seq_len(nrow(detector_data))) {
  detector_sentences <- c(
    detector_sentences,
    format_nmac_sentence(detector_data[i, ], "detector")
  )
}

detector_section <- c(
  "### NMAC by detector",
  "",
  paste(detector_sentences, collapse = " "),
  "",
  caution,
  ""
)

# =============================================================================
# Build phase subsection
# =============================================================================

phase_order <- c("Arrival", "Enroute", "Departure", "Surface", "Unknown")
phase_data <- table4 |>
  filter(context_var == "phase_simple", plot_included) |>
  mutate(context_level = factor(context_level, levels = phase_order)) |>
  arrange(context_level)

phase_sentences <- character()
for (i in seq_len(nrow(phase_data))) {
  phase_sentences <- c(
    phase_sentences,
    format_nmac_sentence(phase_data[i, ], "flight phase")
  )
}

phase_section <- c(
  "### NMAC by flight phase",
  "",
  paste(phase_sentences, collapse = " "),
  "",
  caution,
  ""
)

# =============================================================================
# Build time block subsection
# =============================================================================

time_order <- c("0001-0600", "0601-1200", "1201-1800", "1801-2400", "Unknown")
time_data <- table4 |>
  filter(context_var == "time_block", plot_included) |>
  mutate(context_level = factor(context_level, levels = time_order)) |>
  arrange(context_level)

time_sentences <- character()
for (i in seq_len(nrow(time_data))) {
  time_sentences <- c(
    time_sentences,
    format_nmac_sentence(time_data[i, ], "time block")
  )
}

time_section <- c(
  "### NMAC by time of day",
  "",
  paste(time_sentences, collapse = " "),
  "",
  caution,
  ""
)

# =============================================================================
# Build "So what" summary
# =============================================================================

top_detector <- detector_data |> slice_head(n = 1)
low_detector <- detector_data |> slice_tail(n = 1)

so_what <- c(
  "### Summary observations",
  "",
  glue(
    "- **Detector separation**: {top_detector$context_level} showed the ",
    "highest NMAC prevalence ({round(top_detector$p_hat * 100, 0)}%), while ",
    "{low_detector$context_level} showed the lowest ",
    "({round(low_detector$p_hat * 100, 0)}%). This difference likely reflects ",
    "reporting patterns rather than causal relationships."
  ),
  "",
  glue(
    "- **Phase patterns**: Arrival and enroute phases showed higher NMAC ",
    "prevalence than departure, though confidence intervals overlap ",
    "substantially, limiting inferential conclusions."
  ),
  "",
  glue(
    "- **Time of day**: Time block comparisons are exploratory; wide ",
    "confidence intervals preclude strong conclusions about temporal patterns."
  ),
  "",
  glue(
    "- **Data notes**: 'Unknown' values reflect missing or not reported data. ",
    "Groups with fewer than 5 reports were excluded from figures (Table 4 ",
    "retains all groups with plot_included = FALSE for transparency)."
  ),
  ""
)

# =============================================================================
# Assemble new section
# =============================================================================

new_section <- c(
  "",
  "## Context of NMAC tags",
  "",
  "The following subsections describe how NMAC prevalence varies across",
  "operational context variables. See Figures 4-6 and Table 4 for visual",
  "representations of these patterns.",
  "",
  detector_section,
  phase_section,
  time_section,
  so_what
)

# =============================================================================
# Find insertion point and insert
# =============================================================================

insert_after_pattern <- "^## Safety significance markers"
insert_idx <- grep(insert_after_pattern, draft_lines)

if (length(insert_idx) == 0) {
  stop("Could not find '## Safety significance markers' in draft")
}

next_section_pattern <- "^## "
subsequent_sections <- grep(next_section_pattern, draft_lines)
subsequent_sections <- subsequent_sections[subsequent_sections > insert_idx[1]]

if (length(subsequent_sections) == 0) {
  insert_before_idx <- length(draft_lines) + 1
} else {
  insert_before_idx <- subsequent_sections[1]
}

updated_draft <- c(
  draft_lines[1:(insert_before_idx - 1)],
  new_section,
  draft_lines[insert_before_idx:length(draft_lines)]
)

writeLines(updated_draft, draft_path)
cat("Updated:", draft_path, "\n")

# =============================================================================
# Write change log
# =============================================================================

changelog <- c(
  "# Descriptive Findings Change Log",
  "",
  glue("**Last updated**: {Sys.time()}"),
  "",
  "---",
  "",
  "## Changes",
  "",
  "### Added: Context of NMAC tags section",
  "",
  glue("- **Date/time**: {Sys.time()}"),
  "- **Section inserted after**: ## Safety significance markers",
  "- **Subsections added**:",
  "    - ### NMAC by detector",
  "    - ### NMAC by flight phase",
  "    - ### NMAC by time of day",
  "    - ### Summary observations",
  "",
  "- **Data sources**:",
  "    - Table 4: `output/tables/table4_nmac_by_context.csv`",
  "    - Figures 4-6: `output/figures/fig4_nmac_by_phase_ci.png`, etc.",
  "",
  "- **Implementation notes**:",
  "    - All numeric values programmatically pulled from CSV to avoid drift",
  "    - Only groups with plot_included == TRUE are described in text",
  "    - Wilson 95% CIs reported with one decimal precision",
  "    - Caution sentence appended to each subsection",
  ""
)

writeLines(changelog, "output/notes/descriptive_findings_change_log.md")
cat("Written: output/notes/descriptive_findings_change_log.md\n")

cat("\nDraft update complete.\n")
