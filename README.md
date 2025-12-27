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
# Clone repository
git clone https://github.com/mikehickey2/uas_asrs_curated.git
cd uas_asrs_curated

# Restore R environment
Rscript -e "renv::restore()"
```

### Dependencies

- R >= 4.0
- tidyverse, checkmate, assertr, testthat (managed by renv)

## Usage

### Import Pipeline

```r
# Import and clean data
source("scripts/import_data.R")

# Validate imported data
source("R/validate_asrs.R")
validate_asrs(asrs_uas_reports)
```

Output is written to `output/asrs_uas_reports_clean.csv`.

### EDA Pipeline

```bash
# Run full 12-step EDA pipeline
Rscript scripts/eda/00_run_all.R

# Run specific steps (e.g., steps 10-12)
Rscript scripts/eda/00_run_all.R --from 10 --to 12

# List all pipeline steps
Rscript scripts/eda/00_run_all.R --list

# Run with lint + tests first
Rscript scripts/eda/00_run_all.R --smoke
```

Outputs are written to `output/reports/`, `output/tables/`, and
`output/figures/`.

### Testing

```bash
# Run all tests
Rscript -e "testthat::test_dir('tests/testthat')"

# Lint R files
Rscript -e "lintr::lint_dir('R')"
```

## Project Structure

```
uas_asrs_curated/
├── R/                      # Functions and utilities
│   ├── asrs_schema.R       # Column definitions, types, valid values
│   ├── import_asrs.R       # Pure import function
│   ├── validate_asrs.R     # Validation function
│   ├── validation_helpers.R
│   └── apa_tables.R        # APA-formatted flextable output
├── scripts/
│   ├── import_data.R       # Import wrapper
│   ├── dev/                # Development tools (lint, test runners)
│   └── eda/                # 12-step EDA pipeline
│       ├── 00_run_all.R    # Pipeline orchestrator
│       ├── 01_audit.R      # Data audit and completeness
│       ├── 02_constructs.R # Derived variables
│       ├── ...             # Steps 03-11
│       └── 12_render_descriptives.R
├── tests/testthat/         # Test suite (150+ tests)
├── data/                   # Raw ASRS CSV exports
├── output/
│   ├── reports/            # HTML and DOCX reports
│   ├── tables/             # CSV tables
│   └── figures/            # PNG figures
├── assets/                 # APA reference document
└── doc/                    # Documentation
```

## Documentation

The `doc/` directory contains reference materials:

| Document | Description |
|----------|-------------|
| `asrs_data_dictionary.md` | Complete field definitions, data types, and valid values for all 125 columns |
| `asrs_coding_key.pdf` | Official NASA ASRS coding form with field definitions (April 2024) |
| `asrs_curated_uas_reports.pdf` | Human-readable version of the 50 curated UAS reports |

## Data

The current dataset contains **50 UAS encounter reports** curated by NASA ASRS
staff specifically for UAS research. These reports are included in the
repository.

For additional ASRS data:

1. Visit [ASRS Database Online](https://asrs.arc.nasa.gov/search/database.html)
2. Query and export as CSV
3. Place in `data/` and run the import pipeline

The import tools handle the standard ASRS CSV export format and are designed
to scale to larger datasets.

## Exploratory Data Analysis

The `scripts/eda/` directory contains a 12-step pipeline that produces
publication-ready descriptive analysis outputs:

| Step | Script | Output |
|------|--------|--------|
| 1 | `01_audit.R` | Data completeness audit |
| 2 | `02_constructs.R` | Derived variables (phase, time block, detector) |
| 3 | `03_tags.R` | Tag analysis with co-occurrence pairs |
| 4 | `04_tables_descriptives.R` | Tables 1-3 (overview, context, severity) |
| 5 | `05_figures_story.R` | Figures 1-3 (detection, markers, tags) |
| 6 | `06_descriptive_findings_md.R` | Narrative draft |
| 7 | `07_context_severity_slices.R` | NMAC by context (Table 4, Figures 4-6) |
| 8-9 | Append/rewrite scripts | Polish NMAC section |
| 10 | `10_build_inventory_captions.R` | Asset manifest with APA captions |
| 11 | `11_assemble_descriptives_qmd.R` | Assemble Quarto document |
| 12 | `12_render_descriptives.R` | Render HTML + DOCX reports |

### Key Features

- **Wilson confidence intervals** for binomial proportions
- **APA-formatted tables** via flextable for Word output
- **Fail-loud error handling** with native stack traces
- **Denominator transparency** in all tables and figures

### Output Files

- `output/reports/01_descriptive_analysis.html` - Self-contained HTML report
- `output/reports/01_descriptive_analysis.docx` - APA-styled Word document
- `output/tables/*.csv` - Machine-readable table data
- `output/figures/*.png` - Publication-ready figures

---

## Citation

If you use this software or data in academic work, please cite:

> Hickey, M. J. (2025). *uas_asrs_curated: Import and validation tools for
> NASA ASRS UAS incident reports* (Version 1.0) [Computer software].
> https://github.com/mikehickey2/uas_asrs_curated

### BibTeX

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

### NASA Aviation Safety Reporting System

This project uses data from the [NASA Aviation Safety Reporting System
(ASRS)](https://asrs.arc.nasa.gov/), a confidential voluntary safety reporting
program administered by NASA under agreement with the Federal Aviation
Administration (FAA). The ASRS has collected aviation safety incident reports
from pilots, controllers, and other aviation professionals since 1976.

The 50 UAS encounter reports in this repository were curated by ASRS staff for
UAS research purposes.

> The ASRS collects, analyzes, and responds to voluntarily submitted aviation
> safety incident reports in order to lessen the likelihood of aviation
> accidents.

ASRS data and reports: https://asrs.arc.nasa.gov/

### Schema Design

The column naming convention (entity prefixes with double underscore separator,
e.g., `ac1__make_model_name`) was adapted from the
[qge/ASRS](https://github.com/qge/ASRS) repository. This pattern solves the
duplicate column name problem in ASRS exports and enables programmatic access
by entity (Aircraft 1, Aircraft 2, Person 1, etc.).

---

## Author

**Michael J. Hickey**  
ORCID: [0009-0009-1402-1228](https://orcid.org/0009-0009-1402-1228)  
Email: [michael.j.hickey@und.edu](mailto:michael.j.hickey@und.edu)  
LinkedIn: [michael-hickey-mba](https://www.linkedin.com/in/michael-hickey-mba/)  
GitHub: [mikehickey2](https://github.com/mikehickey2)

## License

This project is licensed under the [PolyForm Noncommercial License
1.0.0](LICENSE.md). Commercial use is prohibited without written permission.

Academic and research use is permitted. See LICENSE.md for full terms and
citation requirements.