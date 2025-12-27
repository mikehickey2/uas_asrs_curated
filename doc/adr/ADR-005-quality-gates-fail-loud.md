# ADR-005: Quality Gates and Fail-Loud Policy

**Date:** 2025-12-27
**Status:** Accepted

## Context

Maintaining code quality in a data analysis project requires explicit,
enforceable constraints. Without these, scripts grow unwieldy, errors get
silently swallowed, and technical debt accumulates.

This ADR establishes engineering constraints that shape the project architecture
and defines how they are enforced.

## Decision

### Script Size Limits

| Limit | Lines | Action Required |
|-------|-------|-----------------|
| **Soft limit** | 300 | Preferred maximum; consider refactoring |
| **Hard limit** | 500 | Refactor required before merge |

**Rationale:** Long scripts are harder to understand, test, and maintain. The
300-line soft limit encourages modular design. The 500-line hard limit is a
non-negotiable gate.

**Counting rules:**
- Count all lines including comments and blank lines
- Exclude shebang and file header comments (first 10 lines)
- Use `wc -l` or equivalent for measurement

### Line Length Policy

| Threshold | Characters | Rule |
|-----------|------------|------|
| **Target** | 80 | Default for general R code (improves diff readability) |
| **Allowed** | 110 | Exceptions for paths, regex, YAML, complex calls |
| **Hard stop** | 120 | Refactor required; no exceptions |

**Lint enforcement:** `.lintr` is configured with `line_length_linter(110)`.
Lines exceeding 110 characters will fail lint checks.

**Handling long lines:**
- Extract constants or use intermediate variables
- Break `glue()` strings across lines
- Split long pipelines
- Use `# nolint` sparingly with explanatory comment

### Fail-Loud Policy

**Rule:** Orchestration scripts must not catch-and-stringify errors. Errors
should propagate with full stack traces.

**Prohibited patterns:**
```r
# DO NOT DO THIS
tryCatch(risky_operation(), error = function(e) message(e))

# DO NOT DO THIS
suppressWarnings(potentially_problematic())

# DO NOT DO THIS
suppressMessages(noisy_function())
```

**Allowed exceptions:**
- `tryCatch` with explicit re-throw after logging
- `suppressWarnings` only with user approval and documented rationale
- Production deployments may have different error handling (not applicable here)

**Rationale:** During development and analysis, silent failures hide bugs. Stack
traces are essential for debugging. If something fails, we want to know
immediately with full context.

### Required Quality Gate Commands

Before merging changes, run these commands in order:

```bash
# 1. Lint check (enforces line length, style)
Rscript scripts/dev/01_lint.R

# 2. Test suite (validates functions)
Rscript scripts/dev/02_test.R

# 3. Smoke test (runs full pipeline with lint+tests first)
Rscript scripts/eda/00_run_all.R --smoke
```

All three must pass with zero errors.

## Consequences

### Positive

- Consistent code quality across all scripts
- Errors surface immediately during development
- Easier debugging with full stack traces
- Enforced via automation (lint, tests, smoke)

### Negative

- Stricter discipline required from contributors
- Some legitimate long lines need `# nolint` annotations
- Cannot silently handle known-benign warnings

### Alternatives Considered

**Alternative A: No hard limits, guidelines only**
Rejected because guidelines without enforcement lead to drift. Hard limits
provide clear boundaries.

**Alternative B: Stricter limits (200 lines, 80 char hard)**
Rejected because overly strict limits cause excessive refactoring overhead
and awkward line breaks that hurt readability.

**Alternative C: Allow `tryCatch` for "expected" errors**
Rejected because distinguishing "expected" from "unexpected" errors is
subjective and leads to hidden failures.

## Enforcement

### Script Size

| Mechanism | How |
|-----------|-----|
| Code review | Reviewer checks line count for new/modified scripts |
| Manual check | `wc -l scripts/eda/*.R` before commit |

### Line Length

| Mechanism | Tool | Configuration |
|-----------|------|---------------|
| Automated lint | lintr | `.lintr` with `line_length_linter(110)` |
| Dev script | `scripts/dev/01_lint.R` | Runs lintr on `R/` and `scripts/` |
| Smoke test | `00_run_all.R --smoke` | Runs lint before pipeline |

### Fail-Loud

| Mechanism | How |
|-----------|-----|
| Code review | Reviewer flags `tryCatch`, `suppressWarnings`, `suppressMessages` |
| CLAUDE.md | AI agents instructed never to use suppression without approval |
| Grep check | `grep -r "suppressWarnings\|suppressMessages\|tryCatch" R/ scripts/` |

### Full Quality Gate

```bash
# Run all gates in sequence
Rscript scripts/dev/01_lint.R && \
Rscript scripts/dev/02_test.R && \
Rscript scripts/eda/00_run_all.R --smoke
```

If any command fails, the gate fails.

## References

- Project `.lintr` configuration: `line_length_linter(110)`
- [lintr package documentation](https://lintr.r-lib.org/)
- [testthat package documentation](https://testthat.r-lib.org/)
- CLAUDE.md "CRITICAL WORK RULES" section establishes fail-loud as a
  project norm