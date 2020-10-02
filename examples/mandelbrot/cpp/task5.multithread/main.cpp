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
#include <omp.h>
#include "mandelbrot.h"
#include "constants.h"

using namespace std;

int main() {
  
  size_t bytes=WIDTH*HEIGHT*sizeof(unsigned int);
  unsigned char *image=(unsigned char*)malloc(bytes);
  int num_blocks = 8, block_size = (HEIGHT/num_blocks)*WIDTH;
  FILE *fp=fopen("image.pgm","wb");
  fprintf(fp,"P5\n%s\n%d %d\n%d\n","#comment",WIDTH,HEIGHT,MAX_COLOR);
  double st = omp_get_wtime();

#pragma acc data create(image[WIDTH*HEIGHT])
  for(int block = 0; block < num_blocks; block++ ) {
    int start = block * (HEIGHT/num_blocks),
        end   = start + (HEIGHT/num_blocks);
#pragma acc update device(image[block*block_size:block_size]) async(block)
#pragma acc parallel loop async(block)
    for(int y=start;y<end;y++) {
      for(int x=0;x<WIDTH;x++) {
        image[y*WIDTH+x]=mandelbrot(x,y);
      }
    }
#pragma acc update self(image[block*block_size:block_size]) async(block)
  }
#pragma acc wait
  
  double et = omp_get_wtime();
  printf("Time: %lf seconds.\n", (et-st));
  fwrite(image,sizeof(unsigned char),WIDTH*HEIGHT,fp);
  fclose(fp);
  free(image);
  return 0;
}
