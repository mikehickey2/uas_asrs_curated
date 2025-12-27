# Centralized path constants for data products and output directories
#
# This file is the SINGLE SOURCE OF TRUTH for all pipeline paths.
# All scripts should source this file and use these constants
# to prevent path drift across the codebase.
#
# See ADR-006 for the rationale behind data product locations.

# nolint start: object_name_linter
PATHS <- list(
  # ---------------------------------------------------------------------------
  # Data products (versioned in data/)
  # ---------------------------------------------------------------------------
  raw_csv = "data/asrs_curated_drone_reports.csv",
  curated_csv = "data/asrs_uas_reports_clean.csv",
  constructed_rds = "data/asrs_constructed.rds",

  # ---------------------------------------------------------------------------
  # Output directories (generated artifacts)
  # ---------------------------------------------------------------------------
  output_tables = "output/tables",
  output_figures = "output/figures",
  output_notes = "output/notes",
  output_reports = "output/reports",

  # ---------------------------------------------------------------------------
  # Static assets (inputs for rendering)
  # ---------------------------------------------------------------------------
  apa_reference_doc = "assets/apa_reference.docx"
)
# nolint end
