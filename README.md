

# Portfolio Cramér Rao bounds

## Why does this happen?

![this](http://www.imgur.com/5oOkkSR.jpg)

There are numerous oft-lamented reasons for this kind of 'out-of-sample
experience', _viz._

* Plain old overfit ('p-value hacking').
* Broken backtests: lookahead bias, survivorship bias, _etc._
* Bad understanding of trade costs. 
* Bad execution.

However, these are largely preventable errors committed only by 'bad' quants.
Broken backtest code, for example, should be fixed to remove 'time traveling'.
Quants should not overfit or debias their estimates of Sharpe to control for
data mining bias, _etc._ Assuming these errors have been corrected, is there
some kind of fundamental headwind that all quants, even the 'good' ones, face?

## Cramér Rao

It happens to be the case that there is some fundamental bound. To talk about
it, consider a portfolio construction method (an 'estimator') as a function
which takes historical data, say the _T x p_ matrix, _X_, and 
produces a _p_ vector of the portfolio weights. To control for bad luck in the
out-of-sample period, I consider the (population) Sharpe ratio of this
portfolio. That is, the expected return of this portfolio divided by its
volatility. In theory this will be 'stochastically monotonic' with the achieved
Sharpe in the out-of-sample period. We will bound the expected value of this
Sharpe, where expectation is over draws of the historical data _X_.

## The bound

Using the (multivariate) Cramér Rao theorem, some geometry and linear algebra, we
arrive at a bound on the expected Sharpe. It looks something like:

  Expected Sharpe &le; sqrt(effect size / (effect size + # knobs)) * maximal Sharpe

where Expectation is over draws of the historical data, effect size is number of years
times squared maximal Sharpe, and the # of knobs is _p - 1_. (Only direction matters,
so we get one degree of freedom for free.)  This inequality holds under a wide
range of conditions.

## Control your free variables


This is why portfolio optimization is not performed on 100's of unknowns:
If maximal Sharpe is 1.1, observing 5 yr of data:
- for 10 stocks, the bound is 0.7.
- for 40 stocks, the bound is 0.4.
- for 160 stocks, the bound is 0.21.

However, maximal Sharpe should grow with universe size.
Can it grow fast enough?

## Diversification and universe size

The 'Fundamental law' suggests that maximal Sharpe should grow as the square root of the
number of assets. This is fairly optimistic, however: if all the assets were zero mean, the
maximal Sharpe would be identically zero. 

Supposing that maximal Sharpe might follow a power law with respect to universe size, _i.e._
_log(Sharpe) = gamma log(p) + c_ (GFM does not support proper math equations), here I plot the
bound on expected Sharpe versus _p_ for different values of _gamma_. One can prove that there
is a change in behavior at _gamma = 1/4_. For smaller values, the upper bound eventually
_decreases_ with increasing universe size.


```r
ope <- 253
n.stok <- 6
n.yr <- 4
n.obs <- ceiling(ope * n.yr)
zeta.s <- 1.25/sqrt(ope)  # optimal SNR, in daily units

bound.experiment <- function(pow, n.obs, zeta.s, n.stok = n.stok, 
    ope = ope, plims = c(2, 250)) {
    require(reshape2)
    all.ps <- unique(round(exp(seq(log(min(plims)), 
        log(max(plims)), length.out = 140))))
    zeta.0 <- zeta.s/(n.stok^pow)
    all.zeta <- zeta.0 * (all.ps^pow)
    all.bnd <- sqrt(ope * n.obs) * all.zeta^2/sqrt(all.ps - 
        1 + n.obs * all.zeta^2)
    
    # population.max=sqrt(ope) * all.zeta,
    foo.df <- data.frame(p = all.ps, pow = rep(pow, 
        length(all.bnd)), bound = all.bnd)
    measure.vars <- colnames(foo.df)
    id.vars <- c("p", "pow")
    measure.vars <- measure.vars[!measure.vars %in% 
        id.vars]
    require(reshape2)
    melt.df <- melt(foo.df, id.vars = id.vars, variable.name = "Sharpe", 
        measure.vars = measure.vars)
    return(melt.df)
}

bound.plot <- function(pow, n.obs, zeta.s, plims = c(2, 
    250), ...) {
    melt.df <- NULL
    for (ppp in pow) {
        addon.df <- bound.experiment(ppp, n.obs, zeta.s, 
            plims = plims, ...)
        if (is.null(melt.df)) 
            melt.df <- addon.df else melt.df <- rbind(melt.df, addon.df)
    }
    melt.df$gamma <- factor(melt.df$pow)
    
    require(ggplot2)
    ph <- ggplot(data = melt.df, aes(x = p, y = value, 
        group = gamma, colour = gamma))
    ph <- ph + geom_line()
    ph <- ph + labs(x = "# assets", y = "Signal-Noise ratio (annualized)")
    ph <- ph + guides(colour = guide_legend(title = expression(gamma)))
    ph <- ph + scale_x_log10(limits = c(1, max(plims)))
    ph <- ph + scale_y_log10(limits = c(0.5, 4), breaks = 2^seq(from = -1, 
        to = 2, by = 0.5))
    return(ph)
}

pgammas <- seq(from = 0.15, to = 0.35, by = 0.05)

print(bound.plot(pgammas, n.obs = n.obs, zeta.s = zeta.s, 
    n.stok = n.stok, ope = ope))
```

<img src="figure/readme_show_grow_bound-1.png" title="plot of chunk show_grow_bound" alt="plot of chunk show_grow_bound" width="700px" height="600px" />


## Empirical diversification in the S&P 100 universe

To get some empirical estimate of the value of _gamma_, I downloaded
the returns of stocks which were in the S&P 100 as of March 21, 2014.
I then use the 'KRS' estimator from the 
[SharpeR](http://github.com/shabbychef/SharpeR) package to estimate
the population maximal Sharpe as a function of universe size. If you
do this for stocks in alphabetical order, there is an 'AAPL effect'. 
I randomly reorder the stocks and compute the KRS statistic as a function
of universe size, repeating 1000 times. Here is a boxplot, over Monte Carlo
replications, of the maximal Sharpe as function of universe size. There is
effectively _no_ diversification. That is, it appears that _gamma = 0_.




```r
require(SharpeR)
# compute MLE and KRS estimators on maximal SR in
# alphabetical order
MLEs <- unlist(lapply(1:dim(sub.lr)[2], function(n) {
    inference(as.sropt(sub.lr[, 1:n]), "MLE")
}))
KRSs <- unlist(lapply(1:dim(sub.lr)[2], function(n) {
    inference(as.sropt(sub.lr[, 1:n]), "KRS")
}))

# try for random reorderings:
set.seed(12312L)
buncho.KRSs <- replicate(1000, unlist(lapply(sample.int(dim(sub.lr)[2]), 
    function(n) {
        inference(as.sropt(sub.lr[, 1:n]), "KRS")
    })))
```


```r
foo.df <- data.frame(df = rep(1:(dim(buncho.KRSs)[1]), 
    dim(buncho.KRSs)[2]), KRS = as.vector(t(buncho.KRSs)))
foo.df <- foo.df[foo.df$df < 11, ]

require(ggplot2)
ph <- ggplot(data = foo.df, aes(x = factor(df), y = KRS))
ph <- ph + geom_boxplot()
ph <- ph + labs(x = "# assets", y = expression(zeta["*"]))
print(ph)
```

<img src="figure/readme_plot_KRS_sp100-1.png" title="plot of chunk plot_KRS_sp100" alt="plot of chunk plot_KRS_sp100" width="700px" height="600px" />

## Learn more

- Read the [paper](http://arxiv.org/abs/1409.5936)
- Try the Monte Carlo experiment shiny app. Via
[shinyapps.io](https://shabbychef.shinyapps.io/shiny), or run it locally via:

```r
library(shiny)
shiny::runGitHub("rfin2015", "shabbychef", subdir = "app")
```
- Ask me questions.
- Thank you.


