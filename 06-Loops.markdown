Optimize Loops
==============
***Does `async` go here? Where should I put that? Does it deserve its own
chapter?  Maybe an "Advanced OpenACC Techniques" chapter?***

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

Efficient Loop Ordering
-----------------------

Mapping Parallelism to the Hardware
-----------------------------------
* Gang clause
* Worder clause
* Vector clause
* Seq clause

Collapse Directive
------------------

Tile Directive
--------------
***NOTE: I'm tempted to leave this off because I've yet to find a case where it
was beneficial.***

