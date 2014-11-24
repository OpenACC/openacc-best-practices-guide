all: outline.pdf

outline.pdf: outline.mkd
	pandoc outline.mkd -o outline.pdf -V geometry:margin=1in

clean:
	rm -f outline.pdf
