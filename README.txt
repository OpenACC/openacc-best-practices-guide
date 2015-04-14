OpenACC Porting and Portability Guide
=====================================
This guide is written in Pandoc markdown format
(http://johnmacfarlane.net/pandoc/README.html). 

The build.bat file may be used to generate a PDF once Pandoc and a LaTex
package are installed or the command may be modified to generate on
another platform.

Windows Instructions
--------------------
On Windows it is necessary to install the pandoc package and 
MiKTeX (http://miktex.org/). The first time you build the pdf using
build.bat, MiKTeX will need to install several dependencies. This will 
only happen the first time the document is built.

Linux Instructions
------------------
On Linux it is necessary to install the pandoc package and a LaTeX 
interpreter. Once installed, the included Makefile can be used to 
generate a PDF.

FIXME 
-----
* The implicit_figures feature is disabled until I can determine how to
  make the figures inline rather than lumped together at the end. This
  may simply be an issue of a different LaTeX -> PDF converter.
* Need to look into installing filter for internal figure references.
* Need to generate SVG diagrams instead of PNG.
