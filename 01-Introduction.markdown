What is OpenACC?
================
With the emergence of GPU and many-core architectures in high performance
computing, programmers desire the ability to program using a familiar, high
level programming model that provides both high performance and portability to
a wide range of computing architectures. OpenACC emerged in 2011 as a
programming model that uses high-level compiler directives to expose
parallelism in the code and parallelizing compilers to build the code for a
variety of parallel accelerators. This document is intended as a best practices
guide for accelerating an application using OpenACC to give both good
performance and portability to other devices.

The OpenACC Accelerator Model
-----------------------------
In order to ensure that OpenACC would be portable to all computing
architectures available at the time of its inception and into the future,
OpenACC defines an abstract model for accelerated computing. This model exposes
multiple levels of parallelism that may appear on a processor as well as a
hierarchy of memories with varying degrees of speed and addressibility. The
goal of this model is to ensure that OpenACC will not be applicable to just a
particular architecture or even just the architectures in wide availability at
the time, but to ensure that OpenACC could be used on devices that were not yet
available. 

At its core OpenACC supports offloading of both computation and data from a
*host* device to and *accelerator* device. In fact, these devices may be the
same or may be completely different architectures, such as the case of a CPU
host and GPU accelerator. The two devices may also have separate memory spaces
or a single memory space. In the case that the two devices have different
memories the OpenACC compiler and runtime will analyze the code and handle any
accelerator memory management and the transfer of data between host and device
memory. Figure _ shows a high level diagram of the OpenACC abstract
accelerator, but remember that the devices and memories may be physically the
same on some architectures.

![OpenACC's Abstract Accelerator Model](images/execution_model2.png)

OpenACC defines three levels of parallelism: *gang*, *worker*, and *vector*.
Additionally exectution may be marked as being sequential (*seq*). Vector
parallelism has the finest granularity, with an individual instruction
operating on multiple pieces of data (much like *SIMD* parallelism on a modern
CPU or *SIMT* parallelism on a modern GPU). Vector operations are performed
with a particular *vector length*, indicating how many datums may being
operated on with the same instruction. Gang parallelism is coarse-grained
parallelism, where gangs work independently of each other and may not
synchronize. Worker parallelism sits between vector and gang levels. A gang
consists of 1 or more workers, each of which operates a vector of some length.
Within a gang the OpenACC model exposes a cache memory, which can be used by
all workers and vectors within the gang, and it is legal to synchronize within
a gang, although OpenACC does not expose synchronization to the user. Using
these three levels of parallelism, plus sequential, a programmer can map the
parallelism in the code to any device. OpenACC does not require the programmer
to do this mapping, however. If the programmer chooses not to explicitly map
loops to the device of interest the compiler will implicitly perform this
mapping using what it knows about the target device. This makes OpenACC highly
portable, since the same code may be mapped to any number of target devices.

![OpenACC's Three Levels of Parallelism](images/levels_of_parallelism.png)

Benefits and Limitations of Compiler Directives
-----------------------------------------------
