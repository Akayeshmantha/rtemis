# mplot3.bar
# ::rtemis::
# 2017 Efstathios D. Gennatas egenn.github.io
# TODO: fix for when x is negative
# TODO: groups support (set xlim for besides = T)

#' \code{mplot3}: Barplot
#' 
#' Draw barplots
#' 
#' @inheritParams mplot3.xy
#' @param x Vector or Matrix: If Vector, each value will be drawn as a bar. 
#' If Matrix, each column is a vector, so multiple columns signify a different group.
#' e.g. Columns could be months and rows could be N days sunshine, N days rainfall, N days snow, etc.
#' @param col Vector of colors to use
#' @param alpha Float: Alpha to be applied to \code{col}
#' @param border Color if you wish to draw border around bars, NA for no borders (Default)
#' @param space Float: Space left free on either side of the bars, as a fraction of bar width. A single number or a 
#' vector, one value per bar. If \code{x} is a matrix, space can be length 2 vector, signifying space between bars 
#' within group and between groups. Default = c(0, 1) if x is matrix and \code{beside = TRUE}, otherwise Default = .2
#' @param ... Additional arguments to \code{graphics::barplot}
#' @author Efstathios D. Gennatas
#' @export

mplot3.bar <- function(x,
                       error = NULL,
                       col = NULL,
                       error.col = "white",
                       error.lwd = 2, 
                       alpha = 1,
                       # beside = TRUE,
                       border = NA,
                       width = 1,
                       space = NULL, #c(1, .2),
                       xlim = NULL,
                       ylim = NULL,
                       xlab = NULL,
                       xlab.line = 1.5,
                       ylab = NULL,
                       ylab.line = 1.5,
                       main = NULL,
                       main.line = .5,
                       main.adj = 0,
                       main.col = NULL,
                       main.font = 2,
                       main.family = "",
                       names.arg = NULL,
                       axisnames = FALSE,
                       las = 1.5,
                       group.names = NULL,
                       group.names.srt = 0,
                       group.names.adj = ifelse(group.names.srt == 0, .5, 1),
                       group.names.line = 0.5,
                       group.names.font = 1,
                       group.names.cex = 1,
                       group.names.y.pad = .06,
                       group.names.at = NULL,
                       legend = FALSE,
                       legend.names = NULL,
                       legend.position = "topright",
                       legend.inset = c(0, 0),
                       toplabels = NULL,
                       mar = c(3, 2.5, 2.5, 1),
                       pty = "m",
                       cex = 1.2,
                       cex.axis = cex,
                       cex.names = 1,
                       bg = NULL,
                       plot.bg = NULL,
                       barplot.axes = FALSE,
                       yaxis = TRUE,
                       ylim.pad = .04,
                       y.axis.padj = 1,
                       tck = -.015,
                       tick.col = NULL,
                       theme = getOption("rt.theme", "light"),
                       axes.col = NULL,
                       labs.col = NULL,
                       grid = FALSE,
                       grid.ny = NULL,
                       grid.lty = NULL,
                       grid.lwd = NULL,
                       grid.col = NULL,
                       grid.alpha = 1,
                       par.reset = TRUE,
                       pdf.width = 6,
                       pdf.height = 6,
                       filename = NULL, ...) {
  
  # [ ARGUMENTS ] ====
  # Compatibility with rtlayout()
  if (exists("rtpar", envir = rtenv)) par.reset <- FALSE
  p <- NCOL(x)
  if (is.null(col)) {
    if (p == 1) {
      col = ucsfPalette
    } else {
      col = ucsfPalette[seq(p)]
    }
  }
  
  if (length(col) < p) col <- rep(col, p/length(col))
  
  if (is.null(space)) {
    space <- if (min(size(x)) > 2) c(0, .2) else .2
  }
  
  # Group names
  # if (is.null(group.names)) {
  #   if (!is.null(colnames(x))) group.names <- colnames(x)
  # }
  
  # if (!is.null(group.names)) {
  #   if (is.null(group.names.at)) {
  #     if (beside) {
  #       group.names.at <- seq(1 + NROW(x)/2, NCOL(x) + NROW(x) * NCOL(x), NROW(x) + 1)
  #     } else {
  #       group.names.at <- 1:NCOL(x)
  #     }
  #   }
  # }
  
  # Legend names
  if (is.null(legend.names)) {
    if (!is.null(rownames(x))) legend.names <- rownames(x)
  }
  
  # .grouped <- !is.null(dim(x)) #wip add element labels at 45 degress if grouped
  cols <- colorAdjust(col, alpha = alpha)
  par.orig <- par(no.readonly = TRUE)
  if (par.reset) on.exit(suppressWarnings(par(par.orig)))
  
  # Output directory
  if (!is.null(filename))
    if (!dir.exists(dirname(filename)))
      dir.create(dirname(filename), recursive = TRUE)
  
  # [ NAMES for vectors ] ====
  if (is.null(names.arg)) {
    if (NROW(x) == 1 & !is.null(colnames(x))) names.arg <- colnames(x)
    if (NCOL(x) == 1 & !is.null(rownames(x))) names.arg <- rownames(x)
  }
  
  # [ DATA ] ====
  x <- as.matrix(x)
  # beside <- if (NROW(x) == 1) FALSE else TRUE
  beside <- TRUE
  if (!is.null(dim(x))) {
    if (NROW(x) == 1) {
      x <- as.numeric(x)
      if (!is.null(error)) error <- as.numeric(error)
    }
  }
  if (!is.null(error)) error <- as.matrix(error)
  
  # [ THEMES ] ====
  # Defaults for all themes
  if (is.null(grid.lty)) grid.lty <- 1
  if (is.null(grid.lwd)) grid.lwd <- 1
  
  if (theme == "lightgrid" | theme == "darkgrid") {
    if (is.null(grid.lty)) grid.lty <- 1
    # if (is.null(zero.lty)) zero.lty <- 1
    if (is.null(grid.lwd)) grid.lwd <- 1.5
  }
  if (theme == "lightgrid") {
    theme <- "light"
    if (is.null(plot.bg)) plot.bg <- "gray90"
    grid <- TRUE
    if (is.null(grid.col)) grid.col <- "white"
    if (is.null(tick.col)) tick.col <- "white"
  }
  if (theme == "darkgrid") {
    theme <- "dark"
    if (is.null(plot.bg)) plot.bg <- "gray15"
    grid <- TRUE
    if (is.null(grid.col)) grid.col <- "black"
    if (is.null(tick.col)) tick.col <- "black"
  }
  themes <- c("light", "dark", "box", "darkbox")
  if (!theme %in% themes) {
    warning(paste(theme, "is not an accepted option; defaulting to \"light\""))
    theme <- "light"
  }
  
  if (theme == "light") {
    if (is.null(bg)) bg <- "white"
    # if (is.null(col) & length(xl) == 1) {
    #   # col <- as.list(adjustcolor("black", alpha.f = point.alpha)) 
    #   col <- list("gray30")
    # }
    # box.col <- "white"
    if (is.null(axes.col)) axes.col <- adjustcolor("white", alpha.f = 0)
    if (is.null(tick.col)) tick.col <- "gray10"
    if (is.null(labs.col)) labs.col <- "gray10"
    if (is.null(main.col)) main.col <- "black"
    if (is.null(grid.col)) grid.col <- "black"
    # if (is.null(diagonal.col)) diagonal.col <- "black"
    # if (is.null(hline.col)) hline.col <- "black"
    # gen.col <- "black"
  } else if (theme == "dark") {
    if (is.null(bg)) bg <- "black"
    # if (is.null(col) & length(xl) == 1) {
    #   # col <- as.list(adjustcolor("white", alpha.f = point.alpha)) 
    #   col <- list("gray70")
    # }
    # box.col <- "black"
    if (is.null(axes.col)) axes.col <- adjustcolor("black", alpha.f = 0)
    if (is.null(tick.col)) tick.col <- "gray90"
    if (is.null(labs.col)) labs.col <- "gray90"
    if (is.null(main.col)) main.col <- "white"
    if (is.null(grid.col)) grid.col <- "white"
    # if (is.null(diagonal.col)) diagonal.col <- "white"
    # if (is.null(hline.col)) hline.col <- "white"
    gen.col <- "white"
  } else if (theme == "box") {
    if (is.null(bg)) bg <- "white"
    # if (is.null(col) & length(xl) == 1) {
    #   # col <- as.list(adjustcolor("black", alpha.f = point.alpha))
    #   col <- list("gray30")
    # }
    # if (is.null(box.col)) box.col <- "gray10"
    if (is.null(axes.col)) axes.col <- adjustcolor("white", alpha.f = 0)
    if (is.null(tick.col)) tick.col <- "gray10"
    if (is.null(labs.col)) labs.col <- "gray10"
    if (is.null(main.col)) main.col <- "black"
    if (is.null(grid.col)) grid.col <- "black"
    # if (is.null(diagonal.col)) diagonal.col <- "black"
    # if (is.null(hline.col)) hline.col <- "black"
    gen.col <- "black"
  } else if (theme == "darkbox") {
    if (is.null(bg)) bg <- "black"
    # if (is.null(col) & length(xl) == 1) {
    #   # col <- as.list(adjustcolor("white", alpha.f = point.alpha))
    #   col <- list("gray70")
    # }
    # if (is.null(box.col)) box.col <- "gray90"
    if (is.null(axes.col)) axes.col <- adjustcolor("black", alpha.f = 0)
    if (is.null(tick.col)) tick.col <- "gray90"
    if (is.null(labs.col)) labs.col <- "gray90"
    if (is.null(main.col)) main.col <- "white"
    if (is.null(grid.col)) grid.col <- "white"
    # if (is.null(diagonal.col)) diagonal.col <- "white"
    # if (is.null(hline.col)) hline.col <- "white"
    gen.col <- "white"
  }
  
  # [ PLOT ] ====
  if (!is.null(filename)) pdf(filename, width = pdf.width, height = pdf.height, title = "rtemis Graphics")
  par(mar = mar, bg = bg, pty = pty, cex = cex)
  # [ XLIM & YLIM ] ====
  # if (beside) {
  #   # if (is.null(xlim)) xlim <- c(0, length(x) + NCOL(x) + 1)
  #   if (is.null(xlim)) xlim <- c(0, (length(x) * width * sum(space)) * 1.02)
  #   # if (is.null(ylim)) ylim <- range(c(0, x + 1)) # works for non-negative data only
  # } else {
  #   if (is.null(xlim)) {
  #     xlim <- c(0, NCOL(x) + 1.8)
  #   }
  #   # if (is.null(ylim)) ylim <- range(c(0, x + 1)) # works for non-negative data only
  #   # if (is.null(ylim)) ylim <- range(c(0, apply(x, 2, sum)))
  # }
  xlim <- range(barplot(x, beside = beside, width = width, space = space, plot = FALSE))
  xlim[1] <- xlim[1] - .5 - max(space)
  xlim[2] <- xlim[2] + .5 + max(space)
  if (is.null(ylim)) {
    if (is.null(error)) {
      ylim <- range(c(0, x))
    } else {
      ylim <- range(c(0, x + error))
    }
  }
  
  # Add x% either side (unless zero)
  if (ylim[1] != 0) ylim[1] <- ylim[1] - ylim.pad * diff(ylim)
  ylim[2] <- ylim[2] + ylim.pad * diff(ylim)
  plot(NULL, NULL, xlim = xlim, ylim = ylim, bty = 'n', axes = FALSE, ann = FALSE,
       xaxs = "i", yaxs = "i")
  
  # [ PLOT BG ] ====
  if (!is.null(plot.bg)) {
    # bg.ylim <- c(min(ylim) - .04 * diff(range(ylim)), max(ylim) + .04 * diff(range(ylim)))
    bg.ylim <- c(min(ylim), max(ylim) + .04 * diff(range(ylim)))
    rect(xlim[1], bg.ylim[1], xlim[2], bg.ylim[2], border = NA, col = plot.bg)
  }
  
  # [ GRID ] ====
  grid.col <- colorAdjust(grid.col, grid.alpha)
  if (grid) grid(col = grid.col, lty = grid.lty, lwd = grid.lwd, ny = grid.ny, nx = 0)
  
  # [ BARPLOT ] ====
  barCenters <- barplot(x, beside = beside, col = cols,
                        border = border, ylim = ylim, axes = barplot.axes,
                        cex.axis = cex.axis, cex.names = cex.names, add = TRUE, xlab = NULL,
                        axisnames = axisnames, names.arg = names.arg, las = las,
                        width = width, space = space, ...)
  
  # [ ERROR BARS ] ====
  if (!is.null(error)) {
    segments(as.vector(barCenters), as.vector(x) - as.vector(error),
             as.vector(barCenters), as.vector(x) + as.vector(error), 
             lwd = error.lwd, col = error.col)
    
    arrows(barCenters, x - as.vector(error), 
           barCenters, x + as.vector(error),
           lwd = error.lwd, angle = 90, code = 3, length = 0.05, col = error.col)
  }
  
  # [ y AXIS ] ====
  if (yaxis) axis(2, col = axes.col, col.axis = labs.col, col.ticks = tick.col, 
                  padj = y.axis.padj, tck = tck, cex = cex)
  
  # [ MAIN ] ====
  if (!is.null(main)) {
    # suppressWarnings(mtext(bquote(paste(bold(.(main)))), line = main.line,
    #                        adj = main.adj, cex = cex, col = main.col))
    mtext(main, line = main.line, font = main.font, family = main.family,
          adj = main.adj, cex = cex, col = main.col)
  }
  
  # [ GROUP NAMES ] ====
  if (is.null(group.names) & !is.null(colnames(x)))
    group.names <- colnames(x)
  if (!is.null(group.names)) {
    # mtext(group.names, side = 1, line = group.names.line, at = barCenters,
    #       font = group.names.font, cex = cex)
    if (is.null(group.names.at)) group.names.at <- colMeans(barCenters)
    text(x = group.names.at, y = -diff(ylim) * group.names.y.pad, labels = group.names,
         srt = group.names.srt, adj = group.names.adj, xpd = TRUE,
         font = group.names.font, cex = group.names.cex)
  }
  
  # # [ ROWNAMES for 1 column ] ====
  # if (ncol(x) == 1) {
  #   if (!is.null(rownames(x))) {
  #     text(x = 1:nrow(x) + .8, y = -diff(ylim) * .033, labels = rownames(x), srt = 45, xpd = NA, pos = 2)
  #     # axis(side = 1, 1:nrow(x), at = 1:nrow(x) + .5, labels = rownames(x),
  #     #      tick = FALSE, hadj = 0, las = 3)
  #   }
  # }
  
  # [ LEGEND ] ====
  if (legend) {
    legend(legend.position, legend = legend.names,
           fill = cols, border = cols, inset = legend.inset, xpd = TRUE, bty = "n")
  }
  
  # [ AXIS LABS ] ====
  if (!is.null(xlab))  mtext(xlab, 1, cex = cex, line = xlab.line)
  if (!is.null(ylab))  mtext(ylab, 2, cex = cex, line = ylab.line)
  
  # [ TOP LABELS ] ====
  if (!is.null(toplabels)) {
    mtext(toplabels, 3, at = barCenters)
  }
  
  # [ OUTRO ] ====
  if (!is.null(filename)) dev.off()
  invisible(barCenters)
  
} # rtemis::mplot3.bar
