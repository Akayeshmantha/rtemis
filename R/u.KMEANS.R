# u.KMEANS.R
# ::rtemis::
# 2016 Efstathios D. Gennatas egenn.github.io

#' K-means Clustering
#'
#' Perform K-means clustering
#'
#' @param x Input matrix / data.frame
#' @param x.test Testing set matrix / data.frame
#' @param k Integer: Number of clusters to get
#' @param dist String: Distance measure to use: 'euclidean' or 'manhattan'
#' @param verbose Logical: If TRUE, print messages to screen
#' @param ... Additional parameters to be passed to \code{flexclust::cclust}
#' @author Efstathios D. Gennatas
#' @family Clustering
#' @export

u.KMEANS <- function(x, x.test = NULL,
                     k = 2,
                     dist = "euclidean",
                     verbose = TRUE, ...) {

  # [ INTRO ] ====
  start.time <- intro(verbose = verbose)
  call <- NULL
  clust.name <- "KMEANS"
  if (is.null(colnames(x))) colnames(x) <- paste0("Feature.", 1:NCOL(x))
  xnames <- colnames(x)

  # [ DEPENDENCIES ] ====
  if (!depCheck("flexclust", verbose = FALSE)) {
    cat("\n"); stop("Please install dependencies and try again")
  }

  # [ ARGUMENTS ] ====
  if (missing(x)) {
    print(args(u.KMEANS))
    stop("x is missing")
  }

  # [ KMEANS ] ====
  if (verbose) msg("Performing K-means Clustering with k = ", k, "...", sep = "")
  clust <- flexclust::cclust(x,
                             k = k,
                             dist = dist,
                             method = "kmeans", ...)

  # [ CLUSTERS ] ====
  clusters.train <- flexclust::clusters(clust)
  if (!is.null(x.test)) {
    clusters.test <- flexclust::clusters(clust, x.test)
  } else {
    clusters.test <- NULL
  }

  # [ OUTRO ] ====
  cl <- rtClust$new(clust.name = clust.name,
                    k = k,
                    xnames = xnames,
                    clust = clust,
                    clusters.train = clusters.train,
                    clusters.test = clusters.test,
                    extra = list())
  outro(start.time, verbose = verbose)
  cl

} # rtemis::u.KMEANS
