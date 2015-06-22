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
