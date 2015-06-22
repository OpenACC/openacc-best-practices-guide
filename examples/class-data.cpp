#include <iostream>
using namespace std;

template <class ctype> class Data
{
  private:
    /// Length of the data array
    int len; 
    /// Data array
    ctype *arr;

  public:
    /// Class constructor
    Data(int length)
    {
      len = length;
      arr = new ctype[len];
#pragma acc enter data copyin(this)      
#pragma acc enter data create(arr[0:len])
    }
    /// Copy constructor
    Data(const Data<ctype> &d)
    {
      len = d.len;
      arr = new ctype[len];
#pragma acc enter data copyin(this)      
#pragma acc enter data create(arr[0:len])
#pragma acc parallel loop present(arr[0:len],d)
      for(int i = 0; i < len; i++)
        arr[i] = d.arr[i];
    }

    /// Class destructor
    ~Data()
    {
#pragma acc exit data delete(arr)
#pragma acc exit data delete(this)
      delete arr;
      len = 0;
    }
    int size()
    {
      return len;
    }
#pragma acc routine seq
    ctype &operator[](int i)
    {
      // Simple bounds protection
      if ( (i < 0) || (i >= len) ) return arr[0];
      return arr[i];
    }
    void populate()
    {
#pragma acc parallel loop present(arr[0:len])
      for(int i = 0; i < len; i++)
        arr[i] = 2*i;
    }
#ifdef _OPENACC
    void update_host()
    {
#pragma acc update self(arr[0:len])
      ;
    }
    void update_device()
    {
#pragma acc update device(arr[0:len])
      ;
    }
#endif    
};

int main(int argc, char **argv)
{
  Data <double> d_data = Data<double>(1024);

  d_data.populate();

  Data <double> d_data2 = Data<double>(d_data);

#ifdef _OPENACC
  d_data2.update_host();
#endif
  cout << d_data2.size() << endl;
  cout << d_data2[0] << endl;
  cout << d_data2[d_data2.size()-1] << endl;

  return 0;
}
