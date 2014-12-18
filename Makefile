all: outline.pdf

openacc-guide.pdf: 
	pandoc -f markdown-implicit_figures -s -o openacc-guide.pdf ??-*.markdown --toc --toc-depth=2 --chapters -V geometry:margin=1in --filter pandoc-citeproc -V documentclass:book

outline.pdf: outline.mkd
	pandoc outline.mkd -o outline.pdf -V geometry:margin=1in

clean:
	rm -f outline.pdf
