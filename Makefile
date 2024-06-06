# Compiler Setup

# Check your compiler version to make sure it is compatible: https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#host-compiler-support-policy
# You can use something like lmod to load the correct versions
CC=gcc

# Paths to nvcc and nvdisasm, my paths are different because I use arch btw :)
#NVCC=/usr/local/cuda/bin/nvcc
#NVDISASM=/usr/local/cuda/bin/nvdisasm
NVCC=/opt/cuda/bin/nvcc
NVDISASM=/opt/cuda/bin/nvdisasm

# Python
PYTHON=python3

# Get the compute capabilities from here: https://developer.nvidia.com/cuda-gpus
# It doesn't seem to work for any compute capability below sm_50
#architectures=sm_20 sm_21 sm_30 sm_35 sm_37 sm_50 sm_52 sm_53 sm_60 sm_61 sm_62 sm_70 sm_72 sm_75 sm_80 sm_86 sm_87 sm_89 sm_90
architectures=sm_50 sm_52 sm_53 sm_60 sm_61 sm_62 sm_70 sm_72 sm_75 sm_80 sm_86 sm_87 sm_89 sm_90

targets = $(architectures:=_instructions.txt) $(architectures:=_latencies.txt)

all: $(targets)

clean:
	-rm -f $(targets)

# Generate the SASS versions.
%.cubin: example.cu
	$(NVCC) -o $@ -arch=$(basename $@) -cubin $<

%.so: %.c
	$(CC) -fPIC -shared -o $@ $< -ldl

# Not sure if the OMP things are needed, same with the flushing of stdout. We pipe it through strings to get only readable parts.
%_intercept.txt: %.cubin intercept.so
	OMP_NUM_THREADS=1 OMP_THREAD_LIMIT=1 LD_PRELOAD=./intercept.so $(NVDISASM) $< | strings -n 1 > $@

%_instructions.txt %_latencies.txt: %_intercept.txt
	$(PYTHON) funnel.py $<
