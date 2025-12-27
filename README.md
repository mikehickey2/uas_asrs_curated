# uas_asrs_curated

Import, validation, and exploratory analysis tools for NASA ASRS UAS incident
reports.

## Overview

This project provides a reproducible pipeline for importing, transforming,
validating, and analyzing CSV exports from NASA's Aviation Safety Reporting
System (ASRS). The current dataset contains 50 UAS/drone encounter reports
curated by ASRS staff.

The tools are designed to scale to larger ASRS CSV exports beyond this curated
sample.

## Installation

```bash
git clone https://github.com/mikehickey2/uas_asrs_curated.git
cd uas_asrs_curated
Rscript -e "renv::restore()"
```

### Dependencies

- R >= 4.0
- tidyverse, checkmate, assertr, testthat (managed by renv)

## Usage

All commands assume execution from the repository root.

### Import Pipeline

The curated CSV is already present in the repository. To re-import from raw:

```bash
Rscript scripts/import_data.R
```

This reads `data/asrs_curated_drone_reports.csv` (`PATHS$raw_csv`) and writes
`data/asrs_uas_reports_clean.csv` (`PATHS$curated_csv`).

### EDA Pipeline

The pipeline reads from the curated CSV, derives analytical columns (written to
`data/asrs_constructed.rds`), and generates outputs in `output/`.

```bash
# Run full 12-step pipeline
Rscript scripts/eda/00_run_all.R

# Smoke test (lint + tests before running)
Rscript scripts/eda/00_run_all.R --smoke

# Run specific steps
Rscript scripts/eda/00_run_all.R --from 1 --to 3 --no-render

# List all pipeline steps
Rscript scripts/eda/00_run_all.R --list
```

**CLI flags:** `--list`, `--from`, `--to`, `--smoke`, `--no-render`

Outputs are written to `output/reports/`, `output/tables/`, `output/figures/`,
and `output/notes/`.

### Quality Gates

```bash
Rscript scripts/dev/01_lint.R           # Lint check
Rscript scripts/dev/02_test.R           # Run tests (219 tests)
Rscript scripts/eda/00_run_all.R --smoke  # Full smoke test
```

## Path Constants

`R/paths.R` is the single source of truth for all data and output paths.
See [ADR-006](doc/adr/ADR-006-data-product-location.md) for rationale.

| Constant | Path |
|----------|------|
| `PATHS$raw_csv` | `data/asrs_curated_drone_reports.csv` |
| `PATHS$curated_csv` | `data/asrs_uas_reports_clean.csv` |
| `PATHS$constructed_rds` | `data/asrs_constructed.rds` |
| `PATHS$output_*` | `output/tables/`, `output/figures/`, etc. |

Scripts must `source("R/paths.R")` and use `PATHS$...` constants.

## Project Structure

```
uas_asrs_curated/
├── R/                          # Functions and utilities
│   ├── paths.R                 # Path constants (single source of truth)
│   ├── asrs_schema.R           # Column definitions, types, valid values
│   ├── asrs_constructs_schema.R # Schema for 11 derived analytical columns
│   ├── construct_helpers.R     # Helpers for deriving analytical columns
│   ├── import_asrs.R           # Pure import function
│   ├── validate_asrs.R         # Validation function
│   └── apa_tables.R            # APA-formatted flextable output
├── scripts/
│   ├── import_data.R           # Import wrapper
│   ├── dev/                    # Development tools (lint, test runners)
│   └── eda/                    # EDA pipeline
│       ├── 00_run_all.R        # Pipeline orchestrator (runs steps 01-12)
│       ├── 01_audit.R          # Data audit and completeness
│       ├── 02_constructs.R     # Derived variables
│       ├── 03-12_*.R           # Remaining pipeline steps
│       └── 13_create_apa_reference.R  # One-time helper (not a pipeline step)
├── tests/testthat/             # Test suite (219 tests)
├── data/                       # Data products (per ADR-006)
│   ├── asrs_curated_drone_reports.csv  # Raw ASRS export
│   ├── asrs_uas_reports_clean.csv      # Curated dataset (125 columns)
│   └── asrs_constructed.rds            # With derived columns (136 columns)
├── output/
│   ├── reports/                # HTML and DOCX reports
│   ├── tables/                 # CSV tables
│   ├── figures/                # PNG figures
│   └── notes/                  # Markdown drafts and manifests
├── assets/                     # Static inputs (APA reference document)
└── doc/                        # Documentation and ADRs
```

## Documentation

| Document | Description |
|----------|-------------|
| `doc/asrs_data_dictionary.md` | Field definitions for all 125 columns |
| `doc/asrs_coding_key.pdf` | Official NASA ASRS coding form (April 2024) |
| `doc/adr/` | Architecture Decision Records (ADR-001 to ADR-006) |

## EDA Pipeline Steps

| Step | Script | Output |
|------|--------|--------|
| 1 | `01_audit.R` | Data completeness audit |
| 2 | `02_constructs.R` | Derived variables (phase, time block, flags) |
| 3 | `03_tags.R` | Tag analysis with co-occurrence pairs |
| 4 | `04_tables_descriptives.R` | Tables 1-3 (overview, context, severity) |
| 5 | `05_figures_story.R` | Figures 1-3 (detection, markers, tags) |
| 6 | `06_descriptive_findings_md.R` | Narrative draft |
| 7 | `07_context_severity_slices.R` | NMAC by context (Table 4, Figures 4-6) |
| 8-9 | Append/rewrite scripts | Polish NMAC section |
| 10 | `10_build_inventory_captions.R` | Asset manifest with APA captions |
| 11 | `11_assemble_descriptives_qmd.R` | Assemble Quarto document |
| 12 | `12_render_descriptives.R` | Render HTML + DOCX reports |

`13_create_apa_reference.R` is a one-time helper that generates
`assets/apa_reference.docx` if missing; it runs automatically during preflight
when needed.

### Output Files

- `output/reports/01_descriptive_analysis.html` - Self-contained HTML report
- `output/reports/01_descriptive_analysis.docx` - APA-styled Word document
- `output/tables/*.csv` - Machine-readable table data
- `output/figures/*.png` - Publication-ready figures

---

## Data

The dataset contains **50 UAS encounter reports** curated by NASA ASRS staff.

For additional ASRS data, visit
[ASRS Database Online](https://asrs.arc.nasa.gov/search/database.html),
export as CSV, place in `data/`, and run the import pipeline.

---

## Citation
If you use this software or data in academic work, please cite:
> Hickey, M. J. (2025). *uas_asrs_curated: Import and validation tools for
> NASA ASRS UAS incident reports* (Version 1.0) [Computer software].
> https://github.com/mikehickey2/uas_asrs_curated

```bibtex
@software{hickey2025uasasrs,
  author       = {Hickey, Michael J.},
  title        = {uas\_asrs\_curated: Import and validation tools for NASA
                  ASRS UAS incident reports},
  year         = {2025},
  version      = {1.0},
  url          = {https://github.com/mikehickey2/uas_asrs_curated}
}
```

---

## Acknowledgments

This project uses data from the [NASA Aviation Safety Reporting System
(ASRS)](https://asrs.arc.nasa.gov/), a confidential voluntary safety reporting
program administered by NASA under agreement with the FAA.

The column naming convention (entity prefixes with `__` separator) was adapted
from the [qge/ASRS](https://github.com/qge/ASRS) repository.

---

## Author

**Michael J. Hickey**
ORCID: [0009-0009-1402-1228](https://orcid.org/0009-0009-1402-1228)
Email: [michael.j.hickey@und.edu](mailto:michael.j.hickey@und.edu)
GitHub: [mikehickey2](https://github.com/mikehickey2)

## License

[PolyForm Noncommercial License 1.0.0](LICENSE.md). Academic and research use
permitted. See LICENSE.md for full terms and [CONTRIBUTING.md](CONTRIBUTING.md)
for contribution guidelines.