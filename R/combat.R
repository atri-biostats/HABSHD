
#' ComBat Harmonization for Longitudinal Data
#'
#' @param fixed a two-sided linear formula object describing the fixed-effects 
#' part of the model
#' @param data a data frame
#' @param random1 primary random effects. See `random` in [nlme::lme()]
#' @param random2 secondary random effects. If model with `random1` fails to 
#' converge
#' @param weights See [nlme::lme()] and [nlme::varIdent()]. This should be of the form, e.g.
#' `varIdent(form = ~ 1 | scanner_type)` so that results are harmonized with
#' respect to the variance per scanner type. The scanner type variable should 
#' be a factor variable with at least two levels. Data will be harmonized 
#' assuming the reference scanner (lowest level) of this factor variable.
#' @param ... other arguments passed to [nlme::lme()]
#' @returns vector of ComBat harmonized data.
#' @export
#' @references
#' Beer JC, Tustison NJ, Cook PA, Davatzikos C, Sheline YI, Shinohara RT, 
#' Linn KA; Alzheimer’s Disease Neuroimaging Initiative. Longitudinal ComBat: 
#' A method for harmonizing longitudinal multi-scanner imaging data. 
#' *Neuroimage*. 2020 Oct 15;220:117129. doi: 10.1016/j.neuroimage.2020.117129. 
#' Epub 2020 Jul 5. PMID: 32640273; PMCID: PMC7605103.
#' @importFrom nlme lme
#' @importFrom stats resid
#' @importFrom stats predict
#' @importFrom dplyr pull
#' @importFrom magrittr %>%
#' @examples
#' library(tidyverse)
#' library(nlme)
#' set.seed(20250312)
#' dd <- tibble(
#'   id = 1:100,
#'   scanner = as.factor(c(rep(1,50), rep(2,50))),
#'   ran.int = rnorm(sd=350, n = 100),
#'   ran.slope = rnorm(sd=120, n = 100)
#' ) %>%
#'   cross_join(tibble(scale_age = c(-1,0,1))) %>%
#'   mutate(
#'     e = rnorm(sd=60, n = 300),
#'     Y = case_when(
#'       scanner == 1 ~ ran.int + ran.slope*scale_age + e,
#'       scanner == 2 ~ 3000 + ran.int + ran.slope*scale_age + 1.4*e
#'     ))
#' 
#' dd$Y_combat <- ComBatLong(Y ~ scanner + scale_age, data = dd, 
#'   random1 = ~scale_age|id,
#'   random2 = ~1|id,
#'   weights = varIdent(form = ~ 1 | scanner))
#' 
#' ggplot(dd, aes(x=scale_age, y=Y)) +
#'   geom_line(aes(group = id, color = scanner))
#' 
#' ggplot(dd, aes(x=scale_age, y=Y_combat)) +
#'   geom_line(aes(group = id, color = scanner))
#' 
#' ggplot(dd, aes(x=Y, y=Y_combat)) +
#'   geom_point(aes(color = scanner)) +
#'   geom_abline(intercept = 0, slope = 1, linetype = 'dashed')
#'   
#' # Model used for harmonization:
#' summary(lme(Y ~ scanner + scale_age, 
#'   data = dd, 
#'   random = ~scale_age|id, 
#'   weights = varIdent(form = ~ 1 | scanner)))
#' 
#' # After harmonization, scanner fixed effect and variance weights are reduced:
#' summary(lme(Y_combat ~ scanner + scale_age, 
#'   data = dd, 
#'   random = ~scale_age|id, 
#'   weights = varIdent(form = ~ 1 | scanner)))
ComBatLong <- function(fixed, data, random1, random2, weights, ...){
  scanner_variable <- all.vars(attr(weights, "formula"))
  if(!is.factor(data %>% pull(scanner_variable)))
    stop(scanner_variable, ' must be a factor variable')
  if(nlevels(data %>% pull(scanner_variable)) < 2)
    stop(scanner_variable, ' must have at least two levels')
  fit <- try(lme(fixed, random = random1, weights = weights, 
    data = data, ...), silent = TRUE)
  if(class(fit)[1] == 'try-error'){
    message('Model with random1 failed to converge, trying random2.')
    fit <- lme(fixed, random = random2, weights = weights,
      data = data, ...)
  }
  # Y_combat = (homogenized residual) + (fitted value | reference scanner type)
  homogenized_residuals <- unlist(resid(fit, level = 1, type = "pearson")) *
    sigma(fit)
  # create nd, new data, with scanner_variable set to reference value for
  # all observations
  nd <- data
  nd[,scanner_variable] <- sort(unique(nd %>% pull(scanner_variable)))[1]
  fitted_value_ref_scanner <- unlist(predict(fit, newdata = nd, level = 1))
  homogenized_residuals + fitted_value_ref_scanner
}
