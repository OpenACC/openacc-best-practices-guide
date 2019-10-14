!
!  Copyright 2019 NVIDIA Corporation
!
!  Licensed under the Apache License, Version 2.0 (the "License");
!  you may not use this file except in compliance with the License.
!  You may obtain a copy of the License at
!
!      http://www.apache.org/licenses/LICENSE-2.0
!
!  Unless required by applicable law or agreed to in writing, software
!  distributed under the License is distributed on an "AS IS" BASIS,
!  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
!  See the License for the specific language governing permissions and
!  limitations under the License.
!
program saxpy
  integer, parameter :: N=1024
  real, dimension(N) :: x, y
  integer            :: i

  !$acc kernels
  do i=1,N
    y(i) = 0
    x(i) = i
  enddo

  do i=1,N
    y(i) = 2.0 * x(i) + y(i)
  enddo
  !$acc end kernels

  print *, y(1), y(N)

end program saxpy
