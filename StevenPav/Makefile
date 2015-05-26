
help :
	@-echo "make slideshow.html             slidify slideshow"
	@-echo "make README.md                  github README"


# simple build rules

all : slideshow.html README.md

slideshow.html : slideshow.Rmd
	r -l slidify -e "slidify(basename('$<'))"

%.md : %.Rmd
	r -l knitr -e "knitr::knit(basename('$<'))"

