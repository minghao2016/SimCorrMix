#' @title Calculate Intermediate MVN Correlation for Poisson Variables: Correlation Method 1
#'
#' @description This function calculates a \code{k_pois x k_pois} intermediate matrix of correlations for the
#'     Poisson variables using the method of Yahav & Shmueli (2012, \doi{10.1002/asmb.901}). The intermediate correlation between Z1 and Z2
#'     (the standard normal variables used to generate the Poisson variables Y1 and Y2 via the inverse CDF method) is
#'     calculated using a logarithmic transformation of the target correlation.  First, the upper and lower Frechet-Hoeffding bounds
#'     (mincor, maxcor) on \eqn{\rho_{Y1, Y2}} are simulated.  Then the intermediate correlation is found as follows:
#'     \deqn{\rho_{Z1, Z2} = \frac{1}{b} * log(\frac{\rho_{Y1, Y2} - c}{a}),}
#'     where \eqn{a = -(maxcor * mincor)/(maxcor + mincor)}, \eqn{b = log((maxcor + a)/a)}, and \eqn{c = -a}.
#'     The function adapts code from Amatya & Demirtas' (2016) package \code{\link[PoisNor]{PoisNor-package}} by:
#'
#'     1) allowing specifications for the number of random variates and the seed for reproducibility
#'
#'     2) providing the following checks: if \code{Sigma_(Z1, Z2)} > 1, \code{Sigma_(Z1, Z2)} is set to 1; if \code{Sigma_(Z1, Z2)} < -1,
#'     \code{Sigma_(Z1, Z2)} is set to -1
#'
#'     3) simulating regular and zero-inflated Poisson variables.
#'
#'     The function is used in \code{\link[SimCorrMix]{intercorr}} and \code{\link[SimCorrMix]{corrvar}} and would not ordinarily be called by the user.
#'
#' @param rho_pois a \code{k_pois x k_pois} matrix of target correlations ordered 1st regular and 2nd zero-inflated
#' @param lam a vector of lambda (mean > 0) constants for the regular and zero-inflated Poisson variables (see \code{stats::dpois});
#'     the order should be 1st regular Poisson variables, 2nd zero-inflated Poisson variables
#' @param p_zip a vector of probabilities of structural zeros (not including zeros from the Poisson distribution) for the
#'     zero-inflated Poisson variables (see \code{VGAM::dzipois}); if \code{p_zip} = 0, \eqn{Y_{pois}} has a regular Poisson
#'     distribution; if \code{p_zip} is in (0, 1), \eqn{Y_{pois}} has a zero-inflated Poisson distribution;
#'     if \code{p_zip} is in \code{(-(exp(lam) - 1)^(-1), 0)}, \eqn{Y_{pois}} has a zero-deflated Poisson distribution and \code{p_zip}
#'     is not a probability; if \code{p_zip = -(exp(lam) - 1)^(-1)}, \eqn{Y_{pois}} has a positive-Poisson distribution
#'     (see \code{VGAM::dpospois}); if \code{length(p_zip) < length(lam)}, the missing values are set to 0 (and ordered 1st)
#' @param nrand the number of random numbers to generate in calculating the bound (default = 10000)
#' @param seed the seed used in random number generation (default = 1234)
#' @importFrom stats cor dbeta dbinom dchisq density dexp df dgamma dlnorm dlogis dmultinom dnbinom dnorm dpois dt dunif dweibull ecdf
#'     median pbeta pbinom pchisq pexp pf pgamma plnorm plogis pnbinom pnorm ppois pt punif pweibull qbeta qbinom qchisq qexp qf qgamma
#'     qlnorm qlogis qnbinom qnorm qpois qt quantile qunif qweibull rbeta rbinom rchisq rexp rf rgamma rlnorm rlogis rmultinom rnbinom
#'     rnorm rpois rt runif rweibull sd uniroot var
#' @import utils
#' @importFrom VGAM qzipois
#' @export
#' @keywords correlation Poisson method1
#' @seealso \code{\link[SimCorrMix]{intercorr_nb}}, \code{\link[SimCorrMix]{intercorr_pois_nb}},
#'     \code{\link[SimCorrMix]{intercorr}}, \code{\link[SimCorrMix]{corrvar}}
#' @return the \code{k_pois x k_pois} intermediate correlation matrix for the Poisson variables
#' @references
#' Amatya A & Demirtas H (2015). Simultaneous generation of multivariate mixed data with Poisson and normal marginals.
#'     Journal of Statistical Computation and Simulation, 85(15):3129-39. \doi{10.1080/00949655.2014.953534}.
#'
#' Demirtas H & Hedeker D (2011). A practical way for computing approximate lower and upper correlation bounds.
#'     American Statistician, 65(2):104-109.
#'
#' Frechet M (1951). Sur les tableaux de correlation dont les marges sont donnees.  Ann. l'Univ. Lyon SectA, 14:53-77.
#'
#' Hoeffding W. Scale-invariant correlation theory. In: Fisher NI, Sen PK, editors. The collected works of Wassily Hoeffding.
#'     New York: Springer-Verlag; 1994. p. 57-107.
#'
#' Yahav I & Shmueli G (2012). On Generating Multivariate Poisson Data in Management Science Applications. Applied Stochastic
#'     Models in Business and Industry, 28(1):91-102. \doi{10.1002/asmb.901}.
#'
#' Yee TW (2018). VGAM: Vector Generalized Linear and Additive Models. R package version 1.0-5. \url{https://CRAN.R-project.org/package=VGAM}.
#'
intercorr_pois <- function(rho_pois = NULL, lam = NULL, p_zip = 0,
                           nrand = 100000, seed = 1234) {
  if (length(p_zip) < length(lam))
    p_zip <- c(rep(0, length(lam) - length(p_zip)), p_zip)
  Sigma_pois <- diag(1, nrow(rho_pois), ncol(rho_pois))
  set.seed(seed)
  u <- runif(nrand, 0, 1)
  for (i in 1:(nrow(rho_pois) - 1)) {
    for (j in (i + 1):ncol(rho_pois)) {
      maxcor <- cor(qzipois(u, lam[i], pstr0 = p_zip[i]),
                    qzipois(u, lam[j], pstr0 = p_zip[j]))
      mincor <- cor(qzipois(u, lam[i], pstr0 = p_zip[i]),
                    qzipois(1 - u, lam[j], pstr0 = p_zip[j]))
      a <- -(maxcor * mincor)/(maxcor + mincor)
      b <- log((maxcor + a)/a)
      c <- -a
      Sigma_pois[i, j] <- (1/b) * log((rho_pois[i, j] - c)/a)
      if (Sigma_pois[i, j] > 1) Sigma_pois[i, j] <- 1
      if (Sigma_pois[i, j] < -1) Sigma_pois[i, j] <- -1
      Sigma_pois[j, i] <- Sigma_pois[i, j]
    }
  }
  return(Sigma_pois)
}
