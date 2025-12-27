# Create APA reference DOCX for Quarto rendering
# Sets fonts, margins, and paragraph styles

library(officer)

output_path <- "assets/apa_reference.docx"

doc <- read_docx()

doc <- body_set_default_section(
  doc,
  value = prop_section(
    page_size = page_size(
      width = 8.5,
      height = 11,
      orient = "portrait"
    ),
    page_margins = page_mar(
      bottom = 1,
      top = 1,
      right = 1,
      left = 1,
      header = 0.5,
      footer = 0.5,
      gutter = 0
    )
  )
)

normal_props <- fp_text(
  font.family = "Times New Roman",
  font.size = 12
)

normal_par <- fp_par(
  line_spacing = 2,
  text.align = "left"
)

heading1_text <- fp_text(
  font.family = "Times New Roman",
  font.size = 14,
  bold = TRUE
)

heading2_text <- fp_text(
  font.family = "Times New Roman",
  font.size = 12,
  bold = TRUE
)

table_text <- fp_text(
  font.family = "Times New Roman",
  font.size = 11
)

doc <- doc |>
  body_add_fpar(
    fpar(ftext("Document Title", prop = heading1_text)),
    style = "heading 1"
  ) |>
  body_add_fpar(
    fpar(ftext(
      "This is body text in Times New Roman 12pt with double spacing.",
      prop = normal_props
    )),
    style = "Normal"
  ) |>
  body_add_fpar(
    fpar(ftext("Section Heading", prop = heading2_text)),
    style = "heading 2"
  ) |>
  body_add_fpar(
    fpar(ftext(
      "Additional body text paragraph for reference formatting.",
      prop = normal_props
    )),
    style = "Normal"
  )

sample_df <- data.frame(
  Variable = c("Item A", "Item B", "Item C"),
  n = c(10, 20, 30),
  Percentage = c("20%", "40%", "60%")
)

ft <- flextable::flextable(sample_df)
ft <- flextable::font(ft, fontname = "Times New Roman", part = "all")
ft <- flextable::fontsize(ft, size = 11, part = "all")
ft <- flextable::bold(ft, part = "header")
ft <- flextable::border_remove(ft)
ft <- flextable::hline_top(
  ft,
  border = fp_border(color = "black", width = 1),
  part = "header"
)
ft <- flextable::hline_bottom(
  ft,
  border = fp_border(color = "black", width = 0.5),
  part = "header"
)
ft <- flextable::hline_bottom(
  ft,
  border = fp_border(color = "black", width = 1),
  part = "body"
)
ft <- flextable::autofit(ft)

doc <- flextable::body_add_flextable(doc, ft)

print(doc, target = output_path)
cat("Created:", output_path, "\n")
cat("Features:\n")
cat("  - 1\" margins\n")
cat("  - Times New Roman throughout\n")
cat("  - 12pt body, 11pt tables\n")
cat("  - Double-spaced body text\n")
cat("  - APA table borders (horizontal only)\n")
