Analyze Application Performance
===============================
A variety of tools can be used to evaluate application performance and
which are available will depend on your development environment. From simple
application timers to graphical performance analyzers, the choice of
performance analysis tool is outside of the scope of this document. The purpose
of this section is to provide guidance on choosing important sections of code
for acceleration, which is independent of the profiling tools available. 

Because this document is focused on OpenACC, the PGPROF tool, which is provided
with the PGI OpenACC compiler will be used for CPU profiling. When accelerator
profiling is needed, the application will be run on an Nvidia GPU and the
Nvidia Visual Profiler will be used.

***NOTE: May choose to fall back to PGI_ACC_TIME or nvprof occaisionally, since
the text would be easy to understand. PGPROF also has GPU profiling, but I
haven't used it yet so I don't know whether it's as useful as NVVP.***

Baseline Profiling
------------------
Before parallelizing an application with OpenACC the programmer must first
understand where time is currently being spent in the code. Routines and loops
that take up a significant percentage of the runtime are frequently referred to
as *hot spots* and will be the starting point for accelerating the application. 

Case Study - Analysis
---------------------
