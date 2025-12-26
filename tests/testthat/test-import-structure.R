test_that("structure is intact", {
  expect_gt(nrow(test_data), 0)
  expect_equal(ncol(test_data), length(asrs_expected_cols))
  expect_true(all(asrs_expected_cols %in% names(test_data)))
  expect_equal(dplyr::n_distinct(test_data$acn), nrow(test_data))
  expect_false("...126" %in% names(test_data))
  expect_false(any(grepl("^\\.\\.\\.\\d+$", names(test_data))))
})

test_that("entity prefixes are valid", {
  prefix_res <- check_entity_prefixes(test_data, asrs_entity_prefixes)
  expect_true(prefix_res$ok)
})
