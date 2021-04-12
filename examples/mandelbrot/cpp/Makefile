CXX=nvc++
CXXFLAGS=-fast -acc=gpu -Minfo=all

mandelbrot.x: mandelbrot.o main.o
	$(CXX) $(CXXFLAGS) -o $@ $^
mandelbrot_solution.x: mandelbrot_solution.o main_solution.o
	$(CXX) $(CXXFLAGS) -o $@ $^

.PHONY: clean
clean:
	rm -f *.o core *.lst *.ptx *.pgprof *.cubin *.s *.x *.mod *.nvprof
