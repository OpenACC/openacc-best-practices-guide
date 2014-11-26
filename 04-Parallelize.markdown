Parallelize Using OpenACC
=========================
Now that the importation *hot spots* in the application have been identified,
the programmer should incrementally accelerate these hotspots by adding OpenACC
directives to the important loops within those routines. OpenACC provides two
different approaches for exposing parallelism in the code: `kernels` and
`parallel` regions. Each of these directives will be detailed in the sections
that follow.

The Kernels Construct
---------------------

The Parallel Construct
----------------------

The Loop Construct
------------------

Examples
--------
