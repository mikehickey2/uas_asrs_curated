# Orchestrate the full EDA pipeline end-to-end
#
# Usage examples:
#   Rscript scripts/eda/00_run_all.R                 # Run all steps
#   Rscript scripts/eda/00_run_all.R --from 5        # Start at step 5
#   Rscript scripts/eda/00_run_all.R --to 6          # Stop after step 6
#   Rscript scripts/eda/00_run_all.R --from 3 --to 7 # Run steps 3-7
#   Rscript scripts/eda/00_run_all.R --no-render     # Skip rendering step
#   Rscript scripts/eda/00_run_all.R --list          # List steps and exit
#   Rscript scripts/eda/00_run_all.R --smoke         # Lint + tests first
#
# Steps:
#   1  01_audit.R                    Data audit and completeness
#   2  02_constructs.R               Derived variables
#   3  03_tags.R                     Tag analysis
#   4  04_tables_descriptives.R      Tables 1-3
#   5  05_figures_story.R            Figures 1-3
#   6  06_descriptive_findings_md.R  Narrative draft
#   7  07_context_severity_slices.R  NMAC by context (Table 4, Figs 4-6)
#   8  08_append_nmac_context_to_draft.R
#   9  09_rewrite_nmac_context_section.R
#  10  10_build_inventory_captions.R Asset manifest + APA inventory
#  11  11_assemble_descriptives_qmd.R QMD assembly
#  12  12_render_descriptives.R      Render HTML + DOCX

# =============================================================================
# Pipeline definition
# =============================================================================

pipeline <- list(
  list(
    num = 1,
    script = "scripts/eda/01_audit.R",
    name = "Data audit",
    artifact = NULL
  ),
  list(
    num = 2,
    script = "scripts/eda/02_constructs.R",
    name = "Derived variables",
    artifact = "output/asrs_constructed.rds"
  ),
  list(
    num = 3,
    script = "scripts/eda/03_tags.R",
    name = "Tag analysis",
    artifact = NULL
  ),
  list(
    num = 4,
    script = "scripts/eda/04_tables_descriptives.R",
    name = "Tables 1-3",
    artifact = NULL
  ),
  list(
    num = 5,
    script = "scripts/eda/05_figures_story.R",
    name = "Figures 1-3",
    artifact = NULL
  ),
  list(
    num = 6,
    script = "scripts/eda/06_descriptive_findings_md.R",
    name = "Narrative draft",
    artifact = NULL
  ),
  list(
    num = 7,
    script = "scripts/eda/07_context_severity_slices.R",
    name = "NMAC by context",
    artifact = NULL
  ),
  list(
    num = 8,
    script = "scripts/eda/08_append_nmac_context_to_draft.R",
    name = "Append NMAC section",
    artifact = NULL
  ),
  list(
    num = 9,
    script = "scripts/eda/09_rewrite_nmac_context_section.R",
    name = "Polish NMAC text",
    artifact = NULL
  ),
  list(
    num = 10,
    script = "scripts/eda/10_build_inventory_captions.R",
    name = "Asset manifest",
    artifact = "output/notes/assets_manifest.csv"
  ),
  list(
    num = 11,
    script = "scripts/eda/11_assemble_descriptives_qmd.R",
    name = "QMD assembly",
    artifact = NULL
  ),
  list(
    num = 12,
    script = "scripts/eda/12_render_descriptives.R",
    name = "Render HTML + DOCX",
    artifact = c(
      "output/reports/01_descriptive_analysis.html",
      "output/reports/01_descriptive_analysis.docx"
    ),
    is_render = TRUE
  )
)

total_steps <- length(pipeline)

# =============================================================================
# Parse CLI arguments
# =============================================================================

args <- commandArgs(trailingOnly = TRUE)

parse_arg <- function(args, flag, default) {
  idx <- which(args == flag)
  if (length(idx) == 0) return(default)
  if (idx == length(args)) stop(paste0(flag, " requires a value"))
  as.integer(args[idx + 1])
}

from_step <- parse_arg(args, "--from", 1)
to_step <- parse_arg(args, "--to", total_steps)
no_render <- "--no-render" %in% args
list_steps <- "--list" %in% args
run_smoke <- "--smoke" %in% args

# Handle --list: print steps and exit
if (list_steps) {
  cat("EDA Pipeline Steps:\n")
  cat("===================\n\n")
  for (step in pipeline) {
    artifacts <- if (is.null(step$artifact)) {
      ""
    } else {
      paste0(" -> ", paste(step$artifact, collapse = ", "))
    }
    render_tag <- if (isTRUE(step$is_render)) " [render]" else ""
    cat(sprintf(
      "%2d  %-40s %s%s%s\n",
      step$num,
      step$name,
      basename(step$script),
      render_tag,
      artifacts
    ))
  }
  cat("\n")
  quit(status = 0)
}

if (from_step < 1 || from_step > total_steps) {
  stop(paste0("--from must be between 1 and ", total_steps))
}
if (to_step < 1 || to_step > total_steps) {
  stop(paste0("--to must be between 1 and ", total_steps))
}
if (from_step > to_step) {
  stop("--from cannot be greater than --to")
}

# =============================================================================
# Smoke tests (optional)
# =============================================================================

if (run_smoke) {
  cat("==============================================\n")
  cat("Running smoke tests (lint + testthat)\n")
  cat("==============================================\n\n")

  lint_script <- "scripts/dev/01_lint.R"
  test_script <- "scripts/dev/02_test.R"

  if (!file.exists(lint_script)) {
    stop(paste0("Lint script not found: ", lint_script))
  }
  if (!file.exists(test_script)) {
    stop(paste0("Test script not found: ", test_script))
  }

  cat("RUNNING: Lint (scripts/dev/01_lint.R)\n")
  source(lint_script, local = new.env())
  cat("Lint: PASS\n\n")

  cat("RUNNING: Tests (scripts/dev/02_test.R)\n")
  source(test_script, local = new.env())
  cat("Tests: PASS\n\n")

  cat("Smoke tests passed. Continuing with pipeline...\n\n")
}

# =============================================================================
# Preflight checks
# =============================================================================

cat("==============================================\n")
cat("EDA Pipeline Runner\n")
cat("==============================================\n")
cat("\n")
cat("Preflight checks:\n")

input_csv <- "data/asrs_curated_drone_reports.csv"
if (!file.exists(input_csv)) {
  stop(paste0("  FAILED: Input CSV not found: ", input_csv))
}
cat("  Input CSV exists:", input_csv, "\n")

render_enabled <- !no_render && any(
  vapply(pipeline[from_step:to_step], function(s) {
    isTRUE(s$is_render)
  }, logical(1))
)

if (render_enabled) {
  quarto_path <- Sys.which("quarto")
  if (quarto_path == "") {
    stop("  FAILED: Quarto not found on PATH (required for rendering)")
  }
  cat("  Quarto found:", quarto_path, "\n")

  apa_ref <- "assets/apa_reference.docx"
  if (!file.exists(apa_ref)) {
    cat("  APA reference doc missing, generating...\n")
    apa_script <- "scripts/eda/13_create_apa_reference.R"
    if (!file.exists(apa_script)) {
      stop(paste0("  FAILED: ", apa_script, " not found"))
    }
    source(apa_script, local = new.env())
    if (!file.exists(apa_ref)) {
      stop(paste0("  FAILED: Could not generate ", apa_ref))
    }
    cat("  APA reference doc created:", apa_ref, "\n")
  } else {
    cat("  APA reference doc exists:", apa_ref, "\n")
  }
}

cat("\n")
cat("Configuration:\n")
cat("  Steps:", from_step, "to", to_step, "of", total_steps, "\n")
cat("  Rendering:", if (no_render) "DISABLED" else "enabled", "\n")
cat("\n")

# =============================================================================
# Run pipeline
# =============================================================================

cat("==============================================\n")
cat("Running pipeline\n")
cat("==============================================\n")
cat("\n")

pipeline_start <- Sys.time()
step_times <- list()

for (step in pipeline[from_step:to_step]) {
  if (no_render && isTRUE(step$is_render)) {
    cat(sprintf(
      "STEP %d/%d: %s -- SKIPPED (--no-render)\n",
      step$num, total_steps, step$name
    ))
    next
  }

  if (!file.exists(step$script)) {
    stop(paste0("Script not found: ", step$script))
  }

  cat(sprintf(
    "RUNNING STEP %d/%d: %s -- %s\n",
    step$num, total_steps, step$name, step$script
  ))

  step_start <- Sys.time()
  source(step$script, local = new.env())

  step_elapsed <- round(
    difftime(Sys.time(), step_start, units = "secs"),
    1
  )
  step_times[[as.character(step$num)]] <- step_elapsed

  cat(sprintf("  Completed in %.1fs\n", step_elapsed))

  if (!is.null(step$artifact)) {
    for (artifact in step$artifact) {
      if (!file.exists(artifact)) {
        cat(sprintf("  WARNING: Expected artifact missing: %s\n", artifact))
      } else {
        size_kb <- round(file.info(artifact)$size / 1024, 1)
        cat(sprintf("  Artifact verified: %s (%.1f KB)\n", artifact, size_kb))
      }
    }
  }

  cat("\n")
}

# =============================================================================
# Summary
# =============================================================================

pipeline_elapsed <- round(
  difftime(Sys.time(), pipeline_start, units = "secs"),
  1
)

cat("==============================================\n")
cat("Pipeline COMPLETE\n")
cat("==============================================\n")
cat("\n")
cat("Step timings:\n")
for (num in names(step_times)) {
  step_info <- pipeline[[as.integer(num)]]
  elapsed <- step_times[[num]]
  cat(sprintf("  Step %s: %s -- %.1fs\n", num, step_info$name, elapsed))
}
cat("\n")
cat(sprintf("Total runtime: %.1fs\n", pipeline_elapsed))
cat("\n")
