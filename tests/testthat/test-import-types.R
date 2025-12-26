test_that("key columns have expected types", {
  expect_type(test_data$acn, "character")
  expect_s3_class(test_data$time__date, "Date")
})

test_that("integer, double, logical columns conform", {
  expect_true(all(purrr::map_lgl(
    asrs_integer_cols,
    ~ is.integer(test_data[[.x]]) || all(is.na(test_data[[.x]]))
  )))
  expect_true(all(purrr::map_lgl(
    asrs_double_cols,
    ~ is.numeric(test_data[[.x]]) || all(is.na(test_data[[.x]]))
  )))
  expect_true(all(purrr::map_lgl(
    asrs_logical_cols,
    ~ is.logical(test_data[[.x]]) || all(is.na(test_data[[.x]]))
  )))
})
