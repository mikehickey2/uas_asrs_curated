#' APA-style table formatting for flextable
#'
#' Provides consistent APA-compliant table styling for Word output.
#'
#' @name apa_tables

#' Format a data frame as an APA-style flextable
#'
#' @param df A data frame to format
#' @param title Optional table title (displayed above table)
#' @param note Optional table note (displayed below table)
#' @param font_name Font family (default: "Times New Roman")
#' @param font_size Body font size in points (default: 11)
#' @param header_size Header font size in points (default: 11)
#'
#' @return A flextable object with APA styling applied
#'
#' @details
#' APA table style features:
#' - Horizontal rules only (top, below header, bottom)
#' - No vertical rules
#' - Bold header row
#' - Left-align text columns, right-align numeric columns
#' - Consistent font throughout
#'
#' @export
as_apa_flextable <- function(df,
                              title = NULL,
                              note = NULL,
                              font_name = "Times New Roman",
                              font_size = 11,
                              header_size = 11) {
  checkmate::assert_data_frame(df, min.rows = 1)
  checkmate::assert_string(title, null.ok = TRUE)
  checkmate::assert_string(note, null.ok = TRUE)
  checkmate::assert_string(font_name)
  checkmate::assert_number(font_size, lower = 6, upper = 24)
  checkmate::assert_number(header_size, lower = 6, upper = 24)

  ft <- flextable::flextable(df)

  ft <- flextable::font(ft, fontname = font_name, part = "all")
  ft <- flextable::fontsize(ft, size = font_size, part = "body")
  ft <- flextable::fontsize(ft, size = header_size, part = "header")

  ft <- flextable::bold(ft, part = "header")

  ft <- flextable::border_remove(ft)

  top_border <- officer::fp_border(color = "black", width = 1)
  header_border <- officer::fp_border(color = "black", width = 0.5)
  bottom_border <- officer::fp_border(color = "black", width = 1)

  ft <- flextable::hline_top(ft, border = top_border, part = "header")
  ft <- flextable::hline_bottom(ft, border = header_border, part = "header")
  ft <- flextable::hline_bottom(ft, border = bottom_border, part = "body")

  numeric_cols <- vapply(df, is.numeric, logical(1))
  if (any(numeric_cols)) {
    ft <- flextable::align(
      ft,
      j = which(numeric_cols),
      align = "right",
      part = "all"
    )
  }
  if (any(!numeric_cols)) {
    ft <- flextable::align(
      ft,
      j = which(!numeric_cols),
      align = "left",
      part = "all"
    )
  }

  ft <- flextable::align(ft, align = "center", part = "header")

  ft <- flextable::padding(ft, padding = 4, part = "all")

  ft <- flextable::autofit(ft)

  if (!is.null(title)) {
    ft <- flextable::set_caption(
      ft,
      caption = title,
      style = "Table Caption"
    )
  }

  if (!is.null(note)) {
    ft <- flextable::add_footer_lines(ft, values = paste0("Note. ", note))
    ft <- flextable::fontsize(ft, size = font_size - 1, part = "footer")
    ft <- flextable::italic(ft, part = "footer")
  }

  ft
}
