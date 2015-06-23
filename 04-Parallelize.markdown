Parallelize Loops
=================
Now that the important hotspots in the application have been identified, the
programmer should incrementally accelerate these hotspots by adding OpenACC
directives to the important loops within those routines. There is no reason to
think about the movement of data at this point in the process, the OpenACC
compiler will analyze the data needed in the identified region and
automatically ensure that the data is available on the accelerator. By focusing
solely on the parallelism during this step, the programmer can move as much
computation to the device as possible and ensure that the program is still
giving correct results before optimizing away data motion in the next step.
During this step in the process it is common for the overall runtime of the
application to increase, even if the execution of the individual loops is
faster using the accelerator. This is because the compiler must take a cautious
approach to data movement, frequently copying more data to and from the
accelerator than is actually necessary. Even if overall execution time
increases during this step, the developer should focus on expressing a
significant amount of parallelism in the code before moving on to the next step
and realizing a benefit from the directives.

----

OpenACC provides two different approaches for exposing parallelism in the code:
`parallel` and `kernels` regions. Each of these directives will be detailed in
the sections that follow.

The Kernels Construct
---------------------
The `kernels` construct identifies a region of code that may contain
parallelism, but relies on the automatic parallelization capabilities of the
compiler to analyze the region, identify which loops are safe to parallelize,
and then accelerate those loops. Developers will little or no parallel
programming experience, or those working on functions containing many loop
nests that might be parallelized will find the kernels directive a good
starting place for OpenACC acceleration. The code below demonstrates the use of
`kernels` in both C/C++ and Fortran.

~~~~ {.c .numberLines}
    #pragma acc kernels
    {
      for (i=0; i<N; i++)
      {
        y[i] = 0.0f;
        x[i] = (float)(i+1);
      }
    
      for (i=0; i<N; i++)
      {
        y[i] = 2.0f * x[i] + y[i];
      }
    }
~~~~    

----

~~~~ {.fortran .numberLines}
    !$acc kernels
    do i=1,N
      y(i) = 0
      x(i) = i
    enddo
  
    do i=1,N
      y(i) = 2.0 * x(i) + y(i)
    enddo
    !$acc end kernels
~~~~    

In this example the code is initializing two arrays and then performing a
simple calculation on them. Notice that we have identified a block of code,
using curly braces in C and starting and ending directives in Fortran, that
contains two candidate loops for acceleration. The compiler will analyze these
loops for data independence and parallelize both loops by generating an
accelerator *kernel* for each. The compiler is given complete freedom to
determine how best to map the parallelism available in these loops to the
hardware, meaning that we will be able to use this same code regardless of the
accelerator we are building for. The compiler will use its own knowledge of the
target accelerator to choose the best path for acceleration. One caution about
the `kernels` directive, however, is that if the compiler cannot be certain
that a loop is data independent, it will not parallelize the loop. Common
reasons for why a compiler may misidentify a loop as non-parallel will be
discussed in a later section.

The Parallel Construct
----------------------
The `parallel` construct identifies a region of code that will be parallelized
across OpenACC *gangs*. By itself the a `parallel` region is of limited use,
but when paired with the `loop` directive (discussed in more detail later) the
compiler will generate a parallel version of the loop for the accelerator.
These two directives can, and most often are, combined into a single `parallel
loop` directive. By placing this directive on a loop the programmer asserts
that the affected loop is safe to parallelize and allows the compiler to select
how to schedule the loop iterations on the target accelerator. The code below
demonstrates the use of the `parallel loop` combined directive in both C/C++
and Fortran.

~~~~ {.c .numberLines}
    #pragma acc parallel loop
      for (i=0; i<N; i++)
      {
        y[i] = 0.0f;
        x[i] = (float)(i+1);
      }
    
    #pragma acc parallel loop
      for (i=0; i<N; i++)
      {
        y[i] = 2.0f * x[i] + y[i];
      }
~~~~

----

~~~~ {.fortran .numberLines}
    !$acc parallel loop
    do i=1,N
      y(i) = 0
      x(i) = i
    enddo
  
    !$acc parallel loop
    do i=1,N
      y(i) = 2.0 * x(i) + y(i)
    enddo
~~~~    

Notice that, unlike the `kernels` directive, each loop needs to be explicitly
decorated with `parallel loop` directives. This is because the `parallel`
construct relies on the programmer to identify the parallelism in the code
rather than performing its own compiler analysis of the loops. In this case,
the programmer is only identifying the availability of parallelism, but still
leaving the decision of how to map that parallelism to the accelerator to the
compiler's knowledge about the device. This is a key feature that
differentiates OpenACC from other, similar programming models. The programmer
identifies the parallelism without dictating to the compiler how to exploit
that parallelism. This means that OpenACC code will be portable to devices
other than the device on which the code is being developed, because details
about how to parallelize the code are left to compiler knowledge rather than
being hard-coded into the source. 

Differences Between Parallel and Kernels
----------------------------------------
One of the biggest points of confusion for new OpenACC programmers is why the
specification has both the `parallel` and `kernels` directives, which appear to
do the same thing. While they are very closely related there are subtle
differences between them. The `kernels` construct gives the compiler maximum
leeway to parallelize and optimize the code how it sees fit for the target
accelerator, but also relies most heavily on the compiler's ability to
automatically parallelize the code. As a result, the programmer may see
differences in what different compilers are able to parallelize and how they do
so. The `parallel loop` directive is an assertion by the programmer
that it is both safe and desirable to parallelize the affected loop. This
relies on the programmer to have correctly identified parallelism in the code
and remove anything in the code that may be unsafe to parallelize. If the
programmer asserts incorrectly that the loop may be parallelized then the
resulting application may produce incorrect results. 

To put things another way: the `kernels` construct may be thought of as a hint
to the compiler of where it should look for parallelism while the `parallel`
directive is an assertion to the compiler of where there is parallelism.

An important thing to note about the `kernels` construct is that the compiler
will analyze the code and only parallelize when it is certain that it is safe
to do so.  In some cases the compiler may not have enough information at
compile time to determine whether a loop is safe the parallelize, in which case
it will not parallelize the loop, even if the programmer can clearly see that
the loop is safely parallel. For example, in the case of C/C++ code, where
arrays are passed into functions as pointers, the compiler may not always be
able to determine that two arrays do not share the same memory, otherwise known
as *pointer aliasing*. If the compiler cannot know that two pointers are not
aliased it will not be able to parallelize a loop that accesses those arrays. 

***Best Practice:*** C programmers should use the `restrict` keyword (or the
`__restrict` dectorator in C++) whenever possible to inform the compiler that
the pointers are not aliased, which will frequently give the compiler enough
information to then parallelize loops that it would not have otherwise. In
addition to the `restrict` keyword, declaring constant variables using the
`const` keyword may allow the compiler to use a read-only memory for that
variable if such a memory exists on the accelerator. Use of `const` and
`restrict` is a good programming practice in general, as it gives the compiler
additional information that can be used when optimizing the code.

Fortran programmers should also note that an OpenACC compiler will parallelize
Fortran array syntax that is contained in a `kernels` construct. When using
`parallel` instead, it will be necessary to explicitly introduce loops over the
elements of the arrays.

One more notable benefit that the `kernels` construct provides is that if data
is moved to the device for use in loops contained in the region, that data will
remain on the device for the full extent of the region, or until it is needed
again on the host within that region. This means that if multiple loops access
the same data it will only be copied to the accelerator once. When `parallel
loop` is used on two subsequent loops that access the same data a compiler may
or may not copy the data back and forth between the host and the device between
the two loops. In the examples shown in the previous section the compiler
generates implicit data movement for both parallel loops, but only
generates data movement once for the `kernels` approach, which may result in
less data motion by default. This difference will be revisited in the case
study later in this chapter.

For more information on the differences between the `kernels` and `parallel`
directives, please see [http://www.pgroup.com/lit/articles/insider/v4n2a1.htm].

---

At this point many programmers will be left wondering which directive they
should use in their code. More experienced parallel programmers, who may have
already identified parallel loops within their code, will likely find the
`parallel loop` approach more desirable. Programmers with less parallel
programming experience or whose code contains a large number of loops that need
to be analyzed may find the `kernels` approach much simpler, as it puts more of
the burden on the compiler. Both approaches have advantages, so new OpenACC
programmers should determine for themselves which approach is a better fit for
them. A programmer may even choose to use `kernels` in one part of the code,
but `parallel` in another if it makes sense to do so.

**Note:** For the remainder of the document the phrase *parallel region* will be
used to describe either a `parallel` or `kernels` region. When refering to the
`parallel` construct, a terminal font will be used, as shown in this
sentence.

The Loop Construct
------------------
The `loop` construct gives the compiler additional information about the very
next loop in the source code. The `loop` directive was shown above in
connection with the `parallel` directive, although it is also valid with
`kernels`. Loop clauses come in two forms: clauses for correctness and clauses
for optimization. This chapter will only discuss the two correctness clauses
and a later chapter will discuss optimization clauses.

### private ###
The private clause specifies that each loop iteration requires its own copy of
the listed variables. For example, if each loop contains a small, temporary
array named `tmp` that it uses during its calculation, then this variable must
be made private to each loop iteration in order to ensure correct results. If
`tmp` is not declared private, then threads executing different loop iterations
may access this shared `tmp` variable in unpredictable ways, resulting in a
race condition and potentially incorrect results. Below is the synax for the
`private` clause.

    private(variable)

There are a few special cases that must be understood about scalar
variables within loops. First, loop iterators will be privatized by default, so
they do not need to be listed as private. Second, unless otherwise specified,
any scalar accessed within a parallel loop will be made *first private* by
default, meaning a private copy will be made of the variable for each loop
iteration and it will be initialized with the value of that scalar upon
entering the region. Finally, any variables (scalar or not) that are declared
within a loop in C or C++ will be made private to the iterations of that loop
by default.

Note: The `parallel` construct also has a `private` clause which will privatize
the listed variables for each gang in the parallel region. 

### reduction ###
The `reduction` clause works similarly to the `private` clause in that a
private copy of the affected variable is generated for each loop iteration, but
`reduction` goes a step further to reduce all of those private copies into one
final result, which is returned from the region. For example, the maximum of
all private copies of the variable may be required or perhaps the sum. A
reduction may only be specified on a scalar variable and only common, specified
operations can be performed, such as `+`, `*`, `min`, `max`, and various
bitwise operations (see the OpenACC specification for a complete lsit). The
format of the reduction clause is as follows, where *operator* should be
replaced with the operation of interest and *variable* should be replaced with
the variable being reduced:

    reduction(operator:variable)

An example of using the `reduction` clause will come in the case study below.

Routine Directive
-----------------
Function or subroutine calls within parallel loops can be problematic for
compilers, since it's not always possible for the compiler to see all of the
loops at one time. OpenACC 1.0 compilers were forced to either inline all
routines called within parallel regions or not parallelize loops containing
routine calls at all. OpenACC 2.0 introduced the `routine` directive to address
this shortcoming. The `routine` directive gives the compiler the necessary
information about the function or subroutine and the loops it contains in order
to parallelize the calling parallel region. The routine directive must be added
to a function definition informing the compiler of the level of parallelism
used within the routine. OpenACC's *levels of parallelism* will be discussed in a
later section.

###C++ Class Functions###
When operating on C++ classes, it's frequently necessary to call class
functions from within parallel regions. The example below shows a C++ class
`float3` that contains 3 floating point values and has a `set` function that is
used to set the values of its `x`, `y`, and `z` members to that of another
instance of `float3`. In order for this to work from within a parallel region,
the `set` function is declared as an OpenACC routine using the `acc routine`
directive. Since we know that it will be called by each iteration of a parallel
loop, it's declared a `seq` (or *sequential*) routine. 

~~~~ {.cpp .numberLines}
    class float3 {
       public:
     	float x,y,z;
    
       #pragma acc routine seq
       void set(const float3 *f) {
    	x=f->x;
    	y=f->y;
    	z=f->z;
       }
    };
~~~~


Case Study - Parallelize
------------------------
In the last chapter we identified the two loop nests within the convergence
loop as the most time consuming parts of our application.  Additionally we
looked at the loops and were able to determine that the outer, convergence loop
is not parallel, but the two loops nested within are safe to parallelize. In
this chapter we will accelerate those loop nests with OpenACC using the
directives discussed earlier in this chapter. To further emphasize the
similarities and differences between `parallel` and `kernels` directives, we
will accelerate the loops using both and discuss the differences.

### Parallel Loop ###
We previously identified the available parallelism in our code, now we will use
the `parallel loop` directive to accelerate the loops that we identified. Since
we know that the two, doubly-nested sets of loops are parallel, simply add a
`parallel loop` directive above each of them. This will inform the compiler
that the outer of the two loops is safely parallel. Some compilers will
additionally analyze the inner loop and determine that it is also parallel, but
to be certain we will also add a `loop` directive around the inner loops. 

There is one more subtlty to accelerating the loops in this example: we are
attempting to calculate the maximum value for the variable `error`. As
discussed above, this is considered a *reduction* since we are reducing from
all possible values for `error` down to just the single maximum. This means
that it is necessary to indicate a reduction on the first loop nest (the one
that calculates `error`). 

***Best Practice:*** Some compilers will detect the reduction on `error` and
implicitly insert the `reduction` clause, but for maximum portability the
programmer should always indicate reductions in the code.

At this point the code looks like the examples below.

~~~~ {.c .numberLines startFrom="52"}
    while ( error > tol && iter < iter_max )
    {
      error = 0.0;
      
      #pragma acc parallel loop reduction(max:error) 
      for( int j = 1; j < n-1; j++)
      {
        for( int i = 1; i < m-1; i++ )
        {
          A[j][i] = 0.25 * ( Anew[j][i+1] + Anew[j][i-1]
                           + Anew[j-1][i] + Anew[j+1][i]);
          error = fmax( error, fabs(A[j][i] - Anew[j][i]));
        }
      }

      #pragma acc parallel loop
      for( int j = 1; j < n-1; j++)
      {
        for( int i = 1; i < m-1; i++ )
        {
          A[j][i] = Anew[j][i];
        }
      }
      
      if(iter % 100 == 0) printf("%5d, %0.6f\n", iter, error);
      
      iter++;
    }
~~~~    
      
----

~~~~ {.fortran .numberLines startFrom="52"}
    do while ( error .gt. tol .and. iter .lt. iter_max )
      error=0.0_fp_kind
        
      !$acc parallel loop reduction(max:error)
      do j=1,m-2
        !$acc loop
        do i=1,n-2
          A(i,j) = 0.25_fp_kind * ( Anew(i+1,j  ) + Anew(i-1,j  ) + &
                                    Anew(i  ,j-1) + Anew(i  ,j+1) )
          error = max( error, abs(A(i,j) - Anew(i,j)) )
        end do
      end do

      !$acc parallel loop
      do j=1,m-2
        do i=1,n-2
          A(i,j) = Anew(i,j)
        end do
      end do

      if(mod(iter,100).eq.0 ) write(*,'(i5,f10.6)'), iter, error
      iter = iter + 1
    end do
~~~~    

Building the above code using the PGI compiler (version 15.5) produces the
following compiler feedback (showing for C, but the Fortran output is similar).

    $ pgcc -acc -ta=tesla -Minfo=accel laplace2d-parallel.c
    main:
         56, Accelerator kernel generated
             56, Max reduction generated for error
             57, #pragma acc loop gang /* blockIdx.x */
             59, #pragma acc loop vector(128) /* threadIdx.x */
         56, Generating copyout(Anew[1:4094][1:4094])
             Generating copyin(A[:][:])
             Generating Tesla code
         59, Loop is parallelizable
         67, Accelerator kernel generated
             68, #pragma acc loop gang /* blockIdx.x */
             70, #pragma acc loop vector(128) /* threadIdx.x */
         67, Generating copyin(Anew[1:4094][1:4094])
             Generating copyout(A[1:4094][1:4094])
             Generating Tesla code
         70, Loop is parallelizable

Analyzing the compiler feedback gives the programmer the ability to ensure that
the compiler is producing the expected results and fix any problems if it's not.
In the output above we see that accelerator kernels were generated for the two
loops that were identified (at lines 58 and 71, in the compiled source file)
and that the compiler automatically generated data movement, which will be
discussed in more detail in the next chapter.

Other clauses to the `loop` directive that may further benefit the performance
of the resulting code will be discussed in a later chapter.  (***TODO: Link to
later chapter when done.***)

### Kernels ###
Using the `kernels` construct to accelerate the loops we've identified requires
inserting just one directive in the code and allowing the compiler to perform
the parallel analysis. Adding a `kernels` construct around the two
computational loop nests results in the following code.

~~~~ {.c .numberLines startFrom="51"}
    while ( error > tol && iter < iter_max )
    {
      error = 0.0;
      
      #pragma acc kernels 
      {
        for( int j = 1; j < n-1; j++)
        {
          for( int i = 1; i < m-1; i++ )
          {
            A[j][i] = 0.25 * ( Anew[j][i+1] + Anew[j][i-1]
                             + Anew[j-1][i] + Anew[j+1][i]);
            error = fmax( error, fabs(A[j][i] - Anew[j][i]));
          }
        }
      
        for( int j = 1; j < n-1; j++)
        {
          for( int i = 1; i < m-1; i++ )
          {
            A[j][i] = Anew[j][i];
          }
        }
      }        
      
      if(iter % 100 == 0) printf("%5d, %0.6f\n", iter, error);
      
      iter++;
    }
~~~~    

----

~~~~ {.fortran .numberLines startFrom="51"}
    do while ( error .gt. tol .and. iter .lt. iter_max )
      error=0.0_fp_kind
        
      !$acc kernels 
      do j=1,m-2
        do i=1,n-2
          A(i,j) = 0.25_fp_kind * ( Anew(i+1,j  ) + Anew(i-1,j  ) + &
                                    Anew(i  ,j-1) + Anew(i  ,j+1) )
          error = max( error, abs(A(i,j) - Anew(i,j)) )
        end do
      end do

      do j=1,m-2
        do i=1,n-2
          A(i,j) = Anew(i,j)
        end do
      end do
      !$acc end kernels
        
      if(mod(iter,100).eq.0 ) write(*,'(i5,f10.6)'), iter, error
      iter = iter + 1
    end do
~~~~    
    
The above code demostrates some of the power that the `kernels` construct
provides, since the compiler will analyze the code and identify both loop nests
as parallel and it will automatically discover the reduction on the `error`
variable without programmer intervention. An OpenACC compiler will likely
discover not only that the outer loops are parallel, but also the inner loops,
resulting in more available parallelism with fewer directives than the
`parallel loop` approach. Had the programmer put the `kernels` construct around
the convergence loop, which we have already determined is not parallel, the
compiler likely would not have found any available parallelism. Even with the
`kernels` directive it is necessary for the programmer to do some amount of
analysis to determine where parallelism may be found.

Taking a look at the compiler output points to some more subtle differences
between the two approaches.

    $ pgcc -acc -ta=tesla -Minfo=accel laplace2d-kernels.c
    main:
         56, Generating copyout(Anew[1:4094][1:4094])
             Generating copyin(A[:][:])
             Generating copyout(A[1:4094][1:4094])
             Generating Tesla code
         58, Loop is parallelizable
         60, Loop is parallelizable
             Accelerator kernel generated
             58, #pragma acc loop gang /* blockIdx.y */
             60, #pragma acc loop gang, vector(128) /* blockIdx.x threadIdx.x */
             64, Max reduction generated for error
         68, Loop is parallelizable
         70, Loop is parallelizable
             Accelerator kernel generated
             68, #pragma acc loop gang /* blockIdx.y */
             70, #pragma acc loop gang, vector(128) /* blockIdx.x threadIdx.x */

The first thing to notice from the above output is that the compiler correctly
identified all four loops as being parallelizable and generated kernels from
those loops. Also notice that the compiler only generated implicit data
movement directives at line 54 (the beginning of the `kernels` region), rather
than at the beginning of each `parallel loop`. This means that the resulting
code should perform fewer copies between host and device memory in this version
than the version from the previous section. A more subtle difference between
the output is that the compiler chose a different loop decomposition scheme (as
is evident by the implicit `acc loop` directives in the compiler output) than
the parallel loop because `kernels` allowed it to do so. More details on how to
interpret this decomposition feedback and how to change the behavior will be
discussed in a later chapter.

---

At this point we have expressed all of the parallelism in the example code and
the compiler has parallelized it for an accelerator device. Analyzing the
performance of this code may yield surprising results on some accelerators,
however. The results below demonstrate the performance of this code on 1 - 8
CPU threads on a modern CPU at the ime of publication and an NVIDIA Tesla K40
GPU using both implementations above. The *y axis* for figure 3.1 is execution
time in seconds, so smaller is better. For the two OpenACC versions, the bar is
divided by time transferring data between the host and device, time executing
on the device, and other time.

![Jacobi Iteration Performance - Step 1](images/jacobi_step1_graph.png)

Notice that the performance of this code improves as CPU threads are added to
the calcuation and that the `kernels` version outperforms even the best CPU
case by a large margin. The OpenACC `parallel loop` case, however, performs
dramaticaly worse than even the slowest CPU version. Further performance
analysis is necessary to identify the source of this slowdown. A variety of
tools are available for performing this analysis, but since this performance
study was compiled with the PGI compiler, the PGI internal timers will give us
a high-level analysis of the performance.

~~~~
    $ export PGI_ACC_TIME=1
    $ ./a.out
    Jacobi relaxation Calculation: 4096 x 4096 mesh
        0, 0.250000
      100, 0.002397
      200, 0.001204
      300, 0.000804
      400, 0.000603
      500, 0.000483
      600, 0.000403
      700, 0.000345
      800, 0.000302
      900, 0.000269
     total: 206.204458 s
    
    Accelerator Kernel Timing data
    laplace2d.c
      main  NVIDIA  devicenum=0
        time(us): 4,622,652
        55: data region reached 1000 times
            55: data copyin transfers: 8000
                 device time(us): total=109,504 max=75 min=8 avg=13
            66: data copyout transfers: 8000
                 device time(us): total=161,007 max=465 min=7 avg=20
        55: compute region reached 1000 times
            55: kernel launched 1000 times
                grid: [4094]  block: [128]
                 device time(us): total=2,335,051 max=2,405 min=2,256 avg=2,335
                elapsed time(us): total=2,403,319 max=2,568 min=2,328 avg=2,403
            55: reduction kernel launched 1000 times
                grid: [1]  block: [256]
                 device time(us): total=13,042 max=21 min=13 avg=13
                elapsed time(us): total=42,028 max=85 min=39 avg=42
        66: data region reached 1000 times
            66: data copyin transfers: 8000
                 device time(us): total=201,963 max=97 min=10 avg=25
            75: data copyout transfers: 8000
                 device time(us): total=157,935 max=72 min=6 avg=19
        66: compute region reached 1000 times
            66: kernel launched 1000 times
                grid: [4094]  block: [128]
                 device time(us): total=1,644,150 max=1,661 min=1,633 avg=1,644
                elapsed time(us): total=1,715,129 max=2,253 min=1,684 avg=1,715
~~~~ 

Notice in the above output that the majority of the time in the parallel loop
version is being spent doing memory copies, as evident by the time spent in each `data copyin` and `data copyout` transfer. Since the test machine has two distinct memory spaces for the CPU and
GPU memories, it's necessary to copy the data between the memory spaces. The
next tool that may be helpful debugging the amount memory transfers is the
NVIDIA Visual Profiler. The screenshot in figure 3.2 shows NVIDIA Visual
Profiler for ***2*** iterations of the convergence loop in the `parallel loop`
version of the code.

![Screenshot of NVIDIA Visual Profiler on 2 steps of the Jacobi Iteration
showing a high amount of data transfer compared to
computation.](images/jacobi_step1_nvvp.png) 

In this screenshot, the tool represents data transfers using the tan color
boxes in the two *MemCpy* rows and the computation time in the green and purple
boxes in the rows below *Compute*. It should be obvious from the timeline
displayed that significantly more time is being spent copying data two and from
the accelerator before and after each compute kernel than actually computing on
the device. In the next chapter we will fix this inefficiency.
