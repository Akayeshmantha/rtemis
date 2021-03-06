# s.ADDT.R
# ::rtemis::
# 2018 Gilmer Valdes, Efstathios D Gennatas egenn.github.io
# Grow rule along with tree in global env, extract leaf rules an
# Added rpart.control min.bucket = 5
# was s.ADDTminobslin

#' Additive Tree with Linear Nodes [R]
#'
#' Train an Additive Tree for Regression
#'
#' The Additive Tree grows a tree using a sequence of regularized linear models and tree stumps
#'
#' tree structure:
#' tree
#'    '-x             the data that belong to this node
#'    '-y             the outcomes that belong to this node
#'    '-Fval          the F value at this node
#'    '-index         the index that was applied to the parent node to give this
#'    '-depth         the depth of the tree at this levels
#'    '-partlin       holds output of partLin(), if run
#'          '-lin.coef         The linear model coefficients
#'          '-part.c.left      The tree-derived constant for the left partition
#'          '-part.c.right     The tree-derived constant for the right partition
#'          '-lin.val          Fval of the linear model
#'          '-part.val         Fval of the tree
#'          '-cutFeat.name     The name of the feature on which the split was performed
#'          '-cutFeat.point    The point at which the split was made, left split < this point
#'                             if the cut feature was continuous
#'          '-cutFeat.category The factor levels that correspond to the left split,
#'                             if the the cut feature was categorical
#'          '-part.index       The split index, with "L" and "R" for left and right, respectively
#'          '-split.rule       The rule, based on cutFeat.name and cutFeat.point or cutFeat.category,
#'                             based on which the split was made.
#'          '-terminal         Logical: if TRUE, partlin did not split.
#'    '-left          holds the left split, if the node was split
#'    '-right         holds the right split, if the node was split
#'    '-terminal      TRUE if it is a terminal node
#'    '-type          "split", "nosplit", "max.depth", "minobsinnode"
#'
#' @inheritParams s.GLM
#' @param max.depth Integer: Max depth of additive tree
#' @param init Initial value. Default = \code{mean(y)}
#' @param lambda Float: lambda parameter for \code{MASS::lm.ridge} Default = .01
#' @param minobsinnode Integer: Minimum N observations needed in node, before considering splitting
#' @param part.max.depth Integer: Max depth for each tree model within the additive tree
#' @author Gilmer Valdes (algorithm), Efstathios D. Gennatas (R code)
#' @export

s.ADDT <- function(x, y = NULL,
                   x.test = NULL, y.test = NULL,
                   max.depth = 5,
                   lambda = .05,
                   minobsinnode = 2,
                   minobsinnode.lin = 10,
                   learning.rate = 1,
                   part.minsplit = 2,
                   part.xval = 0,
                   part.max.depth = 1,
                   part.cp = 0,
                   weights = NULL,
                   metric = "MSE",
                   maximize = FALSE,
                   grid.resample.rtset = rtset.grid.resample(),
                   init = NULL,
                   keep.x = FALSE,
                   simplify = TRUE,
                   cxrcoef = FALSE,
                   n.cores = rtCores,
                   verbose = TRUE,
                   verbose.predict = FALSE,
                   trace = 0,
                   x.name = NULL,
                   y.name = NULL,
                   question = NULL,
                   outdir = NULL,
                   print.plot = TRUE,
                   plot.fitted = NULL,
                   plot.predicted = NULL,
                   plot.theme = getOption("rt.fit.theme", "lightgrid"),
                   save.mod = FALSE) {

  # [ INTRO ] ====
  if (missing(x)) {
    print(args(s.ADDT))
    return(invisible(9))
  }
  if (!is.null(outdir)) outdir <- paste0(normalizePath(outdir, mustWork = FALSE), "/")
  logFile <- if (!is.null(outdir)) {
    paste0(outdir, "/", sys.calls()[[1]][[1]], ".", format(Sys.time(), "%Y%m%d.%H%M%S"), ".log")
  } else {
    NULL
  }
  start.time <- intro(verbose = verbose, logFile = logFile)
  call <- NULL
  mod.name <- "ADDT"

  # [ DEPENDENCIES ] ====
  if (!depCheck("MASS", "rpart", verbose = FALSE)) {
    cat("\n"); stop("Please install dependencies and try again")
  }

  # [ ARGUMENTS ] ====
  if (is.null(x.name)) x.name <- getName(x, "x")
  if (is.null(y.name)) y.name <- getName(y, "y")

  # [ DATA ] ====
  dt <- dataPrepare(x, y, x.test, y.test,
                    # ipw = ipw, ipw.type = ipw.type,
                    # upsample = upsample, upsample.seed = upsample.seed,
                    verbose = verbose)
  x <- dt$x
  y <- dt$y
  x.test <- dt$x.test
  y.test <- dt$y.test
  xnames <- dt$xnames
  type <- dt$type
  if (type != "Regression") stop("This function currently only supports Regression. Use s.AADDT for Classification")
  # .classwt <- if (is.null(classwt) & ipw) dt$class.weights else classwt
  if (verbose) dataSummary(x, y, x.test, y.test, type)
  if (verbose) parameterSummary(max.depth, lambda, minobsinnode)
  if (print.plot) {
    if (is.null(plot.fitted)) plot.fitted <- if (is.null(y.test)) TRUE else FALSE
    if (is.null(plot.predicted)) plot.predicted <- if (!is.null(y.test)) TRUE else FALSE
  } else {
    plot.fitted <- plot.predicted <- FALSE
  }
  if (is.null(init)) init <- mean(y)

  # [ GLOBAL ] ====
  .env <- environment()

  # [ GRID SEARCH ] ====
  if (gridCheck(max.depth, lambda, minobsinnode, learning.rate, part.cp)) {
    gs <- gridSearchLearn(x, y,
                          mod.name,
                          resample.rtset = grid.resample.rtset,
                          grid.params = list(max.depth = max.depth,
                                             lambda = lambda,
                                             minobsinnode = minobsinnode,
                                             learning.rate = learning.rate,
                                             part.cp = part.cp),
                          weights = weights,
                          maximize = maximize,
                          verbose = verbose,
                          n.cores = n.cores)
    max.depth <- gs$best.tune$max.depth
    lambda <- gs$best.tune$lambda
    minobsinnode <- gs$best.tune$minobsinnode
    learning.rate <- gs$best.tune$learning.rate
    part.cp <- gs$best.tune$part.cp
  } else {
    gs <- NULL
  }

  # [ lin1 ] ====
  if (verbose) msg0("Training Additive Tree (max depth = ", max.depth, ")...",
                    newline = TRUE)

  lin1 <- MASS::lm.ridge(y ~ ., data.frame(x, y), lambda = lambda)
  coef.c <- coef(lin1)
  Fval <- init + learning.rate * (data.matrix(cbind(1, x)) %*% coef.c)[, 1]

  # [ .addTree ] ====
  root <- list(x = x,
               y = y,
               Fval = Fval,
               index = rep(1, length(y)),
               depth = 0,
               partlin = NULL,    # To hold the output of partLin()
               left = NULL,       # \  To hold the left and right nodes,
               right = NULL,      # /  if partLin splits
               lin = NULL,
               part = NULL,
               coef.c = coef.c,
               terminal = FALSE,
               type = NULL,
               rule = "TRUE")
  mod <- addTree(node = root,
                 max.depth = max.depth,
                 minobsinnode = minobsinnode,
                 minobsinnode.lin = minobsinnode.lin,
                 learning.rate = learning.rate,
                 lambda = lambda,
                 coef.c = coef.c,
                 part.minsplit = part.minsplit,
                 part.xval = part.xval,
                 part.max.depth = part.max.depth,
                 part.cp = part.cp,
                 .env = .env,
                 keep.x = keep.x,
                 simplify = simplify,
                 verbose = verbose,
                 trace = trace)
  mod$init <- init
  mod$leafs <- list(rule = .env$leaf.rule,
                    coef = .env$leaf.coef)
  class(mod) <- c("addTree", "list")

  parameters <- list(max.depth = max.depth,
                     minobsinnode = minobsinnode,
                     learning.rate = learning.rate,
                     lambda = lambda)

  # [ FITTED ] ====
  fitted <- predict.addTree(mod, x,
                            learning.rate = learning.rate,
                            trace = trace,
                            verbose = verbose.predict,
                            cxrcoef = cxrcoef)
  if (cxrcoef) {
    cxrcoef <- fitted$cxrcoef
    fitted <- fitted$yhat
    mod$cxrcoef <- cxrcoef
  } else {
    cxrcoef <- NULL
  }
  error.train <- modError(y, fitted)
  if (verbose) errorSummary(error.train)

  # [ PREDICTED ] ====
  predicted <- error.test <- NULL
  if (!is.null(x.test)) {
    predicted <- predict.addTree(mod, x.test,
                                 learning.rate = learning.rate,
                                 trace = trace,
                                 verbose = verbose.predict)
    if (!is.null(y.test)) {
      error.test <- modError(y.test, predicted)
      if (verbose) errorSummary(error.test)
    }
  }

  # [ OUTRO ] ====
  extra <- list(gridSearch = gs)
  rt <- rtModSet(mod = mod,
                 mod.name = mod.name,
                 type = type,
                 parameters = parameters,
                 call = call,
                 y.train = y,
                 y.test = y.test,
                 x.name = x.name,
                 y.name = y.name,
                 xnames = xnames,
                 fitted = fitted,
                 se.fit = NULL,
                 error.train = error.train,
                 predicted = predicted,
                 se.prediction = NULL,
                 error.test = error.test,
                 varimp = NULL,
                 question = question,
                 extra = extra)

  rtMod.out(rt,
            print.plot,
            plot.fitted,
            plot.predicted,
            y.test,
            mod.name,
            outdir,
            save.mod,
            verbose,
            plot.theme)

  outro(start.time, verbose = verbose, sinkOff = ifelse(is.null(logFile), FALSE, TRUE))
  rt

} # rtemis:: s.ADDT


#' \pkg{rtemis} internal: Recursive function to build Additive Tree
#'
#' @keywords internal
addTree <- function(node = list(x = NULL,
                                y = NULL,
                                Fval = NULL,
                                index = NULL,
                                depth = NULL,
                                partlin = NULL,    # To hold the output of partLin()
                                left = NULL,       # \  To hold the left and right nodes,
                                right = NULL,      # /  if partLin splits
                                lin = NULL,
                                part = NULL,
                                coef.c = NULL,
                                terminal = NULL,
                                type = NULL,
                                rule = NULL),
                    coef.c = 0,
                    max.depth = 7,
                    minobsinnode = 2,
                    minobsinnode.lin = 5,
                    learning.rate = 1,
                    lambda = .01,
                    part.minsplit = 2,
                    part.xval = 0,
                    part.max.depth = 1,
                    part.cp = 0,
                    .env = NULL,
                    keep.x = FALSE,
                    simplify = FALSE,
                    verbose = TRUE,
                    trace = 0) {

  # [ EXIT ] ====
  if (node$terminal) return(node)

  x <- node$x
  y <- node$y
  depth <- node$depth
  Fval <- node$Fval
  if (trace > 1) msg("y is", y)
  if (trace > 1) msg("Fval is", Fval)
  resid <- y - Fval
  nobsinnode <- length(node$index)

  # [ Add partlin to node ] ====
  if (node$depth < max.depth && nobsinnode >= minobsinnode) {
    if (trace > 1) msg("y1 (resid) is", resid)
    node$partlin <- partLin(x1 = x, y1 = resid,
                            lambda = lambda,
                            part.minsplit = part.minsplit,
                            part.xval = part.xval,
                            part.max.depth = part.max.depth,
                            part.cp = part.cp,
                            minobsinnode.lin = minobsinnode.lin,
                            verbose = verbose,
                            trace = trace)
    # Fval <- Fval + learning.rate * (node$partlin$part.val + node$partlin$lin.val)
    # resid <- y - Fval
    if (trace > 1) msg("Fval is", Fval)

    # '- If node split ====
    if (!node$partlin$terminal) {
      node$type <- "split"
      # left.index <- node$partlin$part.index == "L"
      # right.index <- node$partlin$part.index == "R"
      left.index <- node$partlin$left.index
      right.index <- node$partlin$right.index
      if (trace > 1) msg("Depth:", depth, "left.index:", node$partlin$left.index)
      x.left <- x[left.index, , drop = FALSE]
      x.right <- x[right.index, , drop = FALSE]
      y.left <- y[left.index]
      y.right <- y[right.index]
      if (trace > 1) msg("y.left is", y.left)
      if (trace > 1) msg("y.right is", y.right)
      Fval.left <- Fval[left.index] + learning.rate * (node$partlin$part.val[left.index] + node$partlin$lin.val.left)
      Fval.right <- Fval[right.index] + learning.rate * (node$partlin$part.val[right.index] + node$partlin$lin.val.right)
      # resid.left <- y[left.index] - Fval.left
      # resid.right <- y[right.index] - Fval.right
      coef.c.left <- coef.c.right <- coef.c
      # coef.c.left[[paste0("depth", depth + 1)]] <- list(coef = node$partlin$lin.coef,
      #                                                   c = node$partlin$part.c.left)

      # Add rpart constant to intercept of linmod
      # coef.c.left[[paste0("depth", depth + 1)]] <- c(node$partlin$lin.coef[1] + node$partlin$part.c.left,
      #                                                t(node$partlin$lin.coef[-1]))
      # coef.c.right[[paste0("depth", depth + 1)]] <- c(node$partlin$lin.coef[1] + node$partlin$part.c.right,
      #                                                 t(node$partlin$lin.coef[-1]))

      # Cumulative sum of coef.c
      coef.c.left <- coef.c.left + c(node$partlin$lin.coef.left[1] + node$partlin$part.c.left,
                                     node$partlin$lin.coef.left[-1])
      coef.c.right <- coef.c.right + c(node$partlin$lin.coef.right[1] + node$partlin$part.c.right,
                                       node$partlin$lin.coef.right[-1])
      if (trace > 1) msg("coef.c.left is", coef.c.left, "coef.c.right is", coef.c.right)
      # coef.c.right[[paste0("depth", depth + 1)]] <- list(coef = node$partlin$lin.coef,
      #                                                    c = node$partlin$part.c.right)
      if (!is.null(node$partlin$cutFeat.point)) {
        rule.left <- node$partlin$split.rule
        rule.right <- gsub("<", ">=", node$partlin$split.rule)
      } else {
        rule.left <- node$partlin$split.rule
        rule.right <- paste0("!", rule.left) # fix: get cutFeat.name levels and find complement
      }

      # Init Left and Right nodes
      node$left <- list(x = x.left,
                        y = y.left,
                        Fval = Fval.left,
                        index = left.index,
                        depth = depth + 1,
                        coef.c = coef.c.left,
                        partlin = NULL,    # To hold the output of partLin()
                        left = NULL,       # \  To hold the left and right nodes,
                        right = NULL,      # /  if partLin splits
                        terminal = FALSE,
                        type = NULL,
                        rule = paste0(node$rule, " & ", node$partlin$rule.left))
      node$right <- list(x = x.right,
                         y = y.right,
                         Fval = Fval.right,
                         index = right.index,
                         depth = depth + 1,
                         coef.c = coef.c.right,
                         partlin = NULL,    # To hold the output of partLin()
                         left = NULL,       # \  To hold the right and right nodes,
                         right = NULL,      # /  if partLin splits
                         terminal = FALSE,
                         type = NULL,
                         rule = paste0(node$rule, " & ", node$partlin$rule.right))

      if (!keep.x) node$x <- NULL
      node$split.rule <- node$partlin$split.rule
      if (simplify) {
        node$y <- node$Fval <- node$index <- node$depth <- node$lin <- node$part <- node$type <- node$partlin <- NULL
      }

      # Run Left and Right nodes
      # [ LEFT ] ====
      if (trace > 0) msg("Depth = ", depth + 1, "; Working on Left node...", sep = "")
      node$left <- addTree(node$left,
                           coef.c = coef.c.left,
                           max.depth = max.depth,
                           minobsinnode = minobsinnode,
                           minobsinnode.lin = minobsinnode.lin,
                           learning.rate = learning.rate,
                           lambda = lambda,
                           part.minsplit = part.minsplit,
                           part.xval = part.xval,
                           part.max.depth = part.max.depth,
                           part.cp = part.cp,
                           .env = .env,
                           keep.x = keep.x,
                           simplify = simplify,
                           verbose = verbose,
                           trace = trace)
      # [ RIGHT ] ====
      if (trace > 0) msg("Depth = ", depth + 1, "; Working on Right node...", sep = "")
      node$right <- addTree(node$right,
                            coef.c = coef.c.right,
                            max.depth = max.depth,
                            minobsinnode = minobsinnode,
                            minobsinnode.lin = minobsinnode.lin,
                            learning.rate = learning.rate,
                            lambda = lambda,
                            part.minsplit = part.minsplit,
                            part.xval = part.xval,
                            part.max.depth = part.max.depth,
                            part.cp = part.cp,
                            .env = .env,
                            keep.x = keep.x,
                            simplify = simplify,
                            verbose = verbose,
                            trace = trace)
      if (simplify) node$coef.c <- NULL
    } else {
      # partLin did not split
      node$terminal <- TRUE
      .env$leaf.rule <- c(.env$leaf.rule, node$rule)
      .env$leaf.coef <- c(.env$leaf.coef, list(node$coef.c))
      node$type <- "nosplit"
      if (trace > 0) msg("STOP: nosplit")
      if (simplify) node$x <- node$y <- node$Fval <- node$index <- node$depth <- node$type <- node$partlin <- NULL
    } # !node$terminal

  } else {
    # max.depth or minobsinnode reached
    node$terminal <- TRUE
    .env$leaf.rule <- c(.env$leaf.rule, node$rule)
    .env$leaf.coef <- c(.env$leaf.coef, list(node$coef.c))
    if (node$depth == max.depth) {
      if (trace > 0) msg("STOP: max.depth")
      node$type <- "max.depth"
    } else if (nobsinnode < minobsinnode) {
      if (trace > 0) msg("STOP: minobsinnode")
      node$type <- "minobsinnode"
    }
    if (simplify) node$x <- node$y <- node$Fval <- node$index <- node$depth <- node$type <- node$partlin <- NULL
    return(node)
  } # max.depth, minobsinnode

  node

} # rtemis::addTree


#' \pkg{rtemis} internal: Ridge and Stump
#'
#' Fit a linear model on (x, y) and a tree on the residual yhat - y
partLin <- function(x1, y1,
                    lambda = 1,
                    part.minsplit = 2,
                    part.xval = 0,
                    part.max.depth = 1,
                    part.cp = 0,
                    minobsinnode.lin = 5,
                    verbose = TRUE,
                    trace = 0) {

  # [ PART ] ====
  dat <- data.frame(x1, y1)
  part <- rpart::rpart(y1 ~., dat,
                       control = rpart::rpart.control(minsplit = part.minsplit,
                                                      xval = part.xval,
                                                      maxdepth = part.max.depth,
                                                      minbucket = 5,
                                                      cp = part.cp))
  part.val <- predict(part)

  if (is.null(part$splits)) {
    if (trace > 0) msg("Note: rpart did not split")
    terminal <- TRUE
    cutFeat.name <- cutFeat.point <- cutFeat.category <- NULL
    split.rule <- NULL
    part.c.left <- part.c.right <- 0
    left.index <- right.index <- split.rule.left <- split.rule.right <- NULL
    lin.val.left <- lin.val.right <- 0
    lin.coef.left <- lin.coef.right <- rep(0, NCOL(x1) + 1)
  } else {
    if (part$splits[1, 2] == 1) {
      left.yval.row <- 3
      right.yval.row <- 2
    } else {
      left.yval.row <- 2
      right.yval.row <- 3
    }
    part.c.left <- part$frame$yval[left.yval.row]
    part.c.right <- part$frame$yval[right.yval.row]
    terminal <- FALSE
    cutFeat.name <- rownames(part$splits)[1]
    cutFeat.point <- cutFeat.category <- NULL
    if (!is.null(cutFeat.name)) {
      cutFeat.index <- which(names(x1) == cutFeat.name)
      if (is.numeric(x1[[cutFeat.name]])) {
        cutFeat.point <- part$splits[1, "index"]
        if (trace > 0) msg("Split Feature is \"", cutFeat.name,
                           "\"; Cut Point = ", cutFeat.point,
                           sep = "")
        split.rule.left <- paste(cutFeat.name, "<", cutFeat.point)
        split.rule.right <- paste(cutFeat.name, ">=", cutFeat.point)
        # split.rule.i <- paste0("X[, ", cutFeat.index,"]", " < ", cutFeat.point)
      } else {
        cutFeat.category <- levels(x1[[cutFeat.name]])[which(part$csplit[1, ] == 1)]
        if (trace > 0) msg("Split Feature is \"", cutFeat.name,
                           "\"; Cut Category is \"", cutFeat.category,
                           "\"", sep = "")
        split.rule.left <- paste0(cutFeat.name, " %in% ", "c(", paste(cutFeat.category, collapse = ", "))
        split.rule.right <- paste0("!", cutFeat.name, " %in% ", "c(", paste(cutFeat.category, collapse = ", "))
        # split.rule.i <- paste0("X[, ", cutFeat.index,"]", " %in% ", "c(", paste(cutFeat.category, collapse = ", "))
      }
      # part.index <- rep("R", length(y1))
      if (length(cutFeat.point) > 0) {
        # CHANGE: calc left+right index directly here
        # part.index[x1[, cutFeat.index] < cutFeat.point] <- "L"
        left.index <- which(x1[, cutFeat.index] < cutFeat.point)
        right.index <- seq(NROW(x1))[-left.index]
      } else {
        # part.index[is.element(x1[, cutFeat.index], cutFeat.category)] <- "L"
        left.index <- which(is.element(x1[, cutFeat.index], cutFeat.category))
        right.index <- seq(NROW(x1))[-left.index]
      }
    }
  }

  # [ LIN ] ====
  resid <- y1 - part.val
  resid.left <- resid[left.index]
  resid.right <- resid[right.index]
  if (!is.null(cutFeat.name)) {
    if (is.constant(resid.left) | length(resid.left) < minobsinnode.lin) {
      if (trace > 0) msg("Not fitting any more lines here")
      lin.val.left <- rep(0, length(left.index))
      lin.coef.left <- rep(0, NCOL(x1) + 1)
    } else {
      dat <- data.frame(x1[left.index, , drop = FALSE], resid.left)
      if (NCOL(x1) > 1) {
        lin.left <- MASS::lm.ridge(resid.left ~ ., dat, lambda = lambda)
      } else {
        lin.left <- s.GLM(dat, verbose = FALSE, print.plot = FALSE)$mod
      }

      lin.coef.left <- coef(lin.left)
      if (NCOL(x1) > 1) {
        lin.val.left <- (data.matrix(cbind(1, x1[left.index, ])) %*% lin.coef.left)[, 1]
      } else {
        lin.val.left <- predict(lin.left, x1[left.index, , drop = FALSE])
      }
    } # if (is.constant(resid.left))

    if (is.constant(resid.right) | length(resid.right) < minobsinnode.lin) {
      if (trace > 0) msg("Not fitting any more lines here")
      lin.val.right <- rep(0, length(right.index))
      lin.coef.right <- rep(0, NCOL(x1) + 1)
    } else {
      dat <- data.frame(x1[right.index, , drop = FALSE], resid.right)
      if (NCOL(x1) > 1) {
        lin.right <- MASS::lm.ridge(resid.right ~ ., dat, lambda = lambda)
      } else {
        lin.right <- s.GLM(dat, verbose = FALSE, print.plot = FALSE)$mod
      }

      lin.coef.right <- coef(lin.right)
      if (NCOL(x1) > 1) {
        lin.val.right <- (data.matrix(cbind(1, x1[right.index, ])) %*% lin.coef.right)[, 1]
      } else {
        lin.val.right <- predict(lin.right, x1[right.index, , drop = FALSE])
      }
    } # if (is.constant(resid.right))

  } # if (!is.null(cutFeat.name))


  list(lin.coef.left = lin.coef.left,
       lin.coef.right = lin.coef.right,
       part.c.left = part.c.left,
       part.c.right = part.c.right,
       lin.val.left = lin.val.left,
       lin.val.right = lin.val.right,
       part.val = part.val,
       cutFeat.name = cutFeat.name,
       cutFeat.point = cutFeat.point,
       cutFeat.category = cutFeat.category,
       left.index = left.index,
       right.index = right.index,
       split.rule = split.rule.left,
       # split.rule.i = split.rule.i,
       rule.left = split.rule.left,
       rule.right = split.rule.right,
       terminal = terminal)

} # rtemis::partLin


#' Print method for \code{addTree} object
#'
#' @method print addTree
#' @author Efstathios D. Gennatas
#' @export

print.addTree <- function(x, ...) {

  cat("\n  An Additive Tree model\n\n")

}


# [ preorderMatch adddt ] ====
preorderMatch.addt <- function(node, x, trace = 0) {

  # [ EXIT ] ====
  if (node$terminal) return(node)

  if (trace > 1) msg("Evaluating rule at depth", node$depth)
  if (with(x, eval(parse(text = node$split.rule)))) {
    # [ LEFT ] ====
    if (trace > 1) msg("      <--- Left")
    node <- preorderMatch.addt(node$left, x, trace = trace)
  } else {
    # [ RIGHT ] ====
    if (trace > 1) msg("           Right --->")
    node <- preorderMatch.addt(node$right, x, trace = trace)
  }

  node

} # rtemis::preorderMatch.addt


#' Predict method for \code{addTree} object
#'
#' @method predict addTree
#' @export
#' @author Efstathios D. Gennatas

predict.addTree <- function(object, newdata = NULL,
                            learning.rate = NULL,
                            n.feat = NULL,
                            verbose = FALSE,
                            cxrcoef = FALSE,
                            trace = 0, ...) {

  if (inherits(object, "rtMod")) {
    if (verbose) msg("Found rtMod object")
    tree <- object$mod
    learning.rate <- object$parameters$learning.rate
    if (is.null(n.feat)) n.feat <- length(object$xnames)
  } else if (inherits(object, "addTree")) {
    if (verbose) msg("Found addTree object")
    tree <- object
    if (is.null(learning.rate)) stop("Please provide learning rate")
    if (is.null(n.feat)) n.feat <- NCOL(newdata)
  } else {
    stop("Please provide an object of class 'rtMod' with a trained additive tree, or an 'addTree' object")
  }

  if (is.null(newdata)) return(object$fitted)

  # [ newdata colnames ] ====
  if (is.null(colnames(newdata))) colnames(newdata) <- paste0("V", seq(NCOL(newdata)))

  # [ PREDICT ] ====
  # ncases <- NROW(newdata)
  # yhat <- vector("numeric", ncases)
  #
  # for (i in seq(ncases)) {
  #   leaf <- preorderMatch.addt(tree, newdata[i, , drop = FALSE], trace = trace)
  #   yhat[i] <- tree$init + learning.rate * (data.matrix(cbind(1, newdata[i, , drop = FALSE])) %*% leaf$coef.c)
  # }
  # yhat
  newdata <- newdata[, seq(n.feat), drop = FALSE]
  rules <- plyr::ldply(tree$leafs$rule)[, 1]
  cxr <- matchCasesByRules(newdata, rules)
  coefs <- plyr::laply(tree$leafs$coef, c)
  .cxrcoef <- cxr %*% coefs
  newdata <- data.matrix(cbind(1, newdata))
  yhat <- sapply(seq(NROW(newdata)), function(n)
    tree$init + learning.rate * (newdata[n, ] %*% t(.cxrcoef[n, , drop = FALSE])))

  if (cxrcoef) {
    return(list(yhat = yhat, cxrcoef = .cxrcoef))
  } else {
    return(yhat)
  }

} # rtemis:: predict.addtree


#' Extract coefficients from Additive Tree leaves
#'
#' @param object \code{addTree} object
#' @param newdata matrix/data.frame of features
#' @param verbose Logical: If TRUE, print output to console
#' @param trace Integer {0:2} Increase verbosity
#' @author Efstathios D. Gennatas
#' @export
betas.addTree <- function(object, newdata,
                          verbose = FALSE,
                          trace = 0) {

  if (inherits(object, "rtMod")) {
    tree <- object$mod
  } else if (inherits(object, "addTree")) {
    tree <- object
  } else {
    stop("Please provide an object of class 'rtMod' with a trained additive tree, or an 'addTree' object")
  }

  # [ newdata colnames ] ====
  newdata <- as.data.frame(newdata)
  if (is.null(colnames(newdata))) colnames(newdata) <- paste0("V", seq(NCOL(newdata)))

  # [ BETAS ] ====
  ncases <- NROW(newdata)
  betas <- as.data.frame(matrix(nrow = NROW(newdata), ncol = NCOL(newdata) + 1))

  # TODO: replace with fast data.table matchRules on leafs rules and coefs list
  for (i in seq(ncases)) {
    leaf <- preorderMatch.addt(tree, newdata[i, , drop = FALSE], trace = trace)
    # betas[i, ] <- rowSums(as.data.frame(leaf$coef.c)[-1, , drop = FALSE])
    betas[i, ] <- leaf$coef.c
  }
  colnames(betas) <- c("Intercept", colnames(newdata))
  betas

} # rtemis:: betas.addTree


# [ preorder adddt ] ====
preorder.addt <- function(node, x, trace = 0) {

  # [ EXIT ] ====
  if (node$terminal) return(node)

  if (trace > 1) msg("Evaluating rule at depth", node$depth)
  if (with(x, eval(parse(text = node$split.rule)))) {
    # [ LEFT ] ====
    if (trace > 1) msg("      <--- Left")
    node <- preorder.addt(node$left, x, trace = trace)
  } else {
    # [ RIGHT ] ====
    if (trace > 1) msg("           Right --->")
    node <- preorder.addt(node$right, x, trace = trace)
  }

  node

} # rtemis::preorder.addt


#' Extract coefficients from Additive Tree leaves
#'
#' @param object \code{addTree} object
#' @param newdata matrix/data.frame of features
#' @param verbose Logical: If TRUE, print output to console
#' @param trace Integer {0:2} Increase verbosity
#' @param ... Not used
#' @author Efstathios D. Gennatas
#' @export
coef.addTree <- function(object, newdata,
                         verbose = FALSE,
                         trace = 0, ...) {

  if (inherits(object, "rtMod")) {
    tree <- object$mod
  } else if (inherits(object, "addTree")) {
    tree <- object
  } else {
    stop("Please provide an object of class 'rtMod' with a trained additive tree, or an 'addTree' object")
  }

  # [ newdata colnames ] ====
  newdata <- as.data.frame(newdata)
  if (is.null(colnames(newdata))) colnames(newdata) <- paste0("V", seq(NCOL(newdata)))

  # [ BETAS ] ====
  ncases <- NROW(newdata)
  betas <- as.data.frame(matrix(nrow = NROW(newdata), ncol = NCOL(newdata) + 1))

  # TODO: replace with fast data.table matchRules on leafs rules and coefs list
  for (i in seq(ncases)) {
    leaf <- preorderMatch.addt(tree, newdata[i, , drop = FALSE], trace = trace)
    # betas[i, ] <- rowSums(as.data.frame(leaf$coef.c)[-1, , drop = FALSE])
    betas[i, ] <- leaf$coef.c
  }
  colnames(betas) <- c("Intercept", colnames(newdata))
  betas

} # rtemis:: betas.addTree
