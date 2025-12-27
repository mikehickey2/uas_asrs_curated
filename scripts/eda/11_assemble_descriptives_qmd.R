# Assemble descriptive analysis QMD from outputs
# Combines narrative, tables, and figures with APA captions

library(readr)
library(dplyr)
library(stringr)
library(glue)
library(fs)

source("R/paths.R")

qmd_path <- "scripts/eda/01_descriptive_analysis.qmd"

# =============================================================================
# Read inputs
# =============================================================================

narrative <- readLines(file.path(PATHS$output_notes, "descriptive_findings_draft.md"))
inventory <- readLines(file.path(PATHS$output_notes, "apa_inventory.md"))

# =============================================================================
# Parse inventory into lookup
# =============================================================================

parse_inventory_block <- function(lines, pattern) {
  results <- list()
  i <- 1
  while (i <= length(lines)) {
    if (str_detect(lines[i], pattern)) {
      title_line <- str_trim(lines[i])
      title_line <- str_remove(title_line, "^###\\s*")

      regex_pattern <- "^(Table|Figure)\\s+([0-9a-z]+)\\."
      num <- str_extract(title_line, regex_pattern, group = 2)
      type <- str_extract(title_line, "^(Table|Figure)") |> str_to_lower()
      id <- paste0(type, num)

      caption <- ""
      denom <- ""
      file_path <- ""

      j <- i + 1
      while (j <= length(lines) && !str_detect(lines[j], "^###|^---")) {
        if (str_detect(lines[j], "^\\*\\*Caption\\*\\*:")) {
          caption <- str_remove(lines[j], "^\\*\\*Caption\\*\\*:\\s*")
        }
        if (str_detect(lines[j], "^\\*\\*Denominator note\\*\\*:")) {
          denom <- str_remove(lines[j], "^\\*\\*Denominator note\\*\\*:\\s*")
        }
        if (str_detect(lines[j], "^\\*\\*(Source file|File)\\*\\*:")) {
          file_path <- str_extract(lines[j], "`[^`]+`") |>
            str_remove_all("`")
        }
        j <- j + 1
      }

      results[[id]] <- list(
        title = title_line,
        caption = caption,
        denom = denom,
        path = file_path
      )
      i <- j
    } else {
      i <- i + 1
    }
  }
  results
}

table_info <- parse_inventory_block(inventory, "^### Table")
figure_info <- parse_inventory_block(inventory, "^### Figure")

# =============================================================================
# Helper: wrap long note text for generated R code
# =============================================================================

wrap_note_assignment <- function(note_text, var_name = "tbl_note", indent = 2) {

  prefix <- strrep(" ", indent)
  max_len <- 78 - indent - nchar(var_name) - 6
  if (nchar(note_text) <= max_len) {
    return(glue('{prefix}{var_name} <- "{note_text}"'))
  }
  words <- strsplit(note_text, " ")[[1]]
  lines <- character(0)
  current <- ""
  for (word in words) {
    test <- if (current == "") word else paste(current, word)
    if (nchar(test) > 60) {
      lines <- c(lines, paste0(current, " "))
      current <- word
    } else {
      current <- test
    }
  }
  if (current != "") lines <- c(lines, current)
  first <- glue("{prefix}{var_name} <- paste0(")
  middle <- paste0(prefix, "  \"", lines, "\"", collapse = ",\n")
  last <- glue("{prefix})")
  paste(first, middle, last, sep = "\n")
}

# =============================================================================
# Helper: build table chunk (uses here::here for project-root paths)
# =============================================================================

build_table_chunk <- function(id, csv_path, info) {
  note_lines <- wrap_note_assignment(info$denom)
  c(
    glue("**{info$title}**"),
    "",
    glue("*Caption*: {info$caption}"),
    "",
    glue("*Denominator note*: {info$denom}"),
    "",
    "```{r}",
    glue("#| label: {id}"),
    "#| echo: false",
    "#| message: false",
    "#| warning: false",
    "",
    glue('csv_path <- here::here("{csv_path}")'),
    "tbl <- readr::read_csv(csv_path, show_col_types = FALSE)",
    "",
    'is_docx <- knitr::pandoc_to() == "docx"',
    "",
    "if (is_docx) {",
    note_lines,
    "  as_apa_flextable(tbl, note = tbl_note)",
    "} else {",
    "  knitr::kable(tbl)",
    "}",
    "```",
    ""
  )
}

# =============================================================================
# Helper: build figure block (paths relative to scripts/eda/)
# =============================================================================

build_figure_block <- function(id, png_path, info) {
  alt_text <- str_replace_all(info$title, '"', "'")
  relative_path <- str_replace(png_path, "^output/", "../../output/")
  c(
    glue("**{info$title}**"),
    "",
    glue("*Caption*: {info$caption}"),
    "",
    glue("*Denominator note*: {info$denom}"),
    "",
    glue('![{info$title}]({relative_path}){{fig-alt="{alt_text}"}}'),
    ""
  )
}

# =============================================================================
# Build QMD content
# =============================================================================

timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

qmd_lines <- c(
  "---",
  'title: "ASRS UAS Reports: Descriptive Analysis"',
  "author: \"Michael J. Hickey\"",
  glue("date: \"{Sys.Date()}\""),
  "format:",
  "  html:",
  "    embed-resources: true",
  "    toc: false",
  "  docx:",
  "    toc: false",
  "    reference-doc: ../../assets/apa_reference.docx",
  "execute:",
  "  echo: false",
  "---",
  "",
  "```{r}",
  "#| label: setup",
  "#| include: false",
  'here::i_am("scripts/eda/01_descriptive_analysis.qmd")',
  'source(here::here("R/apa_tables.R"))',
  "```",
  "",
  "# Descriptive Findings",
  "",
  "## Narrative summary",
  "",
  narrative,
  "",
  "---",
  "",
  "## Tables",
  "",
  "The following tables summarize the dataset structure, operational context,",
  "severity markers, and NMAC prevalence patterns.",
  ""
)

table_order <- c("table1", "table2", "table2a", "table3", "table4")
table_paths <- c(
  table1 = file.path(PATHS$output_tables, "table1_overview_completeness.csv"),
  table2 = file.path(PATHS$output_tables, "table2_operational_context.csv"),
  table2a = file.path(PATHS$output_tables, "table2_optional_crosstabs.csv"),
  table3 = file.path(PATHS$output_tables, "table3_severity_markers.csv"),
  table4 = file.path(PATHS$output_tables, "table4_nmac_by_context.csv")
)

for (tid in table_order) {
  if (tid %in% names(table_info)) {
    qmd_lines <- c(
      qmd_lines,
      build_table_chunk(tid, table_paths[[tid]], table_info[[tid]]),
      ""
    )
  }
}

qmd_lines <- c(
  qmd_lines,
  "---",
  "",
  "## Figures",
  "",
  "The following figures visualize detection patterns, severity markers,",
  "dominant tags, and NMAC prevalence across operational context.",
  ""
)

figure_order <- c(
  "figure1", "figure2", "figure3", "figure4", "figure5", "figure6"
)
figure_paths <- c(
  figure1 = file.path(PATHS$output_figures, "fig1_detector_by_phase.png"),
  figure2 = file.path(PATHS$output_figures, "fig2_severity_markers_ci.png"),
  figure3 = file.path(PATHS$output_figures, "fig3_top_tags.png"),
  figure4 = file.path(PATHS$output_figures, "fig4_nmac_by_phase_ci.png"),
  figure5 = file.path(PATHS$output_figures, "fig5_nmac_by_detector_ci.png"),
  figure6 = file.path(PATHS$output_figures, "fig6_nmac_by_timeblock_ci.png")
)

for (fid in figure_order) {
  if (fid %in% names(figure_info)) {
    qmd_lines <- c(
      qmd_lines,
      build_figure_block(fid, figure_paths[[fid]], figure_info[[fid]]),
      ""
    )
  }
}

qmd_lines <- c(
  qmd_lines,
  "---",
  "",
  "## Reproducibility",
  "",
  "This document was generated from CSV and PNG outputs in `output/`.",
  "",
  glue("**Assembly timestamp**: {timestamp}"),
  "",
  "**Source scripts**:",
  "",
  "- `scripts/eda/01_audit.R` through `10_build_inventory_captions.R`",
  "- `scripts/eda/11_assemble_descriptives_qmd.R`",
  "",
  "All numeric values in tables are programmatically generated from the",
  "underlying data to ensure consistency and prevent transcription errors.",
  ""
)

# =============================================================================
# Write QMD
# =============================================================================

writeLines(qmd_lines, qmd_path)
cat("Written:", qmd_path, "\n")

n_tables <- length(intersect(table_order, names(table_info)))
n_figures <- length(intersect(figure_order, names(figure_info)))
cat(glue("Assembled: {n_tables} tables, {n_figures} figures\n"))
