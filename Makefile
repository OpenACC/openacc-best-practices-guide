openacc-guide.pdf: 
	pandoc -f markdown+implicit_figures -s -o openacc-guide.pdf ??-*.markdown --chapters --toc --toc-depth=2 -V geometry:margin=1in --filter pandoc-citeproc -V documentclass:book -V classoption:oneside

outline.pdf: outline.markdown
	pandoc outline.markdown -o outline.pdf -V geometry:margin=1in

all: openacc-guide.pdf outline.pdf

clean:
	rm -f outline.pdf openacc-guide.pdf
