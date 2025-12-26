# uas_asrs_curated

Import and validation tools for NASA ASRS UAS incident reports.

## Overview

This project provides a reproducible pipeline for importing, transforming, and
validating CSV exports from NASA's Aviation Safety Reporting System (ASRS). The
current dataset contains 52 UAS/drone encounter reports curated by ASRS staff.

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

```r
# Import and clean data
source("scripts/import_data.R")

# Validate imported data
source("R/validate_asrs.R")
validate_asrs(asrs_uas_reports)

# Run tests
testthat::test_dir("tests/testthat")
```

Output is written to `output/asrs_uas_reports_clean.csv`.

## Project Structure

```
uas_asrs_curated/
├── R/                      # Functions and utilities
│   ├── asrs_schema.R       # Column definitions, types, valid values
│   ├── import_asrs.R       # Pure import function
│   ├── validate_asrs.R     # Validation function
│   └── validation_helpers.R
├── scripts/                # Executable scripts
│   └── import_data.R       # Import wrapper (writes to output/)
├── tests/testthat/         # Test suite (20 tests)
├── data/                   # Raw ASRS CSV exports
├── output/                 # Processed data, figures, tables
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

The current dataset contains **52 UAS encounter reports** curated by NASA ASRS
staff specifically for UAS research. These reports are included in the
repository.

For additional ASRS data:

1. Visit [ASRS Database Online](https://asrs.arc.nasa.gov/search/database.html)
2. Query and export as CSV
3. Place in `data/` and run the import pipeline

The import tools handle the standard ASRS CSV export format and are designed
to scale to larger datasets.

## Upcoming Work

Analysis scripts are in development. Check the repository branches for updates
to exploratory and statistical analysis.

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

The 52 UAS encounter reports in this repository were curated by ASRS staff for
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