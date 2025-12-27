source("R/paths.R")
source("R/import_asrs.R")

asrs_uas_reports <- import_asrs(PATHS$raw_csv)
readr::write_csv(asrs_uas_reports, PATHS$curated_csv)
