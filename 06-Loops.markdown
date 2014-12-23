Optimize Loops
==============
Once data locality has been expressed developers may wish to further tune the
code for the hardware of interest. It's important to understand that the more
loops are tuned for a particular type of hardware the less performance portable
the code becomes to other architecures. If you're generally running on one
particular accelerator, however, there may be some gains to be had by tuning
how the loops are mapped to the underlying hardware. 

It's tempting to begin tuning the loops before all of the data locality has
been expressed in the code. Because PCIe copies are frequently the limiter to
application performance on the current generation of accelerators the
performance impact of tuning a particular loop may be too difficult to measure
until data locality has been optimized. For this reason the best practice is to
wait to optimize particular loops until after all of the data locality has been
expressed in the code, reducing the PCIe transfer time to a minimum.

Efficient Loop Ordering
-----------------------
Before changing the way OpenACC maps loops onto the hardware of interest, the
developer should examine the important loops to ensure that data arrays are
being accessed in an efficient manner. Most modern hardware, be it a CPU with
large caches and SIMD operations or a GPU with coalesced memory accesses and
SIMT operations, favor accessing arrays in a *stride 1* manner.  That is to say
that each loop iteration accesses consecutive memory addresses. This is
achieved by ensuring that the innermost loop of a loop nest iterates on the
fastest varying array dimension and each successive loop outward accesses the
next fastest varying dimension. Arranging loops in this increasing manner will
frequently improve cache efficiency and improve vectorization on most
architectures. 

***Can we call out any exceptions to this rule of thumb or would that cause
more harm than good?***

OpenACC's 3 Levels of Parallelism
---------------------------------
OpenACC defines three levels of parallelism: *gang*, *worker*, and *vector*.
Additionally exectution may be marked as being sequential (*seq*). Vector
parallelism has the finest granularity, with an individual instruction
operating on multiple pieces of data (much like *SIMD* parallelism on a modern
CPU or *SIMT* parallelism on a modern GPU). Vector operations are performed
with a particular *vector length*, indicating how many datums may being
operated on with the same instruction. Gang parallelism is coarse-grained
parallelism, where gangs work independently of each other and may not
synchronize. Worker parallelism sits between vector and gang levels. A gang
consists of 1 or more workers, each of which operates on a vector of some
length.  Within a gang the OpenACC model exposes a *cache* memory, which can be
used by all workers and vectors within the gang, and it is legal to synchronize
within a gang, although OpenACC does not expose synchronization to the user.
Using these three levels of parallelism, plus sequential, a programmer can map
the parallelism in the code to any device. OpenACC does not require the
programmer to do this mapping explicitly, however. If the programmer chooses
not to explicitly map loops to the device of interest the compiler will
implicitly perform this mapping using what it knows about the target device.
This makes OpenACC highly portable, since the same code may be mapped to any
number of target devices. The more explicit mapping of parallelism the
programmer adds to the code, however, the less portable they make the code to
other architectures.

![OpenACC's Three Levels of Parallelism](images/levels_of_parallelism.png)

Mapping Parallelism to the Hardware
-----------------------------------
With some understanding of how the underlying accelerator hardware works it's
possible to inform that compiler how it should map the loop iterations into
parallelism on the hardware. It's worth restating that the more detail the
compiler is given about how to map the parallelism onto a particular
accelerator the less performance portable the code will be. 

As discussed earlier in this guide the `loop` directive is intended to give the
compiler additional information about the next loop in the code. In addition to
the clauses shown before, which were intended to ensure correctness, the
clauses below inform the compiler which level of parallelism should be used to
for the given loop.

* Gang clause - partition the loop across gangs
* Worder clause - partition the loop across workers
* Vector clause - vectorize the loop
* Seq clause - do not partition this loop, run it sequentially instead

These directives may also be combined on a particular loop. For example, a
`gang vector` loop would be partitioned across gangs, each of which with 1
worker implicitly, and then vectorized. The OpenACC specification enforces that
the outermost loop must be a gang loop, the innermost parallel loop must be
a vector loop, and a worker loop may appear in between. A sequential loop may
appear at any level.

    Insert code example

Informing the compiler where to partition the loops is just one part of
optimizing the loops. The programmer may additionally tell the compiler the
specific number of gangs, workers, or the vector length to use for the loops.
This specific mapping is achieved slightly differently when using the `kernels`
directive or the `parallel` directive. In the case of the `kernels` directive,
the `gang`, `worker`, and `vector` clauses accept an integer parameter that
will optionally inform the compiler how to partition that level of parallelism.
For example, `vector(128)` informs the compiler to use a vector length of 128
for the loop. 

    Insert code example for kernels

When using the `parallel` directive, the information is presented
on the `parallel` directive itself, rather than on each individual loop, in the
form of the `num_gangs`, `num_workers, and `vector\_length` clauses to the
`parallel` directive.

    Insert code example for parallel

Since these mappings will vary between different accelerator, the `loop`
directive accepts a `device\_type` clause, which will inform the compiler that
these clauses only apply to a particular device time. Clauses after a
`device\_type` clause up until either the next `device\_type` or the end of the
directive will apply only to the specified device. Clauses that appear before
all `device\_type` clauses are considered default values, which will be used if
they are not overridden by a later clause. For example, the code below
specifies that a vector length of 128 should be used on devices of type
`acc\_device\_nvidia` or a vector length of 256 should be used on devices of
type `acc\device\radeon`. The compiler will choose a default vector length for
all other device types.

~~~~ {.numberLines}
    #pragma acc parallel loop gang vector \
                device_type(acc_device_nvidia) vector_length(128) \
                device_type(acc_device_radeon) vector_length(256)
    for (i=0; i<N; i++)
    {
      y[i] = 2.0f * x[i] + y[i];
    }
~~~~

Collapse Directive
------------------
When a code contains tightly nested loops it is frequently beneficial to
*collapse* these loops into a single loop. Collpsing loops means that two loops
of trip counts N and M respectively will be automatically turned into a single
loop with a trip count of N times M. By collapsing two or more parallel loops into a
single loop the compiler has an increased amoutn of parallelism to use when
mapping the code to the device. On highly parallel architectures, such as GPUs,
this can result in improved performance. Additionally, if a loop lacked
sufficient parallelism for the hardware by itself, collapsing it with another
loop multiplies the available parallelism. This is especially beneficial on
vector loops, since some hardware types will require longer vector lengths to
acheive high performance than others. The code below demonstrates how to use
the collapse directive.

    Find a good code example that shows a nice speed-up and explain the speedup
    below.

***This section will grow when an example is added above.***

Tile Directive
--------------
***NOTE: I'm tempted to leave this off because I've yet to find a case where it
was beneficial.***

Case Study - Optimize Loops
---------------------------
