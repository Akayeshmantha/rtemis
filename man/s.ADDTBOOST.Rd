% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/s.ADDTBOOST.R
\name{s.ADDTBOOST}
\alias{s.ADDTBOOST}
\title{Boosting of Additive Trees}
\usage{
s.ADDTBOOST(x, y = NULL, x.test = NULL, y.test = NULL,
  x.valid = NULL, y.valid = NULL, resid = NULL, boost.obj = NULL,
  mod.params = rtset.ADDT(), case.p = 1, weights = NULL,
  max.iter = 10, learning.rate = 0.1, init = mean(y),
  cxrcoef = FALSE, print.progress.every = 5,
  print.error.plot = "final", x.name = NULL, y.name = NULL,
  question = NULL, base.verbose = FALSE, verbose = TRUE, trace = 0,
  prefix = NULL, plot.fitted = NULL, plot.predicted = NULL,
  plot.theme = getOption("rt.fit.theme", "lightgrid"),
  print.plot = TRUE, print.base.plot = FALSE, plot.type = "l",
  outdir = NULL, save.mod = ifelse(!is.null(outdir), TRUE, FALSE), ...)
}
\arguments{
\item{x}{Data frame: Input features}

\item{y}{Vector: Output}

\item{x.test}{Numeric vector or matrix / data frame of testing set features
Columns must correspond to columns in \code{x}}

\item{y.test}{Numeric vector of testing set outcome}

\item{mod.params}{Named list of arguments for \code{mod}}

\item{weights}{Numeric vector: Weights for cases. For classification, \code{weights} takes precedence
over \code{ipw}, therefore set \code{weights = NULL} if using \code{ipw}.
Note: If \code{weight} are provided, \code{ipw} is not used. Leave NULL if setting \code{ipw = TRUE}. Default = NULL}

\item{max.iter}{Integer: Maximum number of iterations (additive steps) to perform. Default = 10}

\item{learning.rate}{Float (0, 1] Learning rate for the additive steps}

\item{init}{Float: Initial value for prediction. Default = mean(y)}

\item{cxrcoef}{Logical: If TRUE, pass \code{cxr = TRUE, cxrcoef = TRUE} to \link{predict.addTreeRaw}}

\item{print.error.plot}{String or Integer: "final" plots a training and validation (if available) error curve at the
end of training. If integer, plot training and validation error curve every this many iterations
during training}

\item{x.name}{Character: Name for feature set}

\item{y.name}{Character: Name for outcome}

\item{question}{String: the question you are attempting to answer with this model, in plain language.}

\item{base.verbose}{Logical: \code{verbose} argument passed to learner}

\item{verbose}{Logical: If TRUE, print summary to screen.}

\item{trace}{Integer: If > 0, print diagnostic info to console}

\item{plot.fitted}{Logical: if TRUE, plot True (y) vs Fitted}

\item{plot.predicted}{Logical: if TRUE, plot True (y.test) vs Predicted.
Requires \code{x.test} and \code{y.test}}

\item{plot.theme}{String: "zero", "dark", "box", "darkbox"}

\item{print.plot}{Logical: if TRUE, produce plot using \code{mplot3}
Takes precedence over \code{plot.fitted} and \code{plot.predicted}}

\item{print.base.plot}{Logical: Passed to \code{print.plot} argument of base learner, i.e. if TRUE, print error plot
for each base learner}

\item{outdir}{Path to output directory.
If defined, will save Predicted vs. True plot, if available,
as well as full model output, if \code{save.mod} is TRUE}

\item{save.mod}{Logical. If TRUE, save all output as RDS file in \code{outdir}
\code{save.mod} is TRUE by default if an \code{outdir} is defined. If set to TRUE, and no \code{outdir}
is defined, outdir defaults to \code{paste0("./s.", mod.name)}}

\item{...}{Additional parameters to be passed to learner}

\item{tolerance}{Float: If training error <= this value, training stops}

\item{tolerance.valid}{Float: If validation error <= this value, training stops}
}
\description{
Boost an additive tree using \link{addtboost}
}
\author{
Efstathios D. Gennatas
}
