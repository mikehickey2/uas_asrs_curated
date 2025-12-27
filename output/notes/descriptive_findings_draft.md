# Descriptive Findings: ASRS UAS Encounter Reports

*Draft generated: 2025-12-26*

---

## Data overview and completeness

This analysis examines 50 UAS encounter reports from the NASA Aviation Safety Reporting System (ASRS), spanning 2024-11-01 to 2025-03-01. The dataset contains 125 coded fields per report.

Key observations about data completeness:

- The dataset represents a curated sample of UAS encounters, not a random sample of all aviation safety reports.
- Core identification fields (report ID, date) are complete for all 50 reports.
- Operational context variables (time of day, flight phase, airspace) are 
  available for the majority of reports, though availability varies by field.
- Event coding fields (anomaly tags, contributing factors) are complete, 
  reflecting ASRS analyst review.
- Miss distance information is available for a subset of reports where 
  proximity data was reported and parseable.
- 'Unknown' values in summaries indicate missing or not reported data, not 
  a distinct category.

## Operational context of encounters

**Time of day**: The most common reporting period was 1201-1800, accounting for 21 of 46 reports with time data available (45.7%). This aligns with typical daytime flight operations.

**Flight phase**: Arrival phase accounted for 23 of 50 reports with phase available (46%), followed by Enroute (13 reports, 26%).

**Airspace class**: Class B airspace was most frequently reported, appearing in 13 of 50 reports with airspace data (26%).

**Light conditions**: Daylight conditions were present in 19 of 26 reports with lighting data (73.1%).

## Detection and reporting patterns

Cross-tabulation of detection and reporting variables reveals patterns 
in how encounters are identified and documented:

- The most common reporter-time combination was Air Carrier during 1201-1800, with 9 reports.
- Person Flight Crew was the most common detection source during Arrival phase (17 reports).

## Safety significance markers

Three markers of safety significance were examined: near mid-air collision 
(NMAC) tags, evasive action taken, and ATC assistance or clarification 
requested.

- **NMAC**: Present in 23 of 50 reports (46%, 95% CI [33%, 60%]). NMAC tag present in events__anomaly.
- **Evasive action**: Present in 6 of 50 reports (12%, 95% CI [6%, 24%]). Evasive Action in events__result.
- **ATC assistance**: Present in 5 of 50 reports (10%, 95% CI [4%, 21%]). ATC Assistance or Clarification in events__result.

The wide confidence intervals reflect the small sample size and should be 
interpreted with caution. These proportions describe this curated sample 
and should not be generalized to all UAS encounters.

## Dominant event and contributing-factor themes

### Top anomaly tags

1. **Deviation / Discrepancy - Procedural FAR**: 42 reports (84%)
2. **Deviation / Discrepancy - Procedural Published Material / Policy**: 42 reports (84%)
3. **Airspace Violation All Types**: 41 reports (82%)

### Top contributing factors

1. **Human Factors**: 46 reports (92%)
2. **Software and Automation**: 9 reports (18%)
3. **Procedure**: 7 reports (14%)

### Co-occurring contributing factor themes

The following factor pairs frequently appeared together within the same 
reports, suggesting thematic associations rather than causal relationships:

- **Aircraft** and **Software and Automation**: co-occurred in 5 reports (10%)
- **Chart Or Publication** and **Human Factors**: co-occurred in 5 reports (10%)
- **Environment - Non Weather Related** and **Human Factors**: co-occurred in 5 reports (10%)

## What these descriptives do and do not support

These findings describe patterns within a curated sample of ASRS UAS 
encounter reports. Several limitations apply:

- **Report-coded data**: All tags and classifications reflect ASRS analyst 
  coding of voluntary reports, not objective measurements or population 
  incidence rates.

- **Short time window**: The data span approximately five months. No claims 
  about temporal trends or seasonal patterns are supported.

- **Curated sample**: These reports were selected by ASRS staff for UAS 
  research purposes. The sample may not represent all UAS encounters or 
  all ASRS reports.

- **Miss distance sparsity**: Proximity measurements were available for 
  only a subset of reports. Findings about miss distance apply only to 
  available cases.

- **'Unknown' = missing**: Categories labeled 'Unknown' indicate data that 
  was not reported or could not be coded, not a distinct response category.

- **No causal inference**: Associations between variables do not imply 
  causation. Contributing factors are coded themes, not verified mechanisms.

- **Small sample size**: Confidence intervals are wide, and percentage 
  differences may not be statistically meaningful.

- **Voluntary reporting**: ASRS relies on voluntary submissions. Reporting 
  patterns may reflect reporter characteristics rather than event frequency.

---

*This draft was auto-generated from descriptive analysis outputs. 
Review and edit before publication.*
