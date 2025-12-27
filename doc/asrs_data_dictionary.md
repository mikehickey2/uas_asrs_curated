# ASRS Data Dictionary

**Source:** NASA Aviation Safety Reporting System (ASRS) Database Export  
**Coding Reference:** ASRS Coding Form (April 2024)  
**Version:** 1.0  
**Last Updated:** 2025-12-26

---

## Column Naming Convention

Entity prefixes use double underscore separator: `entity__field_name`

| Prefix | Entity |
|--------|--------|
| `ac1__` | Aircraft 1 (reporting aircraft) |
| `ac2__` | Aircraft 2 (other aircraft, often UAS) |
| `person1__` | Person 1 (primary reporter) |
| `person2__` | Person 2 (secondary reporter) |
| `report1__` | Report 1 (primary narrative) |
| `report2__` | Report 2 (supplemental narrative) |
| `component__` | Component involved |
| `events__` | Event details |
| `assessments__` | ASRS analyst assessments |
| `time__` | Temporal fields |
| `place__` | Location fields |
| `environment__` | Environmental conditions |

---

## Core Fields

| Column | Type | Description | Valid Values |
|--------|------|-------------|--------------|
| `acn` | `character` | Accession Number - unique report identifier | 7-digit numeric string |
| `time__date` | `character` | Report date | YYYYMM format; parse with `lubridate::ym()` |
| `time__local_time_of_day` | `character` | Time block of event | `0001-0600`, `0601-1200`, `1201-1800`, `1801-2400` |

---

## Place Fields

| Column | Type | Description | Valid Values |
|--------|------|-------------|--------------|
| `place__locale_reference` | `character` | Location reference (Airport/NAVAID ID) | Airport: `XXX.Airport`; NAVAID: `XXX.VOR` |
| `place__state_reference` | `character` | US state or country code | 2-letter state code or `US` |
| `place__relative_position_angle_radial` | `integer` | Radial from reference point | 0-360 degrees |
| `place__relative_position_distance_nautical_miles` | `numeric` | Distance from reference point | Nautical miles |
| `place__altitude_agl_single_value` | `integer` | Altitude above ground level | Feet AGL |
| `place__altitude_msl_single_value` | `integer` | Altitude mean sea level | Feet MSL |
| `place__latitude_longitude_uas` | `character` | Lat/Lon for UAS operations | Coordinate string (rarely populated) |

---

## Environment Fields

| Column | Type | Description | Valid Values |
|--------|------|-------------|--------------|
| `environment__flight_conditions` | `character` | Meteorological conditions | `VMC`, `IMC`, `Mixed`, `Marginal` |
| `environment__weather_elements_visibility` | `character` | Weather elements and visibility | Multi-value: `Cloudy`, `Fog`, `Rain`, `Snow`, `Thunderstorm`, `Turbulence`, `Hail`, `Haze / Smoke`, `Icing`, `Windshear`; Visibility in SM |
| `environment__work_environment_factor` | `character` | Environmental factors affecting work | `Poor Lighting`, `Glare`, `Temperature - Extreme`, `Excessive Humidity`, `Excessive Wind (UAS)` |
| `environment__light` | `character` | Lighting conditions | `Dawn`, `Daylight`, `Dusk`, `Night` |
| `environment__ceiling` | `character` | Cloud ceiling | `CLR` or numeric value in feet |
| `environment__rvr_single_value` | `integer` | Runway Visual Range | Feet |

---

## Aircraft 1 Fields

Primary/reporting aircraft. For manned-UAS encounters, typically the manned aircraft.

| Column | Type | Description | Valid Values |
|--------|------|-------------|--------------|
| `ac1__atc_advisory` | `character` | ATC facility in contact | `Tower`, `TRACON`, `Center`, `Ground`, `CTAF`, `UNICOM`, `FSS`, `Ramp`, `Military Facility` |
| `ac1__aircraft_operator` | `character` | Operator type | `Air Carrier`, `Air Taxi`, `Corporate`, `Fractional`, `FBO`, `Government`, `Military`, `Personal`, `Commercial Operator (UAS)`, `Recreational / Hobbyist (UAS)` |
| `ac1__make_model_name` | `character` | Aircraft make/model | Free text or standardized name |
| `ac1__aircraft_zone` | `character` | Geographic zone | Zone identifier |
| `ac1__crew_size` | `integer` | Number of crew | Numeric |
| `ac1__operating_under_far_part` | `character` | FAR Part | `Part 91`, `Part 103`, `Part 107`, `Part 119`, `Part 121`, `Part 125`, `Part 129`, `Part 133`, `Part 135`, `Part 137`, `Public Aircraft Operations (UAS)`, `Recreational Operations / Section 44809 (UAS)` |
| `ac1__flight_plan` | `character` | Flight plan type | `None`, `VFR`, `IFR`, `SVFR`, `DVFR` |
| `ac1__mission` | `character` | Flight mission | `Passenger`, `Cargo / Freight / Delivery`, `Training`, `Personal`, `Ferry / Re-Positioning`, `Ambulance`, `Agriculture`, `Photo Shoot / Video`, `Surveying / Mapping (UAS)`, `Observation / Surveillance (UAS)`, `Public Safety / Pursuit (UAS)`, `Recreational / Hobbyist (UAS)`, `Test Flight / Demonstration`, `Banner Tow`, `Aerobatics`, `Skydiving`, `Traffic Watch`, `Search & Rescue`, `Tactical`, `Utility / Infrastructure`, `Communications (UAS)` |
| `ac1__nav_in_use` | `character` | Navigation equipment | `GPS`, `FMS / FMC`, `INS`, `VOR/VORTAC`, `NDB`, `Localizer / Glideslope / ILS` |
| `ac1__flight_phase` | `character` | Phase of flight | `Parked`, `Taxi`, `Takeoff / Launch`, `Initial Climb`, `Climb`, `Cruise`, `Descent`, `Initial Approach`, `Final Approach`, `Landing`, `Ground / Preflight (UAS)`, `Hovering (UAS)`, `Return to Home (UAS)`, `Refueling` |
| `ac1__route_in_use` | `character` | Route type | `Direct`, `Airway`, `SID`, `STAR`, `Vectors`, `VFR Route`, `Visual Approach`, `Oceanic`, `None` |
| `ac1__airspace` | `character` | Airspace class | `Class A`, `Class B`, `Class C`, `Class D`, `Class E`, `Class G`, `Special Use`, `TFR` + identifier |
| `ac1__maintenance_status_maintenance_deferred` | `logical` | Maintenance deferred? | `Y`, `N` |
| `ac1__maintenance_status_records_complete` | `logical` | Records complete? | `Y`, `N` |
| `ac1__maintenance_status_released_for_service` | `logical` | Released for service? | `Y`, `N` |
| `ac1__maintenance_status_required_correct_doc_on_board` | `logical` | Required docs on board? | `Y`, `N` |
| `ac1__maintenance_status_maintenance_type` | `character` | Maintenance type | `Scheduled Maintenance`, `Unscheduled Maintenance` |
| `ac1__maintenance_status_maintenance_items_involved` | `character` | Items involved | `Inspection`, `Repair`, `Installation`, `Testing`, `Work Cards` |
| `ac1__cabin_lighting` | `character` | Cabin lighting status | `High`, `Medium`, `Low`, `Off` |
| `ac1__number_of_seats_number` | `integer` | Number of seats | Numeric |
| `ac1__passengers_on_board_number` | `integer` | Passengers on board | Numeric |
| `ac1__crew_size_flight_attendant_number_of_crew` | `integer` | Number of flight attendants | Numeric |
| `ac1__airspace_authorization_provider_uas` | `character` | UAS airspace auth provider | `Authorized Third Party`, `FAA Authorization` |
| `ac1__operating_under_waivers_exemptions_authorizations_uas` | `logical` | Operating under waiver? | `Y`, `N` |
| `ac1__waivers_exemptions_authorizations_uas` | `character` | Specific waiver/exemption | `Standard`, `Special`, `Special Authorization / Section 44807`, `Blanket COA`, `Emergency COA`, `Jurisdictional COA`, `91`, `107.25`, `107.29`, `107.31`, `107.33`, `107.35`, `107.37(a)`, `107.39`, `107.51`, `135` |
| `ac1__airworthiness_certification_uas` | `character` | UAS certification status | Free text |
| `ac1__weight_category_uas` | `character` | UAS weight category | `Micro`, `Small`, `Medium`, `Large` |
| `ac1__configuration_uas` | `character` | UAS configuration | `Multi-Rotor`, `Fixed Wing`, `Helicopter`, `Hybrid` |
| `ac1__flight_operated_as_uas` | `character` | UAS operation type | `VLOS`, `BVLOS` |
| `ac1__flight_operated_with_visual_observer_uas` | `logical` | Visual observer present? | `Y`, `N` |
| `ac1__control_mode_uas` | `character` | UAS control mode | `Manual Control`, `Waypoint Flying`, `Autonomous / Fully Automated`, `Transitioning Between Modes` |
| `ac1__flying_in_near_over_uas` | `character` | UAS operating environment | Multi-value: `Airport / Aerodrome / Heliport`, `People / Populated Areas`, `Moving Vehicles`, `Critical Infrastructure`, `Emergency Services`, `Crowds`, `Open Space / Field`, `Private Property`, `No Drone Zone`, `Natural Disaster`, `Indoor / Confined Spaces`, `Aerial Show / Event`, `Recreational Club / Fixed Flying Site` |
| `ac1__passenger_capable_uas` | `logical` | UAS passenger capable? | `Y`, `N` |
| `ac1__type_uas` | `character` | UAS acquisition type | `Purchased`, `Homebuilt/Custom` |
| `ac1__number_of_uas_being_controlled_uas` | `character` | Number of UAS controlled | Text with number (e.g., `Number of UAS 1`) |

---

## Component Fields

| Column | Type | Description | Valid Values |
|--------|------|-------------|--------------|
| `component__aircraft_component` | `character` | Component involved | Free text |
| `component__manufacturer` | `character` | Component manufacturer | Free text |
| `component__aircraft_reference` | `character` | Which aircraft | `X`, `Y`, `Z`, or other letter |
| `component__problem` | `character` | Problem type | `Design`, `Failed`, `Improperly Operated`, `Malfunctioning` |

---

## Aircraft 2 Fields

Second aircraft in encounter. For manned-UAS encounters, typically the UAS.

| Column | Type | Description |
|--------|------|-------------|
| `ac2__atc_advisory` | `character` | Same as `ac1__atc_advisory` |
| `ac2__aircraft_operator` | `character` | Same as `ac1__aircraft_operator` |
| `ac2__make_model_name` | `character` | Same as `ac1__make_model_name` |
| `ac2__aircraft_zone` | `character` | Same as `ac1__aircraft_zone` |
| `ac2__crew_size` | `integer` | Same as `ac1__crew_size` |
| `ac2__operating_under_far_part` | `character` | Same as `ac1__operating_under_far_part` |
| `ac2__flight_plan` | `character` | Same as `ac1__flight_plan` |
| `ac2__mission` | `character` | Same as `ac1__mission` |
| `ac2__nav_in_use` | `character` | Same as `ac1__nav_in_use` |
| `ac2__flight_phase` | `character` | Same as `ac1__flight_phase` |
| `ac2__route_in_use` | `character` | Same as `ac1__route_in_use` |
| `ac2__airspace` | `character` | Same as `ac1__airspace` |
| `ac2__maintenance_status_maintenance_deferred` | `logical` | Same as `ac1__` |
| `ac2__maintenance_status_records_complete` | `logical` | Same as `ac1__` |
| `ac2__maintenance_status_released_for_service` | `logical` | Same as `ac1__` |
| `ac2__maintenance_status_required_correct_doc_on_board` | `logical` | Same as `ac1__` |
| `ac2__maintenance_status_maintenance_type` | `character` | Same as `ac1__` |
| `ac2__maintenance_status_maintenance_items_involved` | `character` | Same as `ac1__` |
| `ac2__cabin_lighting` | `character` | Same as `ac1__` |
| `ac2__number_of_seats_number` | `integer` | Same as `ac1__` |
| `ac2__passengers_on_board_number` | `integer` | Same as `ac1__` |
| `ac2__crew_size_flight_attendant_number_of_crew` | `integer` | Same as `ac1__` |
| `ac2__airspace_authorization_provider_uas` | `character` | Same as `ac1__` |
| `ac2__operating_under_waivers_exemptions_authorizations_uas` | `logical` | Same as `ac1__` |
| `ac2__waivers_exemptions_authorizations_uas` | `character` | Same as `ac1__` |
| `ac2__airworthiness_certification_uas` | `character` | Same as `ac1__` |
| `ac2__weight_category_uas` | `character` | Same as `ac1__` |
| `ac2__configuration_uas` | `character` | Same as `ac1__` |
| `ac2__flight_operated_as_uas` | `character` | Same as `ac1__` |
| `ac2__flight_operated_with_visual_observer_uas` | `logical` | Same as `ac1__` |
| `ac2__control_mode_uas` | `character` | Same as `ac1__` |
| `ac2__flying_in_near_over_uas` | `character` | Same as `ac1__` |
| `ac2__passenger_capable_uas` | `logical` | Same as `ac1__` |
| `ac2__type_uas` | `character` | Same as `ac1__` |
| `ac2__number_of_uas_being_controlled_uas` | `character` | Same as `ac1__` |

---

## Person 1 Fields

Primary reporter.

| Column | Type | Description | Valid Values |
|--------|------|-------------|--------------|
| `person1__location_of_person` | `character` | Where person was located | `Aircraft`, `Facility`, `Company`, `Gate / Ramp / Line`, `Hangar / Base`, `Repair Facility`, `Outdoor / Field Station (UAS)`, `Indoor / Ground Control Station (UAS)` |
| `person1__location_in_aircraft` | `character` | Position in aircraft | `Flight Deck`, `Cabin Jumpseat`, `Crew Rest Area`, `Lavatory`, `Door Area`, `Galley`, `General Seating Area` |
| `person1__reporter_organization` | `character` | Reporter's organization type | `Air Carrier`, `Air Taxi`, `Contracted Service`, `Corporate`, `Fractional`, `Personal`, `Government`, `Military`, `FBO`, `Commercial Operator (UAS)`, `Recreational / Hobbyist (UAS)` |
| `person1__function` | `character` | Reporter's function/role | **Flight Crew:** `Captain`, `First Officer`, `Check Pilot`, `Flight Engineer/Second Officer`, `Instructor`, `Pilot Flying`, `Pilot Not Flying`, `Relief Pilot`, `Single Pilot`, `Trainee`, `Remote PIC (UAS)`, `Person Manipulating Controls (UAS)`, `Visual Observer (UAS)` **ATC:** `Approach`, `Departure`, `Enroute`, `Ground`, `Local`, `Flight Data/Clearance Delivery`, `Supervisor/CIC`, `Trainee` **Maintenance:** `Inspector`, `Technician`, `Lead Technician`, `Repairman` |
| `person1__qualification` | `character` | Certifications/ratings | **Flight Crew:** `Student`, `Sport/Recreational`, `Private`, `Commercial`, `Air Transport Pilot (ATP)`, `Flight Instructor`, `Remote Pilot (UAS)`, `Instrument`, `Multiengine`, `Rotorcraft`, `Glider`, `Lighter-Than-Air`, `Sea` **ATC:** `Fully Certified`, `Developmental` |
| `person1__experience` | `character` | Experience metrics | Free text with values like `Flight Crew Total 5000; Flight Crew Last 90 Days 150; Flight Crew Type 1200` |
| `person1__cabin_activity` | `character` | Flight attendant activity | `Boarding`, `Deplaning`, `Safety Related Duties`, `Service` |
| `person1__human_factors` | `character` | Human factors involved | Multi-value: `Communication Breakdown`, `Confusion`, `Distraction`, `Fatigue`, `Human-Machine Interface`, `Physiological – Other`, `Situational Awareness`, `Time Pressure`, `Training/Qualification`, `Troubleshooting`, `Workload`, `Other / Unknown` |
| `person1__communication_breakdown` | `character` | Comm breakdown parties | Between X and Y format (e.g., `Flight Crew` and `ATC`) |
| `person1__uas_communication_breakdown` | `character` | UAS-specific comm breakdown | Between X and Y (e.g., `Remote PIC` and `Visual Observer`) |
| `person1__asrs_report_number_accession_number` | `character` | Report ACN (redundant) | Same as `acn` |

---

## Person 2 Fields

Secondary reporter (if multiple reports combined).

| Column | Type | Description |
|--------|------|-------------|
| `person2__location_of_person` | `character` | Same as `person1__` |
| `person2__location_in_aircraft` | `character` | Same as `person1__` |
| `person2__reporter_organization` | `character` | Same as `person1__` |
| `person2__function` | `character` | Same as `person1__` |
| `person2__qualification` | `character` | Same as `person1__` |
| `person2__experience` | `character` | Same as `person1__` |
| `person2__cabin_activity` | `character` | Same as `person1__` |
| `person2__human_factors` | `character` | Same as `person1__` |
| `person2__communication_breakdown` | `character` | Same as `person1__` |
| `person2__uas_communication_breakdown` | `character` | Same as `person1__` |
| `person2__asrs_report_number_accession_number` | `character` | Same as `person1__` |

---

## Events Fields

| Column | Type | Description | Valid Values |
|--------|------|-------------|--------------|
| `events__anomaly` | `character` | Event anomaly types | Multi-value: **Conflict:** `NMAC`, `Airborne Conflict`, `Ground Conflict, Critical`, `Ground Conflict, Less Severe` **Deviation:** `Altitude - Excursion from Assigned Altitude`, `Altitude - Crossing Restriction Not Met`, `Altitude - Overshoot`, `Altitude - Undershoot`, `Speed - All Types`, `Track/Heading - All Types` **Procedural:** `Clearance`, `FAR`, `Published Material/Policy`, `MEL / CDL`, `Maintenance`, `Landing without Clearance`, `Unauthorized Flight Operations (UAS)` **Airspace:** `Airspace Violation All Types` **Inflight:** `Weather / Turbulence`, `Wake Vortex Encounter`, `Bird / Animal`, `Object`, `Laser`, `CFTT/CFIT`, `VFR in IMC`, `Loss of Aircraft Control`, `Fuel Issue`, `Unstabilized Approach`, `Fly Away (UAS)`, `Smoke / Fire / Fumes / Odor` **Ground:** `Runway Incursion`, `Taxiway Incursion`, `Ramp Incursion`, `Ground Excursion`, `FOD`, `Ground Strike – Aircraft`, `Jet Blast`, `Loss of VLOS (UAS)` **Other:** `No Specific Anomaly Occurred`, `Unwanted Situation` |
| `events__miss_distance` | `character` | Separation distance | Free text: `Horizontal XXX; Vertical XXX` (feet) |
| `events__were_passengers_involved_in_event` | `logical` | Passengers involved? | `Yes`, `No` |
| `events__detector` | `character` | Who/what detected event | **Automation:** `Aircraft RA`, `Aircraft TA`, `Aircraft Terrain Warning`, `Aircraft Other Automation`, `Collision Avoidance System (UAS)` **Person:** `Flight Crew`, `Air Traffic Control`, `Flight Attendant`, `Maintenance`, `Dispatch`, `Ground Personnel`, `Gate Agent / CSR`, `Passenger`, `Observer`, `UAS Crew`, `Visual Observer (UAS)`, `Other Person` |
| `events__when_detected` | `character` | When event was detected | `Pre-flight`, `Taxi`, `In-flight`, `Aircraft in service at gate`, `Routine inspection`, `Other Post-flight` |
| `events__result` | `character` | Event result/outcome | Multi-value: **General:** `None Reported / Taken`, `Flight Cancelled / Delayed`, `Maintenance Action`, `Police / Security Involved`, `Physical Injury / Incapacitation`, `Evacuated`, `Release Refused / Aircraft not Accepted`, `Work Refused`, `Overcame Equipment Problem` **Flight Crew:** `Became Reoriented`, `Took Evasive Action`, `Executed Go Around / Missed Approach`, `Landed as Precaution`, `Landed in Emergency Condition`, `Diverted`, `Returned to Departure Airport`, `Returned to Gate`, `Returned to Clearance`, `Rejected Takeoff`, `Inflight Shutdown`, `Regained Aircraft Control`, `Exited Penetrated Airspace`, `Requested ATC Assistance/Clarification`, `FLC Complied with Automation / Advisory`, `FLC Overrode Automation` **ATC:** `Issued New Clearance`, `Issued Advisory/Alert`, `Separated Traffic`, `Provided Assistance` **Aircraft:** `Aircraft Damaged`, `Equipment Problem Dissipated`, `Automation Overrode Flight Crew` **UAS:** `Returned to Home (UAS)`, `Automated Return to Home (UAS)`, `Lost Link (UAS)`, `Lost / Unrecoverable (UAS)` |

---

## Assessments Fields

| Column | Type | Description | Valid Values |
|--------|------|-------------|--------------|
| `assessments__contributing_factors_situations` | `character` | Contributing factors | Multi-value: `Aircraft`, `Airport`, `Airspace Structure`, `ATC Equip / Nav Facility / Buildings`, `Chart or Publication`, `Company Policy`, `Environment – Non Weather Related`, `Equipment / Tooling`, `Human Factors`, `Incorrect / Not Installed / Unavailable Part`, `Logbook Entry`, `Manuals`, `MEL`, `Procedure`, `Software and Automation`, `Staffing`, `Weather` |
| `assessments__primary_problem` | `character` | Primary problem category | `Aircraft`, `Airport`, `Airspace Structure`, `Ambiguous`, `ATC Equip / Nav Facility / Buildings`, `Chart or Publication`, `Company Policy`, `Environment – Non Weather Related`, `Equipment / Tooling`, `Human Factors`, `Incorrect / Not Installed / Unavailable Part`, `Logbook Entry`, `Manuals`, `MEL`, `Procedure`, `Software and Automation`, `Staffing`, `Weather` |

---

## Report Fields

| Column | Type | Description | Valid Values |
|--------|------|-------------|--------------|
| `report1__narrative` | `character` | Primary reporter narrative | Free text (de-identified) |
| `report1__callback` | `character` | Callback status/notes | `Attempted`, `Completed`, or callback notes |
| `report1__synopsis` | `character` | ASRS-generated summary | Free text summary |
| `report2__narrative` | `character` | Supplemental narrative | Free text (from Person 2 if present) |
| `report2__callback` | `character` | Supplemental callback | `Attempted`, `Completed`, or callback notes |

---

## Derived Analytical Columns

These columns are created in EDA Step 2 (`scripts/eda/02_constructs.R`) and are present
in `output/asrs_constructed.rds`. They are not part of the raw ASRS export but are
derived from source columns for analytical convenience. The schema definition is
maintained in `R/asrs_constructs_schema.R`.

| Column | Type | Definition | Source Column | Notes |
|--------|------|------------|---------------|-------|
| `month` | `character` | Year-month string (YYYY-MM format) | `time__date` | |
| `time_block` | `character` | Time of day block (direct alias) | `time__local_time_of_day` | |
| `reporter_org` | `character` | Reporter organization (direct alias) | `person1__reporter_organization` | |
| `phase_raw` | `character` | Raw flight phase string (direct alias) | `ac1__flight_phase` | |
| `phase_simple` | `character` | Simplified flight phase category | `ac1__flight_phase` | 5 levels: `Arrival`, `Departure`, `Surface`, `Enroute`, `Unknown` |
| `airspace_class` | `character` | Airspace class extracted from text | `ac1__airspace` | Values `A`-`G` or `Unknown`; regex: `Class\s+([A-G])` |
| `flag_nmac` | `logical` | TRUE if NMAC mentioned in anomaly | `events__anomaly` | regex: `\bNMAC\b` (case-insensitive) |
| `flag_evasive` | `logical` | TRUE if evasive action taken | `events__result` | regex: `Evasive Action` |
| `flag_atc` | `logical` | TRUE if ATC assistance/clarification | `events__result` | regex: `ATC Assistance\|Clarification` |
| `miss_horizontal_ft` | `numeric` | Horizontal miss distance in feet | `events__miss_distance` | Parsed from `Horizontal NNN` pattern |
| `miss_vertical_ft` | `numeric` | Vertical miss distance in feet | `events__miss_distance` | Parsed from `Vertical NNN` pattern |

### Categorical Level Definitions

**`phase_simple`** maps raw flight phase values to simplified categories:

| Level | Keywords Matched |
|-------|------------------|
| `Arrival` | Final Approach, Initial Approach, Descent, Landing |
| `Departure` | Takeoff, Launch, Climb |
| `Surface` | Taxi, Ground |
| `Enroute` | Cruise |
| `Unknown` | No match or missing value |

**`airspace_class`** extracts the class letter from airspace descriptions:

| Level | Meaning |
|-------|---------|
| `A`-`G` | FAA airspace class extracted via regex |
| `Unknown` | Class could not be extracted or source value missing |

---

## Complete Column List

```
acn
time__date
time__local_time_of_day
place__locale_reference
place__state_reference
place__relative_position_angle_radial
place__relative_position_distance_nautical_miles
place__altitude_agl_single_value
place__altitude_msl_single_value
place__latitude_longitude_uas
environment__flight_conditions
environment__weather_elements_visibility
environment__work_environment_factor
environment__light
environment__ceiling
environment__rvr_single_value
ac1__atc_advisory
ac1__aircraft_operator
ac1__make_model_name
ac1__aircraft_zone
ac1__crew_size
ac1__operating_under_far_part
ac1__flight_plan
ac1__mission
ac1__nav_in_use
ac1__flight_phase
ac1__route_in_use
ac1__airspace
ac1__maintenance_status_maintenance_deferred
ac1__maintenance_status_records_complete
ac1__maintenance_status_released_for_service
ac1__maintenance_status_required_correct_doc_on_board
ac1__maintenance_status_maintenance_type
ac1__maintenance_status_maintenance_items_involved
ac1__cabin_lighting
ac1__number_of_seats_number
ac1__passengers_on_board_number
ac1__crew_size_flight_attendant_number_of_crew
ac1__airspace_authorization_provider_uas
ac1__operating_under_waivers_exemptions_authorizations_uas
ac1__waivers_exemptions_authorizations_uas
ac1__airworthiness_certification_uas
ac1__weight_category_uas
ac1__configuration_uas
ac1__flight_operated_as_uas
ac1__flight_operated_with_visual_observer_uas
ac1__control_mode_uas
ac1__flying_in_near_over_uas
ac1__passenger_capable_uas
ac1__type_uas
ac1__number_of_uas_being_controlled_uas
component__aircraft_component
component__manufacturer
component__aircraft_reference
component__problem
ac2__atc_advisory
ac2__aircraft_operator
ac2__make_model_name
ac2__aircraft_zone
ac2__crew_size
ac2__operating_under_far_part
ac2__flight_plan
ac2__mission
ac2__nav_in_use
ac2__flight_phase
ac2__route_in_use
ac2__airspace
ac2__maintenance_status_maintenance_deferred
ac2__maintenance_status_records_complete
ac2__maintenance_status_released_for_service
ac2__maintenance_status_required_correct_doc_on_board
ac2__maintenance_status_maintenance_type
ac2__maintenance_status_maintenance_items_involved
ac2__cabin_lighting
ac2__number_of_seats_number
ac2__passengers_on_board_number
ac2__crew_size_flight_attendant_number_of_crew
ac2__airspace_authorization_provider_uas
ac2__operating_under_waivers_exemptions_authorizations_uas
ac2__waivers_exemptions_authorizations_uas
ac2__airworthiness_certification_uas
ac2__weight_category_uas
ac2__configuration_uas
ac2__flight_operated_as_uas
ac2__flight_operated_with_visual_observer_uas
ac2__control_mode_uas
ac2__flying_in_near_over_uas
ac2__passenger_capable_uas
ac2__type_uas
ac2__number_of_uas_being_controlled_uas
person1__location_of_person
person1__location_in_aircraft
person1__reporter_organization
person1__function
person1__qualification
person1__experience
person1__cabin_activity
person1__human_factors
person1__communication_breakdown
person1__uas_communication_breakdown
person1__asrs_report_number_accession_number
person2__location_of_person
person2__location_in_aircraft
person2__reporter_organization
person2__function
person2__qualification
person2__experience
person2__cabin_activity
person2__human_factors
person2__communication_breakdown
person2__uas_communication_breakdown
person2__asrs_report_number_accession_number
events__anomaly
events__miss_distance
events__were_passengers_involved_in_event
events__detector
events__when_detected
events__result
assessments__contributing_factors_situations
assessments__primary_problem
report1__narrative
report1__callback
report2__narrative
report2__callback
report1__synopsis
```

---

## R Type Specification

```r
asrs_col_types <- cols(
  acn = col_character(),
  time__date = col_character(),
  time__local_time_of_day = col_character(),
  place__locale_reference = col_character(),
  place__state_reference = col_character(),
  place__relative_position_angle_radial = col_integer(),
  place__relative_position_distance_nautical_miles = col_double(),
  place__altitude_agl_single_value = col_integer(),
  place__altitude_msl_single_value = col_integer(),
  place__latitude_longitude_uas = col_character(),
  environment__flight_conditions = col_character(),
  environment__weather_elements_visibility = col_character(),
  environment__work_environment_factor = col_character(),
  environment__light = col_character(),
  environment__ceiling = col_character(),
  environment__rvr_single_value = col_integer(),
  .default = col_character()
)
```

---

## Multi-Value Field Parsing

Several fields contain semicolon-separated multiple values:

- `events__anomaly`
- `events__result`
- `assessments__contributing_factors_situations`
- `person1__human_factors`
- `ac1__flying_in_near_over_uas`
- `ac1__mission`
- `ac1__flight_phase`

**Suggested parsing function:**

```r
parse_multi_value <- function(x, sep = "; ") {
 str_split(x, sep)
}
```

---

## Notes

1. **Empty columns:** Many maintenance and cabin-specific fields are empty for UAS reports
2. **De-identification:** Narratives use `ZZZ` for locations, `XXX` for identifiers
3. **Aircraft reference:** `X` = primary, `Y` = secondary, `Z` = tertiary
4. **UAS-specific fields:** Fields ending in `_uas` are UAS-only; will be NA for manned aircraft
5. **Naming convention:** Follows qge/ASRS repository schema pattern (`Entity__Field`)
