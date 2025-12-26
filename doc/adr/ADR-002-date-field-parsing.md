# ADR-002: Date Field Parsing

**Date:** 2025-12-26  
**Status:** Accepted

## Context

ASRS exports dates in `YYYYMM` format (e.g., `202501`). This is month-level precision only—no day information exists in the source data. We need to decide how to represent this in R for analysis and visualization.

Options considered:
1. `lubridate::ym()` → Returns `Date` object set to first of month (e.g., `2025-01-01`)
2. `zoo::as.yearmon()` → Returns `yearmon` class preserving month-level semantics
3. Keep as character → No date operations possible

## Decision

Use `lubridate::ym()` to parse `time__date` into a proper `Date` object.

```r
mutate(time__date = ym(time__date))
```

The first-of-month convention is widely understood for month-level data. This enables native date operations, ggplot2 time axes, and dplyr date filtering without adding the `zoo` dependency.

## Consequences

**Positive:**
- Standard `Date` class works everywhere (ggplot2, dplyr, base R)
- Enables date arithmetic (`time__date + months(3)`)
- No additional dependencies beyond lubridate (already in tidyverse)

**Negative:**
- Implies false day-level precision (day=1 is a convention, not data)
- Users must understand this is month-level data despite `Date` type

We accept this tradeoff because the convention is standard practice for monthly time series data.
