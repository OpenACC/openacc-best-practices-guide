OpenACC Interoperability
========================
The authors of OpenACC recognized that it may sometimes be beneficial to mix
OpenACC code with code accelerated using other parallel programming languages,
such as CUDA or OpenCL, or accelerated math libraries. This interoperability
means that a developer can choose the programming paradigm that makes the most
sense in the particular situation and leverage code and libraries that may
already be available. Developers don't need to decide at the begining of a
project between OpenACC *or* something else, they can choose to use OpenACC *and*
other technologies.

***NOTE:*** The examples used in this chapter can be found online at
https://github.com/jefflarkin/openacc-interoperability

The Host Data Region
--------------------
The first method for interoperating between OpenACC and some other code is by
managing all data using OpenACC, but calling into a function that requires
device data. For the purpose of example the `cublasSaxpy` routine will be used
in place of writing a *saxpy* routine, as was shown in an earlier chapter. This
routine is freely provided by NVIDIA for their hardware in the CUBLAS library.
Most other vendors provide their own, tuned library.

The `host_data` region gives the programmer a way to expose the device address
of a given array to the host for passing into a function. This data must have
already been moved to the device previously. The name of this construct often 
confuses new users, but it can be thought of as a reverse `data` region, since 
it takes data on the `device` and exposes it to the `host`. The `host_data`
region accepts only the `use_device` clause, which specifies which device
variables should be exposed to the host. In the example below, the arrays `x`
and `y` are placed on the device via a `data` region and then initialized in
an OpenACC loop. These arrays are then passed to the `cublasSaxpy` function
as device pointers using the `host_data` region.

~~~~ {.c .numberLines}
    #pragma acc data create(x[0:n]) copyout(y[0:n])
    {
      #pragma acc kernels
      {
        for( i = 0; i < n; i++)
        {
          x[i] = 1.0f;
          y[i] = 0.0f;
        }
      }
  
      #pragma acc host_data use_device(x,y)
      {
        cublasSaxpy(n, 2.0, x, 1, y, 1);
      }
    }
~~~~

---

~~~~ {.fortran .numberLines}
    !$acc data create(x,y)
    !$acc kernels
    X(:) = 1.0
    Y(:) = 0.0
    !$acc end kernels

    !$acc host_data use_device(x,y)
    call cublassaxpy(N, 2.0, x, 1, y, 1)
    !$acc end host_data
    !$acc update self(y)
    !$acc end data
~~~~

The call to `cublasSaxpy` can be changed to any function that expects device
memory as parameter.

Using Device Pointers
---------------------
Because there is already a large ecosystem of accelerated applications using
languages such as CUDA or OpenCL, it may also be necessary to add an OpenACC
region to an existing accelerated application. In this case the arrays may be
managed outside of OpenACC and already exist on the device. For this case
OpenACC provides the `deviceptr` data clause, which may be used where any data
clause may appear. This clause informs the compiler that the variables
specified are already device on the device and no other action needs to be
taken on them. The example below uses the `acc_malloc` function, which
allocates device memory and returns a pointer, to allocate an array only on the
device and then uses that array within an OpenACC region.

~~~~ {.c .numberLines}
    void saxpy(int n, float a, float * restrict x, float * restrict y)
    {
      #pragma acc kernels deviceptr(x,y)
      {
        for(int i=0; i<n; i++)
        {
          y[i] += a*x[i];
        }
      }
    }
    void set(int n, float val, float * restrict arr)
    {
    #pragma acc kernels deviceptr(arr)
      {
        for(int i=0; i<n; i++)
        {
          arr[i] = val;
        }
      }
    }
    int main(int argc, char **argv)
    {
      float *x, *y, tmp;
      int n = 1<<20;
    
      x = acc_malloc((size_t)n*sizeof(float));
      y = acc_malloc((size_t)n*sizeof(float));
    
      set(n,1.0f,x);
      set(n,0.0f,y);
    
      saxpy(n, 2.0, x, y);
      acc_memcpy_from_device(&tmp,y,(size_t)sizeof(float));
      printf("%f\n",tmp);
      acc_free(x);
      acc_free(y);
      return 0;
    }
~~~~

---

~~~~ {.fortran .numberLines}
    module saxpy_mod
      contains
      subroutine saxpy(n, a, x, y)
        integer :: n
        real    :: a, x(:), y(:)
        !$acc parallel deviceptr(x,y)
        y(:) = y(:) + a * x(:)
        !$acc end parallel
      end subroutine
    end module
~~~~

Notice that in the `set` and `saxpy` routines, where the OpenACC compute
regions are found, each compute region is informed that the pointers being
passed in are already device pointers by using the `deviceptr` keyword. This
example also uses the `acc_malloc`, `acc_free`, and `acc_memcpy_from_device`
routines for memory management. Although the above example uses `acc_malloc`
and `acc_memcpy_from_device`, which are provided by the OpenACC specification
for portable memory management, a device-specific API may have also been used,
such as `cudaMalloc` and `cudaMemcpy`.

Obtaining Device and Host Pointer Addresses
-------------------------------------------
OpenACC provides the `acc_deviceptr` and `acc_hostptr` function calls for
obtaining the device and host addresses of pointers based on the host and
device addresses, respectively. These routines require that the addresses
actually have corresponding addresses, otherwise they will return NULL.

<!---
Mapping Arrays
--------------
***This is a pretty complicated thing to explain. Would anyone object to it
being left out?***
--->

Additional Vendor-Specific Interoperability Features
----------------------------------------------------
The OpenACC specification suggests several features that are specific to
individual vendors. While implementations are not required to provide the
functionality, it's useful to know that these features exist in some
implementations. The purpose of these features are to provide interoperability
with the native runtime of each platform. Developers should refer to the
OpenACC specification and their compiler's documentation for a full list of
supported features.

### Asynchronous Queues and CUDA Streams (NVIDIA)
As demonstrated in the next chapter, asynchronous work queues are frequently an
important way to deal with the cost of PCIe data transfers on devices with
distinct host and device memory. In the NVIDIA CUDA programming model
asynchronous operations are programmed using CUDA streams. Since developers may
need to interoperate between CUDA streams and OpenACC queues, the specification
suggests two routines for mapping CUDA streams and OpenACC asynchronous queues.

The `acc_get_cuda_stream` function accepts an integer async id and returns a
CUDA stream object (as a void\*) for use as a CUDA stream.

The `acc_set_cuda_stream` function accepts an integer async handle and a CUDA
stream object (as a void\*) and maps the CUDA stream used by the async handle
to the stream provided.

With these two functions it's possible to place both OpenACC operations and
CUDA operations into the same underlying CUDA stream so that they will execute
in the appropriate order.

### CUDA Managed Memory (NVIDIA)
NVIDIA added support for *CUDA Managed Memory*, which provides a single pointer
to memory regardless of whether it is accessed from the host or device, in CUDA
6.0. In many ways managed memory is similar to OpenACC memory management, in
that only a single reference to the memory is necessary and the runtime will
handle the complexities of data movement. The advantage that managed memory
sometimes has it that it is better able to handle complex data structures, such
as C++ classes or structures containing pointers, since pointer references are
valid on both the host and the device. More information about CUDA Managed
Memory can be obtained from NVIDIA. To use managed memory within an OpenACC
program the developer can simply declare pointers to managed memory as device
pointers using the `deviceptr` clause so that the OpenACC runtime will not
attempt to create a separate device allocation for the pointers. 

It is also worth noting that the NVIDIA HPC compiler (formerly PGI compiler)
has direct support for using CUDA Managed Memory by way of a compiler option.
See the compiler documentation for more details.

### Using CUDA Device Kernels (NVIDIA)
The `host_data` directive is useful for passing device memory to host-callable
CUDA kernels. In cases where it's necessary to call a device kernel (CUDA
`__device__` function) from within an OpenACC parallel region it's possible to
use the `acc routine` directive to inform the compiler that the function being
called is available on the device. The function declaration must be decorated
with the `acc routine` directive and the level of parallelism at which the
function may be called. In the example below the function `f1dev` is a sequential
function that will be called from each CUDA thread, so it is declared `acc
routine seq`. 

~~~~ {.cpp .numberLines}
    // Function implementation
    extern "C" __device__ void
    f1dev( float* a, float* b, int i ){
      a[i] = 2.0 * b[i];
    }
    
    // Function declaration
    #pragma acc routine seq
    extern "C" void f1dev( float*, float* int );
    
    // Function call-site
    #pragma acc parallel loop present( a[0:n], b[0:n] )
    for( int i = 0; i < n; ++i )
    {
      // f1dev is a __device__ function build with CUDA
      f1dev( a, b, i );
    }
~~~~
