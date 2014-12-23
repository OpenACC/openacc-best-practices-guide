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
applications will observe the benefit of OpenACC acceleration. This step will
be primarily beneficial on machine where the host and device have seperate
memories.

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
  without any address translation. This clause is generally used when OpenACC
  is mixed with another programming model, as will be discussed in the
  interoperability chapter.

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
C++ class data is one of the primary reasons that unstructured data lifetimes
were added to OpenACC. As described above, the encapsulation provided by
classes makes it impossible to use a structured `data` region to control the
locality of the class data. Programmers may choose to use the unstructured data
lifetime directives or the OpenACC API to control data locality within a C++
class. Use of the directives is preferable, since they will be safely ignored
by non-OpenACC compilers, but the API is also available for times when the
directives are not expressive enough to meet the needs of the programmer. The
API will not be discussed in this guide, but is well-documented on the OpenACC
website.

The example below shows a simple C++ class that has a constructor, a
destructor, and a copy constructor. The data management of these routines has
been handled using OpenACC directives.

    template <class ctype> class Data
    {
      private:
        /// Length of the data array
        int len;
        /// Data array
        ctype *arr;
    
      public:
        /// Class constructor
        Data(int length)
        {
          len = length;
          arr = new ctype[len];
    #pragma acc enter data copyin(this)
    #pragma acc enter data create(arr[0:len])
        }

        /// Copy constructor
        Data(const Data<ctype> &d)
        {
          len = d.len;
          arr = new ctype[len];
    #pragma acc enter data copyin(this)
    #pragma acc enter data create(arr[0:len])
    #pragma acc parallel loop present(arr[0:len],d)
          for(int i = 0; i < len; i++)
            arr[i] = d.arr[i];
        }

        /// Class destructor
        ~Data()
        {
    #pragma acc exit data delete(arr)
    #pragma acc exit data delete(this)
          delete arr;
          len = 0;
        }
    };


Notice that an `enter data` directive is added to the class constructor to
handle creating space for the class data on the device. In addition to the data
array itself the `this` pointer is copied to the device. Copying the `this`
pointer ensures that the scalar member `len`, which denotes the length of the
data array `arr`, and the pointer `arr` are available on the accelerator as
well as the host. It is important to place the `enter data` directive after the
class data has been initialized. Similarly `exit data` directives are added to
the destructor to handle cleaning up the device memory. It is important to
place this directive before array members are freed, because one the host
copies are free the underlying pointer may become invalid, making it impossible
to then free the device memory as well. For the same reason the `this` pointer
should not be removed from the device until after all other memory has been
released.

The copy constructor is a special case that is worth looking at on its own. The
copy constructor will be responsible for allocating space on the device for the
class that it is creating, but it will also rely on data that is managed by the
class being copied. In this example it is assumed that class being copied is
also resident on the device. Since OpenACC does not currently provide a
portable way to copy from one array to another, like a `memcpy` on the host, a
loop is used to copy each individual element to from one array to the other. An
important thing to note is that because the data is being copied in a `parallel
loop` it will only be copied on the device. If the data is also needed on the
host then an `update` direct, which will be discussed in the next section, will
be needed.

Update Directive
----------------
Keeping data resident on the accelerator is often key to obtaining high
performance, but sometimes it's necessary to copy data between host and device
memories. The OpenACC `update` directive provides a way to explicitly
update the values of host or device memory with the values of the other. This
can be thought of as syncrhonizing the contents of the two memories. The
`update` directive accepts a `device` clause for copying data from the host to
the device and a `self` directive for updating from the device to local memory,
which is the host memory, except in the case of nested OpenACC regions. OpenACC
1.0 had a `host` clause, which is deprecated in OpenACC 2.0 and behaves the
same as `self`. The `update` directive has other clauses and the more commonly
used ones will be discussed in a later chapter.

As an example of the `update` directive, below are two routines that may be
added to the above `Data` class to force a copy from host to device and device
to host.

    void update_host()
    {
    #pragma acc update self(arr[0:len])
      ;
    }
    void update_device()
    {
    #pragma acc update device(arr[0:len])
      ;
    }

The update clauses accept an array shape, as already discussed in the data
clauses section. Although the above example copies the entire `arr` array to or
from the device, a partial array may also be provided to reduce the data
transfer cost when only part of an array needs to be updated, such as when
exchanging boundary conditions.

Cache Directive
---------------
***Delaying slightly because the cache directive is still being actively
improved in the PGI compiler.***

Case Study - Optimize Data Locality
-----------------------------------
***Update example from the end of the last chapter with a data region***

