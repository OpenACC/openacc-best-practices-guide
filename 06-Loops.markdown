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

~~~~ {.c .numberLines}
    #pragma acc parallel loop gang
    for ( i=0; i<N; i++)
      #pragma acc loop vector
      for ( j=0; j<M; j++)
        ;
~~~~

--

~~~~ {.fortran .numberLines}
    !$acc parallel loop gang
    do j=1,M
      !$acc loop vector
      do i=1,N
~~~~

Informing the compiler where to partition the loops is just one part of
optimizing the loops. The programmer may additionally tell the compiler the
specific number of gangs, workers, or the vector length to use for the loops.
This specific mapping is achieved slightly differently when using the `kernels`
directive or the `parallel` directive. In the case of the `kernels` directive,
the `gang`, `worker`, and `vector` clauses accept an integer parameter that
will optionally inform the compiler how to partition that level of parallelism.
For example, `vector(128)` informs the compiler to use a vector length of 128
for the loop. 

~~~~ {.c .numberLines}
    #pragma acc kernels
    {
    #pragma acc loop gang
    for ( i=0; i<N; i++)
      #pragma acc loop vector(128)
      for ( j=0; j<M; j++)
        ;
    }
~~~~

---

~~~~ {.fortran .numberLines}
    !$acc kernels
    !$acc loop gang
    do j=1,M
      !$acc loop vector(128)
      do i=1,N

    !$acc end kernels
~~~~

When using the `parallel` directive, the information is presented
on the `parallel` directive itself, rather than on each individual loop, in the
form of the `num_gangs`, `num_workers, and `vector\_length` clauses to the
`parallel` directive.

~~~~ {.c .numberLines}
    #pragma acc parallel loop gang vector_length(128)
    for ( i=0; i<N; i++)
      #pragma acc loop vector
      for ( j=0; j<M; j++)
        ;
~~~~

---

~~~~ {.fortran .numberLines}
    !$acc parallel loop gang vector_length(128)
    do j=1,M
      !$acc loop vector(128)
      do i=1,N
~~~~

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

~~~~ {.c .numberLines}
    #pragma acc parallel loop gang vector \
                device_type(acc_device_nvidia) vector_length(128) \
                device_type(acc_device_radeon) vector_length(256)
    for (i=0; i<N; i++)
    {
      y[i] = 2.0f * x[i] + y[i];
    }
~~~~

Collapse Clause
---------------
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

Tile Clause
-----------
***NOTE: I'm tempted to leave this off because I've yet to find a case where it
was beneficial.***

Routine Parallelism
-------------------
A previous chapter introduced the `routine` directive for calling functions and
subroutines from OpenACC parallel regions. In that chapter it was assumed that
the routine would be called from each loop iteration, therefore requiring a
`routine seq` directive. In some cases, the routine itself may contain
parallelism that must be mapped to the device. In these cases, the `routine`
directive may have a `gang`, `worker`, or `vector` clause instead of `seq` to
inform the compiler that the routine will contain the specified level of
parallelism. When the compiler then encounters the call site of the affected
routine, it will then know how it can parallelize the code to use the routine.

Case Study - Optimize Loops
---------------------------
This case study will focus on a different algorithm than the previous chapters.
When a compiler has sufficient information about loops to make informed
decisions, it's frequently difficult to improve the performance of a given
parallel loop by more than a few percent. In some cases, the code lacks the
information necessary for the compiler to make informed optimization decisions.
In these cases, it's often possible for a developer to optimize the parallel
loops significantly by informing the compiler how to decompose and distribute
the loops to the hardware.

The code used in this section implements a sparse, matrix-vector product (SpMV)
operation. This means that a matrix and a vector will be multiplied together,
but the matrix has very few elements that are not zero (it is *sparse*),
meaning that calculating these values is unnecessary. The matrix is stored in a
Compress Sparse Row (CSR) format. In CSR the sparse array, which may contain a
significant number of cells whose value is zero, thus wasting a significant
amount of memory, is stored using three, smaller arrays: one containing the
non-zero values from the matrix, a second that describes where in a given row
these non-zero elements would reside, and a third describing the columns in
which the data would reside. The code for this exercise is below.

~~~~ {.c .numberLines}
    #pragma acc parallel loop
    for(int i=0;i<num_rows;i++) {
      double sum=0;
      int row_start=row_offsets[i];
      int row_end=row_offsets[i+1];
      #pragma acc loop reduction(+:sum)
      for(int j=row_start;j<row_end;j++) {
        unsigned int Acol=cols[j];
        double Acoef=Acoefs[j];
        double xcoef=xcoefs[Acol];
        sum+=Acoef*xcoef;
      }
      ycoefs[i]=sum;
    }
~~~~

---

~~~~ {.fortran .numberLines}
    !$acc parallel loop
    do i=1,a%num_rows
      tmpsum = 0.0d0
      row_start = arow_offsets(i)
      row_end   = arow_offsets(i+1)-1
      !$acc loop reduction(+:tmpsum)
      do j=row_start,row_end
        acol = acols(j)
        acoef = acoefs(j)
        xcoef = x(acol)
        tmpsum = tmpsum + acoef*xcoef
      enddo
      y(i) = tmpsum
    enddo
~~~~

One important thing to note about this code is that the compiler is unable to
determine how many non-zeros each row will contain and use that information in
order to schedule the loops. The developer knows, however, that the number of
non-zero elements per row is very small and this detail will be key to
achieving high performance. 

***NOTE: Because this case study features optimization techniques, it is
necessary to perform optimizations that may be beneficial on one hardware, but
not on others. This case study was performed using the PGI 2015 compiler on an
NVIDIA Tesla K40 GPU. These same techniques may apply on other architectures,
particularly those similar to NVIDIA GPUs, but it will be necessary to make
certain optimization decisions based on the particular accelerator in use.***

In examining the compiler feedback from the code shown above, I know that the
compiler has chosen to use a vector length of ___ on the innermost loop. I
could have also obtained this information from a runtime profile of the
application. Based on my knowledge of the matrix, I know that this is
significantly larger than the typical number of non-zeros per row, so many of
the *vector lanes* on the accelerator will be wasted because there's not
sufficient work for them. The first thing to try in order to improve
performance is to adjust the vector length used on the innermost loop. I happen
to know that the compiler I'm using will restrict me to using multiples of the
*warp size* of this processor (***REFERENCE SOME NVIDIA DOCUMENT HERE?***),
which is 32. This detail will vary according to the accelerator of choice.
Below is the modified code using a vector length of 32.


~~~~ {.c .numberLines}
    #pragma acc parallel loop vector_length(32)
    for(int i=0;i<num_rows;i++) {
      double sum=0;
      int row_start=row_offsets[i];
      int row_end=row_offsets[i+1];
      #pragma acc loop vector reduction(+:sum)
      for(int j=row_start;j<row_end;j++) {
        unsigned int Acol=cols[j];
        double Acoef=Acoefs[j];
        double xcoef=xcoefs[Acol];
        sum+=Acoef*xcoef;
      }
      ycoefs[i]=sum;
    }
~~~~

---

~~~~ {.fortran .numberLines}
    !$acc parallel loop vector_length(32)
    do i=1,a%num_rows
      tmpsum = 0.0d0
      row_start = arow_offsets(i)
      row_end   = arow_offsets(i+1)-1
      !$acc loop vector reduction(+:tmpsum)
      do j=row_start,row_end
        acol = acols(j)
        acoef = acoefs(j)
        xcoef = x(acol)
        tmpsum = tmpsum + acoef*xcoef
      enddo
      y(i) = tmpsum
    enddo
~~~~

Notice that I have now explicitly informed the compiler that the innermost loop
should be a vector loop, to ensure that the compiler will map the parallelism
exactly how I wish. I can try different vector lengths to find the optimal
value for my accelerator by modifying the `num_gangs` clause. Below is a graph
showing the relative speed-up of varying the vector length
compared to the compiler-selected value.

***INSERT GRAPH***

Notice that the best performance comes from the smallest vector length. Again,
this is because the number of non-zeros per row is very small, so a small
vector length results in fewer wasted compute resources. On the particular chip
I'm using, the smallest possible vector length, 32, achieves the best possible
performance. On this particular accelerator, I also know that the hardware will
not perform efficiently at this vector length unless we can identify further
parallelism another way. In this case, we can use the *worker* level of
parallelism to fill each *gang* with more of these short vectors. Below is the
modified code.

~~~~ {.c .numberLines}
    #pragma acc parallel loop gang worker num_workers(32) vector_length(32)
    for(int i=0;i<num_rows;i++) {
      double sum=0;
      int row_start=row_offsets[i];
      int row_end=row_offsets[i+1];
      #pragma acc loop vector
      for(int j=row_start;j<row_end;j++) {
        unsigned int Acol=cols[j];
        double Acoef=Acoefs[j];
        double xcoef=xcoefs[Acol];
        sum+=Acoef*xcoef;
      }
      ycoefs[i]=sum;
    }
~~~~

---

~~~~ {.fortran .numberLines}
    !$acc parallel loop gang worker num_workers(32) vector_length(32)
    do i=1,a%num_rows
      tmpsum = 0.0d0
      row_start = arow_offsets(i)
      row_end   = arow_offsets(i+1)-1
      !$acc loop vector reduction(+:tmpsum)
      do j=row_start,row_end
        acol = acols(j)
        acoef = acoefs(j)
        xcoef = x(acol)
        tmpsum = tmpsum + acoef*xcoef
      enddo
      y(i) = tmpsum
    enddo
~~~~

In this version of the code, I've explicitly mapped the outermost look to both
gang and worker parallelism and will vary the number of workers using the
`num_workers` clause. The results follow.

*** INSERT GRAPH ***

On this particular hardware, the best performance comes from a vector length of
32 and 32 workers. This turns out to be the maximum amount of parallelism that
the particular accelerator being use supports within a gang.

***Best Pratice:*** Although not shown in order to save space, it's generally
best to use the `device_type` clause whenever specifying the sorts of
optimizations demonstrated in this section, because these clauses will likely
differ from accelerator to accelerator. By using the `device_type` clause it's
possible to provide this information only on accelerators where the
optimizations apply and allow the compiler to make its own decisions on other
architectures.

