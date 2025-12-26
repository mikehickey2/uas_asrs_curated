#' Assertr pipeline validation for ASRS data
library(dplyr)
library(assertr)
library(checkmate)
library(purrr)
source("R/asrs_schema.R")

#' Validate ASRS data with assertr
#'
#' @param df Data frame produced by import_data.R.
#' @return Data frame invisibly.
#' @export
validate_asrs_pipeline <- function(df) {
  assert_data_frame(df)
  logical_cols <- asrs_logical_cols
  integer_cols <- asrs_integer_cols
  double_cols <- asrs_double_cols
  df_ref <- df

  df %>%
    verify(ncol(.) == length(asrs_expected_cols)) %>%
    verify(nrow(.) > 0) %>%
    verify(all(c("acn", "time__date") %in% names(.))) %>%
    verify(n_distinct(acn) == nrow(.)) %>%
    verify(with(., all(!is.na(time__date)))) %>%
    verify(with(., all(
      time__date >= as.Date("1976-01-01") &
        time__date <= Sys.Date()
    ))) %>%
    verify(with(., all(
      place__relative_position_angle_radial >= 0 &
        place__relative_position_angle_radial <= 360 |
        is.na(place__relative_position_angle_radial)
    ))) %>%
    verify(with(., all(
      place__altitude_agl_single_value >= 0 |
        is.na(place__altitude_agl_single_value)
    ))) %>%
    verify(with(., all(
      place__altitude_msl_single_value >= -1500 |
        is.na(place__altitude_msl_single_value)
    ))) %>%
    verify({
      all(purrr::map_lgl(logical_cols, function(col) {
        is.logical(df_ref[[col]]) || all(is.na(df_ref[[col]]))
      }))
    }) %>%
    verify({
      all(purrr::map_lgl(integer_cols, function(col) {
        is.integer(df_ref[[col]]) || all(is.na(df_ref[[col]]))
      }))
    }) %>%
    verify({
      all(purrr::map_lgl(double_cols, function(col) {
        is.numeric(df_ref[[col]]) || all(is.na(df_ref[[col]]))
      }))
    }) %>%
    invisible()
}
