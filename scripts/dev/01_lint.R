# Lint R source files
#
# Usage:
#   Rscript scripts/dev/01_lint.R
#
# Lints:
#   - R/
#   - scripts/eda/

library(lintr)

cat("==============================================\n")
cat("Linting R source files\n")
cat("==============================================\n\n")

dirs_to_lint <- c("R", "scripts/eda")
all_lints <- list()
total_lints <- 0

for (dir in dirs_to_lint) {
  if (!dir.exists(dir)) {
    cat("Skipping (not found):", dir, "\n")
    next
  }

  cat("Linting:", dir, "\n")
  lints <- lint_dir(dir, parse_settings = TRUE)

  if (length(lints) > 0) {
    all_lints[[dir]] <- lints
    total_lints <- total_lints + length(lints)
    print(lints)
  } else {
    cat("  No lints found\n")
  }
  cat("\n")
}

cat("==============================================\n")
cat("Summary\n")
cat("==============================================\n")
cat("Total lints:", total_lints, "\n")

if (total_lints > 0) {
  cat("\nLints by directory:\n")
  for (dir in names(all_lints)) {
    cat(" ", dir, ":", length(all_lints[[dir]]), "\n")
  }
  quit(status = 1)
} else {
  cat("All files pass linting.\n")
}
