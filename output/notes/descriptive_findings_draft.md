# Descriptive Findings: ASRS UAS Encounter Reports

*Draft generated: 2025-12-26*

---

## Data overview and completeness

This analysis examines 50 UAS encounter reports from the NASA Aviation Safety Reporting System (ASRS), spanning 2024-11-01 to 2025-03-01. The dataset contains 125 coded fields per report.

Key observations about data completeness:

- The dataset represents a curated sample of UAS encounters, not a random sample of all aviation safety reports.
- Core identification fields (report ID, date) are complete for all 50 reports.
- Operational context variables show varying availability: time of day was
  reported for 46 of 50 reports (92%); flight phase was reported for 47 of
  50 reports (94%), with 3 coded as 'Unknown'; airspace class was reported
  for 30 of 50 reports (60%), with 20 coded as 'Unknown'; and light
  conditions were reported for 26 of 50 reports (52%).
- Event coding fields (anomaly tags, contributing factors) are complete, 
  reflecting ASRS analyst review.
- Miss distance information is available for a subset of reports where 
  proximity data was reported and parseable.
- 'Unknown' values in summaries indicate missing or not reported data, not 
  a distinct category.

## Operational context of encounters

**Time of day**: The most common reporting period was 1201-1800, accounting for 21 of 46 reports with time data reported (46%). Four reports lacked time of day data. This aligns with typical daytime flight operations.

**Flight phase**: Arrival phase accounted for 23 of 47 reports with phase reported (49%), followed by Enroute (13 reports, 28%). Three reports were coded as 'Unknown' (missing/not reported).

**Airspace class**: Class B airspace was most frequently reported, appearing in 13 of 30 reports with airspace class reported (43%). Twenty reports were coded as 'Unknown' (missing/not reported).

**Light conditions**: Daylight conditions were present in 19 of 26 reports with lighting data reported (73%). Twenty-four reports lacked light condition data.

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


## Context of NMAC tags

The following subsections describe how NMAC prevalence varies across operational context variables. See Table 4 and Figures 4-6 for visual representations.

### NMAC by detector

Among reports with detector = Person Flight Crew, NMAC was present in 22 of 29 reports (75.9%, Wilson 95% CI [57.9%, 87.8%]). Among reports with detector = Person UAS Crew, NMAC was present in 1 of 15 reports (6.7%, Wilson 95% CI [1.2%, 29.8%]).

These patterns describe this sample of reports and should not be interpreted as population rates or causal effects.

### NMAC by flight phase

Among reports with flight phase = Arrival, NMAC was present in 14 of 23 reports (60.9%, Wilson 95% CI [40.8%, 77.8%]). Among reports with flight phase = Enroute, NMAC was present in 6 of 13 reports (46.2%, Wilson 95% CI [23.2%, 70.9%]). Among reports with flight phase = Departure, NMAC was present in 2 of 9 reports (22.2%, Wilson 95% CI [6.3%, 54.7%]).

These patterns describe this sample of reports and should not be interpreted as population rates or causal effects.

### NMAC by time of day

Among reports with time block = 0601-1200, NMAC was present in 5 of 14 reports (35.7%, Wilson 95% CI [16.3%, 61.2%]). Among reports with time block = 1201-1800, NMAC was present in 9 of 21 reports (42.9%, Wilson 95% CI [24.5%, 63.5%]). Among reports with time block = 1801-2400, NMAC was present in 5 of 8 reports (62.5%, Wilson 95% CI [30.6%, 86.3%]).

These patterns describe this sample of reports and should not be interpreted as population rates or causal effects.

### Summary observations

- **Detector separation**: In this sample, NMAC tags were more frequent in reports detected by flight crew than by UAS crew (see denominators above).

- **Phase patterns**: NMAC tags were most common in Arrival in this sample; intervals overlapped across phases.

- **Time of day**: Time-block comparisons are exploratory with wide intervals.

- **Data notes**: Unknown indicates missing/not reported; groups with n < 5 were excluded from plots but remain in Table 4.

## Dominant event and contributing-factor themes

### Top anomaly tags

Counts reflect report-level presence (each tag counted once per report,
regardless of how many times it appears within that report).

1. **Deviation / Discrepancy - Procedural FAR**: 42 of 50 reports (84%)
2. **Deviation / Discrepancy - Procedural Published Material / Policy**: 42 of 50 reports (84%)
3. **Airspace Violation All Types**: 41 of 50 reports (82%)

### Top contributing factors

Counts reflect report-level presence (each tag counted once per report,
regardless of how many times it appears within that report).

1. **Human Factors**: 46 of 50 reports (92%)
2. **Software and Automation**: 9 of 50 reports (18%)
3. **Procedure**: 7 of 50 reports (14%)

### Co-occurring contributing factor themes

The following factor pairs frequently appeared together within the same 
reports, suggesting thematic associations rather than causal relationships:

- **Aircraft** and **Software and Automation**: co-occurred in 5 of 50 reports (10%)
- **Chart Or Publication** and **Human Factors**: co-occurred in 5 of 50 reports (10%)
- **Environment - Non Weather Related** and **Human Factors**: co-occurred in 5 of 50 reports (10%)

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
