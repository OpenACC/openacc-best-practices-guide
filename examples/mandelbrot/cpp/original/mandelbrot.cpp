/*
 *  Copyright 2014 NVIDIA Corporation
 *  
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  
 *      http://www.apache.org/licenses/LICENSE-2.0
 *  
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include <cstdio>
#include <cstdlib>
#include <fstream>
#include "mandelbrot.h"
#include "constants.h"

using namespace std;

unsigned char mandelbrot(int Px, int Py) {
  double x0=xmin+Px*dx;
  double y0=ymin+Py*dy;
  double x=0.0;
  double y=0.0;
  int i;
  for(i=0;x*x+y*y<4.0 && i<MAX_ITERS;i++) {
    double xtemp=x*x-y*y+x0;
    y=2*x*y+y0;
    x=xtemp;
  }
  return (double)MAX_COLOR*i/MAX_ITERS;
}
