#!/bin/bash

gc_kernel=none
specific_benchmark=""

rm -f *.o
rm -f *.riscv

# Input flags
while getopts k:b: flag
do
	case "${flag}" in
		k) gc_kernel=${OPTARG};;
		b) specific_benchmark=${OPTARG};;
	esac
done

input_type=simmedium

export PATH_PKGS=$PWD
export PATH_GC_KERNELS="/home/zhejiang/FireGuard_V2/Software/linux/kernels/"


cd $PATH_GC_KERNELS
make clean

make malloc
make gc_main_${gc_kernel}
make initialisation_${gc_kernel}
cp initialisation_${gc_kernel}.riscv $PATH_PKGS

export GC_KERNEL="${PATH_GC_KERNELS}gc_main_${gc_kernel}.o ${PATH_GC_KERNELS}malloc.o"

cd $PATH_PKGS
BENCHMARKS=(blackscholes bodytrack dedup ferret fluidanimate freqmine streamcluster swaptions x264)

# If specific benchmark is provided, validate it and use only that benchmark
if [ "$specific_benchmark" != "" ]; then
    if [[ " ${BENCHMARKS[@]} " =~ " ${specific_benchmark} " ]]; then
        BENCHMARKS=($specific_benchmark)
        echo "Building and running specific benchmark: $specific_benchmark"
    else
        echo "Error: Invalid benchmark '$specific_benchmark'. Available benchmarks for building: ${BENCHMARKS[@]}"
        echo "Usage: $0 [-k gc_kernel] [-b benchmark_name]"
        exit 1
    fi
else
    echo "Building and running all benchmarks: ${BENCHMARKS[@]}"
fi

cmd="parsecmgmt -a clean -p all"
eval ${cmd}
cmd="parsecmgmt -a fulluninstall -p all"
eval ${cmd}


for benchmark in ${BENCHMARKS[@]}; do

    cmd="parsecmgmt -a build -p ${benchmark} -c gcc-serial"
    eval ${cmd}
    
    cmd="parsecmgmt -a run -p ${benchmark} -i ${input_type} -c gcc-serial"
    eval ${cmd}

done

echo ""
echo "All Done!"