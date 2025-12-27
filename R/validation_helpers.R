# Validation helper functions for ASRS imports
# Helpers return a tibble with `check`, `ok`, and `message` columns.

validation_result <- function(check, ok, message) {
  tibble::tibble(check = check, ok = ok, message = message)
}

#' Check column count and required names
#' @export
check_column_count <- function(df, expected_count, required_names = NULL) {
  checkmate::assert_data_frame(df)
  checkmate::assert_int(expected_count, lower = 1)
  if (!is.null(required_names)) {
    checkmate::assert_character(required_names, any.missing = FALSE, unique = TRUE)
  }
  count_ok <- ncol(df) == expected_count
  missing <- if (is.null(required_names)) character(0) else
    setdiff(required_names, names(df))
  names_ok <- length(missing) == 0
  msg <- if (count_ok && names_ok) {
    glue::glue(
      "Column count {ncol(df)} matches expected {expected_count}"
    )
  } else {
    glue::glue(
      "Expected {expected_count} cols, found {ncol(df)}; ",
      "missing: {paste(missing, collapse = ', ')}"
    )
  }
  validation_result("column_count", count_ok && names_ok, msg)
}

#' Check ACN uniqueness
#' @export
check_acn_unique <- function(df) {
  checkmate::assert_data_frame(df)
  if (!"acn" %in% names(df)) {
    return(validation_result("acn_unique", FALSE, "acn column missing"))
  }
  total <- nrow(df)
  distinct <- dplyr::n_distinct(df$acn)
  ok <- total == distinct
  msg <- if (ok) {
    "acn values are unique"
  } else {
    glue::glue("acn not unique: {total - distinct} duplicates")
  }
  validation_result("acn_unique", ok, msg)
}

#' Check entity prefixes
#' @export
check_entity_prefixes <- function(df, prefixes) {
  checkmate::assert_data_frame(df)
  checkmate::assert_character(prefixes, any.missing = FALSE, unique = TRUE)
  allowed <- paste0(prefixes, "__")
  cols <- setdiff(names(df), "acn")
  bad <- cols[!purrr::map_lgl(
    cols,
    ~ any(stringr::str_starts(.x, allowed))
  )]
  ok <- length(bad) == 0
  msg <- if (ok) "All columns use approved prefixes" else
    glue::glue("Bad prefixes: {paste(bad, collapse = ', ')}")
  validation_result("entity_prefixes", ok, msg)
}

#' Check categorical values (handles multi-value splits)
#' @export
check_categorical_values <- function(df, valid_values) {
  checkmate::assert_data_frame(df)
  checkmate::assert_list(valid_values, types = "character", names = "unique")
  purrr::map_dfr(names(valid_values), function(col) {
    if (!col %in% names(df)) {
      return(validation_result(col, FALSE, "column missing"))
    }
    allowed <- c(valid_values[[col]], NA_character_)
    actual <- unique(df[[col]])
    bad <- purrr::discard(actual, is.na) |>
      purrr::discard(function(x) {
        parts <- stringr::str_split(x, ";\\s*")[[1]]
        all(parts %in% allowed)
      })
    ok <- length(bad) == 0
    msg <- if (ok) "Values within allowed set" else glue::glue(
      "Invalid values: {paste(bad, collapse = ', ')}"
    )
    validation_result(col, ok, msg)
  })
}

#' Check numeric ranges
#' @export
check_numeric_range <- function(df, ranges) {
  checkmate::assert_data_frame(df)
  checkmate::assert_list(ranges, names = "unique")
  purrr::map_dfr(names(ranges), function(col) {
    if (!col %in% names(df)) {
      return(validation_result(col, FALSE, "column missing"))
    }
    bounds <- ranges[[col]]
    checkmate::assert_list(bounds, types = "numeric", any.missing = FALSE, len = 2)
    vals <- df[[col]]
    if (!is.numeric(vals)) {
      return(validation_result(col, FALSE, "column not numeric"))
    }
    too_low <- vals < bounds[[1]]
    too_high <- vals > bounds[[2]]
    bad <- sum(too_low | too_high, na.rm = TRUE)
    ok <- bad == 0
    msg <- if (ok) "Values within range" else
      glue::glue("{bad} values outside [{bounds[[1]]}, {bounds[[2]]}]")
    validation_result(col, ok, msg)
  })
}

#' Check date range
#' @export
check_date_range <- function(df, column, min_date, max_date) {
  checkmate::assert_data_frame(df)
  checkmate::assert_string(column)
  checkmate::assert_date(min_date)
  checkmate::assert_date(max_date)
  if (!column %in% names(df)) {
    return(validation_result(column, FALSE, "column missing"))
  }
  vals <- df[[column]]
  if (!inherits(vals, "Date")) {
    return(validation_result(column, FALSE, "column not Date class"))
  }
  too_low <- vals < min_date
  too_high <- vals > max_date
  bad <- sum(too_low | too_high, na.rm = TRUE)
  ok <- bad == 0
  msg <- if (ok) "Dates within range" else
    glue::glue("{bad} dates outside [{min_date}, {max_date}]")
  validation_result(column, ok, msg)
}
