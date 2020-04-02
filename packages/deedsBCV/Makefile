SOURCE1=src/deedsBCV0.cpp
SOURCE2=src/linearBCV.cpp
SOURCE3=src/applyBCV.cpp
SOURCE4=src/applyBCVfloat.cpp
SOURCE5=src/applyBCVinv.cpp
SOURCE6=src/deedsBCVwinv.cpp
SOURCE7=src/getJacobian_6dim.cpp

ifeq ($(SLOW),1)
	OPT =-O
else
	# OPT =-O3 -fopenmp -mavx2 -msse4.2
	# Platform specified optimization flag will fail on older machine.
	OPT =-O3 -fopenmp
endif

.PHONY: target

all: linear deedsBCVwinv apply applyFloat applyBCVinv getJacobian

deeds: $(SOURCE1) Makefile
	g++ $(SOURCE1) -I src -lz -o deedsBCV -std=c++11 $(OPT)

linear: $(SOURCE2) Makefile
	g++ $(SOURCE2) -I src -lz -o linearBCV -std=c++11 $(OPT)

apply: $(SOURCE3) Makefile
	g++ $(SOURCE3) -I src -lz -o applyBCV -std=c++11 $(OPT)

applyFloat: $(SOURCE4) Makefile
	g++ $(SOURCE4) -I src -lz -o applyBCVfloat -std=c++11 $(OPT)

applyBCVinv: ${SOURCE5} Makefile
	g++ $(SOURCE5) -I src -lz -o applyBCVinv -std=c++11 $(OPT)

deedsBCVwinv: ${SOURCE6} Makefile
	g++ ${SOURCE6} -I src -lz -o deedsBCVwinv -std=c++11 $(OPT)

getJacobian: ${SOURCE7} Makefile
	g++ ${SOURCE7} -I src -lz -o getJacobian -std=c++11 $(OPT)


clean:
	rm -f deedsBCV linearBCV applyBCV applyBCVfloat applyBCVinv deedsBCVwinv getJacobian

