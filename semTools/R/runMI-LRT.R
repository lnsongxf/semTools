### Terrence D. Jorgensen & Yves Rosseel
### Last updated: 5 November 2018
### Pooled likelihood ratio test for multiple imputations
### Borrowed source code from lavaan/R/lav_test_LRT.R


## -------------
## Main function
## -------------

##' Likelihood Ratio Test for Multiple Imputations
##'
##' Likelihood ratio test (LRT) for lavaan models fitted to multiple imputed
##' data sets. Statistics for comparing nested models can be calculated by
##' pooling the likelihood ratios across imputed data sets, as described by
##' Meng & Rubin (1992), or by pooling the LRT statistics from each imputation,
##' as described by Li, Meng, Raghunathan, & Rubin (1991).
##'
##' The Meng & Rubin (1992) method, also referred to as the \code{"D3"}
##' statistic, is only applicable when using a likelihood-based estimator.
##' Otherwise (e.g., DWLS for categorical outcomes), users are notified that
##' \code{test} was set to \code{"D2"}.
##'
##' \code{test = "Mplus"} implies \code{"D3"} and \code{asymptotic = TRUE}
##' (see Asparouhov & Muthen, 2010).
##'
##' Note that unlike \code{\link[lavaan]{lavTestLRT}}, \code{lavTestLRT} can
##' only be used to compare a single pair of models, not a longer list of
##' models.  To compare several nested models fitted to multiple imputations,
##' see examples on the \code{\link{compareFit}} help page.
##'
##' @aliases lavTestLRT.mi
##' @importFrom lavaan lavListInspect parTable lavTestLRT
##' @importFrom stats cov pchisq pf
##' @importFrom methods getMethod
##'
##' @param object,h1 An object of class \code{\linkS4class{lavaan.mi}}.
##'   \code{object} should be nested within (more constrained than) \code{h1}.
##' @param test \code{character} indicating which pooling method to use.
##'   \code{"D3"}, \code{"mr"}, or \code{"meng.rubin"} (default) requests the
##'   method described by Meng & Rubin (1992). \code{"D2"}, \code{"LMRR"},
##'   or \code{"Li.et.al"} requests the complete-data LRT statistic should be
##'   calculated using each imputed data set, which will then be pooled across
##'   imputations, as described in Li, Meng, Raghunathan, & Rubin (1991).
##'   Find additional details in Enders (2010, chapter 8).
##' @param asymptotic \code{logical}. If \code{FALSE} (default), the pooled test
##'   will be returned as an \emph{F}-distributed statistic with numerator
##'   (\code{df1}) and denominator (\code{df2}) degrees of freedom.
##'   If \code{TRUE}, the pooled \emph{F} statistic will be multiplied by its
##'   \code{df1} on the assumption that its \code{df2} is sufficiently large
##'   enough that the statistic will be asymptotically \eqn{\chi^2} distributed
##'   with \code{df1}.
##' @param pool.robust \code{logical}. Ignored unless \code{test = "D2"} and a
##'   robust test was requested. If \code{pool.robust = TRUE}, the robust test
##'   statistic is pooled, whereas \code{pool.robust = FALSE} will pool
##'   the naive test statistic (or difference statistic) and apply the average
##'   scale/shift parameter to it (unavailable for mean- and variance-adjusted
##'   difference statistics, so \code{pool.robust} will be set \code{TRUE}).
##' @param ... Additional arguments passed to \code{\link[lavaan]{lavTestLRT}},
##'   only if \code{test = "D2"} and \code{pool.robust = TRUE}
##'
##' @return
##'   A vector containing the LRT statistic (either an \code{F} or \eqn{\chi^2}
##'   statistic, depending on the \code{asymptotic} argument), the degrees of
##'   freedom (numerator and denominator, if \code{asymptotic = FALSE}), and a
##'   \emph{p} value. Robust statistics will also include the average (across)
##'   imputations) scaling factor and (if relevant) shift parameter(s), unless
##'   \code{pool.robust = TRUE}.
##'
##' @author
##'   Terrence D. Jorgensen (University of Amsterdam;
##'   \email{TJorgensen314@@gmail.com})
##'
##' @references
##'   Enders, C. K. (2010). \emph{Applied missing data analysis}.
##'   New York, NY: Guilford.
##'
##'   Li, K.-H., Meng, X.-L., Raghunathan, T. E., & Rubin, D. B. (1991).
##'   Significance levels from repeated \emph{p}-values with multiply-imputed
##'   data. \emph{Statistica Sinica, 1}(1), 65--92. Retrieved from
##'   \url{https://www.jstor.org/stable/24303994}
##'
##'   Meng, X.-L., & Rubin, D. B. (1992). Performing likelihood ratio tests with
##'   multiply-imputed data sets. \emph{Biometrika, 79}(1), 103--111. Retrieved
##'   from \url{https://www.jstor.org/stable/2337151}
##'
##'   Rubin, D. B. (1987). \emph{Multiple imputation for nonresponse in surveys}.
##'   New York, NY: Wiley.
##'
##' @seealso \code{\link[lavaan]{lavTestLRT}}, \code{\link{compareFit}}
##'
##' @examples
##'  \dontrun{
##' ## impose missing data for example
##' HSMiss <- HolzingerSwineford1939[ , c(paste("x", 1:9, sep = ""),
##'                                       "ageyr","agemo","school")]
##' set.seed(12345)
##' HSMiss$x5 <- ifelse(HSMiss$x5 <= quantile(HSMiss$x5, .3), NA, HSMiss$x5)
##' age <- HSMiss$ageyr + HSMiss$agemo/12
##' HSMiss$x9 <- ifelse(age <= quantile(age, .3), NA, HSMiss$x9)
##'
##' ## impute missing data
##' library(Amelia)
##' set.seed(12345)
##' HS.amelia <- amelia(HSMiss, m = 20, noms = "school", p2s = FALSE)
##' imps <- HS.amelia$imputations
##'
##' ## specify CFA model from lavaan's ?cfa help page
##' HS.model <- '
##'   visual  =~ x1 + b1*x2 + x3
##'   textual =~ x4 + b2*x5 + x6
##'   speed   =~ x7 + b3*x8 + x9
##' '
##'
##' fit1 <- cfa.mi(HS.model, data = imps, estimator = "mlm")
##' fit0 <- cfa.mi(HS.model, data = imps, estimator = "mlm", orthogonal = TRUE)
##'
##' ## By default, use D3.
##' ## Must request a chi-squared statistic to be robustified.
##' lavTestLRT.mi(fit1, h1 = fit0, asymptotic = TRUE)
##'
##' ## Using D2, you can either robustify the pooled naive statistic ...
##' lavTestLRT.mi(fit1, h1 = fit0, asymptotic = TRUE, test = "D2")
##' ## ... or pool the robust chi-squared statistic
##' lavTestLRT.mi(fit1, h1 = fit0, asymptotic = TRUE, test = "D2",
##'               pool.robust = TRUE)
##' }
##'
##' @export
lavTestLRT.mi <- function(object, h1 = NULL, test = c("D3","D2"),
                          asymptotic = FALSE, pool.robust = FALSE, ...) {
  ## check class
  if (!inherits(object, "lavaan.mi")) stop("object is not class 'lavaan.mi'")
  useImps <- sapply(object@convergence, "[[", i = "converged")
  nImps <- sum(useImps)
  DF0 <- object@testList[[ which(useImps)[1] ]][[1]][["df"]]

  ## model comparison?
  if (!is.null(h1)) {
    if (!inherits(h1, "lavaan.mi")) stop("h1 is not class 'lavaan.mi'")
    if (lavListInspect(object, "options")$test != lavListInspect(h1, "options")$test) {
      stop('Different test statistics were requested for the 2 models.')
    }
    if (any(useImps != sapply(h1@convergence, "[[", i = "converged")))
      warning('The models being compared did not converge on the same set of ',
              'imputations. Likelihood ratio test conducted using only the ',
              'imputations for which both models converged.')
    useImps <- useImps & sapply(h1@convergence, "[[", i = "converged")
    nImps <- sum(useImps)
    ## check DF
    DF1 <- h1@testList[[ which(useImps)[1] ]][[1]][["df"]]
    if (DF0 == DF1) stop("models have equal degrees of freedom")
    if (DF0 < DF1) {
      H0 <- h1
      h1 <- object
      object <- H0
      H0 <- DF1
      DF1 <- DF0
      DF0 <- H0
    }
    DF <- DF0 - DF1
  } else DF <- DF0

  ## only keep arguments relevant to pass to lavTestLRT (if D2)
  dots <- list(...)[names(formals(lavTestLRT))]

  ## check test options, backward compatibility?
  test <- tolower(test[1])
  if (test == "mplus") {
    test <- "D3"
    asymptotic <- TRUE
  }
  if (tolower(test) %in% c("mr","meng.rubin","likelihood","lrt","d3")) test <- "D3"
  if (tolower(test) %in% c("lmrr","li.et.al","pooled.wald","d2")) test <- "D2"
  if (test == "D3" && !lavListInspect(object, "options")$estimator %in% c("ML","PML","FML")) {
    message('"D3" only available using maximum likelihood estimation. ',
            'Changed test to "D2".')
    test <- "D2"
  }

  ## check for robust
  robust <- lavListInspect(object, "options")$test != "standard"
  #TODO: check for bollen-stine bootstrap test
  if (!robust) pool.robust <- FALSE

  scaleshift <- lavListInspect(object, "options")$test == "scaled.shifted"
  if (scaleshift && !is.null(h1)) {
    if (test == "D3" | !pool.robust)
      message("If test = 'scaled.shifted' (estimator = 'WLSMV' or 'MLMV'), ",
              "model comparison is only available by (re)setting test = 'D2' ",
              "and pool.robust = TRUE.\n",
              "Control more options by passing arguments to lavTestLRT() via ",
              "the '...' argument.\n")
    pool.robust <- TRUE
    test <- 'D2'
  }

  if (robust && !pool.robust && !asymptotic) {
    message('Robust correction can only be applied to pooled chi-squared ',
            'statistic, not F statistic. "asymptotic" was switched to TRUE.')
    asymptotic <- TRUE
  }

  if (pool.robust && test == "D3") {
    message('pool.robust = TRUE is only applicable when test = "D2". ',
            'Changed test to "D2".')
    test <- "D2"
  }

  ## calculate pooled test:
  if (robust && pool.robust) {
    ## pool both the naive and robust test statistics, return both to
    ## make output consistent across options
    out.naive <- D2.LRT(object, h1 = h1, asymptotic = asymptotic,
                        pool.robust = FALSE)
    out.robust <- D2.LRT(object, h1 = h1, asymptotic = asymptotic,
                         pool.robust = TRUE, LRTargs = dots)
    out <- c(out.naive, out.robust)
  } else if (test == "D2") {
    out <- D2.LRT(object, h1 = h1, asymptotic = asymptotic,
                  pool.robust = pool.robust)
  } else if (test == "D3") {
    out <- D3.LRT(object, h1 = h1, asymptotic = asymptotic)
  }

  ## If test statistic is negative, return without any indices or robustness
  if (asymptotic) {
    if (out[["chisq"]] == 0) {
      message('Negative pooled test statistic was set to zero, so fit will ',
              'appear to be arbitrarily perfect. ',
              if (robust) 'Robust corrections uninformative, not returned.',
              '\n')
      class(out) <- c("lavaan.vector","numeric")
      return(out)
    }
  } else {
    if (out[["F"]] == 0) {
      message('Negative pooled test statistic was set to zero, so fit will ',
              'appear to be arbitrarily perfect.\n')
      class(out) <- c("lavaan.vector","numeric")
      return(out)
    }
  }

  ## If robust statistics were not pooled above, robustify naive statistics
  if (robust & !pool.robust) {
    out <- robustify(ChiSq = out, object, h1, useImps)
    if (scaleshift) {
      extraWarn <- ' and shift parameter'
    } else if (lavListInspect(object, "options")$test == "mean.var.adjusted") {
      extraWarn <- ' and degrees of freedom'
    } else extraWarn <- ''
    message('Robust corrections are made by pooling the naive chi-squared ',
            'statistic across ', nImps, ' imputations for which the model ',
            'converged, then applying the average (across imputations) scaling',
            ' factor', extraWarn, ' to that pooled value. \n',
            'To instead pool the robust test statistics, set test = "D2" and ',
            'pool.robust = TRUE. \n')
  }

  class(out) <- c("lavaan.vector","numeric")
  out
}



## ----------------
## Hidden Functions
## ----------------


##' @importFrom lavaan lavListInspect parTable lavTestLRT
D2.LRT <- function(object, h1 = NULL, asymptotic = FALSE,
                   pool.robust = FALSE, LRTargs = list()) {
  useImps <- sapply(object@convergence, "[[", i = "converged")
  if (!is.null(h1)) {
    if (any(useImps != sapply(h1@convergence, "[[", i = "converged")))
      warning('The models being compared did not converge on the same set of ',
              'imputations. Likelihood ratio test conducted using only the ',
              'imputations for which both models converged.')
    useImps <- useImps & sapply(h1@convergence, "[[", i = "converged")
  }

  warn <- lavListInspect(object, "options")$warn

  if (pool.robust && !is.null(h1)) {
    PT1 <- parTable(h1)
    op1 <- lavListInspect(h1, "options")
    oldCall <- object@lavListCall #re-run lavaanList() and save DIFFTEST
    if (!is.null(oldCall$parallel)) {
      if (oldCall$parallel == "snow") {
        oldCall$parallel <- "no"
        oldCall$ncpus <- 1L
        if (warn) warning("Unable to pass lavaan::lavTestLRT() arguments when ",
                          "parallel = 'snow'. Switching to parallel = 'no'. ",
                          "Unless using Windows, parallel = 'multicore' works.")
      }
    }

    ## call lavaanList() again to run lavTestLRT() on each imputation
    oldCall$FUN <- function(obj) {
      fit1 <- try(lavaan::lavaan(PT1, slotOptions = op1, slotData = obj@Data),
                  silent = TRUE)
      if (inherits(fit1, "try-error")) {
        return("fit failed")
      } else {
        argList <- c(list(object = obj, fit1), LRTargs)
      }
      out <- try(do.call(lavTestLRT, argList),
                 silent = TRUE)
      if (inherits(out, "try-error")) return("lavTestLRT() failed")
      c(chisq = out[2, "Chisq diff"], df = out[2, "Df diff"])
    }
    FIT <- eval(as.call(oldCall))
    ## check if there are any results
    noFit <- sapply(FIT@funList, function(x) x[1] == "fit failed")
    noLRT <- sapply(FIT@funList, function(x) x[1] == "lavTestLRT() failed")
    if (all(noFit | noLRT)) stop("No success using lavTestScore() on any imputations.")

    chiList <- sapply(FIT@funList[useImps & !(noFit | noLRT)], "[[", i = "chisq")
    dfList <- sapply(FIT@funList[useImps & !(noFit | noLRT)], "[[", i = "df")
    out <- calculate.D2(chiList, DF = mean(dfList), asymptotic)
    names(out) <- paste0(names(out), ".scaled")
    class(out) <- c("lavaan.vector","numeric")
    return(out)
  }
  ## else, return model fit OR naive difference test to be robustified


  test <- if (pool.robust) 2L else 1L
  ## pool Wald tests
  if (is.null(h1)) {
    DF <- mean(sapply(object@testList[useImps], function(x) x[[test]][["df"]]))
    w <- sapply(object@testList[useImps], function(x) x[[test]][["stat"]])
  } else {
    ## this will not get run if !pool.robust because logic catches that first
    DF0 <- mean(sapply(object@testList[useImps], function(x) x[[1]][["df"]]))
    DF1 <- mean(sapply(h1@testList[useImps], function(x) x[[1]][["df"]]))
    DF <- DF0 - DF1
    w0 <- sapply(object@testList[useImps], function(x) x[[1]][["stat"]])
    w1 <- sapply(h1@testList[useImps], function(x) x[[1]][["stat"]])
    w <- w0 - w1
    ## check DF
    if (DF < 0) {
      w <- -1*w
      DF <- -1*DF
    }
  }
  out <- calculate.D2(w, DF, asymptotic)
  ## add .scaled suffix
  if (pool.robust) names(out) <- paste0(names(out), ".scaled")
  ## for 1 model, add extra info (redundant if pool.robust)
  if (is.null(h1) & !pool.robust) {
    PT <- parTable(object)
    out <- c(out, npar = max(PT$free) - sum(PT$op == "=="),
             ntotal = lavListInspect(object, "ntotal"))
  }

  class(out) <- c("lavaan.vector","numeric")
  out
}

##' @importFrom lavaan parTable lavaan lavListInspect
##' @importFrom methods getMethod
getLLs <- function(object, useImps, saturated = FALSE) {
  ## FIXME: lavaanList does not return info when fixed because no convergence!
  dataList <- object@DataList[useImps]
  lavoptions <- lavListInspect(object, "options")

  group <- lavListInspect(object, "group")
  if (length(group) == 0L) group <- NULL
  cluster <- lavListInspect(object, "cluster")
  if (length(cluster) == 0L) cluster <- NULL

  if (saturated) {
    fit <- lavaan(parTable(object), data = dataList[[ which(useImps)[1] ]],
                  slotOptions = lavoptions, group = group, cluster = cluster)
    ## use saturated parameter table as new model
    PT <- lavaan::lav_partable_unrestricted(fit)
    ## fit saturated parameter table to each imputation, return estimates
    satParams <- lapply(object@DataList[useImps], function(d) {
      parTable(lavaan(model = PT, data = d, slotOptions = lavoptions,
                      group = group, cluster = cluster))$est
    })
    ## set all parameters fixed
    PT$free <- 0L
    PT$user <- 1L
    ## fix them to pooled estimates
    PT$ustart <- colMeans(do.call(rbind, satParams))
    PT$start <- NULL
    PT$est <- NULL
    PT$se <- NULL
  } else {
    ## save parameter table as new model
    PT <- parTable(object)
    ## set all parameters fixed
    PT$free <- 0L
    PT$user <- 1L
    ## fix them to pooled estimates
    fixedValues <- getMethod("coef","lavaan.mi")(object, type = "user")
    PT$ustart <- fixedValues
    PT$start <- NULL
    PT$est <- NULL
    PT$se <- NULL
    ## omit (in)equality constraints and user-defined parameters
    params <- !(PT$op %in% c("==","<",">",":="))
    PT <- PT[params, ]
  }
  ## return log-likelihoods
  sapply(object@DataList[useImps], function(d) {
    lavaan::logLik(lavaan(PT, data = d, slotOptions = lavoptions,
                          group = group, cluster = cluster))
  })
}

##' @importFrom stats pf pchisq
##' @importFrom lavaan lavListInspect parTable
D3.LRT <- function(object, h1 = NULL, asymptotic = FALSE) {
  N <- lavListInspect(object, "ntotal")
  useImps <- sapply(object@convergence, "[[", i = "converged")
  # m <- length(object@testList)
  nImps <- sum(useImps)
  if (!is.null(h1)) {
    if (any(useImps != sapply(h1@convergence, "[[", i = "converged")))
      warning('The models being compared did not converge on the same set of ',
              'imputations. Likelihood ratio test conducted using only the ',
              'imputations for which both models converged.')
    useImps <- useImps & sapply(h1@convergence, "[[", i = "converged")
    nImps <- sum(useImps)
  }
  if (is.null(h1)) {
    DF <- object@testList[[ which(useImps)[1] ]][[1]][["df"]]
  } else {
    DF1 <- h1@testList[[ which(useImps)[1] ]][[1]][["df"]]
    DF0 <- object@testList[[ which(useImps)[1] ]][[1]][["df"]]
    DF <- DF0 - DF1
    if (DF < 0) stop('The "object" model must be nested within (i.e., have ',
                     'fewer degrees of freedom than) the "h1" model.')
  }

  ## calculate m log-likelihoods under pooled H0 estimates
  LL0 <- getLLs(object, useImps)
  ## calculate m log-likelihoods under pooled H1 estimates
  if (is.null(h1)) {
    LL1 <- getLLs(object, useImps, saturated = TRUE)
  } else {
    LL1 <- getLLs(h1, useImps)
  }
  #FIXME: check whether LL1 or LL0 returned errors?  add try()?

  ## calculate average of m LRTs
  LRT_con <- mean(-2*(LL0 - LL1)) # getLLs() already applies [useImps]
  ## average chisq across imputations
  if (is.null(h1)) {
    LRT_bar <- mean(sapply(object@testList[useImps], function(x) x[[1]]$stat))
  } else {
    LRT_bar <- mean(sapply(object@testList[useImps], function(x) x[[1]]$stat) -
                      sapply(h1@testList[useImps], function(x) x[[1]]$stat))
  }
  ## calculate average relative increase in variance
  a <- DF*(nImps - 1)
  ariv <- ((nImps + 1) / a) * (LRT_bar - LRT_con)
  test.stat <- LRT_con / (DF*(1 + ariv))
  if (is.na(test.stat)) stop('D3 test statistic could not be calculated. ',
                             'Try the D2 pooling method.') #FIXME: check whether model-implied Sigma is NPD
  if (test.stat < 0) {
    message('Negative test statistic set to zero \n')
    test.stat <- 0
  }
  if (asymptotic) {
    out <- c("chisq" = test.stat * DF, df = DF,
             pvalue = pchisq(test.stat * DF, df = DF, lower.tail = FALSE))
  } else {
    ## F statistic
    if (a > 4) {
      v4 <- 4 + (a - 4) * (1 + (1 - (2 / a))*(1 / ariv))^2 # Enders (eq. 8.34)
    } else {
      v4 <- a*(1 + 1/DF)*(1 + 1/ariv)^2 / 2 # Enders (eq. 8.35)
      # v4 <- (DF + 1)*(m - 1)*(1 + (1 / ariv))^2 / 2 # Grund et al. (eq. 9)
    }
    out <- c("F" = test.stat, df1 = DF, df2 = v4,
             pvalue = pf(test.stat, df1 = DF, df2 = v4, lower.tail = FALSE))
  }
  ## add log-likelihood and AIC/BIC for target model
  if (is.null(h1)) {
    PT <- parTable(object)
    npar <- max(PT$free) - sum(PT$op == "==")
    out <- c(out, npar = npar, ntotal = N,
             logl = mean(LL0), unrestricted.logl = mean(LL1),
             aic = -2*mean(LL0) + 2*npar, bic = -2*mean(LL0) + npar*log(N),
             bic2 = -2*mean(LL0) + npar*log((N + 2) / 24))
    ## NOTE: Mplus reports the average of m likelihoods evaluated at the
    ##       m point estimates, not evaluated at the pooled point estimates.
    ##       Mplus also uses those to calcluate AIC and BIC.
  }

  class(out) <- c("lavaan.vector","numeric")
  out
}

##' @importFrom stats pchisq
##' @importFrom lavaan lavListInspect
robustify <- function(ChiSq, object, h1 = NULL, useImps) {
  scaleshift <- lavListInspect(object, "options")$test == "scaled.shifted"

  d0 <- mean(sapply(object@testList[useImps], function(x) x[[2]][["df"]]))
  c0 <- mean(sapply(object@testList[useImps],
                    function(x) x[[2]][["scaling.factor"]]))
  if (!is.null(h1)) {
    d1 <- mean(sapply(h1@testList[useImps], function(x) x[[2]][["df"]]))
    c1 <- mean(sapply(h1@testList[useImps],
                      function(x) x[[2]][["scaling.factor"]]))
    delta_c <- (d0*c0 - d1*c1) / (d0 - d1)
    ChiSq["chisq.scaled"] <- ChiSq[["chisq"]] / delta_c
    ChiSq["df.scaled"] <- d0 - d1
    ChiSq["pvalue.scaled"] <- pchisq(ChiSq[["chisq.scaled"]],
                                     df = ChiSq[["df.scaled"]],
                                     lower.tail = FALSE)
    ChiSq["chisq.scaling.factor"] <- delta_c
  } else {
    ChiSq["chisq.scaled"] <- ChiSq[["chisq"]] / c0
    ChiSq["df.scaled"] <- d0
    if (scaleshift) {
      ## add average shift parameter (or average of sums, if nG > 1)
      shift <- mean(sapply(object@testList[useImps],
                           function(x) sum(x[[2]][["shift.parameter"]]) ))
      ChiSq["chisq.scaled"] <- ChiSq[["chisq.scaled"]] + shift
      ChiSq["pvalue.scaled"] <- pchisq(ChiSq[["chisq.scaled"]],
                                       df = ChiSq[["df.scaled"]],
                                       lower.tail = FALSE)
      ChiSq["chisq.scaling.factor"] <- c0
      ChiSq["chisq.shift.parameters"] <- shift
    } else {
      ChiSq["pvalue.scaled"] <- pchisq(ChiSq[["chisq.scaled"]],
                                       df = ChiSq[["df.scaled"]],
                                       lower.tail = FALSE)
      ChiSq["chisq.scaling.factor"] <- c0
    }
  }
  ChiSq
}

