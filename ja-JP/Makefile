MDFILES := $(wildcard ??-*.markdown)
IMGFILES := $(wildcard ../images/*)

# Override with pandoc executable if building without docker
PANDOC ?= docker run --rm -it -u `id -u`:`id -g` -v ${PWD}:/data openacc/best-practices-guide:latest

openacc-guide-ja-JP.pdf: ${MDFILES} ${IMGFILES}
	${PANDOC} -f markdown+implicit_figures -s -o $@ ??-*.markdown --citeproc --highlight-style pygments --top-level-division=chapter -V geometry:letterpaper -H cover-page/main.tex --pdf-engine=xelatex


openacc-guide-ja-JP.tex: ${MDFILES}
	${PANDOC} -f markdown+implicit_figures -s -o $@ ??-*.markdown --citeproc --highlight-style pygments --top-level-division=chapter

openacc-guide-ja-JP.html: ${MDFILES}
	${PANDOC} -f markdown+implicit_figures -s -o $@ ??-*.markdown --top-level-division=chapter --toc --toc-depth=2 -V geometry:margin=1in --citeproc -V documentclass:book -V classoption:oneside --highlight-style pygments

openacc-guide-ja-JP.doc: ${MDFILES} ${IMGFILES}
	${PANDOC} -f markdown+implicit_figures -s -o $@ ??-*.markdown --top-level-division=chapter --toc --toc-depth=2 -V geometry:margin=1in --citeproc

all: openacc-guide-ja-JP.pdf 

clean:
	-rm -rf openacc-guide-ja-JP.pdf openacc-guide-ja-JP.doc openacc-guide-ja-JP.tex openacc-guide-ja-JP.html openacc-guide-ja-JP.rst _build
