openacc-guide.pdf: 
	pandoc -f markdown+implicit_figures -s -o openacc-guide.pdf ??-*.markdown --filter pandoc-citeproc --highlight-style pygments --chapters
	#pandoc -f markdown+implicit_figures -s -o openacc-guide.pdf ??-*.markdown --chapters --toc --toc-depth=2 -V geometry:margin=1in --filter pandoc-citeproc -V documentclass:book -V classoption:oneside --highlight-style pygments
	#pandoc -f markdown+implicit_figures -s -o openacc-guide.tex ??-*.markdown --chapters --toc --toc-depth=2 -V geometry:margin=1in --filter pandoc-citeproc -V documentclass:book -V classoption:oneside
	#sed -i s/htbp/H/ openacc-guide.tex
	#pandoc -s -o openacc-guide.pdf openacc-guide.tex --chapters --toc --toc-depth=2 -V geometry:margin=1in --filter pandoc-citeproc -V documentclass:book -V classoption:oneside

openacc-guide.html: 
	pandoc -f markdown+implicit_figures -s -o openacc-guide.html ??-*.markdown --chapters --toc --toc-depth=2 -V geometry:margin=1in --filter pandoc-citeproc -V documentclass:book -V classoption:oneside --highlight-style pygments

openacc-guide.doc: 
	pandoc -f markdown+implicit_figures -s -o openacc-guide.doc ??-*.markdown --chapters --toc --toc-depth=2 -V geometry:margin=1in --filter pandoc-citeproc

outline.pdf: outline.markdown
	pandoc outline.markdown -o outline.pdf -V geometry:margin=1in

all: openacc-guide.pdf openacc-guide.doc outline.pdf

clean:
	rm -f outline.pdf openacc-guide.pdf openacc-guide.doc openacc-guide.tex
