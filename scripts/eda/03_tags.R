# Tag analysis script for ASRS UAS reports
# Produces tidy tag tables and co-occurrence analysis

library(dplyr)
library(tidyr)
library(stringr)
library(readr)

dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)

asrs <- readRDS("output/asrs_constructed.rds")

if ("acn" %in% names(asrs)) {
  id_col <- "acn"
} else {
  id_col <- names(asrs)[1]
  message("Using '", id_col, "' as report ID (acn not found)")
}

n_total <- nrow(asrs)

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

tag_fields <- c(
  "events__anomaly",
  "events__result",
  "assessments__contributing_factors_situations",
  "assessments__primary_problem"
)

tag_fields <- tag_fields[tag_fields %in% names(asrs)]

field_availability <- tibble(
  field = tag_fields,
  n_reports_total = n_total,
  n_reports_field_present = sapply(tag_fields, function(f) {
    sum(!is.na(asrs[[f]]) & asrs[[f]] != "")
  }),
  pct_field_present = round(n_reports_field_present / n_reports_total * 100, 1)
)

write_csv(field_availability, "output/tables/tag_field_availability_summary.csv")

build_tag_summary <- function(data, id_col, tag_col, n_total) {
  n_field_present <- sum(!is.na(data[[tag_col]]) & data[[tag_col]] != "")

  tags_long <- to_tags(data, id_col, tag_col)

  if (nrow(tags_long) == 0) {
    return(tibble(
      tag = character(),
      n_reports_with_tag = integer(),
      n_reports_total = integer(),
      n_reports_field_present = integer(),
      pct_of_all_reports = numeric(),
      pct_of_reports_with_field_present = numeric()
    ))
  }

  tags_long |>
    count(tag, name = "n_reports_with_tag") |>
    mutate(
      n_reports_total = n_total,
      n_reports_field_present = n_field_present,
      pct_of_all_reports = round(n_reports_with_tag / n_total * 100, 1),
      pct_of_reports_with_field_present = round(
        n_reports_with_tag / n_field_present * 100, 1
      )
    ) |>
    arrange(desc(n_reports_with_tag)) |>
    select(
      tag,
      n_reports_with_tag,
      n_reports_total,
      n_reports_field_present,
      pct_of_all_reports,
      pct_of_reports_with_field_present
    )
}

if ("events__anomaly" %in% tag_fields) {
  tags_anomaly <- build_tag_summary(asrs, id_col, "events__anomaly", n_total)
  write_csv(tags_anomaly, "output/tables/tags_anomaly.csv")
  cat("Written: tags_anomaly.csv (", nrow(tags_anomaly), " unique tags)\n", sep = "")
}

if ("events__result" %in% tag_fields) {
  tags_result <- build_tag_summary(asrs, id_col, "events__result", n_total)
  write_csv(tags_result, "output/tables/tags_result.csv")
  cat("Written: tags_result.csv (", nrow(tags_result), " unique tags)\n", sep = "")
}

if ("assessments__contributing_factors_situations" %in% tag_fields) {
  tags_cf <- build_tag_summary(
    asrs, id_col,
    "assessments__contributing_factors_situations",
    n_total
  )
  write_csv(tags_cf, "output/tables/tags_contributing_factors.csv")
  cat("Written: tags_contributing_factors.csv (", nrow(tags_cf),
      " unique tags)\n", sep = "")
}

if ("assessments__primary_problem" %in% tag_fields) {
  tags_pp <- build_tag_summary(
    asrs, id_col,
    "assessments__primary_problem",
    n_total
  )
  write_csv(tags_pp, "output/tables/tags_primary_problem.csv")
  cat("Written: tags_primary_problem.csv (", nrow(tags_pp),
      " unique tags)\n", sep = "")
}

cf_col <- "assessments__contributing_factors_situations"

if (cf_col %in% names(asrs)) {
  cf_long <- to_tags(asrs, id_col, cf_col)

  if (nrow(cf_long) < 2) {
    cat("Contributing factors field too sparse for co-occurrence analysis\n")
    write_csv(
      tibble(tag1 = character(), tag2 = character(),
             n_reports = integer(), pct_of_all_reports = numeric()),
      "output/tables/contrib_factor_pairs_top20.csv"
    )
  } else {
    pairs <- cf_long |>
      inner_join(cf_long, by = "id", relationship = "many-to-many") |>
      filter(tag.x < tag.y) |>
      rename(tag1 = tag.x, tag2 = tag.y) |>
      count(tag1, tag2, name = "n_reports") |>
      mutate(pct_of_all_reports = round(n_reports / n_total * 100, 1)) |>
      arrange(desc(n_reports)) |>
      slice_head(n = 20)

    write_csv(pairs, "output/tables/contrib_factor_pairs_top20.csv")
    cat("Written: contrib_factor_pairs_top20.csv (",
        nrow(pairs), " pairs)\n", sep = "")
  }
} else {
  cat("Contributing factors field not found - skipping co-occurrence\n")
  write_csv(
    tibble(tag1 = character(), tag2 = character(),
           n_reports = integer(), pct_of_all_reports = numeric()),
    "output/tables/contrib_factor_pairs_top20.csv"
  )
}

cat("\nTag analysis complete. Outputs written to output/tables/\n")
cat("  - tag_field_availability_summary.csv\n")
cat("  - tags_anomaly.csv\n")
cat("  - tags_result.csv\n")
cat("  - tags_contributing_factors.csv\n")
if ("assessments__primary_problem" %in% tag_fields) {
  cat("  - tags_primary_problem.csv\n")
}
cat("  - contrib_factor_pairs_top20.csv\n")
