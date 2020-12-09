Contributing
------------

Please use the following guidelines when contributing to this project. 

Before contributing significant changes, please begin a discussion of the
desired changes via a GitHub Issue to prevent doing unnecessary or overlapping
work.

## License

The source code provided in this project is the licensed under Apache License
2.0 (https://www.apache.org/licenses/LICENSE-2.0) and text documentation is
licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0)
(https://creativecommons.org/licenses/by/4.0/). Contributions under other,
compatible licenses will be considered on a case-by-case basis.

Contributions must include a "signed off by" tag in the commit message for the
contributions asserting the signing of the developers certificate of origin
(https://developercertificate.org/). A GPG-signed commit with the "signed off
by" tag is preferred.

## Styling

Please use the following style guidelines when making contributions.

### Source Code

* Two-space indention, no tabs
* To the extent possible, variable names should be descriptive
* Fortran codes should use free-form source files
* Fortran codes should not use implicit variable names and should use
  `implicit none`
* The following file extensions should be used appropriately
  * C - `.c`
  * C++ - `.cpp`
  * CUDA C/C++ - `.cu`
  * CUDA Fortran - `.cuf`
  * Fortran - `.F90`

### Markdown

* When they appear inline with the text; directive names, clauses, function or
  subroutine names, variable names, file names, commands and command-line
  arguments should appear between two back ticks.
* Code blocks should begin with three back ticks and either 'cpp' or 'fortran'
  to enable appropriate source formatting and end with three back ticks.
* Emphasis, including quotes made for emphasis and introduction of new terms
  should be highlighted between a single pair of asterisks