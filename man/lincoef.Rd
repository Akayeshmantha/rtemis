% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lincoef.R
\name{lincoef}
\alias{lincoef}
\title{Linear Model Coefficients}
\usage{
lincoef(x, y, weights = NULL, method = c("glmnet", "cv.glmnet",
  "lm.ridge", "allSubsets", "forwardStepwise", "backwardStepwise", "glm",
  "sgd", "solve"), alpha = 0, lambda = 0.01, lambda.seq = NULL,
  cv.glmnet.nfolds = 5, which.cv.glmnet.lambda = c("lambda.min",
  "lambda.1se"), nbest = 1, nvmax = 8, sgd.model = "glm",
  sgd.model.control = list(lambda1 = 0, lambda2 = 0),
  sgd.control = list(method = "ai-sgd"), ...)
}
\arguments{
\item{x}{Features}

\item{y}{Outcome}

\item{weights}{Float, vector: Case weights}

\item{method}{String: Method to use: 
"glm": uses \code{stats::lm.wfit};
"glmnet": uses \code{glmnet::glmnet};
"cv.glmnet": uses \code{glmnet:cv.glmnet};
"lm.ridge": uses \code{MASS::lm.ridge};
"allsubsets": uses \code{leaps::regsubsets} with \code{method = "exhaustive"};
"forwardStepwise": uses \code{leaps::regsubsets} with \code{method = "forward};
"backwardStepwise": uses \code{leaps::regsubsets} with \code{method = "backward};
"sgd": uses \code{sgd::sgd}
"solve": uses \code{base::solve}}

\item{alpha}{Float: \code{alpha} for method = \code{glmnet} or \code{cv.glmnet}. Default = 0}

\item{lambda}{Float: The lambda value for \code{glmnet}, \code{cv.glmnet}, \code{lm.ridge}
Note: For \code{glmnet} and \code{cv.glmnet}, this is the lambda used for prediction. Training uses
\code{lambda.seq}. Default = .01}

\item{lambda.seq}{Float, vector: lambda sequence for \code{glmnet} and \code{cv.glmnet}. Default = NULL}

\item{cv.glmnet.nfolds}{Integer: Number of folds for \code{cv.glmnet}}

\item{which.cv.glmnet.lambda}{String: Whitch lambda to pick from cv.glmnet:
"lambda.min": Lambda that gives minimum cross-validated error;}

\item{nbest}{Integer: For \code{method = "allSubsets"}, number of subsets of each size to record. Default = 1}

\item{nvmax}{Integer: For \code{method = "allSubsets"}, maximum number of subsets to examine.}

\item{sgd.model}{String: Model to use for \code{method = "sgd"}. Default = "glm"}

\item{sgd.model.control}{List: \code{model.control} list to pass to \code{sgd::sgd}}

\item{sgd.control}{List: \code{sgd.control} list to pass to \code{sgd::sgd}}

\item{...}{Additional parameters to pass to \code{leaps::regsubsets}
"lambda.1se": Largest lambda such that error is within 1 s.e. of the minimum.}
}
\value{
Coefficients
}
\description{
Get linear model coefficients
}
\author{
Efstathios D. Gennatas
}
