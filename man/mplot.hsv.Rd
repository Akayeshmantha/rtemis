% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mplot.hsv.R
\name{mplot.hsv}
\alias{mplot.hsv}
\title{Plot HSV color range}
\usage{
mplot.hsv(h.steps = seq(0, 1, 0.0125), s.steps = h.steps, v = 1,
  alpha = 1, pch = 15, bg = "black", axes = TRUE, pty = "s",
  cex = 1, mar = c(3, 3, 2, 0.5), lab.col = NULL, type = c("polar",
  "cartesian"))
}
\arguments{
\item{h.steps}{Float, vector: Hue values to plot. Default = \code{seq(0, 1, .0125)}}

\item{s.steps}{Float, vector: Saturation values to plot. Default = same as \code{h.steps}}

\item{v}{Float: Value. Default = 1}

\item{alpha}{Float: Alpha. Default = 1}

\item{pch}{Integer: pch plot parameter. Default = 15 (square)}

\item{bg}{Colot: Background color. Default = "black"}

\item{axes}{Logical: for \code{type = "cartesian"}: If TRUE, draw axes. Default = TRUE}

\item{pty}{String: for \code{type = "cartesian"}: "s", "r", par's pty argument. Default = "s" (square plot)}

\item{cex}{Float: \code{par/plot}'s cex argument. Default = 1}

\item{mar}{Float, vector: for \code{type = "cartesian"}: \code{par}'s mar argument. Default = c(3, 3, 2, .5)}

\item{lab.col}{Color: Color for axes and labels. Defaults to inverse of \code{bg}, i.e. white if bg is black}

\item{type}{String: "cartesian" for square plot, "polar" for radial plot. Default = "polar"}
}
\description{
Plot HSV color range
}
\author{
Efstathios D. Gennatas
}
