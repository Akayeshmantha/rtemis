# dplot3.R
# ::rtemis::
# 2016 Efstathios D. Gennatas egenn.github.io

#' Dynamic Plots (\code{plotly})
#'
#' Build dynamic plots that can be viewed in RStudio Viewer, a web browser, or exported to a static image.
#' Support for (x, y) scatter plots with optional fit line(lm, or gam), and density plots.
#'
#' @param x Numeric vector. x coordinates
#' @param y Numeric vector. y coordinates
#' @param mode String: "scatter" or "density"
#' @param group String: Name of variable to group by (not yet functional)
#' @param point.size Numeric scalar or vector
#' @param point.color Color of points
#' @param point.alpha Float: Alpha of points
#' @param point.symbol String: "circle", "square"; see plotly documentation for more
#'   Default = "circle"
#' @param point.labels String, optional: Point labels displayed on mouse over
#' @param fit String, optional: "lm", "gam"
#' @param gam.k Integer: Number of bases for \code{mgcv::gam}'s smoothing spline
#' @param fit.width Float: Width of fit line
#' @param fit.color Color of fit line
#' @param fit.alpha Float: Alpha of fit line
#' @param se.fit Logical: If TRUE, draws +/- \code{se.times * standard error}
#' @param se.times Float: Multiplier for standard error band. Default = 2
#' @param se.color Color of S.E. band
#' @param se.alpha Float: Alpha of S.E. band
#' @param density.color Color of density line
#' @param density.alpha Float: Alpha of density line
#' @param density.width Integer: Width of density line
#' @param density.mean Logical: If TRUE, draw vertical line at \code{mean(x)}
#' @param density.mean.width Integer: Width of \code{density.mean} line. Default = 2
#' @param main String: Plot title
#' @param xlab String: x-axis label
#' @param ylab String: y-axis label
#' @param font.family String: Axes' legends' font family
#' @param font.color Font color
#' @param font.size Integer: Font size
#' @param axes Logical: If TRUE, show x and y axes. Default = TRUE
#' @param grid Logical: If TRUE, draw grid lines. Default = FALSE
#' @param margin Vector, length 4: Plot margins. Default = c(60, 70, 40, 20)
#' @param pad Numeric: Distance of tick labels from axes
#' @param legend.xy Vector, length 2 [0, 1]: x, y coordinates of legend. 0 means left and bottom for x and y axis
#' respectively; 1 means right and top. Default = c(0, 1) (i.e. top-left)
#' @param axes.square Logical: If TRUE, make axes square
#' @param showlegend Logical: If TRUE, show legends
#' @author Efstathios D. Gennatas
#' @seealso \link{mplot3}
#' @export

dplot3 <- function(x, y = NULL,
                   mode = NULL,
                   group = NULL,
                   point.size = 7,
                   point.color = NULL,
                   point.alpha = .66,
                   point.symbol = "circle",
                   point.labels = NULL,
                   fit = "none",
                   axes.fixedratio = FALSE,
                   xlim = NULL,
                   ylim = NULL,
                   gam.k = 4,
                   fit.width = 3,
                   fit.color = "#18A3AC",
                   fit.alpha = 1,
                   se.fit = TRUE,
                   se.times = 2,
                   se.color = NULL,
                   se.alpha = .2,
                   density.color = "#18A3AC",
                   density.alpha = .66,
                   density.width = 1,
                   density.mean = FALSE,
                   density.mean.width = 2,
                   main = NULL,
                   xlab = "x",
                   ylab = "y",
                   font.family = "Helvetica Neue",
                   font.color = "gray50",
                   font.size = 18,
                   axes = FALSE,
                   grid = TRUE,
                   grid.col = "#fff",
                   zero.lines = TRUE,
                   zero.col = "#7F7F7F",
                   zero.lwd = 1,
                   legend = TRUE,
                   legend.bgcol = "#00000000",
                   legend.bordercol = "gray50",
                   legend.borderwidth = 0,
                   legend.fontcol = "#000000",
                   margins = c(60, 70, 40, 20),
                   pad = 4,   # amount of padding in px between the plotting area and the axis lines
                   bg = "#E5E5E5",
                   showlegend = TRUE,
                   legend.xy = c(0, 1),
                   axes.square = FALSE,
                   height = NULL,
                   width = NULL) {

  # [ DEPENDENCIES ] ====
  if (!depCheck("plotly", verbose = FALSE)) {
    cat("\n"); stop("Please install dependencies and try again")
    }

  # [ MODE ] ====
  if (is.null(mode)) {
    if (!is.null(y)) {
      mode <- "scatter"
    } else {
      mode <- "density"
    }
  }

  # [ COLORS ] ====
  if (is.null(point.color)) {
    point.color <- if (fit == "none") "#18A3AC" else "#505050"
  }

  # [ SIZE ] ====
  if (axes.square) {
    width <- height <- min(dev.size("px")) - 10
  }

  # [ xy SCATTER ] ====
  if (mode == "scatter") {
    if (class(x) == "numeric") {
      index <- order(x)
    } else {
      index <- 1:NROW(x)
    }

    x <- x[index]
    if (!is.null(y)) y <- y[index]

    # '- POINTS ====
    m <- list(size = point.size,
              color = point.color,
              opacity = point.alpha,
              symbol = point.symbol)
    if (!is.null(point.labels)) {
      point.labels <- paste0("(", ddSci(x), ", ", ddSci(y), ")\n", point.labels)
    } else {
      point.labels <- paste0("x =", ddSci(x), "; y =", ddSci(y))
    }

    # '- PLOT ====
    p <- plotly::plot_ly(x = x, y = y,
                         type = "scatter",
                         name = "Raw",
                         mode = "markers",
                         marker = m,
                         split = group,
                         showlegend = showlegend,
                         text = point.labels,
                         hoverinfo = "text",
                         width = width,
                         height = height)

    # '- FITTED & S.E. ====
    fitted <- NULL
    if (!is.null(fit)) {
      if (fit == "lm") {
        modfit <- s.LM(x, y, print.plot = FALSE)
        fitted <- fitted(modfit)
        se.fitted <- modfit$se.fit
      } else if (fit == "gam") {
        modfit <- s.GAM(x, y, k = gam.k, print.plot = FALSE, verbose = FALSE)
        fitted <- fitted(modfit)
        se.fitted <- modfit$se.fit
      }
    }

    # '- S.E. BAND ====
    if (se.fit & !is.null(fitted)) {
      if (is.null(se.color)) se.color <- fit.color
      shade.name <- paste("+/-", se.times, "s.e.")
      # linv <- list(color = plotly::toRGB(se.color, alpha = 0),
      #              width = 0)
      # lse <- list(color = plotly::toRGB(se.color, alpha = 0),
      #             fillcolor = plotly::toRGB(se.color, alpha = se.alpha),
      #             width = 0)
      p <- plotly::add_trace(p, x = x, y = fitted + se.times * se.fitted,
                             type = "scatter",
                             mode = "lines",
                             line = list(color = "transparent"),
                             # fill = "tonexty",
                             # fillcolor = se.color,
                             showlegend = FALSE,
                             # name = "Fit + error",
                             hoverinfo = "none", # delta
                             inherit = FALSE)
      p <- plotly::add_trace(p, x = x, y = fitted - se.times * se.fitted,
                             type = "scatter",
                             mode = "lines",
                             fill = "tonexty",
                             fillcolor = plotly::toRGB(se.color, alpha = se.alpha),
                             line = list(color = "transparent"),
                             name = shade.name,
                             showlegend = showlegend,
                             hoverinfo = "none", # delta
                             inherit = FALSE)
    }

    # '- FIT LINE ====
    if (!is.null(fitted)) {
      lfit = list(color = plotly::toRGB(fit.color, alpha = fit.alpha),
                  width = fit.width)
      p <- plotly::add_trace(p, x = x, y = fitted,
                             type = "scatter",
                             mode = "lines",
                             line = lfit,
                             name = paste(toupper(fit), "fit"),
                             showlegend = showlegend,
                             inherit = FALSE)
    }

  } # End mode == "scatter"

  # [ x DENSITY ] ====
  if (mode == "density") {

    x.density <- density(x)

    # '- LINES ====
    density.x <- x.density$x
    density.y <- x.density$y
    # ldensity <- list(color = plotly::toRGB(density.color, alpha = density.alpha),
    #                  width = density.width)
    density.color <- plotly::toRGB(density.color, alpha = density.alpha)

    # '-  PLOT ====
    p <- plotly::plot_ly(width = width,
                         height = height)
    p <- plotly::add_trace(p, x = density.x, y = density.y,
                           type = "scatter",
                           mode = "none",
                           fill = 'tozeroy',
                           # line = ldensity,
                           fillcolor = density.color,
                           name = "Density",
                           showlegend = showlegend)
    if (density.mean) {
      ldensity.mean <- list(color = "#333333",
                            width = density.mean.width,
                            dash = 5)
      p <- plotly::add_trace(p, x = c(mean(x), mean(x)), y = c(min(density.y), max(density.y)),
                             type = "scatter",
                             mode = "lines",
                             line = ldensity.mean,
                             name = "Mean",
                             showlegend = showlegend)
    }

    if (ylab == "y") ylab <- "Density"

  } # End mode == "density"

  # [ B.1 AXES ] ====
  f <- list(family = font.family,
            size = font.size,
            color = font.color)

  xaxis <- list(title = xlab,
                titlefont = f,
                tickfont = f,
                showline = axes,
                showgrid = grid,
                gridcolor = grid.col,
                zeroline = zero.lines,
                zerolinecolor = zero.col,
                zerolinewidth = zero.lwd,
                dash = "dashed",
                range = xlim)

  yaxis <- list(title = ylab,
                titlefont = f,
                tickfont = f,
                showline = axes,
                showgrid = grid,
                gridcolor = grid.col,
                zeroline = zero.lines,
                zerolinecolor = zero.col,
                zerolinewidth = zero.lwd,
                scaleanchor = if (axes.fixedratio) "x" else NULL,
                range = ylim)

  # [ B.2 LEGEND ] ====
  font <- list(family = font.family,
               size = font.size,
               color = legend.fontcol)

  .legend <- list(font = font,
                 bgcolor = legend.bgcol,
                 bordercolor = legend.bordercol,
                 borderwidth = legend.borderwidth,
                 x = legend.xy[1],
                 y = legend.xy[2])

  # [ C LAYOUT ] ====
  margin <- list(b = margins[1],
                 l = margins[2],
                 t = margins[3],
                 r = margins[4],
                 pad = pad)
  p <- plotly::layout(p, title = main,
                      xaxis = xaxis,
                      yaxis = yaxis,
                      legend = if(legend) .legend else NULL,
                      margin = margin,
                      plot_bgcolor = bg)
  p
  return(p)

} # rtemis::dplot3
