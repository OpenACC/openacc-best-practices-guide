OpenACC Interoperability
========================
The authors of OpenACC recognized that it may sometimes be beneficial to mix
OpenACC code with code acceleratd using other parallel programming languages,
such as CUDA or OpenCL, or accelerated math libraries. This interoperability
means that a developer can choose the programming paradigm that makes the most
sense in the particular situation and leverage code and libraries that may
already be available. Developers don't need to decide at the begining of a
project between OpenACC *or* something else, they can choose to use OpenACC *and*
other technologies.

The Host Data Region
--------------------
The first method for interoperating between OpenACC and some other code is by
managing all data using OpenACC, but calling into a function that requires
device data. For the purpose of example the `cublasSaxpy` routine will be used
in place of writing a *saxpy* routine, as was shown in an earlier chapter. This
routine is freely provided by Nvidia for their hardware in the CUBLAS library.
Most other vendors provide their own, tuned library.

The `host_data` region gives the programmer a way to expose the device address
of a given array to the host for passing into a function. This data must have
already been moved to the device previously. The `host_data` region accepts
only the `use_device` clause, which specifies which device variables should be
exposed to the host. In the example below, the arrays `x` and `y` are placed on
the device via a `data` region and then initialized in an OpenACC
loop. These arrays are then passed to the `cublasSaxpy` function as device
pointers using the `host_data` region. 

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

The call to `cublasSaxpy` can be changed to any function that expects device
memory as parameter.

Using Device Pointers
---------------------
Because there is already a large ecosystem of accelerated applications using
languages such as CUDA or OpenCL it may also be necessary to add an OpenACC
region to an existing accelerated application. In this case the arrays may be
managed outside of OpenACC and already exist on the device. In this case
OpenACC provides the `deviceptr` data clause, which may be used where any data
clause may appear. This clause informs the compiler that the variables
specified are already device on the device and no other action needs to be
taken on them. The example below uses the `acc_malloc` function, which
allocates device memory and returns a pointer, to allocate an array only on the
device and then uses that array within an OpenACC region.

    Simplify existing example to use acc_malloc instead of cudaMalloc

Although the above example uses `acc_malloc`, which is provided by the OpenACC
specification for portable memory management, a device-specific API may have
also been used, such as `cudaMalloc`.

Mapping Arrays
--------------
***This is turning out to be very complicated to explain. I'm going to take
another stab at it once my eyes are fresh.***

Using CUDA Device Kernels
-------------------------
***NOTE: This is the first NVIDIA-specific thing in this document. Is it out of
place to discuss CUDA specifically here?***
