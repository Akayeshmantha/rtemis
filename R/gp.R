# gp.R
# ::rtemis::
# 2016 Efstathios D. Gennatas egenn.github.io
# TODO: output to rtMod or rename

#' Bayesian Gaussian Processes [R]
#'
#' Fit a gaussian process
#'
#' @inheritParams s.GLM
#' @param x Numeric vector or matrix of features, i.e. independent variables
#' @param y Numeric vector of outcome, i.e. dependent variable
#' @param new.x (Optional) Numeric vector or matrix of new set of features
#'   Must have same set of columns as \code{x}
#' @param print.plot Logical: if TRUE, draw plot when done
#' @param lwd Line width for plotting
#' @param cex Character expansion factor for plotting
#' @param par.reset Logical. Reset \code{par} to its original state
#' @param ... Additional arguments to be passed to tgp::bgp
#' @author Efstathios D. Gennatas
#' @export

gp <- function(x, y,
               new.x = NULL,
               x.name = "x", y.name = "y",
               print.plot = TRUE,
               lwd = 3,
               cex = 1.2,
               par.reset = TRUE, ...) {

  # [ BGP ] ====
  s.out <- list(mod.name = "BGP")
  s.out$mod <- mod <- tgp::bgp(X = x, Z = y, XX = new.x, ...)

  # [ FITTED ] ====
  if (is.null(new.x)) {
    s.out$mean <- mean <- mod$Zp.mean
    s.out$q05 <- q05 <- mod$Zp.q1
    s.out$q95 <- q95 <- mod$Zp.q2
  } else {
    s.out$mean <- mean <- mod$ZZ.mean
    s.out$q05 <- q05 <- mod$ZZ.q1
    s.out$q95 <- q95 <- mod$ZZ.q2
  }

  # [ PLOT ] ====
  if (print.plot & class(x) == "numeric") {
    main <- "Bayesian Gaussian Process"
    if (!is.null(new.x)) {
      xl <- list(new.x, new.x, new.x)
    } else {
      xl <- list(x, x, x)
    }
    xl.index <- lapply(xl, order)
    xl <- lapply(1:length(xl), function(i) xl[[i]][xl.index[[i]]])
    yl <- list(mean, q95, q05)
    yl <- lapply(1:length(xl), function(i) yl[[i]][xl.index[[i]]])
    xlim <- range(c(x, new.x))
    ylim <- range(c(y, q95, q05))
    par.orig <- par(no.readonly = TRUE)
    if (par.reset) on.exit(suppressWarnings(par(par.orig)))

    mplot3(x, y, main = main,
           fit = "gam", fit.col = pennCol$orange,
           lty = 1, lwd = lwd,
           xlab = x.name, ylab = y.name,
           xlim = xlim, ylim = ylim,
           mar = c(3, 3, 3, 4),
           cex = cex,
           par.reset = F)
    col <- c(pennCol$orange, pennCol$blue, pennCol$red, pennCol$red)
    lty <- list(mean = 2, q95 = 3, q05 = 3)
    for (i in 1:length(xl)) {
      lines(xl[[i]], yl[[i]], lwd = lwd, col = col[[i + 1]], lty = lty[[i]])
    }
    legend <- c("GAM fit", "   Mean", "  95th Q", "    5th Q")
    mtext(legend, 3, adj = 0, col = col,
          padj = seq(1.5, 1.5 + 1.5 * 3, 1.5), cex = cex)

  }

  #   # Only lines
  #   if (print.plot) {
  #     main <- "Bayesian Gaussian Process Regression"
  #     if (!is.null(new.x)) x <- new.x
  #     yl <- list(mean = mean, q95 = q95, q05 = q05)
  #     mplot3(x, yl, type = "l",
  #            xlab = x.name, ylab = paste("Estimated", y.name),
  #            main = main, col = c(colorAdjust("black", .5), penn.red, penn.red),
  #            group.title = "Estimated", group.names = c("Mean", "95th Q", "5th Q"))
  #   }

  # [ OUTRO ] ====
  s.out

} # rtemis::gp
