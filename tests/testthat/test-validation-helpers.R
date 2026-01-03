test_that("format_acn_list returns empty string when no acn column", {
  df <- data.frame(x = 1:3)
  expect_equal(format_acn_list(df, c(TRUE, FALSE, FALSE)), "")
})

test_that("format_acn_list returns empty string when no bad rows", {
  df <- data.frame(acn = c(100, 200, 300))
  expect_equal(format_acn_list(df, c(FALSE, FALSE, FALSE)), "")
})

test_that("format_acn_list formats single ACN correctly", {
  df <- data.frame(acn = c(100, 200, 300))
  result <- format_acn_list(df, c(FALSE, TRUE, FALSE))
  expect_equal(result, "(ACN: 200)")
})

test_that("format_acn_list formats multiple ACNs correctly", {
  df <- data.frame(acn = c(100, 200, 300))
  result <- format_acn_list(df, c(TRUE, FALSE, TRUE))
  expect_equal(result, "(ACN: 100, 300)")
})

test_that("format_acn_list truncates at max_show with suffix", {
  df <- data.frame(acn = c(100, 200, 300, 400, 500, 600, 700, 800))
  result <- format_acn_list(df, rep(TRUE, 8), max_show = 5)
  expect_equal(result, "(ACN: 100, 200, 300, 400, 500, ... and 3 more)")
})

test_that("format_acn_list respects custom max_show", {
  df <- data.frame(acn = c(100, 200, 300, 400, 500))
  result <- format_acn_list(df, rep(TRUE, 5), max_show = 2)
  expect_equal(result, "(ACN: 100, 200, ... and 3 more)")
})

test_that("format_acn_list works with integer indices", {
  df <- data.frame(acn = c(100, 200, 300, 400))
  result <- format_acn_list(df, c(2, 4))
  expect_equal(result, "(ACN: 200, 400)")
})

test_that("format_acn_list handles NA values in acn column", {
  df <- data.frame(acn = c(100, NA, 300))
  result <- format_acn_list(df, c(TRUE, TRUE, TRUE))
  expect_equal(result, "(ACN: 100, 300)")
})

test_that("format_acn_list handles NA values in row_indices", {
  df <- data.frame(acn = c(100, 200, 300))
  result <- format_acn_list(df, c(TRUE, NA, TRUE))
  expect_equal(result, "(ACN: 100, 300)")
})

test_that("format_acn_list shows all when count equals max_show", {
  df <- data.frame(acn = c(100, 200, 300, 400, 500))
  result <- format_acn_list(df, rep(TRUE, 5), max_show = 5)
  expect_equal(result, "(ACN: 100, 200, 300, 400, 500)")
})
