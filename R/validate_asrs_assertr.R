#' Assertr pipeline validation for ASRS data
#'
# nolint start: pipe_consistency_linter
# assertr::verify() requires magrittr pipe for `.` pronoun support
`%>%` <- magrittr::`%>%`
source("R/asrs_schema.R")

#' Validate ASRS data with assertr
#'
#' @param df Data frame produced by import_data.R.
#' @return Data frame invisibly.
#' @export
validate_asrs_pipeline <- function(df) {
  checkmate::assert_data_frame(df)
  logical_cols <- asrs_logical_cols
  integer_cols <- asrs_integer_cols
  double_cols <- asrs_double_cols
  df_ref <- df

  df %>%
    assertr::verify(ncol(.) == length(asrs_expected_cols)) %>%
    assertr::verify(nrow(.) > 0) %>%
    assertr::verify(all(c("acn", "time__date") %in% names(.))) %>%
    assertr::verify(dplyr::n_distinct(acn) == nrow(.)) %>%
    assertr::verify(with(., all(!is.na(time__date)))) %>%
    assertr::verify(with(., all(
      time__date >= as.Date("1976-01-01") &
        time__date <= Sys.Date()
    ))) %>%
    assertr::verify(with(., all(
      place__relative_position_angle_radial >= 0 &
        place__relative_position_angle_radial <= 360 |
        is.na(place__relative_position_angle_radial)
    ))) %>%
    assertr::verify(with(., all(
      place__altitude_agl_single_value >= 0 |
        is.na(place__altitude_agl_single_value)
    ))) %>%
    assertr::verify(with(., all(
      place__altitude_msl_single_value >= -1500 |
        is.na(place__altitude_msl_single_value)
    ))) %>%
    assertr::verify({
      all(purrr::map_lgl(logical_cols, function(col) {
        is.logical(df_ref[[col]]) || all(is.na(df_ref[[col]]))
      }))
    }) %>%
    assertr::verify({
      all(purrr::map_lgl(integer_cols, function(col) {
        is.integer(df_ref[[col]]) || all(is.na(df_ref[[col]]))
      }))
    }) %>%
    assertr::verify({
      all(purrr::map_lgl(double_cols, function(col) {
        is.numeric(df_ref[[col]]) || all(is.na(df_ref[[col]]))
      }))
    }) %>%
    invisible()
}
# nolint end: pipe_consistency_linter
