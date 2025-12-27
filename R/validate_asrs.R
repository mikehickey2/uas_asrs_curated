# Validate ASRS data frame
# Runs structural, type, categorical, range, prefix, and format checks.
source("R/validation_helpers.R")
source("R/asrs_schema.R")

type_check <- function(df, cols, class, label) {
  if (is.null(cols) || length(cols) == 0) {
    return(validation_result(label, TRUE, "No columns to check"))
  }
  missing <- setdiff(cols, names(df))
  remaining <- setdiff(cols, missing)
  bad_class <- purrr::discard(remaining, ~ inherits(df[[.x]], class))
  ok <- length(missing) == 0 && length(bad_class) == 0
  msg <- if (ok) {
    glue::glue("{label} types ok")
  } else {
    glue::glue(
      "Missing: {paste(missing, collapse = ', ')}; ",
      "Wrong type: {paste(bad_class, collapse = ', ')}"
    )
  }
  validation_result(label, ok, msg)
}

check_multi_value_format <- function(df, cols) {
  purrr::map_dfr(cols, function(col) {
    if (!col %in% names(df)) {
      return(validation_result(col, FALSE, "column missing"))
    }
    vals <- df[[col]]
    pattern <- "^([^;]+)(; [^;]+)*$"
    bad <- vals[!is.na(vals) & !stringr::str_detect(vals, pattern)]
    ok <- length(bad) == 0
    msg <- if (ok) "Semicolon-delimited format ok" else
      glue::glue("{length(bad)} values not in semicolon format")
    validation_result(col, ok, msg)
  })
}

#' Validate an ASRS data frame
#' @export
validate_asrs <- function(
  df,
  expected_names = asrs_expected_cols,
  integer_cols = asrs_integer_cols,
  double_cols = asrs_double_cols,
  logical_cols = asrs_logical_cols,
  valid_values = asrs_valid_values,
  strict = FALSE
) {
  checkmate::assert_data_frame(df)
  range_bounds <- asrs_range_bounds
  multi_value_cols <- asrs_multi_value_cols

  results <- dplyr::bind_rows(
    validation_result(
      "row_count",
      nrow(df) > 0,
      glue::glue("Row count: {nrow(df)}")
    ),
    check_column_count(df, length(expected_names), expected_names),
    check_acn_unique(df),
    check_entity_prefixes(df, asrs_entity_prefixes),
    type_check(df, integer_cols, "integer", "integer_cols"),
    type_check(df, double_cols, "numeric", "double_cols"),
    type_check(df, logical_cols, "logical", "logical_cols"),
    type_check(
      df,
      setdiff(
        expected_names,
        c(integer_cols, double_cols, logical_cols, "acn", "time__date")
      ),
      "character",
      "character_cols"
    ),
    type_check(df, "time__date", "Date", "time__date"),
    check_categorical_values(df, valid_values),
    check_numeric_range(df, range_bounds),
    check_date_range(df, "time__date", as.Date("1976-01-01"), Sys.Date()),
    check_multi_value_format(df, multi_value_cols)
  )

  bad <- results |> dplyr::filter(!ok)
  if (nrow(bad) > 0) {
    msg <- glue::glue("ASRS validation: {nrow(bad)} issues")
    if (strict) rlang::abort(msg, results = bad) else rlang::warn(msg, results = bad)
  } else {
    rlang::inform("ASRS validation: all checks passed")
  }
  invisible(df)
}
