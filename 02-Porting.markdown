Accelerating an Application with OpenACC
----------------------------------------
This section will detail an incremental approach to accelerating an application
using OpenACC. When taking this approach it is beneficial to revisit each
step multiple times, checking the results of each step for correctness. Working
incrementally will limit the scope of each change for improved productivity and
debugging.

### The APOD Cycle ###
***Note: we may wish to revisit this module to decide whether APOD is the
correct approach or some other, similar approach.***

The [NVIDIA CUDA C Best Practices
Guide](http://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html)
introduces a method for accelerating an application to a GPU using CUDA. The
Assess, Parallelize, Optimize, Deploy (APOD) cycle incrementally identifies
candidates for GPU acceleration within an application, parallelizes each
candidate on the GPU, optimizes the resulting code, and then deploys it back
into the production application before starting over. This document will take a
similar approach to accelerate applications with OpenACC. Each step will be
summarized below and revisted in later chapters of this guide.

#### Analyze to Application Performance ####
Before one can begin to accelerate an application it is important to understand
in which routines and loops an application is spending the bulk of its time and
why. It is critical to understand the most timeconsuming parts of the
application to maximize the benefit of acceleration. Amdahl's Law
informs us that the speed-up achievable from running an application on a
parallel accelerator will be limited by the remaining serial code. In other
words, the application will see the most benefit by accelerating as much of the
code as possible and by prioritizing the most time-consuming parts. A variety
of tools may be used to identify important parts of the code, including simple
application timers.

#### Parallelize using OpenACC Directives ####
Once important regions of the code have been identified, OpenACC directives
should be used to accelerate these regions on the target device. Parallel loops
within the code should be decorated with OpenACC directives to provide OpenACC
compilers the information necessary to parallelize the code for the target
architecture.

#### Optimize Data Locality ####
Because many accelerated architectures, such as CPU + GPU architectures, use
distinct memory spaces for the *host* and *device* it is necessary for the
compiler to manage data in both memories and move the data between the two
memories to ensure correct results. Compilers rarely have full knowledge of the
application, so they must be cautious in order to ensure correctness, which
often involves copying data to and from the accelerator more often than is
actually necessary. The programmer can give the compiler additional information
about how to manage the memory so that it remains local to the accelerator as
long as possible and is only moved between the two memories when absolutely
necessary. Programmers will often realize the largest performance gains after
optimizing data movement during this step.

#### Optimize Loops ####
Compilers will make decisions about how to map the parallelism in the code to
the target accelerator based on internal heuristics and the limited knowledge
it has about the application. Sometimes additional performance can be gained by
providing the compiler with more information so that it can make better
decisions on how to map the parallelism to the accelerator. When coming from a
traditional CPU architecture to a more parallel architecture, such as a GPU, it
may also be necessary to restructure loops to expose additional parallelism for
the accelerator or to reduce the frequency of data movement. Frequently code
refactoring that was motivated by improving performance on parallel
accelerators is beneficial to traditional CPUs as well.

#### Deploy ####
Once an important portion of the application has been accelerated by the above
steps the programmer should check for correctness and return to the analysis
step to identify the next important region of the code to accelerate. It is
through repeated application of this cycle that an application will realize the
benefit of acceleration. This document will not discuss steps for deploying the
code changes from the above sections, since this process is no different than
deploying other optimizations and will vary according to the practices and
policies of the code development team.

---

This process is by no means the only way to accelerate using OpenACC, but it
has been proven successful in numerous applications. Doing the same steps in
different orders may cause both frustration and difficulty debugging, so it's
advisable to perform each step of the process in the order shown above. It is
critical that when performing these steps the programmer test for correctness
frequently, as debugging small changes is much simpler than debugging large
changes.

### Heterogenous Computing Best Practices ###
Many applications have been written with little or even no parallelism exposed
in the code. The applications that do expose parallelism frequently do so in a
coarse-grained manner, where a small number of threads or processes execute for
a long time and compute a significant amount work each. Modern GPUs and many-core
processors, however, are designed to execute fine-grained threads, which are
short-lived and execute a minimal amount of work each. These parallel
architectures achieve high throughput by trading single-threaded performance in
favor of several orders in magnitude more parallelism. This means that when
accelerating an application with OpenACC, which was primarily designed for use
with these parallel accelerators, it may be necessary to refactor the code to
favor tightly-nested loops with a significant amount of data reuse. In many
cases these same code changes also benefit more traditional CPU architectures as
well by improving cache use and vectorization.

OpenACC may be used to accelerate applications on devices that have a
discrete memory or that have a memory space that's shared with the host. Even
on devices that utilize a shared memory there is frequently still a hierarchy
of a fast, close memory for the accelerator and a larger, slower memory used by
the host. For this reason it is important to structure the application code
maximize reuse of arrays regardless of whether the underlying architecture uses
discrete or unified memories. When refactoring the code for use with OpenACC it
is frequently beneficial to assume a discrete memory, even if the device you
are developing on has a unified memory. This forces data locality to be a
primary consideration in the refactoring and will ensure that the resulting
code exploits hierarchical memories and is portable to a wide range of devices.

Case Study - Jacobi Iteration
-----------------------------
Throughout this guide we will use a simple application to demonstrate each step
of the acceleration process. This application will implement a technique known
as a Jacobi Iteration (link?), which is a common, iterative technique for
approximating an answer within some allowable tolerance. In the case of our
example we will perform a simple stencil calculation where each point
calculates it value as the mean of its neighbors' values. The calculation will
continue to iterate until either the maximum change in value between two
iterations drops below some tolerance level or a maximum number of iterations
is reached. For the sake of consistent comparison through the document the
examples will always iteration 1000 times. The main iteration loop for both
C/C++ and Fortran appears below.

~~~~ {.numberLines}
    while ( error > tol && iter < iter_max )
    {
        error = 0.0;

        for( int j = 1; j < n-1; j++)
        {
            for( int i = 1; i < m-1; i++ )
            {
                Anew[j][i] = 0.25 * ( A[j][i+1] + A[j][i-1]
                                    + A[j-1][i] + A[j+1][i]);
                error = fmax( error, fabs(Anew[j][i] - A[j][i]));
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

---

~~~~ {.numberLines}
    do while ( error .gt. tol .and. iter .lt. iter_max )
      error=0.0_fp_kind
  
      do j=1,m-2
        do i=1,n-2
          Anew(i,j) = 0.25_fp_kind * ( A(i+1,j  ) + A(i-1,j  ) + &
                                       A(i  ,j-1) + A(i  ,j+1) )
          error = max( error, abs(Anew(i,j)-A(i,j)) )
        end do
      end do
  
      if(mod(iter,100).eq.0 ) write(*,'(i5,f10.6)'), iter, error
      iter = iter + 1
  
      do j=1,m-2
        do i=1,n-2
          A(i,j) = Anew(i,j)
        end do
      end do
  
    end do
~~~~

The outermost loop in each example will be referred to as the *convergence
loop*, since it loops until the answer has converged by reaching some maximum
error tolerance or number of iterations. Notice that whether or not a loop
iteration occurs depends on the error value of the previous iteration. Also,
the values for each element of `A` is calculated based on the values of the
previous iteration, known as a data dependency. These two facts mean that this
loop cannot be run in parallel.

The first loop nest within the convergence loop calculates the new value for
each element based on the current values of its neighbors. Notice that it is
necessary to store this new value into a different array. If each iteration
stored the new value back into itself then a data dependency would exist between
the data elements, as the order each element is calculated would affect the
final answer. By storing into a temporary array we ensure that all values are
calculated using the current state of `A` before `A` is updated. As a result,
each loop iteration is completely independent of each other iteration. These
loop iterations may safely be run in any order or in parallel and the final
result would be the same. This loop also calculates a maximum error value. The
error value is the difference between the new value and the old. If the maximum
amount of change between two iterations is within some tolerance, the problem
is considered converged and the outer loop will exit.

The second loop nest simply updates the value of `A` with the values calculated
into `Anew`. If this is the last iteration of the convergence loop, `A` will be
the final, converged value. If the problem has not yet converged, then `A` will
serve as the input for the next iteration. As with the above loop nest, each
iteration of this loop nest is independent of each other and is safe to
parallelize. A common optimization for this method is to use two pointers so
that with each iteration the pointer to the current and next values will simply
be swapped to avoid expensive memory copies. For the sake of simplicity the
example code forgoes this optimization.

In the coming sections we will accelerate this simple application using the
method described in this document. 

***Can we put the source code to this somewhere externally? Github? We've used
it in so many workshops and talks, it's been widely seen.***
