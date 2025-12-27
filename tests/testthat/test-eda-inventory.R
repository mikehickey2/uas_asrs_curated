# Tests for APA inventory parsing
# Tests: inventory parsing completeness

library(stringr)

# Replicate parse_inventory_block from 11_assemble_descriptives_qmd.R
parse_inventory_block <- function(lines, pattern) {
  results <- list()
  i <- 1
  while (i <= length(lines)) {
    if (str_detect(lines[i], pattern)) {
      title_line <- str_trim(lines[i])
      title_line <- str_remove(title_line, "^###\\s*")

      num <- str_extract(title_line, "^(Table|Figure)\\s+([0-9a-z]+)\\.", group = 2)
      type <- str_extract(title_line, "^(Table|Figure)") |> str_to_lower()
      id <- paste0(type, num)

      caption <- ""
      denom <- ""
      file_path <- ""

      j <- i + 1
      while (j <= length(lines) && !str_detect(lines[j], "^###|^---")) {
        if (str_detect(lines[j], "^\\*\\*Caption\\*\\*:")) {
          caption <- str_remove(lines[j], "^\\*\\*Caption\\*\\*:\\s*")
        }
        if (str_detect(lines[j], "^\\*\\*Denominator note\\*\\*:")) {
          denom <- str_remove(lines[j], "^\\*\\*Denominator note\\*\\*:\\s*")
        }
        if (str_detect(lines[j], "^\\*\\*(Source file|File)\\*\\*:")) {
          file_path <- str_extract(lines[j], "`[^`]+`") |>
            str_remove_all("`")
        }
        j <- j + 1
      }

      results[[id]] <- list(
        title = title_line,
        caption = caption,
        denom = denom,
        path = file_path
      )
      i <- j
    } else {
      i <- i + 1
    }
  }
  results
}

# =============================================================================
# Inventory parsing tests
# =============================================================================

test_that("parse_inventory_block extracts table information", {
  inventory_lines <- c(
    "### Table 1. Dataset overview",
    "",
    "**Caption**: Summary of dataset.",
    "",
    "**Denominator note**: N = 50 reports.",
    "",
    "**Source file**: `output/tables/table1.csv`",
    "",
    "---"
  )

  result <- parse_inventory_block(inventory_lines, "^### Table")

  expect_length(result, 1)
  expect_true("table1" %in% names(result))
  expect_equal(result$table1$title, "Table 1. Dataset overview")
  expect_equal(result$table1$caption, "Summary of dataset.")
  expect_equal(result$table1$denom, "N = 50 reports.")
  expect_equal(result$table1$path, "output/tables/table1.csv")
})

test_that("parse_inventory_block extracts figure information", {
  inventory_lines <- c(
    "### Figure 1. Detection patterns",
    "",
    "**Caption**: Who detects encounters?",
    "",
    "**Denominator note**: N = 50 reports.",
    "",
    "**File**: `output/figures/fig1.png`",
    "",
    "---"
  )

  result <- parse_inventory_block(inventory_lines, "^### Figure")

  expect_length(result, 1)
  expect_true("figure1" %in% names(result))
  expect_equal(result$figure1$title, "Figure 1. Detection patterns")
})

test_that("parse_inventory_block handles multiple entries", {
  inventory_lines <- c(
    "### Table 1. First table",
    "**Caption**: First caption.",
    "**Denominator note**: N = 50.",
    "**Source file**: `t1.csv`",
    "---",
    "### Table 2. Second table",
    "**Caption**: Second caption.",
    "**Denominator note**: N = 100.",
    "**Source file**: `t2.csv`",
    "---",
    "### Table 2a. Optional table",
    "**Caption**: Optional.",
    "**Denominator note**: n varies.",
    "**Source file**: `t2a.csv`"
  )

  result <- parse_inventory_block(inventory_lines, "^### Table")

  expect_length(result, 3)
  expect_setequal(names(result), c("table1", "table2", "table2a"))
})

test_that("parse_inventory_block handles missing fields gracefully", {
  inventory_lines <- c(
    "### Table 1. Minimal table",
    "---"
  )

  result <- parse_inventory_block(inventory_lines, "^### Table")

  expect_length(result, 1)
  expect_equal(result$table1$caption, "")
  expect_equal(result$table1$denom, "")
  expect_equal(result$table1$path, "")
})

test_that("parse_inventory_block returns empty list for no matches", {
  inventory_lines <- c(
    "# Some header",
    "Some text",
    "---"
  )

  result <- parse_inventory_block(inventory_lines, "^### Table")

  expect_length(result, 0)
})

test_that("actual inventory file parses completely", {
  inventory_path <- file.path(root_dir, "output/notes/apa_inventory.md")
  skip_if_not(file.exists(inventory_path))

  inventory <- readLines(inventory_path)

  tables <- parse_inventory_block(inventory, "^### Table")
  figures <- parse_inventory_block(inventory, "^### Figure")

  expect_gte(length(tables), 4)
  expect_gte(length(figures), 6)

  for (tbl in tables) {
    expect_true(nchar(tbl$caption) > 0, info = tbl$title)
    expect_true(nchar(tbl$denom) > 0, info = tbl$title)
  }

  for (fig in figures) {
    expect_true(nchar(fig$caption) > 0, info = fig$title)
    expect_true(nchar(fig$denom) > 0, info = fig$title)
  }
})
