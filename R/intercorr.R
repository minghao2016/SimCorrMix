#' @title Calculate Intermediate MVN Correlation for Ordinal, Continuous, Poisson, or Negative Binomial Variables: Correlation Method 1
#'
#' @description This function calculates a \code{k x k} intermediate matrix of correlations, where \code{k = k_cat + k_cont +}
#'     \code{k_pois + k_nb}, to be used in simulating variables with \code{\link[SimCorrMix]{corrvar}}.  The \code{k_cont} includes regular continuous variables
#'     and components of continuous mixture variables.  The ordering of the variables must be
#'     ordinal, continuous non-mixture, components of continuous mixture variables, regular Poisson, zero-inflated Poisson, regular Negative
#'     Binomial (NB), and zero-inflated NB (note that it is possible for \code{k_cat}, \code{k_cont}, \code{k_pois}, and/or \code{k_nb} to be 0).
#'     There are no parameter input checks in order to decrease simulation time.  All inputs should be checked prior to simulation with
#'     \code{\link[SimCorrMix]{validpar}}.  There is a message given if the calculated
#'     intermediate correlation matrix \code{Sigma} is not positive-definite because it may not be possible to find a MVN correlation
#'     matrix that will produce the desired marginal distributions.  This function is called by the simulation function
#'     \code{\link[SimCorrMix]{corrvar}}, and would only be used separately if the user wants to first find the intermediate correlation matrix.
#'     This matrix \code{Sigma} can be used as an input to \code{\link[SimCorrMix]{corrvar}}.
#'
#'     Please see the \bold{Comparison of Correlation Methods 1 and 2} vignette for information about calculations by variable pair type and the differences between
#'     this function and \code{\link[SimCorrMix]{intercorr2}}.
#'
#' @param k_cat the number of ordinal (r >= 2 categories) variables (default = 0)
#' @param k_cont the number of continuous non-mixture variables and components of continuous mixture variables (default = 0)
#' @param k_pois the number of regular and zero-inflated Poisson variables (default = 0)
#' @param k_nb the number of regular and zero-inflated Negative Binomial variables (default = 0)
#' @param method the method used to generate the \code{k_cont} continuous variables.  "Fleishman" uses a third-order polynomial transformation
#'     and "Polynomial" uses Headrick's fifth-order transformation.
#' @param constants a matrix with \code{k_cont} rows, each a vector of constants c0, c1, c2, c3 (if \code{method} = "Fleishman") or
#'     c0, c1, c2, c3, c4, c5 (if \code{method} = "Polynomial") like that returned by \code{\link[SimMultiCorrData]{find_constants}}
#' @param marginal a list of length equal to \code{k_cat}; the i-th element is a vector of the cumulative
#'     probabilities defining the marginal distribution of the i-th variable;
#'     if the variable can take r values, the vector will contain r - 1 probabilities (the r-th is assumed to be 1; default = list())
#' @param support a list of length equal to \code{k_cat}; the i-th element is a vector of containing the r
#'     ordered support values; if not provided (i.e. \code{support} = list()), the default is for the i-th element to be the vector 1, ..., r
#' @param lam a vector of lambda (mean > 0) constants for the regular and zero-inflated Poisson variables (see \code{stats::dpois});
#'     the order should be 1st regular Poisson variables, 2nd zero-inflated Poisson variables
#' @param p_zip a vector of probabilities of structural zeros (not including zeros from the Poisson distribution) for the
#'     zero-inflated Poisson variables (see \code{VGAM::dzipois}); if \code{p_zip} = 0, \eqn{Y_{pois}} has a regular Poisson
#'     distribution; if \code{p_zip} is in (0, 1), \eqn{Y_{pois}} has a zero-inflated Poisson distribution;
#'     if \code{p_zip} is in \code{(-(exp(lam) - 1)^(-1), 0)}, \eqn{Y_{pois}} has a zero-deflated Poisson distribution and \code{p_zip}
#'     is not a probability; if \code{p_zip = -(exp(lam) - 1)^(-1)}, \eqn{Y_{pois}} has a positive-Poisson distribution
#'     (see \code{VGAM::dpospois}); if \code{length(p_zip) < length(lam)}, the missing values are set to 0 (and ordered 1st)
#' @param size a vector of size parameters for the Negative Binomial variables (see \code{stats::dnbinom}); the order should be
#'     1st regular NB variables, 2nd zero-inflated NB variables
#' @param prob a vector of success probability parameters for the NB variables; order the same as in \code{size}
#' @param mu a vector of mean parameters for the NB variables (*Note: either \code{prob} or \code{mu} should be supplied for all Negative Binomial variables,
#'     not a mixture; default = NULL); order the same as in \code{size}; for zero-inflated NB this refers to
#'     the mean of the NB distribution (see \code{VGAM::dzinegbin})
#' @param p_zinb a vector of probabilities of structural zeros (not including zeros from the NB distribution) for the zero-inflated NB variables
#'     (see \code{VGAM::dzinegbin}); if \code{p_zinb} = 0, \eqn{Y_{nb}} has a regular NB distribution;
#'     if \code{p_zinb} is in \code{(-prob^size/(1 - prob^size),} \code{0)}, \eqn{Y_{nb}} has a zero-deflated NB distribution and \code{p_zinb}
#'     is not a probability; if \code{p_zinb = -prob^size/(1 - prob^size)}, \eqn{Y_{nb}} has a positive-NB distribution (see
#'     \code{VGAM::dposnegbin}); if \code{length(p_zinb) < length(size)}, the missing values are set to 0 (and ordered 1st)
#' @param rho the target correlation matrix which must be ordered
#'     \emph{1st ordinal, 2nd continuous non-mixture, 3rd components of continuous mixtures, 4th regular Poisson, 5th zero-inflated Poisson,
#'     6th regular NB, 7th zero-inflated NB}; note that \code{rho} is specified in terms of the components of \eqn{Y_{mix}}
#' @param seed the seed value for random number generation (default = 1234)
#' @param epsilon the maximum acceptable error between the pairwise correlations (default = 0.001)
#'     in the calculation of ordinal intermediate correlations with \code{\link[SimCorrMix]{ord_norm}}
#' @param maxit the maximum number of iterations to use (default = 1000) in the calculation of ordinal
#'     intermediate correlations with \code{\link[SimCorrMix]{ord_norm}}
#' @param nrand the number of random numbers to generate in calculating intermediate correlations (default = 10000)
#' @param quiet if FALSE prints simulation messages, if TRUE suppresses message printing
#' @importFrom stats cor dbeta dbinom dchisq density dexp df dgamma dlnorm dlogis dmultinom dnbinom dnorm dpois dt dunif dweibull ecdf
#'     median pbeta pbinom pchisq pexp pf pgamma plnorm plogis pnbinom pnorm ppois pt punif pweibull qbeta qbinom qchisq qexp qf qgamma
#'     qlnorm qlogis qnbinom qnorm qpois qt quantile qunif qweibull rbeta rbinom rchisq rexp rf rgamma rlnorm rlogis rmultinom rnbinom
#'     rnorm rpois rt runif rweibull sd uniroot var integrate
#' @import utils
#' @import BB
#' @importFrom Matrix nearPD
#' @export
#' @keywords correlation method1
#' @seealso \code{\link[SimCorrMix]{corrvar}}
#' @return the intermediate MVN correlation matrix
#' @references Please see references for \code{\link[SimCorrMix]{SimCorrMix}}.
#'
#' @examples
#' Sigma1 <- intercorr(k_cat = 1, k_cont = 1, method = "Polynomial",
#'   constants = matrix(c(0, 1, 0, 0, 0, 0), 1, 6), marginal = list(0.3),
#'   support = list(c(0, 1)), rho = matrix(c(1, 0.4, 0.4, 1), 2, 2),
#'   quiet = TRUE)
#' \dontrun{
#' # 1 continuous mixture, 1 binary, 1 zero-inflated Poisson, and
#' # 1 zero-inflated NB variable
#' seed <- 1234
#'
#' # Mixture of N(-2, 1) and N(2, 1)
#' constants <- rbind(c(0, 1, 0, 0, 0, 0), c(0, 1, 0, 0, 0, 0))
#'
#' marginal <- list(0.3)
#' support <- list(c(0, 1))
#' lam <- 0.5
#' p_zip <- 0.1
#' size <- 2
#' prob <- 0.75
#' p_zinb <- 0.2
#'
#' k_cat <- k_pois <- k_nb <- 1
#' k_cont <- 2
#' Rey <- matrix(0.35, 5, 5)
#' diag(Rey) <- 1
#' rownames(Rey) <- colnames(Rey) <- c("O1", "M1_1", "M1_2", "P1", "NB1")
#'
#' # set correlation between components of the same mixture variable to 0
#' Rey["M1_1", "M1_2"] <- Rey["M1_2", "M1_1"] <- 0
#'
#' Sigma2 <- intercorr(k_cat, k_cont, k_pois, k_nb, "Polynomial", constants,
#'   marginal, support, lam, p_zip, size, prob, mu = NULL, p_zinb, Rey, seed)
#' }
intercorr <- function(k_cat = 0, k_cont = 0, k_pois = 0, k_nb = 0,
                      method = c("Fleishman", "Polynomial"), constants = NULL,
                      marginal = list(), support = list(), lam = NULL,
                      p_zip = 0, size = NULL, prob = NULL, mu = NULL,
                      p_zinb = 0, rho = NULL, seed = 1234, epsilon = 0.001,
                      maxit = 1000, nrand = 100000, quiet = FALSE) {
  k <- k_cat + k_cont + k_pois + k_nb
  if (k_pois > 0) {
    if (length(p_zip) < k_pois)
      p_zip <- c(rep(0, k_pois - length(p_zip)), p_zip)
  }
  if (k_nb > 0) {
    if (length(prob) > 0)
      mu <- size * (1 - prob)/prob
    if (length(p_zinb) < k_nb)
      p_zinb <- c(rep(0, k_nb - length(p_zinb)), p_zinb)
  }
  if (k_cat > 0) {
    if (length(support) == 0) {
      for (i in 1:k_cat) {
        support[[i]] <- 1:(length(marginal[[i]]) + 1)
      }
    }
  }
  rho_list <- separate_rho(k_cat = k_cat, k_cont = k_cont, k_pois = k_pois,
                           k_nb = k_nb, rho = rho)
  rho_cat <- rho_list$rho_cat
  rho_cat_pois <- rho_list$rho_cat_pois
  rho_cat_nb <- rho_list$rho_cat_nb
  rho_cont_cat <- rho_list$rho_cont_cat
  rho_cont <- rho_list$rho_cont
  rho_cont_pois <- rho_list$rho_cont_pois
  rho_cont_nb <- rho_list$rho_cont_nb
  rho_pois <- rho_list$rho_pois
  rho_pois_nb <- rho_list$rho_pois_nb
  rho_nb <- rho_list$rho_nb
  Sigma_cat <- NULL
  Sigma_cat_cont <- NULL
  Sigma_cat_pois <- NULL
  Sigma_cat_nb <- NULL
  Sigma_cont_cat <- NULL
  Sigma_cont <- NULL
  Sigma_cont_pois <- NULL
  Sigma_cont_nb <- NULL
  Sigma_pois_cat <- NULL
  Sigma_pois_cont <- NULL
  Sigma_pois <- NULL
  Sigma_pois_nb <- NULL
  Sigma_nb_cat <- NULL
  Sigma_nb_cont <- NULL
  Sigma_nb_pois <- NULL
  Sigma_nb <- NULL
  if (k_cat == 1) {
    Sigma_cat <- matrix(1, nrow = k_cat, ncol = k_cat)
  }
  if (k_cat > 1) {
    Sigma_cat <- diag(1, k_cat, k_cat)
    for (i in 1:(k_cat - 1)) {
      for (j in (i + 1):k_cat) {
        if (length(marginal[[i]]) == 1 & length(marginal[[j]]) == 1) {
          corr_bin <- function(rho) {
            phix1x2 <- integrate(function(z2) {
              sapply(z2, function(z2) {
                integrate(function(z1) ((2 * pi * sqrt((1 - rho^2)))^-1) *
                    exp(-(z1^2 - 2 * rho * z1 * z2 + z2^2)/(2 * (1 - rho^2))),
                          -Inf, qnorm(1 - marginal[[i]][1]))$value
              })
            }, -Inf, qnorm(1 - marginal[[j]][1]))$value -
              rho_cat[i, j] * sqrt(marginal[[i]][1] * (1 - marginal[[j]][1]) *
                                  marginal[[j]][1] * (1 - marginal[[i]][1])) -
              ((1 - marginal[[i]][1]) * (1 - marginal[[j]][1]))
            phix1x2
          }
          Sigma_cat[i, j] <- suppressWarnings(dfsane(par = 0, fn = corr_bin,
                                          control = list(trace = FALSE)))$par
        } else {
          Sigma_cat[i, j] <-
            suppressWarnings(ord_norm(list(marginal[[i]], marginal[[j]]),
              matrix(c(1, rho_cat[i, j], rho_cat[i, j], 1), 2, 2),
              list(support[[i]], support[[j]]), epsilon = epsilon,
              maxit = maxit)$SigmaC[1, 2])
        }
        Sigma_cat[j, i] <- Sigma_cat[i, j]
      }
    }
    if (min(eigen(Sigma_cat, symmetric = TRUE)$values) < 0 & quiet == FALSE) {
      message("It is not possible to find a correlation matrix for MVN ensuring
              rho for the ordinal variables.  Try the error loop.")
    }
  }
  if (k_cont > 0) {
    Sigma_cont <- intercorr_cont(method, constants, rho_cont)
  }
  if (k_cat > 0 & k_cont > 0) {
    Sigma_cont_cat <- findintercorr_cont_cat(method, constants,
                                             rho_cont_cat, marginal, support)
    Sigma_cat_cont <- t(Sigma_cont_cat)
  }
  if (k_cat > 0 & k_pois > 0) {
    Sigma_cat_pois <-
      intercorr_cat_pois(rho_cat_pois, marginal, lam, p_zip, nrand, seed)
    Sigma_pois_cat <- t(Sigma_cat_pois)
  }
  if (k_cat > 0 & k_nb > 0) {
    Sigma_cat_nb <-
      intercorr_cat_nb(rho_cat_nb, marginal, size, mu, p_zinb, nrand, seed)
    Sigma_nb_cat <- t(Sigma_cat_nb)
  }
  if (k_cont > 0 & k_pois > 0) {
    Sigma_cont_pois <- intercorr_cont_pois(method, constants, rho_cont_pois,
                                           lam, p_zip, nrand, seed)
    Sigma_pois_cont <- t(Sigma_cont_pois)
  }
  if (k_cont > 0 & k_nb > 0) {
    Sigma_cont_nb <-
      intercorr_cont_nb(method, constants, rho_cont_nb, size, mu,
                        p_zinb, nrand, seed)
    Sigma_nb_cont <- t(Sigma_cont_nb)
  }
  if (k_pois == 1) {
    Sigma_pois <- matrix(1, nrow = k_pois, ncol = k_pois)
  }
  if (k_pois > 1) {
    Sigma_pois <- intercorr_pois(rho_pois, lam, p_zip, nrand, seed)
  }
  if (k_nb == 1) {
    Sigma_nb <- matrix(1, nrow = k_nb, ncol = k_nb)
  }
  if (k_nb > 1) {
    Sigma_nb <- intercorr_nb(rho_nb, size, mu, p_zinb, nrand, seed)
  }
  if (k_pois > 0 & k_nb > 0) {
    Sigma_pois_nb <- intercorr_pois_nb(rho_pois_nb, lam, p_zip, size, mu,
                                       p_zinb, nrand, seed)
    Sigma_nb_pois <- t(Sigma_pois_nb)
  }
  Sigma <- rbind(cbind(Sigma_cat, Sigma_cat_cont, Sigma_cat_pois,
                       Sigma_cat_nb),
                 cbind(Sigma_cont_cat, Sigma_cont, Sigma_cont_pois,
                       Sigma_cont_nb),
                 cbind(Sigma_pois_cat, Sigma_pois_cont, Sigma_pois,
                       Sigma_pois_nb),
                 cbind(Sigma_nb_cat, Sigma_nb_cont, Sigma_nb_pois,
                       Sigma_nb))
  return(Sigma)
}
