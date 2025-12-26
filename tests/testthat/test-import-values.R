test_that("categorical values are within allowed sets", {
  cat_res <- check_categorical_values(test_data, asrs_valid_values)
  expect_true(all(cat_res$ok))
})

test_that("numeric and date ranges are valid", {
  range_res <- check_numeric_range(test_data, asrs_range_bounds)
  expect_true(all(range_res$ok))
  date_res <- check_date_range(
    test_data,
    "time__date",
    as.Date("1976-01-01"),
    Sys.Date()
  )
  expect_true(all(date_res$ok))
})

test_that("no literal NA strings remain", {
  char_cols <- names(test_data)[sapply(test_data, is.character)]
  na_strings <- sapply(char_cols, function(col) {
    any(test_data[[col]] == "NA", na.rm = TRUE)
  })
  expect_false(any(na_strings))
})

test_that("multi-value fields are semicolon-delimited", {
  pattern <- "^([^;]+)(; [^;]+)*$"
  ok <- purrr::map_lgl(asrs_multi_value_cols, function(col) {
    vals <- test_data[[col]]
    all(is.na(vals) | grepl(pattern, vals))
  })
  expect_true(all(ok))
})

test_that("assertr pipeline passes", {
  expect_s3_class(validate_asrs_pipeline(test_data), "data.frame")
})

test_that("edge cases: empty and single-row", {
  empty_df <- test_data[0, ]
  expect_error(validate_asrs(empty_df, strict = TRUE))
  single_df <- head(test_data, 1)
  expect_s3_class(validate_asrs(single_df, strict = FALSE), "data.frame")
})
