# ADR-006: Data Product Location Policy

**Date:** 2025-12-27
**Status:** Accepted

## Context

The project has two processed datasets that serve as inputs for downstream analysis:

1. **Curated CSV** (`asrs_uas_reports_clean.csv`) - 125 columns, typed, renamed
2. **Constructed RDS** (`asrs_constructed.rds`) - 136 columns (125 + 11 derived)

These were initially stored in `output/` alongside generated artifacts (tables, figures,
reports). This caused confusion because:

- `output/` semantically implies "generated outputs that can be discarded and regenerated"
- The curated and constructed datasets are **analysis inputs** for downstream steps
- Scripts in steps 3-12 depend on these files existing before they can run
- The git policy (CONTRIBUTING.md) was inconsistent about whether to commit the RDS

## Decision

Store curated and constructed datasets in `data/` alongside the raw source data.

| Dataset | Old Location | New Location |
|---------|--------------|--------------|
| Curated CSV | `output/asrs_uas_reports_clean.csv` | `data/asrs_uas_reports_clean.csv` |
| Constructed RDS | `output/asrs_constructed.rds` | `data/asrs_constructed.rds` |

### Path Constants

All scripts use centralized path constants defined in `R/paths.R`:

```r
PATHS <- list(
  # Data products
  raw_csv = "data/asrs_curated_drone_reports.csv",
  curated_csv = "data/asrs_uas_reports_clean.csv",
  constructed_rds = "data/asrs_constructed.rds",
  # Output directories
  output_tables = "output/tables",
  output_figures = "output/figures",
  output_notes = "output/notes",
  output_reports = "output/reports"
)
```

Scripts source `R/paths.R` and reference `PATHS$curated_csv`, etc.

### Directory Semantics

| Directory | Contains | Git Policy |
|-----------|----------|------------|
| `data/` | Project datasets (raw, curated, constructed) | Commit all |
| `output/` | Generated analytical artifacts (tables, figures, reports, notes) | Commit final deliverables |

## Consequences

### Positive

- **Clear semantics**: `data/` = datasets, `output/` = artifacts
- **Stable references**: downstream scripts have reliable input paths
- **Reproducibility**: datasets are versioned with the codebase
- **Single source of truth**: `R/paths.R` prevents path drift

### Negative

- **Git churn on RDS**: regenerating the constructed dataset changes tracked files
- **Larger repo size**: RDS files are binary and compress poorly in git

### Mitigations

- Commit RDS only when: (a) source data changes, or (b) construct logic changes
- Do not commit RDS after every pipeline run if nothing substantive changed
- Use `git diff --stat` to verify actual changes before committing data files

## Rules

1. `data/` contains project datasets (raw source, curated, constructed)
2. `output/` contains generated analytical artifacts only
3. Scripts must not write datasets to `output/`
4. All dataset paths must use constants from `R/paths.R`

## References

- [Cookiecutter Data Science](https://drivendata.github.io/cookiecutter-data-science/) -
  Recommends separating raw, interim, and processed data
- ADR-004: Structure Governance - Establishes directory approval rules
- `.temp/rds_governance_analysis.md` - Analysis that motivated this decision