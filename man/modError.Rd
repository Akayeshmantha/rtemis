% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/modError.R
\name{modError}
\alias{modError}
\title{Error Metrics for Supervised Learning}
\usage{
modError(true, estimated, estimated.prob = NULL, verbose = FALSE,
  type = NULL, rho = TRUE, tau = FALSE, na.rm = TRUE)
}
\arguments{
\item{true}{Vector: True values}

\item{estimated}{Vector: Estimated values}

\item{verbose}{Logical: If TRUE, print output to screen}

\item{type}{String: "Regression", "Classification", or "Survival". If not provided, will be set
to Regression if y is numeric.}

\item{rho}{Logical: If TRUE, calculate Spearman's rho. Default = TRUE}

\item{tau}{Logical: If TRUE, calculate Kendall's tau. Default = FALSE
This can be slow for long vectors}

\item{na.rm}{Logical: Passed to \code{mean} and \code{range} functions. Default = TRUE}
}
\value{
Object of class \code{modError}
}
\description{
Calculate error metrics for pair of vector, e.g. true and estimated values from a model
}
\details{
For classification, caret's confusion matrix is used, modified to include $byClass measures under
$overall. In the case of multiclass outcome, these are averaged.

In regression, NRMSE = RMSE / range(observed)
}
\author{
Efstathios D Gennatas
}
