CXX=pgc++
CXXFLAGS=-fast -ta=tesla,lineinfo -Minfo=all,intensity,ccff
LDFLAGS=${CXXFLAGS}

cg.x: main.o 
	${CXX} $^ -o $@ ${LDFLAGS}

main.o: main.cpp matrix.h matrix_functions.h vector.h vector_functions.h

.SUFFIXES: .o .cpp .h

.PHONY: clean
clean:
	rm -Rf cg.x pgprof* *.o core
