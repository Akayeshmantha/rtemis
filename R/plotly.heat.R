# plotly.heat.R
# ::rtemis::
# 2016 Efstathios D. Gennatas egenn.github.io

#' Heatmap with \code{plotly}
#'
#' Draw a heatmap using \code{plotly}
#'
#' @param z Input matrix
#' @param x,y Vectors for x, y axes
#' @param title Plot title
#' @param col Set of colors to make gradient from
#' @param xlab x-axis label
#' @param ylab y-axis label
#' @param zlab z value label
#' @param transpose Logical. Transpose matrix
#' @author Efstathios D. Gennatas
#' @export

plotly.heat <- function(z, x = NULL, y = NULL,
                        title = NULL, col = penn.heat(21),
                        xlab = NULL, ylab = NULL, zlab = NULL,
                        transpose = TRUE) {

  # [ NS ]
  requireNamespace("plotly")

  # Labels
  if (is.null(xlab)) xlab <- " "
  if (is.null(ylab)) ylab <- " "
  if (is.null(zlab)) zlab <- "value"

  # Axes
  x <- unique(x)
  y <- unique(y)

  # Fonts
  font <- list(
    color = plotly::toRGB("grey50")
  )

  x.axis <- list(
    title = xlab,
    titlefont = font
  )

  y.axis <- list(
    title = ylab,
    titlefont = font
  )

  colorbar <- list(
    title = zlab,
    titlefont = font
  )

  p <- plotly::plot_ly(z = z, x = x, y = y,
                       transpose = transpose,
                       type = "heatmap",
                       colors = col,
                       colorbar = colorbar,
                       text = paste("Value =", ddSci(z)),
                       hoverinfo = "all") %>%
    plotly::layout(title = title,
                   xaxis = x.axis,
                   yaxis = y.axis)
  p
  return(p)

} # rtemis::plotly.heat
