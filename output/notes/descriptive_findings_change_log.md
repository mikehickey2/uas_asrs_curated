# Descriptive Findings Change Log

**Last updated**: 2025-12-27 16:53:05.23718

---

## Changes

### Added: Context of NMAC tags section

- **Date/time**: 2025-12-27 16:53:05.237295
- **Section inserted after**: ## Safety significance markers
- **Subsections added**:
    - ### NMAC by detector
    - ### NMAC by flight phase
    - ### NMAC by time of day
    - ### Summary observations

- **Data sources**:
    - Table 4: `output/tables/table4_nmac_by_context.csv`
    - Figures 4-6: `output/figures/fig4_nmac_by_phase_ci.png`, etc.

- **Implementation notes**:
    - All numeric values programmatically pulled from CSV to avoid drift
    - Only groups with plot_included == TRUE are described in text
    - Wilson 95% CIs reported with one decimal precision
    - Caution sentence appended to each subsection


---

### Rewrite: Context of NMAC tags section

- **Date/time**: 2025-12-27 16:53:05
- **Action**: Rewrote Context of NMAC tags section from table4_nmac_by_context.csv to remove truncation artifacts and standardize APA phrasing.
- **Changes**:
    - Rebuilt all subsections from CSV data
    - Ensured consistent decimal formatting (one decimal place)
    - Removed inferential language from summary bullets
    - Verified no '...' truncation artifacts remain

