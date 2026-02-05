OpenACC 相互運用性
========================
OpenACCの作者は、OpenACCコードをCUDAやOpenCLなどの他の並列プログラミング言語や、アクセラレータ用数学ライブラリを使用して加速されたコードと混在させることが有益な場合があることを認識していました。この相互運用性により、開発者は特定の状況で最も意味のあるプログラミングパラダイムを選択し、既に利用可能なコードやライブラリを活用することができます。開発者はプロジェクトの開始時にOpenACC*か*他のものかを決める必要はなく、OpenACC*と*他の技術を使用することを選択できます。

***注:*** この章で使用される例は、オンラインで以下から入手できます:
https://github.com/jefflarkin/openacc-interoperability

ホストデータ領域
--------------------
OpenACCと他のコード間で相互運用する最初の方法は、すべてのデータをOpenACCを使用して管理し、デバイスデータを必要とする関数を呼び出すことです。例として、前の章で示したような*saxpy*ルーチンを書く代わりに、`cublasSaxpy`ルーチンを使用します。このルーチンは、NVIDIAのハードウェア用にCUBLASライブラリで無料で提供されています。他のほとんどのベンダーは、独自の調整されたライブラリを提供しています。

`host_data`ディレクティブは、プログラマーに、特定の配列のデバイスアドレスをホストに公開して関数に渡す方法を提供します。このデータは、事前にデバイスに移動されている必要があります。この構文の名前は新しいユーザーをしばしば混乱させますが、`device`上のデータを取得して`host`に公開するため、逆の`data`領域と考えることができます。`host_data`領域は`use_device`句のみを受け入れ、どのデバイス変数をホストに公開すべきかを指定します。以下の例では、配列`x`と`y`は`data`領域を介してデバイスに配置され、その後OpenACCループで初期化されます。これらの配列は、`host_data`領域を使用してデバイスポインタとして`cublasSaxpy`関数に渡されます。

~~~~ {.c .numberLines}
    #pragma acc data create(x[0:n]) copyout(y[0:n])
    {
      #pragma acc kernels
      {
        for( i = 0; i < n; i++)
        {
          x[i] = 1.0f;
          y[i] = 0.0f;
        }
      }
  
      #pragma acc host_data use_device(x,y)
      {
        cublasSaxpy(n, 2.0, x, 1, y, 1);
      }
    }
~~~~

---

~~~~ {.fortran .numberLines}
    !$acc data create(x) copyout(y)
    !$acc kernels
    X(:) = 1.0
    Y(:) = 0.0
    !$acc end kernels

    !$acc host_data use_device(x,y)
    call cublassaxpy(N, 2.0, x, 1, y, 1)
    !$acc end host_data
    !$acc end data
~~~~

`cublasSaxpy`の呼び出しは、パラメータとしてデバイスポインタを期待する任意の関数に変更できます。

### 非同期デバイスライブラリ
***注:*** `host_data`領域を使用して非同期ライブラリ呼び出しやカーネルにデータを渡す場合、デバイス上のデータの寿命に注意を払う必要があります。このパターンの一般的な例は、以下に示すように、デバイス対応MPIライブラリにデバイスデータを渡すことです。

`host_data`領域の一般的な使用法は、デバイス対応MPI実装にデバイスポインタを渡すことです。このようなMPIライブラリは、リモートダイレクトメモリアクセス(RDMA)やパイプライン処理など、デバイスデータを渡されたときに特定の最適化を持つ場合があります。同期MPIルーチンの場合、`host_data`ディレクティブは上記のように使用できますが、このディレクティブを非同期MPI関数(例: MPI_ISend、MPI_IRecvなど)と混在させる場合は注意が必要です。例えば、以下のコードを考えてみましょう:

~~~~ {.c .numberLines}
    #pragma acc data copyin(buf)
    { // Data in `buf` put on device
    #pragma acc host_data use_device(buf)
    { // Device pointer to `buf` passed to MPI
       MPI_Isend(buf, ...);
       // MPI_Isend immediately returns to main thread
    }
    // MPI_Isend may not have completed sending data
    } // Data in `buf` potentially removed from device
~~~~

~~~~ {.fortran .numberLines}
    !$acc data copyin(buf)
    ! Data in `buf` put on device
    !$acc host_data use_device(buf)
    ! Device pointer to `buf` passed to MPI
       call MPI_Isend(buf, ...);
       ! MPI_Isend immediately returns to main thread
    !$acc end host_data
    ! MPI_Isend may not have completed sending data
    !$acc end data
    ! Data in `buf` potentially removed from device
~~~~

上記の例では、`buf`内のデータへのデバイスポインタが`MPI_ISend`に提供されますが、これはデータがまだ送信されていなくても、すぐに実行スレッドに制御を返します。そのため、データ領域の終わりに達したときに、MPIライブラリがデータの送信を完了する前に`buf`のデバイスコピーが解放される可能性があります。これにより、アプリケーションがクラッシュするか、アプリケーションが続行されるがガベージ値を送信する可能性があります。この問題を修正するには、開発者は、`buf`を変更または解放しても安全であることを確認するために、データ領域の終わりの前に`MPI_Wait`を発行する必要があります。以下の例は、非同期MPI呼び出しで`host_data`を正しく使用する方法を示しています。

~~~~ {.c .numberLines}
    #pragma acc data copyin(buf)
    { // Data in `buf` put on device
    #pragma acc host_data use_device(buf)
    { // Device pointer to `buf` passed to MPI
       MPI_Isend(buf, ..., request);
       // MPI_Isend immediately returns to main thread
    }
    // Wait to ensure `buf` is safe to deallocate
    MPI_Wait(request, ...);
    } // Data in `buf` potentially removed from device
~~~~

~~~~ {.fortran .numberLines}
    !$acc data copyin(buf)
    ! Data in `buf` put on device
    !$acc host_data use_device(buf)
    ! Device pointer to `buf` passed to MPI
       call MPI_Isend(buf, ...)
       ! MPI_Isend immediately returns to main thread
    !$acc end host_data
    ! Wait to ensure `buf` is safe to deallocate
    call MPI_Wait(request, ...)
    !$acc end data
    ! Data in `buf` potentially removed from device
~~~~

デバイスポインタの使用
---------------------
CUDAやOpenCLなどの言語を使用した加速アプリケーションの大規模なエコシステムが既に存在するため、既存の加速アプリケーションにOpenACC領域を追加する必要がある場合もあります。この場合、配列はOpenACCの外部で管理され、既にデバイス上に存在する可能性があります。このケースのために、OpenACCは`deviceptr`データ句を提供しており、これは任意のデータ句が現れる場所で使用できます。この句は、指定された変数が既にデバイス上にあり、それらに対して他のアクションを実行する必要がないことをコンパイラに通知します。以下の例では、デバイスメモリを割り当ててポインタを返す`acc_malloc`関数を使用して、デバイス上のみに配列を割り当て、その配列をOpenACC領域内で使用しています。

~~~~ {.c .numberLines}
    void saxpy(int n, float a, float * restrict x, float * restrict y)
    {
      #pragma acc kernels deviceptr(x,y)
      {
        for(int i=0; i<n; i++)
        {
          y[i] += a*x[i];
        }
      }
    }
    void set(int n, float val, float * restrict arr)
    {
    #pragma acc kernels deviceptr(arr)
      {
        for(int i=0; i<n; i++)
        {
          arr[i] = val;
        }
      }
    }
    int main(int argc, char **argv)
    {
      float *x, *y, tmp;
      int n = 1<<20;
    
      x = acc_malloc((size_t)n*sizeof(float));
      y = acc_malloc((size_t)n*sizeof(float));
    
      set(n,1.0f,x);
      set(n,0.0f,y);
    
      saxpy(n, 2.0, x, y);
      acc_memcpy_from_device(&tmp,y,(size_t)sizeof(float));
      printf("%f\n",tmp);
      acc_free(x);
      acc_free(y);
      return 0;
    }
~~~~

---

~~~~ {.fortran .numberLines}
    module saxpy_mod
      contains
      subroutine saxpy(n, a, x, y)
        integer :: n
        real    :: a, x(:), y(:)
        !$acc parallel deviceptr(x,y)
        y(:) = y(:) + a * x(:)
        !$acc end parallel
      end subroutine
    end module
~~~~

OpenACC計算領域が見つかる`set`および`saxpy`ルーチンでは、各計算領域は、渡されるポインタが既にデバイスポインタであることを`deviceptr`句を使用して通知されていることに注意してください。この例では、メモリ管理のために`acc_malloc`、`acc_free`、および`acc_memcpy_from_device`ルーチンも使用しています。上記の例では、ポータブルなメモリ管理のためにOpenACC仕様で提供されている`acc_malloc`と`acc_memcpy_from_device`を使用していますが、`cudaMalloc`や`cudaMemcpy`などのデバイス固有のAPIも使用できます。

デバイスとホストのポインタアドレスの取得
-------------------------------------------
OpenACCは、ホストとデバイスのアドレスに基づいてポインタのデバイスとホストのアドレスを取得するための`acc_deviceptr`および`acc_hostptr`関数呼び出しを提供します。これらのルーチンは、アドレスが実際に対応するアドレスを持っていることを必要とし、そうでない場合はNULLを返します。

~~~~ {.c .numberLines}
    double * x = (double*) malloc(N*sizeof(double));
    #pragma acc data create(x[:N])
    {
        double * device_x = (double*) acc_deviceptr(x);
        foo(device_x);
    }
~~~~

<!---
Mapping Arrays
--------------
***This is a pretty complicated thing to explain. Would anyone object to it
being left out?***
--->

追加のベンダー固有の相互運用機能
----------------------------------------------------
OpenACC仕様は、個々のベンダーに固有のいくつかの機能を提案しています。実装がその機能を提供する必要はありませんが、これらの機能が一部の実装に存在することを知っておくと便利です。これらの機能の目的は、各プラットフォームのネイティブランタイムとの相互運用性を提供することです。開発者は、サポートされている機能の完全なリストについて、OpenACC仕様とコンパイラのドキュメントを参照する必要があります。

### 非同期キューとCUDAストリーム (NVIDIA)
次の章で示されるように、非同期ワークキューは、ホストとデバイスのメモリが異なるデバイスでのPCIeデータ転送のコストに対処するための重要な方法です。NVIDIA CUDAプログラミングモデルでは、非同期操作はCUDAストリームを使用してプログラミングされます。開発者がCUDAストリームとOpenACCキュー間で相互運用する必要がある場合があるため、仕様はCUDAストリームとOpenACC非同期キューをマッピングするための2つのルーチンを提案しています。

`acc_get_cuda_stream`関数は、整数の非同期IDを受け入れ、CUDAストリームとして使用するためのCUDAストリームオブジェクト(void\*として)を返します。

`acc_set_cuda_stream`関数は、整数の非同期ハンドルとCUDAストリームオブジェクト(void\*として)を受け入れ、非同期ハンドルで使用されるCUDAストリームを提供されたストリームにマッピングします。

これらの2つの関数により、OpenACC操作とCUDA操作の両方を同じ基礎となるCUDAストリームに配置して、適切な順序で実行されるようにすることができます。

### CUDA管理メモリ (NVIDIA)
NVIDIAは、CUDA 6.0で*CUDA管理メモリ*のサポートを追加しました。これは、ホストまたはデバイスからアクセスされるかどうかに関係なく、メモリへの単一のポインタを提供します。多くの点で、管理メモリはOpenACCメモリ管理に似ており、メモリへの単一の参照のみが必要で、ランタイムがデータ移動の複雑さを処理します。管理メモリが時々持つ利点は、C++クラスやポインタを含む構造体などの複雑なデータ構造をより適切に処理できることです。これは、ポインタ参照がホストとデバイスの両方で有効であるためです。CUDA管理メモリの詳細については、NVIDIAから入手できます。OpenACCプログラム内で管理メモリを使用するには、開発者は単に管理メモリへのポインタを`deviceptr`句を使用してデバイスポインタとして宣言するだけで、OpenACCランタイムがポインタ用に別のデバイス割り当てを作成しようとしないようにすることができます。

また、NVIDIA HPCコンパイラ(旧PGIコンパイラ)は、コンパイラオプションによってCUDA管理メモリを使用するための直接サポートを持っていることも注目に値します。詳細については、コンパイラのドキュメントを参照してください。

### CUDAデバイスカーネルの使用 (NVIDIA)
`host_data`ディレクティブは、ホスト呼び出し可能なCUDAカーネルにデバイスメモリを渡すのに役立ちます。OpenACC並列領域内からデバイスカーネル(CUDA `__device__`関数)を呼び出す必要がある場合、`acc routine`ディレクティブを使用して、呼び出される関数がデバイス上で利用可能であることをコンパイラに通知することができます。関数宣言は、`acc routine`ディレクティブと関数が呼び出される並列性のレベルで装飾される必要があります。以下の例では、関数`f1dev`は各CUDAスレッドから呼び出される逐次関数であるため、`acc routine seq`として宣言されています。

~~~~ {.cpp .numberLines}
    // Function implementation
    extern "C" __device__ void
    f1dev( float* a, float* b, int i ){
      a[i] = 2.0 * b[i];
    }
    
    // Function declaration
    #pragma acc routine seq
    extern "C" void f1dev( float*, float* int );
    
    // Function call-site
    #pragma acc parallel loop present( a[0:n], b[0:n] )
    for( int i = 0; i < n; ++i )
    {
      // f1dev is a __device__ function build with CUDA
      f1dev( a, b, i );
    }
~~~~
