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
    }


    !$acc data
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
    !$acc end data

The `data` region in the above examples enables the `A` and `Anew` arrays to be
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

* Copy - Create space for the listed variables on the device, initialize the
  variable by copying data to the device at the beginning of the region, copy
  the results back to the host at the end of the region, and finally release
  the space on the device when done.
* Copyin - Create space for the listed variables on the device, initialize the
  variable by copying data to the device at the beginning of the region, and release
  the space on the device when done without copying the data back the the host.
* Copyout - Create space for the listed variables on the device but do not
  initialize them. At the end of the region, copy the results back to the host and release
  the space on the device.
* Create - Create space for the listed variables and release it at the end of
  the region, but do not copy to or from the device.
* Present - The listed variables are already present on the device, so no
  further action needs to be taken. This is most frequently used when a data
  region exists in a higher-level routine.
* Deviceptr - The listed variables use device memory that has been managed
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
The figure below is a screenshot from the Nvidia CUDA Visual Profiler before
and after adding the data region ***(TODO: Generate figure)***. Notice that
data movement has been reduced by eliminating the data copies between the two
regions, but there's still two arrays being copied at the beginning of the data
region. The output below is compiler feedback from building
this code using the PGI OpenACC compiler. 

         58, Accelerator kernel generated
             59, #pragma acc loop gang /* blockIdx.x */
             62, #pragma acc loop vector(256) /* threadIdx.x */
             66, Max reduction generated for error
         58, Generating present_or_copyout(Anew[1:4094][1:4094])
             Generating present_or_copyin(A[:][:])
             Generating Tesla code
         62, Loop is parallelizable
         71, Accelerator kernel generated
             72, #pragma acc loop gang /* blockIdx.x */
             75, #pragma acc loop vector(256) /* threadIdx.x */
         71, Generating present_or_copyin(Anew[1:4094][1:4094])
             Generating present_or_copyout(A[1:4094][1:4094])
             Generating Tesla code
         75, Loop is parallelizable

Notice that at lines 58 and 71, which correspond with the two `parallel` regions, the compiler
is generating implicit data movement clauses causing the initial value of `A` to
be copied to the device and the final values of both `A` and `Anew` to be copied
back from the device. This is because it knows that the initial value of `A` is
needed for the calculation and that the values of `A` and `Anew` are both
modified, so it assumes those values are needed back on the CPU. As the
programmer I know that this is more data motion than is actually necessary, so
I will add data clauses to the `data` region with my knowledge of how the data
is actually used.

    #pragma acc data pcreate(Anew) pcopy(A)
    {
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
    }


    !$acc data pcreate(Anew) pcopy(A)
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
    !$acc end data

I've now informed the compiler that the `Anew` array is a temporary array, so
it should only be created on the device, if it is not already present, and
never copied between the host and device. For the `A` array I've informed the
compiler that both the initial data and the final results need to be copied
between host and device memory. Looking once more at the NVIDIA CUDA Visual
Profiler, we now see that data movement has been further reduced to only the
minimal amount needed.

Unstructured Data Lifetimes
---------------------------

### C++ Class Data ###

Update Directive
----------------

Cache Directive
---------------

Case Study - Optimize Data Locality
-----------------------------------

----
***QUESTION: Should asynchronous overlapping go here or in a separate section?
It's related to data motion, but not directly***
