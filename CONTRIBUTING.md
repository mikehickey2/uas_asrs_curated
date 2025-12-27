# Contributing to uas_asrs_curated

## Purpose

This repository is an analysis pipeline with governance rules enforced by
automated tests. For design rationale, see the
[Architecture Decision Records](doc/adr/). This guide covers how to work here.

## Setup

```bash
git clone https://github.com/mikehickey2/uas_asrs_curated.git
cd uas_asrs_curated
Rscript -e "renv::restore()"
```

## Common Commands

### Quality Gates

```bash
Rscript scripts/dev/01_lint.R
Rscript scripts/dev/02_test.R
Rscript scripts/eda/00_run_all.R --smoke
```

### Pipeline

```bash
Rscript scripts/eda/00_run_all.R                    # Full 12-step pipeline
Rscript scripts/eda/00_run_all.R --from 1 --to 3    # Run steps 1-3
Rscript scripts/eda/00_run_all.R --no-render        # Skip rendering
Rscript scripts/eda/00_run_all.R --list             # List all steps
```

### Import

```bash
Rscript scripts/import_data.R
```

## Quality Gates

All enforced gates must pass before merge.

### Enforced Gates

| Gate | Tool | Fails When |
|------|------|------------|
| Line length | `.lintr` (lintr) | Any line exceeds 110 characters |
| Path constants | `tests/testthat/test-governance-paths.R` | Hardcoded paths instead of `PATHS$` constants |
| Script size | `tests/testthat/test-governance-script-size.R` | Any script exceeds 500 lines |
| Lint check | `scripts/dev/01_lint.R` | lintr reports any issues |
| Test suite | `scripts/dev/02_test.R` | Any testthat test fails |
| Smoke test | `scripts/eda/00_run_all.R --smoke` | Lint, tests, or pipeline fails |

### Policy Gates (Code Review)

| Gate | Expectation |
|------|-------------|
| Script size soft limit | Scripts should stay under 300 lines; refactor if exceeded |
| Fail-loud conventions | No `suppressWarnings()`, `suppressMessages()`, or `tryCatch` without approval |
| Tidyverse style | Follow tidyverse conventions; use `styler` for formatting |

## Branch and PR Workflow

### Branch Naming

Use descriptive prefixes:

```
feat/add-altitude-analysis
fix/validation-edge-case
docs/update-data-dictionary
refactor/extract-helper-functions
test/add-constructs-coverage
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>
```

**Types:** `feat`, `fix`, `data`, `docs`, `refactor`, `test`, `chore`

**Examples:**

```
feat(eda): add NMAC prevalence by flight phase figure
fix(validation): correct altitude range for negative MSL
docs: update data dictionary derived columns section
refactor(constructs): extract phase mapping to helper
test(governance): add script size enforcement
chore(renv): snapshot new package version
```

### Push and PR

1. Run all quality gates locally before pushing
2. Push branch and open a PR
3. Request review before merging (even for solo work)
4. Merge is blocked if any enforced gate fails

## Path Constants

`R/paths.R` defines all data and output paths. This is enforced by tests.

Scripts must:

1. Add `source("R/paths.R")` at the top
2. Use `PATHS$raw_csv`, `PATHS$curated_csv`, `PATHS$constructed_rds`, etc.
3. Never hardcode `"data/"`, `"output/"`, or `"assets/"` path literals

See [ADR-006](doc/adr/ADR-006-data-product-location.md) for rationale.

## Generated Artifacts

The `output/` and `data/` directories contain generated artifacts. Commit policy
is documented in [ADR-006](doc/adr/ADR-006-data-product-location.md).

**Do not create new top-level directories without approval.**

Approved directories: `R/`, `scripts/`, `tests/`, `doc/`, `assets/`, `data/`,
`output/`, `renv/`