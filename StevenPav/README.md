

# Portfolio Cramer Rao bounds

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



```r
if (require(devtools)) {
    # latest greatest
    install_github("shabbychef/sadists")
}
# via drat:
if (require(drat)) {
    drat:::add("shabbychef")
    install.packages("sadists")
}
```


