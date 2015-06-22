#include <stdio.h>
#define N 1024

int main(int argc, char **argv)
{
  float x[N], y[N];
  int i;

#pragma acc parallel loop
  for (i=0; i<N; i++)
  {
    y[i] = 0.0f;
    x[i] = (float)(i+1);
  }

#pragma acc parallel loop
  for (i=0; i<N; i++)
  {
    y[i] = 2.0f * x[i] + y[i];
  }

  printf("%f %f\n",y[0],y[N-1]);

  return 0;
}
