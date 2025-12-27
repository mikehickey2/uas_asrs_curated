options(cli.default_handler = function(...) {})
library(dplyr)
library(purrr)
library(checkmate)
library(withr)

find_root <- function() {
  cur <- normalizePath(getwd())
  repeat {
    candidate <- file.path(cur, "R", "asrs_schema.R")
    if (file.exists(candidate)) return(cur)
    parent <- dirname(cur)
    if (parent == cur) stop("Project root not found")
    cur <- parent
  }
}

root_dir <- find_root()
withr::local_dir(root_dir, .local_envir = parent.frame())

source("R/asrs_schema.R")
source("R/import_asrs.R")
source("R/validation_helpers.R")
source("R/validate_asrs.R")
source("R/validate_asrs_assertr.R")

testthat::local_edition(3)

test_data <- import_asrs(
  file.path(root_dir, "data", "asrs_curated_drone_reports.csv")
)
