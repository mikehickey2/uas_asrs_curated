# Render descriptive analysis QMD to HTML and DOCX
# Includes preflight validation and format patching

library(readr)
library(dplyr)
library(fs)
library(glue)

qmd_path <- "scripts/eda/01_descriptive_analysis.qmd"
manifest_path <- "output/notes/assets_manifest.csv"
output_dir <- normalizePath("output/reports", mustWork = FALSE)
log_path <- file.path(output_dir, "render_log.txt")

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

log_lines <- c(
  glue("Render Log"),
  glue("==========="),
  glue("Started: {Sys.time()}"),
  ""
)

log_msg <- function(msg) {
  log_lines <<- c(log_lines, msg)
  cat(msg, "\n")
}

# =============================================================================
# Preflight: verify Quarto is available
# =============================================================================

log_msg("Preflight checks:")

quarto_check <- Sys.which("quarto")
if (quarto_check == "") {
  log_msg("  ERROR: Quarto not found on PATH")
  writeLines(log_lines, log_path)
 stop("Install Quarto or ensure it's on PATH. See https://quarto.org/docs/get-started/")
}
log_msg(glue("  Quarto found: {quarto_check}"))

# =============================================================================
# Preflight: verify QMD exists
# =============================================================================

if (!file.exists(qmd_path)) {
  log_msg(glue("  ERROR: QMD not found: {qmd_path}"))
  writeLines(log_lines, log_path)
  stop(glue("QMD file not found: {qmd_path}"))
}
log_msg(glue("  QMD exists: {qmd_path}"))

# =============================================================================
# Preflight: verify all assets exist
# =============================================================================

if (!file.exists(manifest_path)) {
  log_msg(glue("  ERROR: Manifest not found: {manifest_path}"))
  writeLines(log_lines, log_path)
  stop(glue("Asset manifest not found: {manifest_path}"))
}

manifest <- read_csv(manifest_path, show_col_types = FALSE)
missing_assets <- manifest |> filter(!exists)

if (nrow(missing_assets) > 0) {
  log_msg("  ERROR: Missing assets detected:")
  for (i in seq_len(nrow(missing_assets))) {
    log_msg(glue("    - {missing_assets$path[i]}"))
  }
  writeLines(log_lines, log_path)
  stop(glue("{nrow(missing_assets)} asset(s) missing. See render_log.txt."))
}

log_msg(glue("  All {nrow(manifest)} assets verified"))

# =============================================================================
# Patch YAML to support dual formats if needed
# =============================================================================

log_msg("")
log_msg("Checking QMD format configuration:")

qmd_content <- readLines(qmd_path)
qmd_text <- paste(qmd_content, collapse = "\n")

has_docx <- grepl("docx:", qmd_text, fixed = TRUE)
has_embed <- grepl("embed-resources:", qmd_text, fixed = TRUE)

if (!has_docx || !has_embed) {
  log_msg("  Patching YAML for dual-format output...")

  yaml_start <- grep("^---$", qmd_content)[1]
  yaml_end <- grep("^---$", qmd_content)[2]

  if (is.na(yaml_start) || is.na(yaml_end)) {
    log_msg("  ERROR: Could not parse YAML frontmatter")
    writeLines(log_lines, log_path)
    stop("Could not parse YAML frontmatter in QMD")
  }

  yaml_lines <- qmd_content[(yaml_start + 1):(yaml_end - 1)]
  body_lines <- qmd_content[(yaml_end + 1):length(qmd_content)]

  keep_lines <- character()
  skip_until_unindent <- FALSE

  for (line in yaml_lines) {
    if (grepl("^format:", line) || grepl("^execute:", line)) {
      skip_until_unindent <- TRUE
      next
    }
    if (skip_until_unindent) {
      if (grepl("^[^ ]", line) && line != "") {
        skip_until_unindent <- FALSE
        keep_lines <- c(keep_lines, line)
      }
    } else {
      keep_lines <- c(keep_lines, line)
    }
  }

  new_format <- c(
    "format:",
    "  html:",
    "    toc: true",
    "    embed-resources: true",
    "  docx:",
    "    toc: true",
    "execute:",
    "  echo: false",
    "  warning: false",
    "  message: false"
  )

  new_qmd <- c("---", keep_lines, new_format, "---", body_lines)
  writeLines(new_qmd, qmd_path)
  log_msg("  YAML patched successfully")
} else {
  log_msg("  Format configuration OK (html + docx)")
}

# =============================================================================
# Render to HTML
# =============================================================================

log_msg("")
log_msg("Rendering to HTML...")

html_output <- file.path(output_dir, "01_descriptive_analysis.html")

html_result <- system2(
  "quarto",
  args = c("render", qmd_path, "--to", "html", "--output-dir", output_dir),
  stdout = TRUE,
  stderr = TRUE
)

html_exit <- attr(html_result, "status")
if (is.null(html_exit)) html_exit <- 0

log_lines <- c(log_lines, "", "--- HTML Render Output ---", html_result)

if (html_exit == 0 && file.exists(html_output)) {
  html_size <- round(file.info(html_output)$size / 1024, 1)
  log_msg(glue("  HTML rendered: {html_output} ({html_size} KB)"))
  html_success <- TRUE
} else {
  log_msg(glue("  HTML render failed (exit code: {html_exit})"))
  html_success <- FALSE
}

# =============================================================================
# Render to DOCX
# =============================================================================

log_msg("")
log_msg("Rendering to DOCX...")

docx_output <- file.path(output_dir, "01_descriptive_analysis.docx")

docx_result <- system2(
  "quarto",
  args = c("render", qmd_path, "--to", "docx", "--output-dir", output_dir),
  stdout = TRUE,
  stderr = TRUE
)

docx_exit <- attr(docx_result, "status")
if (is.null(docx_exit)) docx_exit <- 0

log_lines <- c(log_lines, "", "--- DOCX Render Output ---", docx_result)

if (docx_exit == 0 && file.exists(docx_output)) {
  docx_size <- round(file.info(docx_output)$size / 1024, 1)
  log_msg(glue("  DOCX rendered: {docx_output} ({docx_size} KB)"))
  docx_success <- TRUE
} else {
  log_msg(glue("  DOCX render failed (exit code: {docx_exit})"))
  docx_success <- FALSE
}

# =============================================================================
# Post-render checks
# =============================================================================

log_msg("")
log_msg("Post-render validation:")

html_valid <- file.exists(html_output) && file.info(html_output)$size > 0
docx_valid <- file.exists(docx_output) && file.info(docx_output)$size > 0

log_msg(glue("  HTML exists and >0 KB: {html_valid}"))
log_msg(glue("  DOCX exists and >0 KB: {docx_valid}"))

# =============================================================================
# Summary
# =============================================================================

log_msg("")
log_msg("Summary:")
log_msg(glue("  HTML: {if (html_success && html_valid) 'SUCCESS' else 'FAILED'}"))
log_msg(glue("  DOCX: {if (docx_success && docx_valid) 'SUCCESS' else 'FAILED'}"))
log_msg("")
log_msg(glue("Completed: {Sys.time()}"))

writeLines(log_lines, log_path)
cat("\nLog written to:", log_path, "\n")

if (html_success && html_valid && docx_success && docx_valid) {
  cat("\n")
  cat("========================================\n")
  cat("Render complete. Output files:\n")
  cat(glue("  - {html_output}\n"))
  cat(glue("  - {docx_output}\n"))
  cat("========================================\n")
} else {
  stop("One or more renders failed. Check render_log.txt for details.")
}
