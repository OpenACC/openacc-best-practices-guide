MDFILES := $(wildcard ??-*.markdown)
IMGFILES := $(wildcard images/*)

# Override with pandoc executable if building without docker
PANDOC ?= docker run --rm -it -u `id -u`:`id -g` -v ${PWD}:/data pandoc/latex:latest

openacc-guide.pdf: ${MDFILES} ${IMGFILES}
	${PANDOC} -f markdown+implicit_figures -s -o openacc-guide-nocover.pdf ??-*.markdown --citeproc --highlight-style pygments --top-level-division=chapter -V geometry:letterpaper
	pdfunite cover-page/cover-page.pdf openacc-guide-nocover.pdf openacc-guide.pdf

openacc-guide.tex: ${MDFILES}
	${PANDOC} -f markdown+implicit_figures -s -o openacc-guide.tex ??-*.markdown --citeproc --highlight-style pygments --top-level-division=chapter

openacc-guide.html: ${MDFILES}
	${PANDOC} -f markdown+implicit_figures -s -o openacc-guide.html ??-*.markdown --top-level-division=chapter --toc --toc-depth=2 -V geometry:margin=1in --citeproc -V documentclass:book -V classoption:oneside --highlight-style pygments

openacc-guide.doc: ${MDFILES} ${IMGFILES}
	${PANDOC} -f markdown+implicit_figures -s -o openacc-guide.doc ??-*.markdown --top-level-division=chapter --toc --toc-depth=2 -V geometry:margin=1in --citeproc

outline.pdf: outline.markdown
	${PANDOC} outline.markdown -o outline.pdf -V geometry:margin=1in

all: openacc-guide.pdf 

clean:
	rm -f outline.pdf openacc-guide.pdf openacc-guide.doc openacc-guide.tex openacc-guide.html outline.pdf
