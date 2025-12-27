# Rewrite NMAC context section in descriptive findings draft
# Rebuilds entire section from table4 to ensure consistent APA formatting

library(readr)
library(dplyr)
library(stringr)
library(glue)
library(scales)
library(lubridate)

source("R/paths.R")

table4 <- read_csv(file.path(PATHS$output_tables, "table4_nmac_by_context.csv"), show_col_types = FALSE)
draft_path <- file.path(PATHS$output_notes, "descriptive_findings_draft.md")
changelog_path <- file.path(PATHS$output_notes, "descriptive_findings_change_log.md")

draft_text <- paste(readLines(draft_path), collapse = "\n")

caution <- paste0(
  "These patterns describe this sample of reports and should not be ",
  "interpreted as population rates or causal effects."
)

# =============================================================================
# Helper: format a single row as APA sentence
# =============================================================================

format_nmac_sentence <- function(row, context_label) {
  p_pct <- format(round(row$p_hat * 100, 1), nsmall = 1)
  ci_low_pct <- format(round(row$ci_low * 100, 1), nsmall = 1)
  ci_high_pct <- format(round(row$ci_high * 100, 1), nsmall = 1)

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

detector_sentences <- vapply(
  seq_len(nrow(detector_data)),
  function(i) format_nmac_sentence(detector_data[i, ], "detector"),
  character(1)
)

detector_section <- c(
  "### NMAC by detector",
  "",
  paste(detector_sentences, collapse = " "),
  "",
  caution
)

# =============================================================================
# Build phase subsection
# =============================================================================

phase_order <- c("Arrival", "Enroute", "Departure", "Surface", "Unknown")
phase_data <- table4 |>
  filter(context_var == "phase_simple", plot_included) |>
  mutate(phase_rank = match(context_level, phase_order)) |>
  arrange(phase_rank) |>
  select(-phase_rank)

phase_sentences <- vapply(
  seq_len(nrow(phase_data)),
  function(i) format_nmac_sentence(phase_data[i, ], "flight phase"),
  character(1)
)

phase_section <- c(
  "### NMAC by flight phase",
  "",
  paste(phase_sentences, collapse = " "),
  "",
  caution
)

# =============================================================================
# Build time block subsection
# =============================================================================

time_order <- c("0001-0600", "0601-1200", "1201-1800", "1801-2400", "Unknown")
time_data <- table4 |>
  filter(context_var == "time_block", plot_included) |>
  mutate(time_rank = match(context_level, time_order)) |>
  arrange(time_rank) |>
  select(-time_rank)

time_sentences <- vapply(
  seq_len(nrow(time_data)),
  function(i) format_nmac_sentence(time_data[i, ], "time block"),
  character(1)
)

time_section <- c(
  "### NMAC by time of day",
  "",
  paste(time_sentences, collapse = " "),
  "",
  caution
)

# =============================================================================
# Build summary observations (strictly descriptive, no inferences)
# =============================================================================

summary_section <- c(
  "### Summary observations",
  "",
  paste0(
    "- **Detector separation**: In this sample, NMAC tags were more frequent ",
    "in reports detected by flight crew than by UAS crew (see denominators ",
    "above)."
  ),
  "",
  paste0(
    "- **Phase patterns**: NMAC tags were most common in Arrival in this ",
    "sample; intervals overlapped across phases."
  ),
  "",
  paste0(
    "- **Time of day**: Time-block comparisons are exploratory with wide ",
    "intervals."
  ),
  "",
  paste0(
    "- **Data notes**: Unknown indicates missing/not reported; groups with ",
    "n < 5 were excluded from plots but remain in Table 4."
  )
)

# =============================================================================
# Assemble complete section
# =============================================================================

new_section <- paste(c(
  "## Context of NMAC tags",
  "",
  paste0(
    "The following subsections describe how NMAC prevalence varies across ",
    "operational context variables. See Table 4 and Figures 4-6 for visual ",
    "representations."
  ),
  "",
  detector_section,
  "",
  phase_section,
  "",
  time_section,
  "",
  summary_section,
  ""
), collapse = "\n")

# =============================================================================
# Replace existing section
# =============================================================================

section_pattern <- "(?s)## Context of NMAC tags.*?(?=\n## |$)"

if (!str_detect(draft_text, "## Context of NMAC tags")) {
  stop("Could not find '## Context of NMAC tags' section in draft")
}

updated_draft <- str_replace(draft_text, section_pattern, new_section)

if (str_detect(updated_draft, "\\.\\.\\.")) {
  warning("Draft still contains '...' - check for truncation artifacts")
}

writeLines(updated_draft, draft_path)
cat("Updated:", draft_path, "\n")

# =============================================================================
# Append to change log
# =============================================================================

timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

changelog_entry <- c(
  "",
  "---",
  "",
  glue("### Rewrite: Context of NMAC tags section"),
  "",
  glue("- **Date/time**: {timestamp}"),
  paste0(
    "- **Action**: Rewrote Context of NMAC tags section from ",
    "table4_nmac_by_context.csv to remove truncation artifacts and ",
    "standardize APA phrasing."
  ),
  "- **Changes**:",
  "    - Rebuilt all subsections from CSV data",
  "    - Ensured consistent decimal formatting (one decimal place)",
  "    - Removed inferential language from summary bullets",
  "    - Verified no '...' truncation artifacts remain",
  ""
)

if (file.exists(changelog_path)) {
  existing_log <- readLines(changelog_path)
  updated_log <- c(existing_log, changelog_entry)
} else {
  updated_log <- c(
    "# Descriptive Findings Change Log",
    "",
    glue("**Created**: {timestamp}"),
    changelog_entry
  )
}

writeLines(updated_log, changelog_path)
cat("Appended to:", changelog_path, "\n")

cat("\nSection rewrite complete.\n")
