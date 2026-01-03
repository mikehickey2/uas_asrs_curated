source("R/paths.R")
source("R/import_asrs.R")
source("R/data_integrity.R")

manifest_path <- "data/data_manifest.json"

if (file.exists(manifest_path)) {
  rlang::inform(c("i" = "Verifying raw data integrity before import..."))
  manifest <- read_manifest(manifest_path, verify = TRUE)
}

asrs_uas_reports <- import_asrs(PATHS$raw_csv)
readr::write_csv(asrs_uas_reports, PATHS$curated_csv)

lock_raw_data(PATHS$raw_csv)

create_manifest(
  path = PATHS$raw_csv,
  output_path = manifest_path,
  fetch_date = "2025-12-26"
)

rlang::inform(
  c(
    "v" = glue::glue("Import complete: {nrow(asrs_uas_reports)} records"),
    "i" = glue::glue("Curated CSV: {PATHS$curated_csv}")
  )
)
