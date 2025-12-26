# ADR-003: Multi-Value Field Handling

**Date:** 2025-12-26  
**Status:** Accepted

## Context

Several ASRS fields contain multiple values in a single cell, semicolon-delimited:

```
"Airspace Violation All Types; Deviation / Discrepancy - Procedural FAR; ..."
```

Affected fields:  
- `events__anomaly`  
- `events__result`  
- `assessments__contributing_factors_situations`  
- `person1__human_factors`  
- `ac1__flying_in_near_over_uas`  
- `ac1__mission`  

Options considered:
1. Parse to list-columns at import → Native R lists, enables `unnest()`
2. Normalize to long format → Separate tables, proper 3NF
3. Keep as delimited strings → Parse on-demand with helper functions

## Decision

Keep multi-value fields as semicolon-delimited strings in the canonical data frame. Provide helper functions to parse on-demand.

```r
#' Parse multi-value ASRS field to vector
parse_multi <- function(x) {
 str_split(x, "; ")[[1]]
}

#' Unnest a multi-value column to long format
unnest_multi <- function(df, col) {
 df |>
   select(acn, {{ col }}) |>
   separate_longer_delim({{ col }}, delim = "; ")
}
```

Usage:  
```
# One-off parsing
parse_multi(df$events__anomaly[1])

# Analysis-ready long format
unnest_multi(df, events__anomaly) |> count(events__anomaly, sort = TRUE)
```

## Consequences

**Positive:**  
- CSV remains human-readable and grep-able  
- No schema change required for storage  
- List-columns or long format generated on-demand as needed  
- Clean round-trip: import → export → import produces identical data  
- PostgreSQL normalization deferred until actually needed  

**Negative:**  
- Extra step required for aggregation/counting by value  
- `str_detect()` needed for filtering instead of exact match  

We accept this tradeoff because it keeps the import simple and flexible. Normalization can happen at PostgreSQL load time if needed.
