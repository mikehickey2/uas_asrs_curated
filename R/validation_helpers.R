# Validation helper functions for ASRS imports
# Helpers return a tibble with `check`, `ok`, and `message` columns.

validation_result <- function(check, ok, message) {
  tibble::tibble(check = check, ok = ok, message = message)
}

#' Format a list of ACN values for error messages
#'
#' Returns a compact string representation of ACN values for rows that failed
#' validation. Truncates to max_show values with "and N more" suffix.
#'
#' @param df Data frame containing an `acn` column.
#' @param row_indices Logical or integer vector identifying rows with issues.
#' @param max_show Maximum number of ACNs to display before truncating.
#' @return Character string like "ACN: 123, 456, 789" or
#'   "ACN: 123, 456, ... and 3 more".
#' @export
format_acn_list <- function(df, row_indices, max_show = 5) {
  checkmate::assert_data_frame(df)
  checkmate::assert_int(max_show, lower = 1)

  if (!"acn" %in% names(df)) {
    return("")
  }

  if (is.logical(row_indices)) {
    row_indices[is.na(row_indices)] <- FALSE
    acns <- df$acn[row_indices]
  } else {
    checkmate::assert_integerish(row_indices, lower = 1, upper = nrow(df))
    acns <- df$acn[row_indices]
  }

  acns <- acns[!is.na(acns)]
  n_total <- length(acns)

  if (n_total == 0) {
    return("")
  }

  if (n_total <= max_show) {
    return(paste0("(ACN: ", paste(acns, collapse = ", "), ")"))
  }

  shown <- acns[seq_len(max_show)]
  remaining <- n_total - max_show
  paste0(
    "(ACN: ", paste(shown, collapse = ", "),
    ", ... and ", remaining, " more)"
  )
}

#' Check column count and required names
#'
#' Validates that a data frame has the expected number of columns and
#' optionally checks that all required column names are present.
#'
#' @param df A data frame to validate.
#' @param expected_count Integer, the expected number of columns.
#' @param required_names Optional character vector of column names that must
#'   be present.
#' @return A tibble with columns `check`, `ok`, and `message`.
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
#'
#' Validates that all values in the `acn` column are unique (no duplicates).
#'
#' @param df A data frame containing an `acn` column.
#' @return A tibble with columns `check`, `ok`, and `message`.
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
#'
#' Validates that all column names (except `acn`) use approved entity prefixes
#' with double-underscore separator (e.g., `ac1__`, `events__`).
#'
#' @param df A data frame to validate.
#' @param prefixes Character vector of allowed entity prefixes.
#' @return A tibble with columns `check`, `ok`, and `message`.
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

#' Check categorical values
#'
#' Validates that categorical columns contain only allowed values. Handles
#' semicolon-delimited multi-value fields by splitting and checking each part.
#'
#' @param df A data frame to validate.
#' @param valid_values Named list where names are column names and values are
#'   character vectors of allowed values.
#' @return A tibble with columns `check`, `ok`, and `message` (one row per
#'   column checked).
#' @export
check_categorical_values <- function(df, valid_values) {
  checkmate::assert_data_frame(df)
  checkmate::assert_list(valid_values, types = "character", names = "unique")
  purrr::map_dfr(names(valid_values), function(col) {
    if (!col %in% names(df)) {
      return(validation_result(col, FALSE, "column missing"))
    }
    allowed <- c(valid_values[[col]], NA_character_)
    is_bad_row <- purrr::map_lgl(df[[col]], function(x) {
      if (is.na(x)) return(FALSE)
      parts <- stringr::str_split(x, ";\\s*")[[1]]
      !all(parts %in% allowed)
    })
    n_bad <- sum(is_bad_row)
    ok <- n_bad == 0
    if (ok) {
      msg <- "Values within allowed set"
    } else {
      bad_values <- unique(df[[col]][is_bad_row])
      acn_suffix <- format_acn_list(df, is_bad_row)
      msg <- glue::glue(
        "Invalid values: {paste(bad_values, collapse = ', ')} {acn_suffix}"
      )
    }
    validation_result(col, ok, msg)
  })
}

#' Check numeric ranges
#'
#' Validates that numeric columns have values within specified bounds.
#' NA values are ignored.
#'
#' @param df A data frame to validate.
#' @param ranges Named list where names are column names and values are
#'   two-element lists of (min, max) bounds.
#' @return A tibble with columns `check`, `ok`, and `message` (one row per
#'   column checked).
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
    is_bad_row <- (too_low | too_high) & !is.na(vals)
    n_bad <- sum(is_bad_row)
    ok <- n_bad == 0
    if (ok) {
      msg <- "Values within range"
    } else {
      acn_suffix <- format_acn_list(df, is_bad_row)
      msg <- glue::glue(
        "{n_bad} values outside [{bounds[[1]]}, {bounds[[2]]}] {acn_suffix}"
      )
    }
    validation_result(col, ok, msg)
  })
}

#' Check date range
#'
#' Validates that a Date column has values within specified bounds.
#' NA values are ignored.
#'
#' @param df A data frame to validate.
#' @param column Character string naming the date column to check.
#' @param min_date Date object for the minimum allowed date.
#' @param max_date Date object for the maximum allowed date.
#' @return A tibble with columns `check`, `ok`, and `message`.
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
