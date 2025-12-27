# Tests for EDA tag processing
# Tests: tag uniqueness (report-level deduplication)

library(dplyr)
library(tidyr)
library(stringr)

# Replicate to_tags function from 03_tags.R
to_tags <- function(data, id_col, tag_col) {
  if (!tag_col %in% names(data)) {
    return(tibble(id = character(), tag = character()))
  }

  data |>
    select(id = all_of(id_col), tag_raw = all_of(tag_col)) |>
    filter(!is.na(tag_raw), tag_raw != "") |>
    separate_rows(tag_raw, sep = ";") |>
    mutate(tag = str_squish(tag_raw)) |>
    filter(tag != "") |>
    distinct(id, tag) |>
    select(id, tag)
}

# =============================================================================
# Tag uniqueness tests
# =============================================================================

test_that("to_tags returns unique id-tag pairs", {
  test_data <- tibble(
    report_id = c("A", "A", "B"),
    tags = c("Tag1; Tag2; Tag1", "Tag1; Tag3", "Tag2")
  )

  result <- to_tags(test_data, "report_id", "tags")

  expect_equal(nrow(result), 4)

  report_a <- result |> filter(id == "A")
  expect_equal(nrow(report_a), 3)
  expect_setequal(report_a$tag, c("Tag1", "Tag2", "Tag3"))
})

test_that("to_tags handles empty and NA values", {
  test_data <- tibble(
    report_id = c("A", "B", "C"),
    tags = c("Tag1", NA_character_, "")
  )

  result <- to_tags(test_data, "report_id", "tags")

  expect_equal(nrow(result), 1)
  expect_equal(result$id, "A")
  expect_equal(result$tag, "Tag1")
})

test_that("to_tags handles missing column gracefully", {
  test_data <- tibble(
    report_id = c("A", "B"),
    other_col = c("x", "y")
  )

  result <- to_tags(test_data, "report_id", "nonexistent_col")

  expect_equal(nrow(result), 0)
  expect_equal(names(result), c("id", "tag"))
})

test_that("to_tags trims whitespace from tags", {
  test_data <- tibble(
    report_id = c("A"),
    tags = c("  Tag1  ;  Tag2  ")
  )

  result <- to_tags(test_data, "report_id", "tags")

  expect_equal(nrow(result), 2)
  expect_setequal(result$tag, c("Tag1", "Tag2"))
})

test_that("to_tags deduplicates same tag appearing multiple times", {
  test_data <- tibble(
    report_id = c("A"),
    tags = c("NMAC; Other; NMAC; NMAC")
  )

  result <- to_tags(test_data, "report_id", "tags")

  nmac_count <- sum(result$tag == "NMAC")
  expect_equal(nmac_count, 1)
})
