OpenACC Porting and Best Practices Guide
========================================
1. What is OpenACC?
-------------------
High level overview of compiler directives

* Compiler directives basics
* Benefits and Tradeoffs to compiler directives
* Abstract accelerator model
    * Multiple Levels of Parallelism
    * Memory hierarchies
* Should I say something here about the relevance toward OpenMP target
  directives?

2. Accelerating an application
------------------------------
Describe the porting process at a high level including APOD

* Assess the code to identify parallelism
* Parallelize the code with directives
* Optimize data locality (Optimize, part 1)
* Optimize loops (Optimize, part 2)
* Return to step 1 (Deploy?)

3. Assess
---------
Where to start

* Generating a CPU profile using common tools
   * What tools can we point to here?
* Discuss coarse vs. fine-grained parallelism
* Utilizing existing OpenMP directives?

4. Parallelize
--------------
Moving computation to the GPU

* PARALLEL and KERNELS regions
* LOOP directive
    * private clause
    * reduction clause
* ROUTINE directive

5. Optimize Data Locality
-------------------------
Improving data movement

* Introduction to data regions
* Data clauses
* Introduction to unstructured data lifetimes
    * Show usage in C++ classes
* CACHE directive
* Asynchronous overlapping
* Dealing with global data (is this needed?)

6. Optimize Loops
-----------------
Loop-level optimizations that make a difference

* Common loop transformations
* COLLAPSE directive
* TILE directive
    * I will leave this out unless someone can provide me a case where it's
      beneficial

7. Deploy
---------
What more is there to say at this point?

8. Interoperability
-------------------
How to use OpenACC with math libraries and CUDA

* Reuse examples from my blog post

9. Interacting with MPI
-----------------------
Expand on previous chapter with specifics around MPI

* Reuse Jiri's material

10. Writing Portable OpenACC
----------------------------
Tips on writing code with portability in mind. I'm not sure exactly what will
go here, but it seems important to me.

A. Appendix - OpenACC for XX programmers
----------------------------------------
Tips for understanding OpenACC if you already have understanding of another parallel programming paradigm.
* OpenACC for CUDA programmers
* OpenACC for OpenCL programmers
* OpenACC for OpenMP programmers

NOTES: 
------

* What tools can/should I show?
    * pgprof/gprof for CPU profiling
        * Identifies hotspots, but not loop info
    * CUDA visual profiler/Nsight 
        * Good for data motion insights
        * Good for prioritizing kernels
        * Poor for guiding how to optimize loops
    * Vampir/Tau?
        * CPU/GPU/MPI profiling in 1 tool
    * DDT/Totalview?
        * Commercial products, limited OpenACC support
