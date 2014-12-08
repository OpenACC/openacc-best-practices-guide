Optimize Data Locality
======================
***I don't like how this is starting at all, I'll need to revisit this and give it
another shot.***

Data locality means that data used in device or host memory should remain local
to that memory for as long as it's needed. This idea may also be thought of as
optimizing data reuse or optimizing away unnecessary data copies between the
host and device memories. After expressing the parallelism of a program's
important regions it's frequently necessary to provide the compiler with
additional information about the locality of the data used by the parallel
regions. As noted in the previous section, a compiler will take a cautious
approach to data movement, always copying data that may be required, so that
the program will still produce correct results. A programmer will have
knowledge of what data is really needed and when it will be needed. The
programmer will also have knowledge of how data may be shared between two
functions, something that is difficult for a compiler to determine. 

The next step in the acceleration process is to provide the compiler with
additional information about data locality to maximize reuse of data on the
device and minimize data transfers. It is after this step that most
applications will observe the benefit of OpenACC acceleration.

OpenACC Data Regions
--------------------
The OpenACC `data` construct facilitates the sharing of data between multiple
parallel regions. A data region may be added around one or more parallel
regions in the same function or may be placed at a higher level in the program
call tree to enable data to be shared between regions in multiple functions.
The `data` construct is a structured construct, meaning that it must begin and
end in the same scope (such as the same function or subroutine). A later
section will discuss how to handle cases where a structured construct is not
useful. A `data` region may be added to the earlier `parallel loop` example to
enable data to be shared between both loop nests as follows.

    #pragma acc data
    {
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
    }

----

    !$acc data
    !$acc parallel loop
    do i=1,N
      y(i) = 0
      x(i) = i
    enddo
  
    !$acc parallel loop
    do i=1,N
      y(i) = 2.0 * x(i) + y(i)
    enddo
    !$acc end data

The `data` region in the above examples enables the `x` and `y` arrays to be
reused between the two `parallel` regions. This will remove any data copies
that happen between the two regions, but it still does not guarantee optimial
data movement. In order to provide the information necessary to perform optimal
data movement, the programmer can add data clauses to the `data` region.

Data Clauses 
------------
Data clauses give the programmer additional control over how and when data is
created on and copied to or from the device. These clauses may be added to any
`data`, `parallel`, or `kernels` construct to inform the compiler of the data
needs of that region of code. The data directives, along with a brief
description of their meanings, follow.

* `copy` - Create space for the listed variables on the device, initialize the
  variable by copying data to the device at the beginning of the region, copy
  the results back to the host at the end of the region, and finally release
  the space on the device when done.
* `copyin` - Create space for the listed variables on the device, initialize the
  variable by copying data to the device at the beginning of the region, and release
  the space on the device when done without copying the data back the the host.
* `copyout` - Create space for the listed variables on the device but do not
  initialize them. At the end of the region, copy the results back to the host and release
  the space on the device.
* `create` - Create space for the listed variables and release it at the end of
  the region, but do not copy to or from the device.
* `present` - The listed variables are already present on the device, so no
  further action needs to be taken. This is most frequently used when a data
  region exists in a higher-level routine.
* `deviceptr` - The listed variables use device memory that has been managed
  outside of OpenACC, therefore the variables should be used on the device
  without any address translation.

In addition to these data clauses, OpenACC 1.0 and 2.0 provide `present_or_*`
clauses (`present_or_copy`, for instance) that inform the compiler to check
whether the variable is already present on the device; if it is present, use
that existing copy of the data, if it is not, perform the action listed. These
routines are frequently abbreviated, like `pcopyin` instead of
`present_or_copyin`. In an upcoming OpenACC specification the behavior of all
data directives will be *present or*, so programmers should begin writing their
applications using these directives to ensure correctness with future OpenACC
specifications. This change will simplify data reuse for the programmer.

----

With these data clauses it is possible to further improve the example shown
above by informing the compiler how and when it should perform data transfers.
In this simple example above, the programmer knows that both `x` and `y` will
be populated with data on the device, so neither will need to be copied to the
device, but the results of `y` are significant, so it will need to be copied
back to the host at the end of the calculation. The code below demonstrates
using the `pcreate` and `pcopyout` directives to describe exactly this data
locality to the compiler.

    #pragma acc data pcreate(x) pcopyout(y)
    {
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
    }

----

    !$acc data pcreate(x) pcopyout(y)
    !$acc parallel loop
    do i=1,N
      y(i) = 0
      x(i) = i
    enddo
  
    !$acc parallel loop
    do i=1,N
      y(i) = 2.0 * x(i) + y(i)
    enddo
    !$acc end data

### Shaping Arrays ###
Sometimes a compiler will need some extra help determining the size and shape
of arrays used in parallel or data regions. For the most part, Fortran
programmers can rely on the self-describing nature of Fortran arrays, but C/C++
programmers will frequently need to give additional information to the compiler
so that it will know how large an array to allocate on the device and how much
data needs to be copied. To give this information the programmer adds a *shape*
specification to the data clauses. 

In C/C++ the shape of an array is described
as `x[start:count]` where *start* is the first element to be copied and
*count* is the number of elements to copy. If the first element is 0, then it
may be left off. 

In Fortran the shape of an array is described as `x(start:end)` where *start*
is the first element to be copied and *end* is the last element to be copied.
If *start* is the beginning of the array or *end* is the end of the array, they
may be left off. 

Array shaping is frequently necessary in C/C++ codes when the OpenACC appears
inside of function calls or the arrays are dynamically allocated, since the
shape of the array will not be known at compile time. Shaping is also useful
when only a part of the array needs to be stored on the device. 

As an example of array shaping, the code below modifies the previous example by
adding shape information to each of the arrays.

    #pragma acc data pcreate(x[0:N]) pcopyout(y[0:N])
    {
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
    }

----

    !$acc data pcreate(x(1:N)) pcopyout(y(1:N))
    !$acc parallel loop
    do i=1,N
      y(i) = 0
      x(i) = i
    enddo
  
    !$acc parallel loop
    do i=1,N
      y(i) = 2.0 * x(i) + y(i)
    enddo
    !$acc end data

Unstructured Data Lifetimes
---------------------------
While structured data regions are generally sufficient for optimizing the data
locality in a program, they are not sufficient for some programs, particularly
those using Object Oriented coding practices. For example, in a C++ class data
is frequently allocated in a class constructor, deallocated in the destructor,
and cannot be accessed outside of the class. This makes using structured data
regions impossible because there is no single, structured scope where the
construct can be placed.  For these situations OpenACC 2.0 introduced
unstructured data lifetimes. The `enter data` and `exit data` directives can be
used to identify precisely when data should be allocated and deallocated on the
device. 

The `enter data` directive accepts the `create` and `copyin` data clauses and
may be used to specify when data should be created on the device.

The `exit data` directive accepts the `copyout` and a special `delete` data
clause to specify when data should be removed from the device. 

Please note that multiple `enter data` directives may place an array on the
device, but when any `exit data` directive removes it from the device it will
be immediately removed, regardless of how many `enter data` regions reference
it.

### C++ Class Data ###
C++ class data is the primary 

Update Directive
----------------

Cache Directive
---------------

Case Study - Optimize Data Locality
-----------------------------------
***Update example from the end of the last chapter with a data region***

----

***QUESTION: Should asynchronous overlapping go here or in a separate section?
It's related to data motion, but not directly***

