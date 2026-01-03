# Data integrity functions for raw ASRS data
#
# Provides SHA-256 hash verification, file locking, and manifest creation
# for reproducibility and data provenance tracking.

source("R/paths.R")

#' Compute SHA-256 hash of a file
#'
#' @param path Path to file. Defaults to PATHS$raw_csv.
#' @return Character string containing 64-character hex SHA-256 hash.
#' @export
compute_raw_hash <- function(path = PATHS$raw_csv) {
  checkmate::assert_file_exists(path, access = "r")
  digest::digest(file = path, algo = "sha256")
}

#' Verify file integrity against expected hash
#'
#' @param expected_hash Character string containing expected SHA-256 hash.
#' @param path Path to file. Defaults to PATHS$raw_csv.
#' @return TRUE invisibly if verification passes.
#' @export
verify_raw_integrity <- function(expected_hash, path = PATHS$raw_csv) {
  checkmate::assert_string(expected_hash, pattern = "^[a-f0-9]{64}$")
  checkmate::assert_file_exists(path, access = "r")

  actual_hash <- compute_raw_hash(path)

  if (actual_hash != expected_hash) {
    rlang::abort(
      c(
        "Data integrity check failed",
        x = glue::glue("Expected: {expected_hash}"),
        x = glue::glue("Actual:   {actual_hash}"),
        i = glue::glue("File: {path}")
      ),
      class = "integrity_error"
    )
  }

  rlang::inform(
    c(
      "v" = "Data integrity verified",
      i = glue::glue("Hash: {actual_hash}")
    )
  )
  invisible(TRUE)
}

#' Lock raw data file (read-only)
#'
#' Sets file permissions to 444 (read-only for all) on Unix systems.
#' Issues a warning on Windows where chmod is not fully supported.
#'
#' @param path Path to file. Defaults to PATHS$raw_csv.
#' @return TRUE invisibly if successful.
#' @export
lock_raw_data <- function(path = PATHS$raw_csv) {
  checkmate::assert_file_exists(path)

  if (.Platform$OS.type == "windows") {
    rlang::warn(
      c(
        "File locking not fully supported on Windows",
        i = "Consider using file system permissions manually"
      )
    )
    return(invisible(FALSE))
  }

  Sys.chmod(path, mode = "0444")
  rlang::inform(c("v" = glue::glue("Locked: {path} (mode 444)")))
  invisible(TRUE)
}

#' Unlock raw data file (read-write)
#'
#' Sets file permissions to 644 (owner read-write, others read) on Unix.
#' Issues a warning on Windows where chmod is not fully supported.
#'
#' @param path Path to file. Defaults to PATHS$raw_csv.
#' @return TRUE invisibly if successful.
#' @export
unlock_raw_data <- function(path = PATHS$raw_csv) {
  checkmate::assert_file_exists(path)

  if (.Platform$OS.type == "windows") {
    rlang::warn(
      c(
        "File unlocking not fully supported on Windows",
        i = "Consider using file system permissions manually"
      )
    )
    return(invisible(FALSE))
  }

  Sys.chmod(path, mode = "0644")
  rlang::inform(c("v" = glue::glue("Unlocked: {path} (mode 644)")))
  invisible(TRUE)
}

#' Create data manifest JSON
#'
#' Generates a JSON manifest containing file metadata, hash, and data summary
#' for provenance tracking and reproducibility.
#'
#' @param path Path to raw data file. Defaults to PATHS$raw_csv.
#' @param output_path Path for manifest JSON. Defaults to "data/data_manifest.json".
#' @param fetch_date Date when data was fetched from source (character YYYY-MM-DD).
#' @return List containing manifest data, invisibly.
#' @export
create_manifest <- function(path = PATHS$raw_csv,
                            output_path = "data/data_manifest.json",
                            fetch_date = NULL) {
  checkmate::assert_file_exists(path, access = "r")
  checkmate::assert_string(output_path)
  checkmate::assert_string(fetch_date, pattern = "^\\d{4}-\\d{2}-\\d{2}$",
                           null.ok = TRUE)

  file_info <- file.info(path)
  hash <- compute_raw_hash(path)

  data <- readr::read_csv(
    path,
    skip = 1,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  date_col <- data[["Date"]]
  date_range <- if (!is.null(date_col) && any(!is.na(date_col))) {
    dates <- date_col[!is.na(date_col)]
    list(earliest = min(dates), latest = max(dates))
  } else {
    list(earliest = NA_character_, latest = NA_character_)
  }

  file_mode <- if (.Platform$OS.type != "windows") {
    as.character(file_info$mode)
  } else {
    NA_character_
  }
  is_locked <- identical(file_mode, "444")

  manifest <- list(
    schema_version = "1.0",
    generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    generated_by = "uas_asrs_curated/R/data_integrity.R",
    source = list(
      name = "NASA Aviation Safety Reporting System (ASRS)",
      url = "https://asrs.arc.nasa.gov",
      fetch_date = fetch_date %||% NA_character_,
      fetch_method = "manual_csv_export",
      curation_notes = "UAS/drone encounter filter applied by NASA ASRS staff"
    ),
    raw_file = list(
      name = basename(path),
      hash_sha256 = hash,
      size_bytes = as.integer(file_info$size),
      modified_at = format(file_info$mtime, "%Y-%m-%dT%H:%M:%S%z")
    ),
    data_summary = list(
      record_count = nrow(data),
      column_count = ncol(data),
      date_range = date_range
    ),
    integrity = list(
      locked = is_locked,
      verification_command = glue::glue(
        "source('R/data_integrity.R'); verify_raw_integrity('{hash}')"
      )
    )
  )

  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
  jsonlite::write_json(manifest, output_path, pretty = TRUE, auto_unbox = TRUE)

  rlang::inform(
    c(
      "v" = glue::glue("Manifest created: {output_path}"),
      i = glue::glue("Records: {manifest$data_summary$record_count}"),
      i = glue::glue("Hash: {hash}")
    )
  )

  invisible(manifest)
}

#' Read data manifest JSON
#'
#' Reads a manifest file and optionally verifies the raw data hash matches.
#'
#' @param manifest_path Path to manifest JSON file.
#' @param verify Logical; if TRUE, verify hash against raw file. Default TRUE.
#' @return List containing manifest data.
#' @export
read_manifest <- function(manifest_path = "data/data_manifest.json",
                          verify = TRUE) {
  checkmate::assert_file_exists(manifest_path, access = "r")
  checkmate::assert_flag(verify)

  manifest <- jsonlite::read_json(manifest_path)

  if (verify) {
    raw_path <- file.path(
      dirname(manifest_path),
      manifest$raw_file$name
    )
    verify_raw_integrity(manifest$raw_file$hash_sha256, raw_path)
  }

  manifest
}
