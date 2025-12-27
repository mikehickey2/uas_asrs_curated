# APA Inventory: Tables and Figures

*Generated: 2025-12-27*

This document provides standardized titles, captions, and denominator
notes for all tables and figures produced by the exploratory data analysis.

---

## Tables

### Table 1. Dataset overview and completeness

**Caption**: Summarizes dataset dimensions, date range, and field-level completeness across 125 coded variables.

**Denominator note**: N = 50 reports. Denominators vary by field; n available is reported per variable.

**Source file**: `output/tables/table1_overview_completeness.csv`

---

### Table 2. Operational context of encounters

**Caption**: Frequency distributions for operational context variables including time of day, flight phase, airspace class, and light conditions.

**Denominator note**: N = 50 reports. n available varies by field due to missing data; percentages computed against both N total and n available.

**Source file**: `output/tables/table2_operational_context.csv`

---

### Table 2a. Optional cross-tabulations (detector by phase; reporter by time)

**Caption**: Cross-tabulations of detector by flight phase and reporter organization by time block.

**Denominator note**: N = 50 reports. Row and column percentages reported; n available varies by variable pair.

**Source file**: `output/tables/table2_optional_crosstabs.csv`

---

### Table 3. Safety significance markers with Wilson 95% intervals

**Caption**: Prevalence of NMAC tags, evasive action, and ATC assistance markers with Wilson 95% confidence intervals.

**Denominator note**: N = 50 reports with complete data for all markers.

**Source file**: `output/tables/table3_severity_markers.csv`

---

### Table 4. NMAC prevalence by operational context with Wilson 95% intervals

**Caption**: NMAC tag prevalence stratified by detector, flight phase, and time of day with Wilson 95% confidence intervals.

**Denominator note**: N = 50 reports. Groups with n < 5 flagged (plot_included = FALSE) but retained in table for transparency.

**Source file**: `output/tables/table4_nmac_by_context.csv`

---

## Figures

### Figure 1. Event detection by flight phase

**Caption**: Who detects UAS encounters, and during which flight phases?

**Denominator note**: N = 50 reports. Detector available for n = 47 reports; phase available for n = 47 reports. Unknown indicates missing/not reported.

**File**: `output/figures/fig1_detector_by_phase.png`

---

### Figure 2. Severity marker prevalence with Wilson 95% intervals

**Caption**: How frequently do NMAC, evasive action, and ATC assistance markers appear in reports?

**Denominator note**: N = 50 reports. Wilson 95% confidence intervals shown.

**File**: `output/figures/fig2_severity_markers_ci.png`

---

### Figure 3. Dominant tags in UAS encounter reports

**Caption**: What anomaly types and contributing factors are most frequently tagged?

**Denominator note**: N = 50 reports. Counts are report-level (each tag counted once per report regardless of repetition).

**File**: `output/figures/fig3_top_tags.png`

---

### Figure 4. NMAC prevalence by flight phase with Wilson 95% intervals

**Caption**: How does NMAC prevalence vary by flight phase?

**Denominator note**: N = 50 reports. Groups with n >= 5 included in plot. Wilson 95% confidence intervals shown.

**File**: `output/figures/fig4_nmac_by_phase_ci.png`

---

### Figure 5. NMAC prevalence by detector with Wilson 95% intervals

**Caption**: How does NMAC prevalence vary by detection source?

**Denominator note**: N = 50 reports. Groups with n >= 5 included in plot. Wilson 95% confidence intervals shown.

**File**: `output/figures/fig5_nmac_by_detector_ci.png`

---

### Figure 6. NMAC prevalence by time of day with Wilson 95% intervals

**Caption**: How does NMAC prevalence vary by time of day?

**Denominator note**: N = 50 reports. Groups with n >= 5 included in plot. Wilson 95% confidence intervals shown.

**File**: `output/figures/fig6_nmac_by_timeblock_ci.png`

---

## Notes

- All confidence intervals use the Wilson method.
- Unknown categories indicate missing or not reported data.
- Groups with n < 5 were excluded from figures but retained in tables.
- Counts are report-level unless otherwise noted.

