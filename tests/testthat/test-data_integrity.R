raw_csv_path <- file.path(root_dir, PATHS$raw_csv)

test_that("compute_raw_hash returns 64-character hex string", {
  hash <- compute_raw_hash(raw_csv_path)
  expect_type(hash, "character")
  expect_match(hash, "^[a-f0-9]{64}$")
})

test_that("compute_raw_hash is deterministic", {
  hash1 <- compute_raw_hash(raw_csv_path)
  hash2 <- compute_raw_hash(raw_csv_path)
  expect_identical(hash1, hash2)
})

test_that("verify_raw_integrity passes with correct hash", {
  expected <- compute_raw_hash(raw_csv_path)
  expect_true(verify_raw_integrity(expected, raw_csv_path))
})

test_that("verify_raw_integrity aborts with incorrect hash", {
  bad_hash <- paste0(rep("0", 64), collapse = "")
  expect_error(
    verify_raw_integrity(bad_hash, raw_csv_path),
    class = "integrity_error"
  )
})

test_that("verify_raw_integrity rejects malformed hash", {
  expect_error(verify_raw_integrity("not-a-hash"))
  expect_error(verify_raw_integrity("abc123"))
})

test_that("create_manifest produces valid JSON with required fields", {
  tmp_manifest <- withr::local_tempfile(fileext = ".json")

  manifest <- create_manifest(
    path = raw_csv_path,
    output_path = tmp_manifest,
    fetch_date = "2025-12-26"
  )

  expect_type(manifest, "list")
  expect_true(file.exists(tmp_manifest))

  json_content <- jsonlite::read_json(tmp_manifest)

  expect_equal(json_content$schema_version, "1.0")
  expect_true(!is.null(json_content$generated_at))
  expect_equal(json_content$generated_by, "uas_asrs_curated/R/data_integrity.R")

  expect_equal(
    json_content$source$name,
    "NASA Aviation Safety Reporting System (ASRS)"
  )
  expect_equal(json_content$source$url, "https://asrs.arc.nasa.gov")
  expect_equal(json_content$source$fetch_date, "2025-12-26")

  expect_equal(json_content$raw_file$name, basename(PATHS$raw_csv))
  expect_match(json_content$raw_file$hash_sha256, "^[a-f0-9]{64}$")
  expect_type(json_content$raw_file$size_bytes, "integer")

  expect_type(json_content$data_summary$record_count, "integer")
  expect_type(json_content$data_summary$column_count, "integer")
  expect_true(!is.null(json_content$data_summary$date_range))

  expect_type(json_content$integrity$locked, "logical")
  expect_type(json_content$integrity$verification_command, "character")
})

test_that("read_manifest reads and verifies correctly", {
  tmp_manifest <- withr::local_tempfile(fileext = ".json")

  create_manifest(
    path = raw_csv_path,
    output_path = tmp_manifest,
    fetch_date = "2025-12-26"
  )

  expect_type(jsonlite::read_json(tmp_manifest), "list")
})

test_that("read_manifest fails on corrupted hash", {
  tmp_dir <- withr::local_tempdir()
  tmp_csv <- file.path(tmp_dir, basename(PATHS$raw_csv))
  tmp_manifest <- file.path(tmp_dir, "data_manifest.json")

  file.copy(raw_csv_path, tmp_csv)

  create_manifest(
    path = tmp_csv,
    output_path = tmp_manifest
  )

  manifest_data <- jsonlite::read_json(tmp_manifest)
  manifest_data$raw_file$hash_sha256 <- paste0(rep("0", 64), collapse = "")
  jsonlite::write_json(
    manifest_data,
    tmp_manifest,
    pretty = TRUE,
    auto_unbox = TRUE
  )

  expect_error(
    read_manifest(tmp_manifest, verify = TRUE),
    class = "integrity_error"
  )
})

test_that("file locking works on Unix", {
  skip_on_os("windows")

  tmp_file <- withr::local_tempfile()
  writeLines("test content", tmp_file)

  lock_raw_data(tmp_file)
  mode_locked <- as.character(file.info(tmp_file)$mode)
  expect_equal(mode_locked, "444")

  unlock_raw_data(tmp_file)
  mode_unlocked <- as.character(file.info(tmp_file)$mode)
  expect_equal(mode_unlocked, "644")
})

test_that("file locking warns on Windows", {
  skip_on_os(c("mac", "linux", "solaris"))

  tmp_file <- withr::local_tempfile()
  writeLines("test content", tmp_file)

  expect_warning(lock_raw_data(tmp_file), "not fully supported")
  expect_warning(unlock_raw_data(tmp_file), "not fully supported")
})
