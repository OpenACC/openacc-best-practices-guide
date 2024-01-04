OpenACC Porting and Portability Guide
=====================================
This guide is written in Pandoc markdown format
(http://johnmacfarlane.net/pandoc/README.html). 

The build.bat file may be used to generate a PDF once Pandoc and a LaTex
package are installed or the command may be modified to generate on
another platform.

General Build Instructions
--------------------------
The included Makefile will use the `pandoc/latex:latest` docker image to 
build the guide. This can be overriden to point to a local install of 
`pandoc` by providing the `PANDOC` variable to the make command.

Windows Instructions
--------------------
On Windows it is necessary to install the pandoc package and 
MiKTeX (http://miktex.org/). The first time you build the pdf using
build.bat, MiKTeX will need to install several dependencies. This will 
only happen the first time the document is built.

FIXME 
-----
* The implicit_figures feature is disabled until I can determine how to
  make the figures inline rather than lumped together at the end. This
  may simply be an issue of a different LaTeX -> PDF converter.
* Need to look into installing filter for internal figure references.
* Need to generate SVG diagrams instead of PNG.
