# Contributing to uas_asrs_curated

## Setup

```bash
git clone https://github.com/mikehickey2/uas_asrs_curated.git
cd uas_asrs_curated
Rscript -e "renv::restore()"
Rscript -e "testthat::test_dir('tests/testthat')"  # Verify installation
```

## Quality Gates

Before submitting changes, run the full quality gate sequence:

```bash
Rscript scripts/dev/01_lint.R              # Lint check
Rscript scripts/dev/02_test.R              # Test suite
Rscript scripts/eda/00_run_all.R --smoke   # Smoke test (lint + tests + pipeline)
```

All three must pass. See [ADR-005](doc/adr/ADR-005-quality-gates-fail-loud.md)
for script size limits, line length policy, and fail-loud requirements.

## Running the Pipeline

```bash
Rscript scripts/eda/00_run_all.R                    # Full 12-step pipeline
Rscript scripts/eda/00_run_all.R --from 10 --to 12  # Specific steps
Rscript scripts/eda/00_run_all.R --list             # List all steps
```

## Project Structure Rules

See [ADR-004](doc/adr/ADR-004-structure-governance.md) for the full policy.

### No Structure Creep

**Do not create new top-level directories without explicit approval.**

Approved top-level directories: `R/`, `scripts/`, `tests/`, `doc/`, `assets/`,
`data/`, `output/`, `renv/`

Scripts may auto-create only these `output/` subdirectories:
`output/tables/`, `output/figures/`, `output/reports/`, `output/notes/`

### Assets Policy

`assets/` contains static inputs for rendering (e.g., APA reference documents).
Adding new files requires approval.

## Git Policy for Generated Artifacts

| Path | Commit? | Reason |
|------|---------|--------|
| `data/` | Yes | Raw source data (immutable) |
| `output/asrs_uas_reports_clean.csv` | Yes | Canonical cleaned dataset |
| `output/reports/*.html`, `*.docx` | Yes | Final deliverables |
| `output/figures/*.png` | Yes | Publication-ready figures |
| `output/tables/*.csv` | Optional | Machine-readable intermediates |
| `output/notes/*.md` | No | Working documents (regenerable) |
| `output/asrs_constructed.rds` | No | Intermediate data (regenerable) |

**Rationale:** Commit final deliverables so users can view results without
running the pipeline. Skip regenerable intermediates to keep the repo clean.

```bash
# Verify no RDS files staged
git diff --cached --name-only | grep -E "\.(rds|RDS)$"
```

## Code Style

- Follow tidyverse conventions
- Line length: target 80, allowed 110, hard stop 120
- Script size: soft 300, hard 500 lines
- No `suppressWarnings()`, `suppressMessages()`, or `tryCatch` without approval

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>
```

Types: `feat`, `fix`, `data`, `docs`, `refactor`, `test`, `chore`

Example: `feat(eda): add NMAC prevalence by flight phase figure`