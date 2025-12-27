# Generate descriptive findings narrative draft
# Reads existing outputs and writes a markdown summary

library(readr)
library(dplyr)
library(stringr)
library(glue)
library(scales)

dir.create("output/notes", showWarnings = FALSE, recursive = TRUE)

table1 <- read_csv(
  "output/tables/table1_overview_completeness.csv",
  show_col_types = FALSE
)
table2 <- read_csv(
  "output/tables/table2_operational_context.csv",
  show_col_types = FALSE
)
table2_crosstabs <- read_csv(
  "output/tables/table2_optional_crosstabs.csv",
  show_col_types = FALSE
)
table3 <- read_csv(
  "output/tables/table3_severity_markers.csv",
  show_col_types = FALSE
)
tags_anomaly <- read_csv(
  "output/tables/tags_anomaly.csv",
  show_col_types = FALSE
)
tags_result <- read_csv(
  "output/tables/tags_result.csv",
  show_col_types = FALSE
)
tags_cf <- read_csv(
  "output/tables/tags_contributing_factors.csv",
  show_col_types = FALSE
)
tags_pp <- read_csv(
  "output/tables/tags_primary_problem.csv",
  show_col_types = FALSE
)
cf_pairs <- read_csv(
  "output/tables/contrib_factor_pairs_top20.csv",
  show_col_types = FALSE
)

get_table1_value <- function(item_name) {
  table1 |>
    filter(item == item_name) |>
    pull(value) |>
    first()
}

n_reports <- get_table1_value("N reports")
date_min <- get_table1_value("Date range min")
date_max <- get_table1_value("Date range max")
n_fields <- get_table1_value("Number of fields")

get_top_levels <- function(data, var_name, top_n = 3) {
  data |>
    filter(variable == var_name, level != "Unknown") |>
    slice_head(n = top_n)
}

format_pct <- function(x) {
  paste0(round(x, 1), "%")
}

# =============================================================================
# Build narrative sections
# =============================================================================

md <- c(
  "# Descriptive Findings: ASRS UAS Encounter Reports",
  "",
  glue("*Draft generated: {Sys.Date()}*"),
  "",
  "---",
  "",
  "## Data overview and completeness",
  "",
  glue("This analysis examines {n_reports} UAS encounter reports from the NASA ",
       "Aviation Safety Reporting System (ASRS), spanning {date_min} to ",
       "{date_max}. The dataset contains {n_fields} coded fields per report."),
  "",
  "Key observations about data completeness:",
  ""
)

completeness_bullets <- c(
  glue("- The dataset represents a curated sample of UAS encounters, not a ",
       "random sample of all aviation safety reports."),
  glue("- Core identification fields (report ID, date) are complete for all ",
       "{n_reports} reports."),
  "- Operational context variables (time of day, flight phase, airspace) are ",
  "  available for the majority of reports, though availability varies by field.",
  "- Event coding fields (anomaly tags, contributing factors) are complete, ",
  "  reflecting ASRS analyst review.",
  "- Miss distance information is available for a subset of reports where ",
  "  proximity data was reported and parseable.",
  "- 'Unknown' values in summaries indicate missing or not reported data, not ",
  "  a distinct category."
)

md <- c(md, completeness_bullets, "")

# Section 2: Operational context
md <- c(md, "## Operational context of encounters", "")

time_block_data <- get_top_levels(table2, "time_block", 3)
phase_data <- get_top_levels(table2, "phase_simple", 3)
airspace_data <- get_top_levels(table2, "airspace_class", 3)

if (nrow(time_block_data) > 0) {
  top_time <- time_block_data[1, ]
  md <- c(md, glue(
    "**Time of day**: The most common reporting period was {top_time$level}, ",
    "accounting for {top_time$n} of {top_time$n_available} reports with time ",
    "data available ({format_pct(top_time$pct_of_available)}). ",
    "This aligns with typical daytime flight operations."
  ), "")
}

if (nrow(phase_data) > 0) {
  top_phase <- phase_data[1, ]
  second_phase <- if (nrow(phase_data) > 1) phase_data[2, ] else NULL
  phase_text <- glue(
    "**Flight phase**: {top_phase$level} phase accounted for {top_phase$n} of ",
    "{top_phase$n_available} reports with phase available ",
    "({format_pct(top_phase$pct_of_available)})"
  )
  if (!is.null(second_phase)) {
    phase_text <- glue(
      "{phase_text}, followed by {second_phase$level} ",
      "({second_phase$n} reports, {format_pct(second_phase$pct_of_available)})."
    )
  } else {
    phase_text <- paste0(phase_text, ".")
  }
  md <- c(md, phase_text, "")
}

if (nrow(airspace_data) > 0) {
  top_airspace <- airspace_data[1, ]
  md <- c(md, glue(
    "**Airspace class**: Class {top_airspace$level} airspace was most ",
    "frequently reported, appearing in {top_airspace$n} of ",
    "{top_airspace$n_available} reports with airspace data ",
    "({format_pct(top_airspace$pct_of_available)})."
  ), "")
}

light_data <- get_top_levels(table2, "environment__light", 2)
if (nrow(light_data) > 0) {
  top_light <- light_data[1, ]
  md <- c(md, glue(
    "**Light conditions**: {top_light$level} conditions were present in ",
    "{top_light$n} of {top_light$n_available} reports with lighting data ",
    "({format_pct(top_light$pct_of_available)})."
  ), "")
}

# Section 3: Detection and reporting patterns
md <- c(md, "## Detection and reporting patterns", "")

if (nrow(table2_crosstabs) > 0) {
  md <- c(md,
    "Cross-tabulation of detection and reporting variables reveals patterns ",
    "in how encounters are identified and documented:",
    ""
  )

  reporter_crosstab <- table2_crosstabs |>
    filter(crosstab_name == "reporter_org_by_time_block")

  if (nrow(reporter_crosstab) > 0) {
    top_combo <- reporter_crosstab |>
      filter(row_level != "Unknown", col_level != "Unknown") |>
      arrange(desc(n)) |>
      slice_head(n = 1)

    if (nrow(top_combo) > 0) {
      md <- c(md, glue(
        "- The most common reporter-time combination was {top_combo$row_level} ",
        "during {top_combo$col_level}, with {top_combo$n} reports."
      ))
    }
  }

  detector_crosstab <- table2_crosstabs |>
    filter(crosstab_name == "detector_by_phase_simple")

  if (nrow(detector_crosstab) > 0) {
    top_detect <- detector_crosstab |>
      filter(row_level != "Unknown", col_level != "Unknown") |>
      arrange(desc(n)) |>
      slice_head(n = 1)

    if (nrow(top_detect) > 0) {
      md <- c(md, glue(
        "- {top_detect$row_level} was the most common detection source during ",
        "{top_detect$col_level} phase ({top_detect$n} reports)."
      ))
    }
  }
  md <- c(md, "")
} else {
  md <- c(md,
    "Cross-tabulation data was not available for this analysis.",
    ""
  )
}

# Section 4: Safety significance markers
md <- c(md, "## Safety significance markers", "")

md <- c(md,
  "Three markers of safety significance were examined: near mid-air collision ",
  "(NMAC) tags, evasive action taken, and ATC assistance or clarification ",
  "requested.",
  ""
)

for (i in seq_len(nrow(table3))) {
  row <- table3[i, ]
  ci_low_pct <- round(row$ci_low * 100, 0)
  ci_high_pct <- round(row$ci_high * 100, 0)
  p_hat_pct <- round(row$p_hat * 100, 0)

  md <- c(md, glue(
    "- **{row$marker}**: Present in {row$x_yes} of {row$n_available} reports ",
    "({p_hat_pct}%, 95% CI [{ci_low_pct}%, {ci_high_pct}%]). ",
    "{row$definition}."
  ))
}

md <- c(md, "",
  "The wide confidence intervals reflect the small sample size and should be ",
  "interpreted with caution. These proportions describe this curated sample ",
  "and should not be generalized to all UAS encounters.",
  ""
)

# Section 5: Dominant themes
md <- c(md, "## Dominant event and contributing-factor themes", "")

md <- c(md, "### Top anomaly tags", "")

top3_anomaly <- tags_anomaly |> slice_head(n = 3)
for (i in seq_len(nrow(top3_anomaly))) {
  row <- top3_anomaly[i, ]
  md <- c(md, glue(
    "{i}. **{row$tag}**: {row$n_reports_with_tag} reports ",
    "({row$pct_of_all_reports}%)"
  ))
}
md <- c(md, "")

md <- c(md, "### Top contributing factors", "")

top3_cf <- tags_cf |> slice_head(n = 3)
for (i in seq_len(nrow(top3_cf))) {
  row <- top3_cf[i, ]
  md <- c(md, glue(
    "{i}. **{row$tag}**: {row$n_reports_with_tag} reports ",
    "({row$pct_of_all_reports}%)"
  ))
}
md <- c(md, "")

md <- c(md, "### Co-occurring contributing factor themes", "")

md <- c(md,
  "The following factor pairs frequently appeared together within the same ",
  "reports, suggesting thematic associations rather than causal relationships:",
  ""
)

top3_pairs <- cf_pairs |> slice_head(n = 3)
for (i in seq_len(nrow(top3_pairs))) {
  row <- top3_pairs[i, ]
  md <- c(md, glue(
    "- **{row$tag1}** and **{row$tag2}**: co-occurred in {row$n_reports} ",
    "reports ({row$pct_of_all_reports}%)"
  ))
}
md <- c(md, "")

# Section 6: Limitations
md <- c(md, "## What these descriptives do and do not support", "")

md <- c(md,
  "These findings describe patterns within a curated sample of ASRS UAS ",
  "encounter reports. Several limitations apply:",
  "",
  "- **Report-coded data**: All tags and classifications reflect ASRS analyst ",
  "  coding of voluntary reports, not objective measurements or population ",
  "  incidence rates.",
  "",
  "- **Short time window**: The data span approximately five months. No claims ",
  "  about temporal trends or seasonal patterns are supported.",
  "",
  "- **Curated sample**: These reports were selected by ASRS staff for UAS ",
  "  research purposes. The sample may not represent all UAS encounters or ",
  "  all ASRS reports.",
  "",
  "- **Miss distance sparsity**: Proximity measurements were available for ",
  "  only a subset of reports. Findings about miss distance apply only to ",
  "  available cases.",
  "",
  "- **'Unknown' = missing**: Categories labeled 'Unknown' indicate data that ",
  "  was not reported or could not be coded, not a distinct response category.",
  "",
  "- **No causal inference**: Associations between variables do not imply ",
  "  causation. Contributing factors are coded themes, not verified mechanisms.",
  "",
  "- **Small sample size**: Confidence intervals are wide, and percentage ",
  "  differences may not be statistically meaningful.",
  "",
  "- **Voluntary reporting**: ASRS relies on voluntary submissions. Reporting ",
  "  patterns may reflect reporter characteristics rather than event frequency.",
  ""
)

md <- c(md, "---", "",
  "*This draft was auto-generated from descriptive analysis outputs. ",
  "Review and edit before publication.*"
)

writeLines(md, "output/notes/descriptive_findings_draft.md")
cat("Written: output/notes/descriptive_findings_draft.md\n")
