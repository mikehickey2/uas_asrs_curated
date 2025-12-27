#' Import and clean ASRS CSV export
#'
#' Reads a raw ASRS CSV export, renames columns to semantic entity-prefixed
#' names, and coerces columns to appropriate types (Date, integer, double,
#' logical) based on the schema defined in asrs_schema.R.
#'
#' @param path Path to raw ASRS CSV file.
#' @return A tibble with 125 columns:
#'   \itemize{
#'     \item Character columns for most fields
#'     \item Date column for time__date (parsed from YYYYMM)
#'     \item Integer columns for counts and numeric codes
#'     \item Double column for distance measurements
#'     \item Logical columns for Y/N maintenance and UAS fields
#'   }
#' @export
library(readr)
library(dplyr)
library(stringr)
library(lubridate)
library(rlang)
source("R/asrs_schema.R")

parse_logical_yn <- function(x) {
  cleaned <- str_trim(str_to_upper(x))
  case_when(
    cleaned %in% c("Y", "YES", "TRUE") ~ TRUE,
    cleaned %in% c("N", "NO", "FALSE") ~ FALSE,
    TRUE ~ NA
  )
}

import_asrs <- function(path) {
  rename_map <- c(
    "ACN" = "acn",
    "Date" = "time__date",
    "Local Time Of Day" = "time__local_time_of_day",
    "Locale Reference" = "place__locale_reference",
    "State Reference" = "place__state_reference",
    "Relative Position.Angle.Radial" =
      "place__relative_position_angle_radial",
    "Relative Position.Distance.Nautical Miles" =
      "place__relative_position_distance_nautical_miles",
    "Altitude.AGL.Single Value" = "place__altitude_agl_single_value",
    "Altitude.MSL.Single Value" = "place__altitude_msl_single_value",
    "Latitude / Longitude (UAS)" = "place__latitude_longitude_uas",
    "Flight Conditions" = "environment__flight_conditions",
    "Weather Elements / Visibility" =
      "environment__weather_elements_visibility",
    "Work Environment Factor" = "environment__work_environment_factor",
    "Light" = "environment__light",
    "Ceiling" = "environment__ceiling",
    "RVR.Single Value" = "environment__rvr_single_value",
    "ATC / Advisory...17" = "ac1__atc_advisory",
    "Aircraft Operator...18" = "ac1__aircraft_operator",
    "Make Model Name...19" = "ac1__make_model_name",
    "Aircraft Zone...20" = "ac1__aircraft_zone",
    "Crew Size...21" = "ac1__crew_size",
    "Operating Under FAR Part...22" = "ac1__operating_under_far_part",
    "Flight Plan...23" = "ac1__flight_plan",
    "Mission...24" = "ac1__mission",
    "Nav In Use...25" = "ac1__nav_in_use",
    "Flight Phase...26" = "ac1__flight_phase",
    "Route In Use...27" = "ac1__route_in_use",
    "Airspace...28" = "ac1__airspace",
    "Maintenance Status.Maintenance Deferred...29" =
      "ac1__maintenance_status_maintenance_deferred",
    "Maintenance Status.Records Complete...30" =
      "ac1__maintenance_status_records_complete",
    "Maintenance Status.Released For Service...31" =
      "ac1__maintenance_status_released_for_service",
    "Maintenance Status.Required / Correct Doc On Board...32" =
      "ac1__maintenance_status_required_correct_doc_on_board",
    "Maintenance Status.Maintenance Type...33" =
      "ac1__maintenance_status_maintenance_type",
    "Maintenance Status.Maintenance Items Involved...34" =
      "ac1__maintenance_status_maintenance_items_involved",
    "Cabin Lighting...35" = "ac1__cabin_lighting",
    "Number Of Seats.Number...36" = "ac1__number_of_seats_number",
    "Passengers On Board.Number...37" = "ac1__passengers_on_board_number",
    "Crew Size Flight Attendant.Number Of Crew...38" =
      "ac1__crew_size_flight_attendant_number_of_crew",
    "Airspace Authorization Provider (UAS)...39" =
      "ac1__airspace_authorization_provider_uas",
    "Operating Under Waivers / Exemptions / Authorizations (UAS)...40" =
      "ac1__operating_under_waivers_exemptions_authorizations_uas",
    "Waivers / Exemptions / Authorizations (UAS)...41" =
      "ac1__waivers_exemptions_authorizations_uas",
    "Airworthiness Certification (UAS)...42" =
      "ac1__airworthiness_certification_uas",
    "Weight Category (UAS)...43" = "ac1__weight_category_uas",
    "Configuration (UAS)...44" = "ac1__configuration_uas",
    "Flight Operated As (UAS)...45" = "ac1__flight_operated_as_uas",
    "Flight Operated with Visual Observer (UAS)...46" =
      "ac1__flight_operated_with_visual_observer_uas",
    "Control Mode (UAS)...47" = "ac1__control_mode_uas",
    "Flying In / Near / Over (UAS)...48" = "ac1__flying_in_near_over_uas",
    "Passenger Capable (UAS)...49" = "ac1__passenger_capable_uas",
    "Type (UAS)...50" = "ac1__type_uas",
    "Number of UAS Being Controlled (UAS)...51" =
      "ac1__number_of_uas_being_controlled_uas",
    "Aircraft Component" = "component__aircraft_component",
    "Manufacturer" = "component__manufacturer",
    "Aircraft Reference" = "component__aircraft_reference",
    "Problem" = "component__problem",
    "ATC / Advisory...56" = "ac2__atc_advisory",
    "Aircraft Operator...57" = "ac2__aircraft_operator",
    "Make Model Name...58" = "ac2__make_model_name",
    "Aircraft Zone...59" = "ac2__aircraft_zone",
    "Crew Size...60" = "ac2__crew_size",
    "Operating Under FAR Part...61" = "ac2__operating_under_far_part",
    "Flight Plan...62" = "ac2__flight_plan",
    "Mission...63" = "ac2__mission",
    "Nav In Use...64" = "ac2__nav_in_use",
    "Flight Phase...65" = "ac2__flight_phase",
    "Route In Use...66" = "ac2__route_in_use",
    "Airspace...67" = "ac2__airspace",
    "Maintenance Status.Maintenance Deferred...68" =
      "ac2__maintenance_status_maintenance_deferred",
    "Maintenance Status.Records Complete...69" =
      "ac2__maintenance_status_records_complete",
    "Maintenance Status.Released For Service...70" =
      "ac2__maintenance_status_released_for_service",
    "Maintenance Status.Required / Correct Doc On Board...71" =
      "ac2__maintenance_status_required_correct_doc_on_board",
    "Maintenance Status.Maintenance Type...72" =
      "ac2__maintenance_status_maintenance_type",
    "Maintenance Status.Maintenance Items Involved...73" =
      "ac2__maintenance_status_maintenance_items_involved",
    "Cabin Lighting...74" = "ac2__cabin_lighting",
    "Number Of Seats.Number...75" = "ac2__number_of_seats_number",
    "Passengers On Board.Number...76" = "ac2__passengers_on_board_number",
    "Crew Size Flight Attendant.Number Of Crew...77" =
      "ac2__crew_size_flight_attendant_number_of_crew",
    "Airspace Authorization Provider (UAS)...78" =
      "ac2__airspace_authorization_provider_uas",
    "Operating Under Waivers / Exemptions / Authorizations (UAS)...79" =
      "ac2__operating_under_waivers_exemptions_authorizations_uas",
    "Waivers / Exemptions / Authorizations (UAS)...80" =
      "ac2__waivers_exemptions_authorizations_uas",
    "Airworthiness Certification (UAS)...81" =
      "ac2__airworthiness_certification_uas",
    "Weight Category (UAS)...82" = "ac2__weight_category_uas",
    "Configuration (UAS)...83" = "ac2__configuration_uas",
    "Flight Operated As (UAS)...84" = "ac2__flight_operated_as_uas",
    "Flight Operated with Visual Observer (UAS)...85" =
      "ac2__flight_operated_with_visual_observer_uas",
    "Control Mode (UAS)...86" = "ac2__control_mode_uas",
    "Flying In / Near / Over (UAS)...87" = "ac2__flying_in_near_over_uas",
    "Passenger Capable (UAS)...88" = "ac2__passenger_capable_uas",
    "Type (UAS)...89" = "ac2__type_uas",
    "Number of UAS Being Controlled (UAS)...90" =
      "ac2__number_of_uas_being_controlled_uas",
    "Location Of Person...91" = "person1__location_of_person",
    "Location In Aircraft...92" = "person1__location_in_aircraft",
    "Reporter Organization...93" = "person1__reporter_organization",
    "Function...94" = "person1__function",
    "Qualification...95" = "person1__qualification",
    "Experience...96" = "person1__experience",
    "Cabin Activity...97" = "person1__cabin_activity",
    "Human Factors...98" = "person1__human_factors",
    "Communication Breakdown...99" = "person1__communication_breakdown",
    "UAS Communication Breakdown...100" =
      "person1__uas_communication_breakdown",
    "ASRS Report Number.Accession Number...101" =
      "person1__asrs_report_number_accession_number",
    "Location Of Person...102" = "person2__location_of_person",
    "Location In Aircraft...103" = "person2__location_in_aircraft",
    "Reporter Organization...104" = "person2__reporter_organization",
    "Function...105" = "person2__function",
    "Qualification...106" = "person2__qualification",
    "Experience...107" = "person2__experience",
    "Cabin Activity...108" = "person2__cabin_activity",
    "Human Factors...109" = "person2__human_factors",
    "Communication Breakdown...110" = "person2__communication_breakdown",
    "UAS Communication Breakdown...111" =
      "person2__uas_communication_breakdown",
    "ASRS Report Number.Accession Number...112" =
      "person2__asrs_report_number_accession_number",
    "Anomaly" = "events__anomaly",
    "Miss Distance" = "events__miss_distance",
    "Were Passengers Involved In Event" =
      "events__were_passengers_involved_in_event",
    "Detector" = "events__detector",
    "When Detected" = "events__when_detected",
    "Result" = "events__result",
    "Contributing Factors / Situations" =
      "assessments__contributing_factors_situations",
    "Primary Problem" = "assessments__primary_problem",
    "Narrative...121" = "report1__narrative",
    "Callback...122" = "report1__callback",
    "Narrative...123" = "report2__narrative",
    "Callback...124" = "report2__callback",
    "Synopsis" = "report1__synopsis"
  )

  read_csv(
    path,
    skip = 1,
    col_types = cols(.default = col_character()),
    show_col_types = FALSE
  ) |>
    rename(!!!set_names(names(rename_map), rename_map)) |>
    select(all_of(unname(rename_map))) |>
    mutate(
      time__date = ym(time__date),
      across(
        all_of(asrs_integer_cols),
        ~ parse_integer(.x, na = c("", NA_character_))
      ),
      across(
        all_of(asrs_double_cols),
        ~ parse_double(.x, na = c("", NA_character_))
      ),
      across(all_of(asrs_logical_cols), parse_logical_yn)
    )
}
