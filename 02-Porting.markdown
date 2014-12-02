Accelerating an Application with OpenACC
========================================
This section will detail an incremental approach to accelerating an application
using OpenACC. When taking this approach it is beneficial to revisit each
step multiple times, checking the results of each step for correctness. Working
incrementally will limit the scope of each change for improved productivity and
debugging.

The APOD Cycle
--------------
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

### Analyze to Identify Parallelism ###
Before one can begin to accelerate an application it is important to understand
in which routines and loops an application is spending the bulk of its time and
why. It is critical to understand the most timeconsuming parts of the
application to maximize the benefit of acceleration. Amdahl's Law [see @amdahl]
informs us that the speed-up achievable from running an application on a
parallel accelerator will be limited by the remaining serial code. In other
words, the application will see the most benefit by accelerating as much of the
code as possible and by prioritizing the most time-consuming parts. A variety
of tools may be used to identify important parts of the code, including simple
application timers.

### Parallelize using OpenACC Directives ###
Once important regions of the code have been identified, OpenACC directives
should be used to accelerate these regions on the target device. Parallel loops
within the code should be decorated with OpenACC directives to provide OpenACC
compilers the information necessary to parallelize the code for the target
architecture.

### Optimize Data Locality ###
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

### Optimize Loops ###
Compilers will make decisions about how to map the parallelism in the code to
the target accelerator based on internal heuristics and the limited knowledge
it has about the application. Sometimes additional performance can be gained by
providing the compiler with more information so that it can make better
decisions on how to map the parallelism to the accelerator. When coming from a
traditional CPU architecture to a more parallel architecture, such as a GPU, it
may also be necessary to restructure loops to expose additional parallelism for
the accelerator or to reduce the frequency of data movement. Frequently code
refactoring that was motivated by improving performance on parallel
accelerators bring benefit to traditional CPUs as well.

### Deploy ###
Once an important portion of the application has been accelerated by the above
steps the programmer should check for correctness and return to the analysis
step to identify the next important region of the code to accelerate. It is
through repeated application of this cycle that an application will realize the
benefit of acceleration.

---

This process is by no means the only way to accelerate using OpenACC, but it
has been proven successful in numerous applications. Doing the same steps in
different orders may cause both frustration and difficulty debugging, so it's
advisable to perform each step of the process in the order shown above. It is
critical that when performing these steps the programmer test for correctness
frequently, as debugging small changes is much simpler than debugging large
changes.

Heterogenous Computing Best Practices
-------------------------------------
Many applications have been written with little or even no parallelism exposed
in the code. The applications that do expose parallelism frequently do so in a
coarse-grained manner, where a small number of threads or processes execute for
a long time and compute a significant amount work each. Modern many-core
processors, however, are designed to execute fine-grained threads, which are
short-lived and execute a minimal amount of work each. These parallel
architectures achieve high throughput by trading single-threaded performance in
favor several orders in magnitude more parallelism. This means that when
accelerating an application with OpenACC, which was primarily designed for use
with these parallel accelerators, it may be necessary to refactor the code to
favor tightly-nested loops with a significant amount of data reuse. In many
cases this same code changes also benefit more traditional CPU architectures as
well by improving cache use and vectorization.
