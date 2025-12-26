source("R/import_asrs.R")

asrs_uas_reports <- import_asrs("data/asrs_curated_drone_reports.csv")
readr::write_csv(asrs_uas_reports, "output/asrs_uas_reports_clean.csv")
