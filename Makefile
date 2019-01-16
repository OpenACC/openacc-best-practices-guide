openacc-guide.pdf: 
	pandoc -f markdown+implicit_figures -s -o openacc-guide.pdf ??-*.markdown --filter pandoc-citeproc --highlight-style pygments --top-level-division=chapter
	#pandoc -f markdown+implicit_figures -s -o openacc-guide.pdf ??-*.markdown --top-level-division=chapter --toc --toc-depth=2 -V geometry:margin=1in --filter pandoc-citeproc -V documentclass:book -V classoption:oneside --highlight-style pygments
	#pandoc -f markdown+implicit_figures -s -o openacc-guide.tex ??-*.markdown --top-level-division=chapter --toc --toc-depth=2 -V geometry:margin=1in --filter pandoc-citeproc -V documentclass:book -V classoption:oneside
	#sed -i s/htbp/H/ openacc-guide.tex
	#pandoc -s -o openacc-guide.pdf openacc-guide.tex --top-level-division=chapter --toc --toc-depth=2 -V geometry:margin=1in --filter pandoc-citeproc -V documentclass:book -V classoption:oneside

openacc-guide.tex: 
	pandoc -f markdown+implicit_figures -s -o openacc-guide.tex ??-*.markdown --filter pandoc-citeproc --highlight-style pygments --top-level-division=chapter

openacc-guide.html: 
	pandoc -f markdown+implicit_figures -s -o openacc-guide.html ??-*.markdown --top-level-division=chapter --toc --toc-depth=2 -V geometry:margin=1in --filter pandoc-citeproc -V documentclass:book -V classoption:oneside --highlight-style pygments

openacc-guide.doc: 
	pandoc -f markdown+implicit_figures -s -o openacc-guide.doc ??-*.markdown --top-level-division=chapter --toc --toc-depth=2 -V geometry:margin=1in --filter pandoc-citeproc

outline.pdf: outline.markdown
	pandoc outline.markdown -o outline.pdf -V geometry:margin=1in

all: openacc-guide.pdf openacc-guide.doc outline.pdf

clean:
	rm -f outline.pdf openacc-guide.pdf openacc-guide.doc openacc-guide.tex
