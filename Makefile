openacc-guide.pdf: 
	pandoc -f markdown+implicit_figures -s -o openacc-guide.pdf ??-*.markdown --chapters --toc --toc-depth=2 -V geometry:margin=1in --filter pandoc-citeproc -V documentclass:book -V classoption:oneside

openacc-guide.doc: 
	pandoc -f markdown+implicit_figures -s -o openacc-guide.doc ??-*.markdown --chapters --toc --toc-depth=2 -V geometry:margin=1in --filter pandoc-citeproc

outline.pdf: outline.markdown
	pandoc outline.markdown -o outline.pdf -V geometry:margin=1in

all: openacc-guide.pdf openacc-guide.doc outline.pdf

clean:
	rm -f outline.pdf openacc-guide.pdf openacc-guide.doc
