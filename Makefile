
help :
	@-echo "make README.md                  github README"


# simple build rules

all : README.md

%.md : %.Rmd
	r -l knitr -e "knitr::knit(basename('$<'))"

