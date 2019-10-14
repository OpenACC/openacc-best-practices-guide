/*
 *  Copyright 2019 NVIDIA Corporation
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
#include <stdio.h>
#define N 1024

int main(int argc, char **argv)
{
  float x[N], y[N];
  int i;

#pragma acc kernels
{
  for (i=0; i<N; i++)
  {
    y[i] = 0.0f;
    x[i] = (float)(i+1);
  }

  for (i=0; i<N; i++)
  {
    y[i] = 2.0f * x[i] + y[i];
  }
}

  printf("%f %f\n",y[0],y[N-1]);

  return 0;
}
