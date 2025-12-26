# ADR-001: Column Naming Convention

**Date:** 2025-12-26  
**Status:** Accepted

## Context

ASRS CSV exports contain duplicate column names for repeating entities (Aircraft 1/2, Person 1/2, Report 1/2). When imported with `readr::read_csv()`, R auto-disambiguates by appending position suffixes (`_17`, `_57`, `_91`, etc.). These position-based suffixes are meaningless to readers, require constant lookup, and break if ASRS changes column order in future exports.

## Decision

Use semantic entity prefixes with double-underscore separator:

| Prefix | Entity |
|--------|--------|
| `ac1__` | Aircraft 1 |
| `ac2__` | Aircraft 2 |
| `person1__` | Person 1 (primary reporter) |
| `person2__` | Person 2 (secondary reporter) |
| `report1__` | Report 1 (primary narrative) |
| `report2__` | Report 2 (supplemental) |
| `component__` | Component |
| `events__` | Events |
| `assessments__` | Assessments |
| `time__` | Temporal fields |
| `place__` | Location fields |
| `environment__` | Environmental conditions |

This approach was adopted from the qge/ASRS repository (https://github.com/qge/ASRS), which solved the same problem. No need to reinvent the wheel. The double underscore separator (\_\_) isn't a database standard—it likely derives from scikit-learn's pipeline parameter syntax—but it's visually distinct from the single underscore word separator and trivial to change later via str_replace_all("\_\_", "_") if needed.

## Consequences

**Positive:**
- Self-documenting column names (`ac2__make_model_name` vs `make_model_name_58`)
- Easy column selection with tidyverse (`starts_with("ac1__")`)
- Stable across ASRS export format changes

**Negative:**
- Requires one-time column rename during import
- Longer column names (mitigated by autocomplete)