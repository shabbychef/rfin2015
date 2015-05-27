# Created: 2015.05.18
# Copyright: Steven E. Pav, 2015
# Author: Steven E. Pav <shabbychef@gmail.com>
# Comments: Steven E. Pav

library(shiny)

ui <- shinyUI(fluidPage(
  titlePanel("Cramer Rao bound for Markowitz portfolio"),
  sidebarLayout(
    sidebarPanel(
      h3("parameters"),
      numericInput("n_stock", "Number of stocks:", min = 2, max = 200, value = 10, step=1),
      numericInput("n_yr", "Number of years:", min = 0.5, max = 100, value = 5, step=0.01),
      numericInput("max_sr", "Maximal Sharpe (annualized):", min = 0, max = 10, value = 1, step=0.01),
      selectInput("retmodel", "Model for returns:", 
                  choices=c("normal","t(4)","uniform","coinflip"),
                  selected="normal",multiple=FALSE),
      hr(),
      numericInput("ope", "Observations per year:", min = 12, max = 365, value = 252, step=1),
      numericInput("n_sim", "Number of simulations:", min = 50, max = 10000, value = 400, step=50),
      numericInput("randseed", "Rand seed:", min = 1, max = .Machine$integer.max, value = 2015, step=1),
      hr(),
      h3("references:"),
      a(href='http://arxiv.org/abs/1409.5936','Bounds on portfolio quality')
    ,width=3),
    mainPanel(
      h2('Monte Carlo Simulations'),
      textOutput("explanation_1"),
      br(),
      tableOutput("expectations"),
      br(),
      h3('Under approximation of Equation (25)'),
      textOutput("explanation_2"),
      br(),
      tableOutput("squared_expectations"),
      plotOutput("qqplot"))
  )
,title="Cramer Rao bound for Markowitz portfolio"))

shinyUI(ui)

#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
