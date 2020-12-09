!  Copyright 2014 NVIDIA Corporation
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

module mandelbrot_mod
  implicit none
  integer, parameter :: HEIGHT=16384
  integer, parameter :: WIDTH=16384
  integer, parameter :: MAXCOLORS = 255

contains
  subroutine write_pgm(image, filename, iunit)
    integer(1) :: image(HEIGHT, WIDTH)
    character*(*) :: filename
    integer, optional :: iunit
    character*50 :: hdr
    integer nc, junit
    if (present(iunit)) then
      junit = iunit
    else
      junit = 10
    endif
    open(unit=junit,file=filename,access='stream',form='unformatted')
    write(hdr,fmt='(a,a,a,a,i0,1x,i0,a,i0,a)') 'P5', new_line('a'), '#comment', &
           new_line('a'),WIDTH, HEIGHT, new_line('a'), MAXCOLORS, new_line('a')
    nc = len_trim(hdr)
    write(junit) hdr(1:nc)
    write(junit) image
    close(junit)
  end subroutine
   
  real(8) function mandelbrot(px,py)
    !$acc routine seq
    integer, parameter :: MAX_ITERS=100
    real(8), parameter :: xmin=-1.7d0
    real(8), parameter :: xmax=.5d0
    real(8), parameter :: ymin=-1.2d0
    real(8), parameter :: ymax=1.2d0
    real(8), parameter :: dx=(xmax-xmin)/WIDTH
    real(8), parameter :: dy=(ymax-ymin)/HEIGHT
    integer, intent(in), value :: px, py
    real(8)             :: x0, y0, xtemp, x, y
    integer             :: i

    x0 = xmin+Px*dx
    y0 = ymin+Py*dy
    x = 0.0d0
    y = 0.0d0
    i = 0

    do while(((x*x+y*y).lt.4.0d0).and.(i.lt.MAX_ITERS))
      xtemp=x*x - y*y + x0
      y=2*x*y + y0
      x=xtemp
      i = i+1
    enddo
    mandelbrot =  dble(MAXCOLORS)*i/MAX_ITERS
  end function mandelbrot

end module mandelbrot_mod
