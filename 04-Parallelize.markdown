Parallelize Using OpenACC
=========================
Now that the importation hotspots in the application have been identified,
the programmer should incrementally accelerate these hotspots by adding OpenACC
directives to the important loops within those routines. There is no reason to
think about the movement of data at this point in the process, the OpenACC
compiler will automatically move data to and from the accelerator for any
parallelism the programmer identifies in the code. By focusing solely on the
parallelism during this step, the programmer can move as much computation to
the device as possible and ensure that the program is still giving correct
results before optimizing away data motion in the next step. During this step
in the process it is common for the overall runtime of the application to
increase, even if the execution of the individual loops is faster using the
accelerator. This is because the compiler must take a cautious approach to data
movement, frequently copying more data to and from the accelerator than is
actually necessary. Even if overall execution time increases during this step,
the developer should focus on expressing a significant amount of parallelism in
the code before moving on to the next step and realizing a benefit from the
directives.

----

OpenACC provides two different approaches for exposing parallelism in the code:
`kernels` and `parallel` regions. Each of these directives will be detailed in
the sections that follow.

***NOTE: I used the jacobi iteration example in these sections because I had it
and it shows some of the differences in the two approaches, but I'm concerned
that there's too much here for a first look at the two directives. On the one
hand, there's multiple differences I can point to, on the other I'm having to
explain things like reductions. I'd be interested in feedback about this. Am I
jumping in too fast or is this the right place to discuss these things? Should
I just use something simple like SAXPY here and then do the longer example as a
standalone example at the end of this chapter?***

The Parallel Construct
----------------------
The `parallel` construct identifies a region of code that will be parallelized
across OpenACC gangs. By itself the a `parallel` region is of limited use, but
when paired with the `loop` directive (discussed in more detail later) the
compiler will generate a parallel version of the loop for the accelerator.
These two directives can, and frequently are, combined into a single `parallel
loop` directive. By placing this directive on a loop the programmer asserts
that affected loop is safe to parallelize however the compiler sees fit for the
target device. The code below demonstrates the use of the `parallel loop`
combined directive in both C/C++ and Fortran.

    #pragma acc parallel loop
    for( int j = 1; j < n-1; j++)
    {
      #pragma acc loop
      for( int i = 1; i < m-1; i++ )
      {
        Anew[j][i] = 0.25 * ( A[j][i+1] + A[j][i-1]
                            + A[j-1][i] + A[j+1][i]);
      }
    }
    
    #pragma acc parallel loop reduction(max:error) 
    for( int j = 1; j < n-1; j++)
    {
      #pragma acc loop
      for( int i = 1; i < m-1; i++ )
      {
        A[j][i] = 0.25 * ( Anew[j][i+1] + Anew[j][i-1]
                         + Anew[j-1][i] + Anew[j+1][i]);
        error = fmax( error, fabs(A[j][i] - Anew[j][i]));
      }
    }
           

***TODO: Style code examples better.***

    !$acc parallel loop 
    do j=1,m-2
      !$acc loop
      do i=1,n-2
        Anew(i,j) = 0.25_fp_kind * ( A(i+1,j  ) + A(i-1,j  ) + &
                                     A(i  ,j-1) + A(i  ,j+1) )
      end do
    end do
    
    !$acc parallel loop reduction(max:error)
    do j=1,m-2
      !$acc loop
      do i=1,n-2
        A(i,j) = 0.25_fp_kind * ( Anew(i+1,j  ) + Anew(i-1,j  ) + &
                                  Anew(i  ,j-1) + Anew(i  ,j+1) )
        error = max( error, abs(A(i,j) - Anew(i,j)) )
      end do
    end do

Notice that in addition to the `parallel loop` directive added to the outer
loop a `loop` directive was placed on the inner loop. This is because `parallel
loop` only applies to the next loop, so the innermost loop may not get
parallelized. Some OpenACC compilers are able to detect the parallelism in the
inner loop and also parallelize it, but in order to ensure that the OpenACC
compiler knows that the inner loop is also safe to parallelize the `loop`
directive is added to the inner loop. It is also necessary to inform the
compiler that the second loop nest contains a *reduction* on the variable
`error`. A reduction means that all loop iterations are calculating their own
value for `error`, but only one of those values is desired. In this case, the
value that is needed is the maximum of all errors that are calculated. Some
compilers are able to automatically detect this reduction and act
appropriately, but for maximum portability and correctness it's best for the
programmer to explicitly expose this reduction to the compiler as is shown
above.

Other clauses to the `loop` directive that may further benefit the performance
of the resulting code will be discussed in a later chapter.  (***TODO: Link to
later chapter when done.***)

The Kernels Construct
---------------------
The `kernels` construct identifies a region of code that may contain
parallelism, but relies on the automatic parallelization capabilities of the
compiler to analyze the region, identify which loops are safe to parallelize,
and then accelerate those loops. The code below demonstrates the use of
`kernels` in both C/C++ and Fortran.

    #pragma acc kernels 
    {
      for( int j = 1; j < n-1; j++)
      {
        for( int i = 1; i < m-1; i++ )
        {
          Anew[j][i] = 0.25 * ( A[j][i+1] + A[j][i-1]
                              + A[j-1][i] + A[j+1][i]);
        }
      }
    
      for( int j = 1; j < n-1; j++)
      {
        for( int i = 1; i < m-1; i++ )
        {
          A[j][i] = 0.25 * ( Anew[j][i+1] + Anew[j][i-1]
                           + Anew[j-1][i] + Anew[j+1][i]);
          error = fmax( error, fabs(A[j][i] - Anew[j][i]));
        }
      }
    }        

***TODO: Style code examples better.***

    !$acc kernels 
      do j=1,m-2
        do i=1,n-2
          Anew(i,j) = 0.25_fp_kind * ( A(i+1,j  ) + A(i-1,j  ) + &
                                       A(i  ,j-1) + A(i  ,j+1) )
        end do
      end do
    
      do j=1,m-2
        do i=1,n-2
          A(i,j) = 0.25_fp_kind * ( Anew(i+1,j  ) + Anew(i-1,j  ) + &
                                    Anew(i  ,j-1) + Anew(i  ,j+1) )
          error = max( error, abs(A(i,j) - Anew(i,j)) )
        end do
      end do
    !$acc end kernels

Notice that where the `parallel loop` directive required decorating each loop
with a directive, the `kernels` construct applies to all loops within the
region. Additionally the `kernels` construct applies to both the `i` and `j`
loops in the loop nests, whereas the `parallel loop` construct only directly
applies to the next loop after the directive, thus requiring a directive on
each loop.  Additionally it is the compiler's responsibility, rather than the
programmer's, to discover the reduction on error that was discussed in the
previous example.

Because the `kernels` directive is more compiler-driven, it gives the compiler
additional freedom both in identifying where there is parallelism in the code
and how to map that parallelism to the the accelerator. This also means that
the acceleration of the code is limited by the compiler's ability to identify
parallelism in the code, which will be discussed further in the next section.

Differences Between Parallel and Kernels
----------------------------------------
One of the biggest points of confusion for new OpenACC programmers is why the
specification has both the `kernels` and `parallel` directives, which appear to
do the same thing. While they are very closely related there are subtle
differences between them. The `kernels` construct gives the compiler maximum
leeway to parallelize and optimize the code how it sees fit for the target
accelerator, but also relies most heavily on the compiler's ability to
automatically parallelize the code. As a result, the programmer may see
differences in what different compilers are able to parallelize and how they do
so. The `parallel loop` directive is more of an assertion by the programmer
that it is both safe and desirable to parallelize the affected loop. This
relies on the programmer to have correctly identified parallelism in the code
and remove anything in the code that may be unsafe to parallelize. If the
programmer asserts incorrectly that the loop may be parallelized then the
resulting application may produce incorrect results.

An important thing to note about the `kernels` construct is that the compiler
will analyze the code and only parallelize when it is certain that it is safe
to do so.  In some cases the compiler may not have enough information at
compile time to determine whether a loop is safe the parallelize, in which case
it will not parallelize the loop, even if the programmer can clearly see that
the loop is safely parallel. For example, in the case of C/C++ code, where
arrays are passed into functions as pointers, the compiler may not always be
able to determine that two arrays do not share the same memory, otherwise known
as *pointer aliasing*. If the compiler cannot know that two pointers are not
aliased it will not be able to parallelize a loop that accesses those arrays. C
programmers should use the `restrict` keyword (or the `__restrict` dectorator
in C++) whenever possible to inform the compiler that the pointers are not
aliased, which will frequently give the compiler enough information to then
parallelize loops that it would not have otherwise. 

Fortran programmers should also note that an OpenACC compiler will parallelize
Fortran array syntax that is contained in a `kernels` construct. When using
`parallel` instead it will be necessary to explicitly introduce loops over the
elements of the arrays.

One more notable benefit that the `kernels` construct provides is that if data
is moved to the device for use in loops contained in the region, that data will
remain on the device for the full extent of the region, or until it is needed
again on the host within that region. This means that if multiple loops access
the same data it will only be copied to the accelerator once. When `parallel
loop` is used on two subsequent loops that access the same data a compiler may
or may not copy the data back and forth betwen the host and the device between
the two loops. 

For more information on the differences between the `kernels` and `parallel`
directives, please see [@parallelkernels].

At this point many programmers will be left wondering which directive they
should use in their code. More experienced parallel programmers, who may have
already identified parallel loops within their code, will likely find the
`parallel loop` approach more desirable. Programmers with less parallel
programming experience or whose code contains a large number of loops that need
to be analyzed may find the `kernels` approach much simpler, as it puts more of
the burden on the compiler. Both approaches have advantages, so new OpenACC
programmers should determine for themselves which approach is a better fit for
them.

Note: For the remainder of the document the phrase *parallel region* will be
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
the listed variables. For example, if each loop contains a scalar variable
named `tmp` that it uses as a temporary value during its calculation then this
variable must be made private to each loop iteration in order to ensure correct
results. If `tmp` is not declared private, then threads executing different
loop iterations may access this shared `tmp` variable in unpredictable ways,
resulting in a race condition and potentially incorrect results. This is not
limited to scalar variable, but scalars temporaries are a common programming
pattern.

There are a few things special cases that must be understood about scalar
variables within loops. First, loop iterators will be privatized by default, so
they do not need to be listed as private. Second, unless otherwise specified,
any scalar accessed within a parallel loop will be made *first private* by
default, meaning a private copy will be made of the variable for each loop
iteration and it will be initialized with the value of that scalar upon
entering the region. Finally, any variables (scalar or not) that are declared
within a loop in C or C++ will be made private to the iterations of that loop
by default.

Note: The `parallel` construct also has a parallel clause which will privatize
the listed variables for each gang in the parallel region. 

### reduction ###
The `reduction` clause works similarly to the `private` clause in that a
private copy of the affected variable is generated for each loop iteration, but
`reduction` goes a step further to reduce all of those private copies into one
final result, which is returned from the region. A maximum reduction was shown
in the examples above, but other operations may also be performed as part of
the reduction, such as a sum, minimum, or bitwise operations. A reduction may
only be specified on a scalar variable and only the following operations may be
performed (***TODO: grab list of operations***). The format of the reduction
clause is as follows, where *operator* should be replaced with the operation of
interest and *variable* should be replaced with the variable being reduced:

    reduction(operator:variable)


Case Study - Parallelize
------------------------
***Move the jacobi examples from above here and replace the above with simpler
example.***

### Parallel Loop ###

### Kernels ###
