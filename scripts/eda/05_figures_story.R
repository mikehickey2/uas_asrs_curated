# Story-driven figures for ASRS UAS reports
# Produces publication-ready PNGs with explicit denominators

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(stringr)
library(forcats)
library(patchwork)

dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("output/notes", showWarnings = FALSE, recursive = TRUE)

asrs <- readRDS("output/asrs_constructed.rds")
severity_markers <- read_csv(
  "output/tables/table3_severity_markers.csv",
  show_col_types = FALSE
)
tags_anomaly <- read_csv(
  "output/tables/tags_anomaly.csv",
  show_col_types = FALSE
)
tags_cf <- read_csv(
  "output/tables/tags_contributing_factors.csv",
  show_col_types = FALSE
)

n_total <- nrow(asrs)

# =============================================================================
# Figure 1: Who detects these events, and during what flight phase?
# =============================================================================

n_detector_available <- sum(
  !is.na(asrs$events__detector) & asrs$events__detector != ""
)
n_phase_available <- sum(asrs$phase_simple != "Unknown")

fig1_data <- asrs |>
  mutate(
    detector = if_else(
      is.na(events__detector) | events__detector == "",
      "Unknown",
      events__detector
    ),
    phase = factor(
      phase_simple,
      levels = c("Surface", "Departure", "Enroute", "Arrival", "Unknown")
    )
  )

detector_order <- fig1_data |>
  count(detector, sort = TRUE) |>
  pull(detector)

fig1_data <- fig1_data |>
  mutate(detector = factor(detector, levels = rev(detector_order)))

fig1_counts <- fig1_data |>
  count(detector, phase, .drop = FALSE) |>
  mutate(n = replace_na(n, 0))

max_count <- max(fig1_counts$n)

fig1 <- ggplot(fig1_counts, aes(x = phase, y = detector, fill = n)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = n), color = "black", size = 3.5) +
  scale_fill_gradient(
    low = "white", high = "steelblue", name = "Count",
    limits = c(0, max_count),
    breaks = seq(0, max_count, by = ceiling(max_count / 4))
  ) +
  labs(
    title = "Event Detection by Flight Phase",
    subtitle = paste0(
      "N = ", n_total, " reports | ",
      "Detector available: ", n_detector_available, " | ",
      "Phase available: ", n_phase_available,
      "\n'Unknown' = missing or not reported"
    ),
    x = "Flight Phase",
    y = "Detector"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank(),
    plot.subtitle = element_text(size = 9, color = "gray40")
  )

ggsave(
  "output/figures/fig1_detector_by_phase.png",
  fig1,
  width = 8, height = 5, dpi = 300
)
cat("Written: fig1_detector_by_phase.png\n")

# =============================================================================
# Figure 2: How often do severity markers appear in reports?
# =============================================================================

fig2_data <- severity_markers |>
  mutate(
    marker = fct_reorder(marker, p_hat),
    p_hat_pct = p_hat * 100,
    ci_low_pct = ci_low * 100,
    ci_high_pct = ci_high * 100
  )

n_available_markers <- fig2_data$n_available[1]

fig2 <- ggplot(fig2_data, aes(x = p_hat_pct, y = marker)) +
  geom_pointrange(
    aes(xmin = ci_low_pct, xmax = ci_high_pct),
    color = "steelblue",
    size = 0.8,
    linewidth = 0.8
  ) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  scale_x_continuous(
    limits = c(0, 70),
    breaks = seq(0, 70, 10),
    labels = function(x) paste0(x, "%")
  ) +
  labs(
    title = "Severity Marker Prevalence in UAS Encounter Reports",
    subtitle = paste0(
      "N = ", n_total, " reports | ",
      "n_available = ", n_available_markers, " | ",
      "Wilson 95% CI"
    ),
    x = "Proportion of Reports (%)",
    y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.subtitle = element_text(size = 9, color = "gray40")
  )

ggsave(
  "output/figures/fig2_severity_markers_ci.png",
  fig2,
  width = 7, height = 4, dpi = 300
)
cat("Written: fig2_severity_markers_ci.png\n")

# =============================================================================
# Figure 3: What tags dominate the event narrative and contributing factors?
# =============================================================================

top_anomaly <- tags_anomaly |>
  slice_head(n = 10) |>
  mutate(
    tag_wrap = str_wrap(tag, width = 35),
    tag_wrap = fct_reorder(tag_wrap, n_reports_with_tag)
  )

top_cf <- tags_cf |>
  slice_head(n = 10) |>
  mutate(
    tag_wrap = str_wrap(tag, width = 35),
    tag_wrap = fct_reorder(tag_wrap, n_reports_with_tag)
  )

n_anomaly_field <- tags_anomaly$n_reports_field_present[1]
n_cf_field <- tags_cf$n_reports_field_present[1]

panel_a <- ggplot(top_anomaly, aes(x = n_reports_with_tag, y = tag_wrap)) +
  geom_col(fill = "steelblue", width = 0.7) +
  geom_text(
    aes(label = paste0(n_reports_with_tag, " (", pct_of_all_reports, "%)")),
    hjust = -0.1,
    size = 2.8
  ) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.25))) +
  labs(
    title = "A. Top Anomaly Tags",
    subtitle = paste0(
      "N = ", n_total, " | Field present: ", n_anomaly_field
    ),
    x = "Number of Reports",
    y = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    plot.subtitle = element_text(size = 8, color = "gray40"),
    axis.text.y = element_text(size = 8, lineheight = 0.9)
  )

panel_b <- ggplot(top_cf, aes(x = n_reports_with_tag, y = tag_wrap)) +
  geom_col(fill = "darkorange", width = 0.7) +
  geom_text(
    aes(label = paste0(n_reports_with_tag, " (", pct_of_all_reports, "%)")),
    hjust = -0.1,
    size = 2.8
  ) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.25))) +
  labs(
    title = "B. Top Contributing Factor Tags",
    subtitle = paste0(
      "N = ", n_total, " | Field present: ", n_cf_field
    ),
    x = "Number of Reports",
    y = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    plot.subtitle = element_text(size = 8, color = "gray40"),
    axis.text.y = element_text(size = 8, lineheight = 0.9)
  )

fig3_subtitle <- paste0(
  "Counts reflect report-level presence of tags ",
  "(a tag appearing multiple times in one report counts once)"
)

fig3 <- panel_a / panel_b +
  plot_annotation(
    title = "Dominant Tags in UAS Encounter Reports",
    subtitle = fig3_subtitle,
    theme = theme(
      plot.title = element_text(size = 12, face = "bold"),
      plot.subtitle = element_text(size = 9, color = "gray40")
    )
  )

ggsave(
  "output/figures/fig3_top_tags.png",
  fig3,
  width = 9, height = 8, dpi = 300
)
cat("Written: fig3_top_tags.png\n")

# =============================================================================
# Notes file
# =============================================================================

notes_content <- c(
  "# Figure Notes",
  "",
  paste0("Generated: ", Sys.Date()),
  "",
  "---",
  "",
  "## Figure 1: Event Detection by Flight Phase",
  "",
  "- **Question**: Who detects UAS encounters, and during which flight phases",
  "  do they occur?",
  "",
  paste0("- **Denominators**: N = ", n_total, " total reports. Detector field ",
         "available for ", n_detector_available, " reports; phase available ",
         "for ", n_phase_available, " reports. 'Unknown' indicates missing or ",
         "not reported values."),
  "",
  "- **Key finding**: The distribution shows which detection sources and flight",
  "  phases are most represented in this curated sample. Counts are small and",
  "  should not be interpreted as population rates.",
  "",
  "---",
  "",
  "## Figure 2: Severity Marker Prevalence",
  "",
  "- **Question**: How frequently do NMAC events, evasive actions, and ATC",
  "  assistance appear in the curated UAS encounter reports?",
  "",
  paste0("- **Denominators**: N = ", n_total, " reports with complete data for ",
         "all markers (n_available = ", n_available_markers, "). Wilson 95% ",
         "confidence intervals reflect sampling uncertainty."),
  "",
  "- **Key finding**: Nearly half of reports contain NMAC tags, while evasive",
  "  actions and ATC assistance are less common. Wide confidence intervals",
  "  reflect the small sample size.",
  "",
  "---",
  "",
  "## Figure 3: Top Tags in Event Narratives",
  "",
  "- **Question**: What anomaly types and contributing factors are most",
  "  frequently tagged in UAS encounter reports?",
  "",
  paste0("- **Denominators**: N = ", n_total, " reports. Anomaly field present ",
         "in ", n_anomaly_field, " reports; contributing factors field present ",
         "in ", n_cf_field, " reports. Counts are report-level (each tag ",
         "counted once per report regardless of repetition)."),
  "",
  "- **Key finding**: Procedural deviations and airspace violations dominate",
  "  the anomaly tags. Human factors appears in the majority of contributing",
  "  factor tags. These patterns describe the curated sample and should not be",
  "  generalized to all UAS encounters.",
  ""
)

writeLines(notes_content, "output/notes/figure_notes.md")
cat("Written: figure_notes.md\n")

cat("\nFigure generation complete. Outputs:\n")
cat("  - output/figures/fig1_detector_by_phase.png\n")
cat("  - output/figures/fig2_severity_markers_ci.png\n")
cat("  - output/figures/fig3_top_tags.png\n")
cat("  - output/notes/figure_notes.md\n")
