# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Analysis project for NASA Aviation Safety Reporting System (ASRS) UAS/drone incident reports. Data sourced from https://asrs.arc.nasa.gov on 2025-12-26.

**Author:** Mike Hickey
**Status:** Development

## Commands

```bash
# Run all tests
Rscript -e "testthat::test_dir('tests/testthat')"

# Import data and write cleaned output
Rscript scripts/import_data.R

# Restore renv packages
Rscript -e "renv::restore()"

# Snapshot current packages
Rscript -e "renv::snapshot()"

# Lint R files
Rscript -e "lintr::lint_dir('R')"
```

## Architecture

### Data Flow

```
data/asrs_curated_drone_reports.csv (raw ASRS export)
         |
         v
   import_asrs()          <- R/import_asrs.R (pure function)
         |
         v
   [cleaned tibble]       <- 125 columns, typed, renamed
         |
         +---> validate_asrs()           <- R/validate_asrs.R
         +---> validate_asrs_pipeline()  <- R/validate_asrs_assertr.R
         |
         v
output/asrs_uas_reports_clean.csv
```

### Key Files

| File | Purpose |
|------|---------|
| `R/asrs_schema.R` | Single source of truth for column names, types, valid values |
| `R/import_asrs.R` | Pure function: takes path, returns cleaned tibble |
| `R/validate_asrs.R` | Returns tibble of validation check results |
| `R/validate_asrs_assertr.R` | assertr pipeline with `verify()` assertions |
| `R/validation_helpers.R` | Reusable check functions |
| `scripts/import_data.R` | Thin wrapper that runs import and writes output |

### Schema-Driven Design

All validation and import logic references `R/asrs_schema.R`:
- `asrs_expected_cols` - 125 column names
- `asrs_integer_cols`, `asrs_double_cols`, `asrs_logical_cols` - type specs
- `asrs_valid_values` - allowed categorical values
- `asrs_range_bounds` - numeric range constraints
- `asrs_multi_value_cols` - semicolon-delimited fields
- `asrs_entity_prefixes` - column prefix patterns

## Key Documents

| Document | Location |
|----------|----------|
| Data Dictionary | `doc/asrs_data_dictionary.md` |
| ADR-001 Column Naming | `doc/adr/ADR-001-column-naming-convention.md` |
| ADR-002 Date Handling | `doc/adr/ADR-002-date-field-parsing.md` |
| ADR-003 Multi-Value Fields | `doc/adr/ADR-003-multi-value-field-handling.md` |
| ASRS Coding Form | `doc/asrs_coding_key.pdf` |

## Architecture Decisions

**Column Naming (ADR-001):** Entity prefixes with `__` separator (e.g., `ac1__make_model_name`, `person1__function`). Enables `dplyr::starts_with("ac1__")` selection.

**Date Handling (ADR-002):** ASRS exports `YYYYMM` format. Parse with `lubridate::ym()` to Date class (first-of-month convention).

**Multi-Value Fields (ADR-003):** Keep semicolon-delimited strings in storage. Parse on-demand with `tidyr::separate_longer_delim()`.

## CRITICAL WORK RULES

### Non-negotiables

- Use vectorized solutions when practical; prefer clear, idiomatic R
- Do not claim work is "complete", "approved", "validated", or "good" - provide exact commands and outputs
- Never suppress errors/warnings (no `suppressWarnings()`, `suppressMessages()`, `tryCatch` without approval)
- Use renv for reproducibility; do not upgrade packages opportunistically
- Only add essential comments that focus on "why", not "what", in new code when editing files. Do not remove existing code comments unless also removing the functionality they explain.
- Never use emojis in code, documentation, or outputs. Remove any encountered emojis immediately.

### R Style and Tooling

- Follow tidyverse conventions
- Format: `styler` | Lint: `lintr` | Test: `testthat` (edition 3)
- Validation: `checkmate` (args), `assertr` (pipelines), `rlang` (messages)
- Line length: 80 characters max
- Function length: < 80 lines
- Script length: < 300 lines (prefer shorter)

### Approval and Certification

**AI agentic coders do NOT self-certify.** Only the user approves:
- Bug fixes, test validity, validation completion, phase completion

## MCP Tools (r-btw)

The `r-btw` MCP server provides R session integration. Use these instead of running R code when inspecting the environment or looking up documentation:

- `btw_tool_docs_help_page` - Get function/topic documentation from packages
- `btw_tool_docs_package_news` - Check what changed in package updates
- `btw_tool_docs_available_vignettes` - List package vignettes
- `btw_tool_env_describe_data_frame` - Inspect data frames in the R session
- `btw_tool_env_describe_environment` - List objects in the global environment
- `btw_tool_session_package_info` - Check installed/loaded packages
- `btw_tool_search_packages` - Search CRAN for packages

## Data Schema

### Expected Column Count
125 columns after import (126 raw, drop empty trailing column)

### Type Specifications

**Integer columns:**
- `place__relative_position_angle_radial`
- `place__altitude_agl_single_value`
- `place__altitude_msl_single_value`
- `environment__rvr_single_value`
- `ac1__crew_size`, `ac1__number_of_seats_number`, `ac1__passengers_on_board_number`, `ac1__crew_size_flight_attendant_number_of_crew`
- `ac2__crew_size`, `ac2__number_of_seats_number`, `ac2__passengers_on_board_number`, `ac2__crew_size_flight_attendant_number_of_crew`

**Double columns:**
- `place__relative_position_distance_nautical_miles`

**Logical columns (Y/N):**
- `ac1__maintenance_status_maintenance_deferred`, `ac1__maintenance_status_records_complete`, `ac1__maintenance_status_released_for_service`, `ac1__maintenance_status_required_correct_doc_on_board`
- `ac1__operating_under_waivers_exemptions_authorizations_uas`, `ac1__flight_operated_with_visual_observer_uas`, `ac1__passenger_capable_uas`
- `ac2__` equivalents
- `events__were_passengers_involved_in_event`

### Valid Categorical Values (from ASRS Coding Form)

| Field | Valid Values |
|-------|--------------|
| `environment__flight_conditions` | VMC, IMC, Mixed, Marginal |
| `environment__light` | Dawn, Daylight, Dusk, Night |
| `time__local_time_of_day` | 0001-0600, 0601-1200, 1201-1800, 1801-2400 |
| `ac*__flight_plan` | None, VFR, IFR, SVFR, DVFR |
| `ac*__weight_category_uas` | Micro, Small, Medium, Large |
| `ac*__configuration_uas` | Multi-Rotor, Fixed Wing, Helicopter, Hybrid |
| `ac*__flight_operated_as_uas` | VLOS, BVLOS |
| `component__problem` | Design, Failed, Improperly Operated, Malfunctioning |