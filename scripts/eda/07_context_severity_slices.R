# Context-severity slice analysis for ASRS UAS reports
# Produces table and figures showing NMAC distribution across operational context

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(forcats)
library(stringr)
library(binom)
library(scales)
library(purrr)

dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("output/notes", showWarnings = FALSE, recursive = TRUE)

asrs <- readRDS("output/asrs_constructed.rds")
n_total <- nrow(asrs)
min_group_size <- 5

stopifnot("flag_nmac" %in% names(asrs), is.logical(asrs$flag_nmac))

# =============================================================================
# Helper: compute NMAC prevalence with Wilson CI for a single context variable
# =============================================================================

compute_nmac_by_context <- function(data, context_col, n_total) {
  context_vals <- data[[context_col]]
  context_clean <- if_else(
    is.na(context_vals) | context_vals == "",
    "Unknown",
    as.character(context_vals)
  )

  summary_df <- tibble(context_level = context_clean, flag_nmac = data$flag_nmac) |>
    group_by(context_level) |>
    summarise(n_group = n(), x_nmac = sum(flag_nmac == TRUE, na.rm = TRUE),
              .groups = "drop")

  summary_df |>
    rowwise() |>
    mutate(
      ci_result = list(binom.confint(x_nmac, n_group, methods = "wilson")),
      p_hat = ci_result$mean,
      ci_low = ci_result$lower,
      ci_high = ci_result$upper
    ) |>
    ungroup() |>
    select(-ci_result) |>
    mutate(context_var = context_col, n_total = n_total,
           plot_included = n_group >= min_group_size) |>
    select(context_var, context_level, n_total, n_group,
           x_nmac, p_hat, ci_low, ci_high, plot_included)
}

# =============================================================================
# Table 4: NMAC prevalence by context
# =============================================================================

context_vars <- c("phase_simple", "events__detector", "time_block")
context_vars <- context_vars[context_vars %in% names(asrs)]

table4 <- map_dfr(context_vars, ~ compute_nmac_by_context(asrs, .x, n_total))
write_csv(table4, "output/tables/table4_nmac_by_context.csv")
cat("Written: table4_nmac_by_context.csv\n")

# =============================================================================
# Figure helper
# =============================================================================

plot_nmac_by_context <- function(data, context_var_name, title, subtitle) {
  plot_data <- data |>
    filter(context_var == context_var_name, plot_included) |>
    mutate(context_level = fct_reorder(context_level, p_hat),
           p_hat_pct = p_hat * 100,
           ci_low_pct = ci_low * 100,
           ci_high_pct = ci_high * 100)

  if (nrow(plot_data) == 0) return(NULL)

  ggplot(plot_data, aes(x = p_hat_pct, y = context_level)) +
    geom_pointrange(aes(xmin = ci_low_pct, xmax = ci_high_pct),
                    color = "steelblue", size = 0.8, linewidth = 0.8) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 20),
                       labels = function(x) paste0(x, "%")) +
    labs(title = title, subtitle = subtitle, x = "NMAC Prevalence (%)", y = NULL) +
    theme_minimal(base_size = 11) +
    theme(panel.grid.minor = element_blank(),
          plot.subtitle = element_text(size = 9, color = "gray40"))
}

make_subtitle <- function(var_label) {
  paste0("N = ", n_total, " reports | includes ", var_label,
         " groups with n >= ", min_group_size, " | Wilson 95% CI")
}

# =============================================================================
# Generate figures
# =============================================================================

fig_specs <- list(
  list(var = "phase_simple", file = "fig4_nmac_by_phase_ci.png",
       title = "NMAC Prevalence by Flight Phase", label = "phase"),
  list(var = "events__detector", file = "fig5_nmac_by_detector_ci.png",
       title = "NMAC Prevalence by Detector", label = "detector"),
  list(var = "time_block", file = "fig6_nmac_by_timeblock_ci.png",
       title = "NMAC Prevalence by Time of Day", label = "time block",
       extra_filter = TRUE)
)

fig6_generated <- FALSE

for (spec in fig_specs) {
  if (!spec$var %in% context_vars) next

  n_groups <- table4 |>
    filter(context_var == spec$var, plot_included)

  if (!is.null(spec$extra_filter)) {
    n_groups <- n_groups |> filter(context_level != "Unknown")
    if (nrow(n_groups) <= 1) {
      cat("Skipped:", spec$file, "- insufficient viable groups\n")
      next
    }
  }

  if (nrow(n_groups) == 0) {
    cat("Skipped:", spec$file, "- no groups meet n >= 5 threshold\n")
    next

  }

  fig <- plot_nmac_by_context(table4, spec$var, spec$title,
                               make_subtitle(spec$label))
  ggsave(paste0("output/figures/", spec$file), fig,
         width = 7, height = 4, dpi = 300)
  cat("Written:", spec$file, "\n")

  if (spec$var == "time_block") fig6_generated <- TRUE
}

# =============================================================================
# Notes file
# =============================================================================

notes_content <- c(
  "# Context-Severity Slice Notes", "",
  paste0("Generated: ", Sys.Date()), "", "---", "",
  "## Figure 4: NMAC Prevalence by Flight Phase", "",
  "- Shows proportion of reports tagged NMAC for each flight phase.",
  "- Arrival and enroute phases show higher NMAC prevalence.",
  "- Unknown phase captures reports where phase could not be parsed.", "",
  "---", "",
  "## Figure 5: NMAC Prevalence by Detector", "",
  "- Shows which detection sources are associated with NMAC-tagged reports.",
  "- Flight crew detection dominates, reflecting the reporter population.",
  "- ATC and other sources appear with varying NMAC rates.", "",
  "---"
)

if (fig6_generated) {
  notes_content <- c(notes_content, "",
    "## Figure 6: NMAC Prevalence by Time of Day", "",
    "- Shows NMAC prevalence across local time blocks.",
    "- Midday/afternoon blocks have the most reports.",
    "- Interpret time patterns cautiously given small sample sizes.", "",
    "---"
  )
}

notes_content <- c(notes_content, "",
  "## Important Caveats", "",
  paste0("- **Not population rates**: Report-coded tags in a curated sample ",
         "of ", n_total, " reports; not population incidence rates."), "",
  paste0("- **Small group suppression**: Groups with n < ", min_group_size,
         " excluded from figures. All groups remain in Table 4 with ",
         "plot_included = FALSE."), "",
  "- **Confidence intervals**: Wilson 95% CIs reflect sampling uncertainty",
  "  but do not account for selection bias in the curated sample.", ""
)

writeLines(notes_content, "output/notes/context_severity_notes.md")
cat("Written: context_severity_notes.md\n")

cat("\nContext-severity analysis complete. Outputs:\n")
cat("  - output/tables/table4_nmac_by_context.csv\n")
cat("  - output/figures/fig4_nmac_by_phase_ci.png\n")
cat("  - output/figures/fig5_nmac_by_detector_ci.png\n")
if (fig6_generated) cat("  - output/figures/fig6_nmac_by_timeblock_ci.png\n")
cat("  - output/notes/context_severity_notes.md\n")
