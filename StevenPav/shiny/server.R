# Created: 2015.05.18
# Copyright: Steven E. Pav, 2015
# Author: Steven E. Pav <shabbychef@gmail.com>
# Comments: Steven E. Pav

library(shiny)
library(ggplot2)
library(reshape2)
library(hypergeo)

# approximate quantiles of true Sharpe of sample Markowitz portfolio.
# c.f. Equation (25) of of the paper on arxiv (v1).
qqual <- function(p, df1, df2, zeta.s, use.ope=1, lower.tail=TRUE) {
  # incorporates the annualization factor
  # uses the sin(atan( ... )) formulation:
  atant <- atan((1/sqrt(df1-1)) * 
    qt(p,df=df1-1,ncp=sqrt(df2)*zeta.s,lower.tail=lower.tail))
  retval <- sqrt(use.ope) * zeta.s * sin(atant)
}
# randomly generate a covariance and mean with the given maximal Sharpe.
genpop <- function(nstock,zeta,ope=253) {
  Sigma <- cov(matrix(rnorm((nstock+10)*nstock),ncol=nstock))
  mu <- matrix(rnorm(nstock),ncol=1)
  # make it have the given maximal Sharpe, zeta
  rescal <- (zeta / sqrt(ope)) / sqrt(t(mu) %*% solve(Sigma,mu))
  mu <- rescal[1] * mu 
  retv <- list(mu=mu,Sigma=Sigma)
}
# takes a n x p matrix of historical observations, and produces
# a p vector of the portfolio. Swap this out for your favorite
# portfolio construction technique.
sample_mwitz <- function(X) {
  smu <- colMeans(X)
  sSg <- cov(X)
  w <- solve(sSg,smu)
}
# a Monte Carlo single simulation: 
# generate the population parameters;
# generate observations with those parameters, under
#  some model of the innovations;
# construct the sample Markowitz portfolio;
# compute the true Sharpe of that portfolio.
onesim <- function(nyr,nstock,zeta,ope=253,
                   genf=c("normal","t(4)","uniform","coinflip")) {
  genf <- match.arg(genf)
  nday <- ceiling(nyr*ope)

  # population parameters
  pop <- genpop(nstock=nstock,zeta=zeta,ope=ope)
  Shalf <- chol(pop$Sigma)

  X <- switch(genf,
              "normal"=rnorm(nday*nstock),
              "t(4)"=sqrt(0.5)*rt(nday*nstock,df=4),
              "uniform"=runif(nday*nstock,min=-sqrt(3),max=sqrt(3)),
              "coinflip"=sign(runif(nday*nstock,min=-1,max=1)))
  X <- t(t(matrix(X,nrow=nday) %*% Shalf) + rep(pop$mu,nday))

  mwitz <- sample_mwitz(X)
  # compute true Sharpe of this portfolio
  truesr <- sqrt(ope) * t(mwitz) %*% pop$mu / sqrt(t(mwitz) %*% (pop$Sigma %*% mwitz))
}

# use Equation (22)
# zeta.s is in annualized terms here:
ubound <- function(n.yr,n.stock,zeta.s) {
  effsize <- n.yr * (zeta.s^2)
  df <- n.stock - 1   # lose 1 b/c on a sphere
  loss <- sqrt(effsize / (df + effsize))
  ub <- loss * zeta.s
  ub
}
# use Equation (27)
u2bound <- function(n.yr,n.stock,zeta.s) {
  teff <- 0.5 * n.yr * zeta.s^2
  U <- c(n.stock/2,3/2)
  L <- c((2+n.stock)/2,1/2)
  ub2 <- zeta.s^2 * exp(- teff + sum(lgamma(U)) - sum(lgamma(L)))
  ub2 <- ub2 * hypergeo::genhypergeo(U, L, teff)
  ub2
}
server <- function(input, output) {
  # perform multiple simulations.
  sims <- reactive({
    set.seed(input$randseed)
    srs <- replicate(input$n_sim,onesim(nyr=input$n_yr,
                                        nstock=input$n_stock,
                                        zeta=input$max_sr,
                                        ope=input$ope,
                                        genf=input$retmodel))
  })

  # the Cramer-Rao bound
  output$expectations <- renderTable({
    simv <- sims()
    empirical <- mean(simv)
    ub <- ubound(input$n_yr,input$n_stock,input$max_sr)
    retv <- data.frame(empirical=empirical,upper.bound=ub)
    rownames(retv) <- c("expected Sharpe")
    retv
  })
  # the approximation to variance:
  output$squared_expectations <- renderTable({
    simv <- sims()
    empirical <- mean(simv^2)
    ub <- u2bound(input$n_yr,input$n_stock,input$max_sr)
    retv <- data.frame(empirical=empirical,approx.theoretical=ub)
    rownames(retv) <- c("expected squared Sharpe")
    retv
  })
  output$explanation_1 <- renderText({
    paste0("Here ",input$n_sim," Monte Carlo simulations are performed of drawing ",
           input$n_yr," years of observations (at a rate of ",input$ope," per year) on ",
           input$n_stock," stocks, then constructing the sample Markowitz portfolio on that data. ",
           "Returns are drawn from a ",input$retmodel," distribution, with a fixed maximal Sharpe of ",
           input$max_sr,"/sqrt(yr). ", 
           "Under the Monte Carlo simulations, the population mean and covariance are known, ",
           "so the true Sharpe of the sample portfolio can be computed.  ",
           "The theorem gives an upper bound on the expected Sharpe of certain portfolio ",
           "estimators, including the Markowitz portfolio estimator. The upper bound on the ",
           "expected Sharpe and the empirical mean are given here: ")
  })
  output$explanation_2 <- renderText({
    paste0("Section 3 of the paper gives the approximate distribution of the Sharpe of ",
           "the sample Markowitz portfolio. From this approximation we can infer the expected ",
           "squared Sharpe (c.f. Equation (27)). The approximate and empirical values are given in the ",
           "table below. ",
           "Below is a Q-Q plot of the empirical quantiles against the approximate theoretical quantiles ",
           "from the approximation. (c.f. Equation (25))")
  })

  # qq plot the results.
  output$qqplot <- renderPlot({
    simv <- sims()
    pvs <- ppoints(simv)
    ope <- input$ope

    xydf <- as.data.frame(qqplot(x=qqual(pvs,input$n_stock,ceiling(input$n_yr * ope),
                                         input$max_sr / sqrt(ope),use.ope=ope),
                                 y=simv,plot=F))
    ph <- ggplot(data=xydf,mapping=aes(x=x, y=y))
    ph <- ph + geom_point()
    #ph <- ph + geom_smooth(method="lm", se=FALSE)  
    ph <- ph + geom_abline(intercept=0, slope=1, color="red")
    ph <- ph + labs(x="Theoretical Approximate Quantiles",
                    y="Sample Quantiles")

    return(ph)
  })
}
shinyServer(server)

#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
