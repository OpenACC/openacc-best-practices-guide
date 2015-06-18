Assess Application Performance
==============================
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
A variety of tools exist for generating application profiles, such as gprof,
pgprof, Vampir, and TAU. Selecting the specific tool that works best for a
given application is outside of the scope of this document, but regardless of
which tool or tools are used below are some important pieces of information
that will help guide the next steps in parallelizing the application.

* Application performance - How much time does the application take to run? How
  efficiently does the program use the computing resources? 
* Program hotspots - In which routines is the program spending most of its
  time? What is being done within these important routines? Focusing on the
  most time consuming parts of the application will yield the greatest results.
* Performance limiters - Within the identified hotspots, what's currently
  limiting the application performance? Some common limiters may be I/O, memory
  bandwidth, cache reuse, floating point performance, communication, etc.
  One way to evaluate the performance limiters of a given loop nest is to
  evaluate its *computational intensity*, which is a measure of how many
  operations are performed on a data element per load or store from memory. 
* Available parallelism - Examine the loops within the hotspots to understand
  how much work each loop nest performs. Do the loops iterate 10's, 100's,
  1000's of times (or more)? Do the loop iterations operate independently of
  each other? Look not only at the individual loops, but look a nest of loops
  to understand the bigger picture of the entire nest. 

Gathering baseline data like the above both helps inform the developer where to
focus efforts for the best results and provides a basis for comparing
performance throughout the rest of the process. It's important to choose input
that will realistically reflect how the application will be used once it has
been accelerated. It's tempting to use a known benchmark problem for profiling,
but frequently these benchmark problems use a reduced problem size or reduced
I/O, which may lead to incorrect assumptions about program performance. Many
developers also use the baseline profile to gather the expected output of the
application to use for verifying the correctness of the application as it is
accelerated.

Additional Profiling
--------------------
Through the process of porting and optimizing an application with OpenACC it's
necessary to gather additional profile data to guide the next steps in the
process. Some profiling tools, such as pgprof and Vampir, support profiling on
CPUs and GPUs, while other tools, such as gprof and NVIDIA Visual Profiler, may
only support profiling on a particular platform. Additionally, some compilers
build their own profiling into the application, such is the case with the PGI
compiler, which supports setting the PGI\_ACC\_TIME environment variable for
gathering runtime information about the application. When developing on
offloading platforms, such as CPU + GPU platforms, it's generally important to
use a profiling tool throughout the development process that can evaluate both
time spent in computation and time spent performing PCIe data transfers. This
document will use NVIDIA Visual Profiler for performing this analysis, although
it is only available on NVIDIA platforms.

Case Study - Analysis
---------------------
