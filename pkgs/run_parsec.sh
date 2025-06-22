#!/bin/bash
gc_kernel=none
specific_benchmark=""

# Input flags
while getopts k:b: flag
do
	case "${flag}" in
		k) gc_kernel=${OPTARG};;
		b) specific_benchmark=${OPTARG};;
	esac
done

input_type=simmedium
arch=amd64-linux # Revist: currently is the arch of the host machine


BENCHMARKS=(blackscholes bodytrack dedup ferret fluidanimate freqmine streamcluster swaptions x264)
base_dir=$PWD

# If specific benchmark is provided, validate it and use only that benchmark
if [ "$specific_benchmark" != "" ]; then
    if [[ " ${BENCHMARKS[@]} " =~ " ${specific_benchmark} " ]]; then
        BENCHMARKS=($specific_benchmark)
        echo "Running specific benchmark: $specific_benchmark"
    else
        echo "Error: Invalid benchmark '$specific_benchmark'. Available benchmarks: ${BENCHMARKS[@]}"
        echo "Usage: $0 [-k gc_kernel] [-b benchmark_name]"
        exit 1
    fi
else
    echo "Running all benchmarks: ${BENCHMARKS[@]}"
fi

if [ $gc_kernel != "none" ]; then 
    ./initialisation_${gc_kernel}.riscv
fi

for benchmark in ${BENCHMARKS[@]}; do
    sub_dir=apps
    if [ $benchmark == "dedup" ]; then 
        sub_dir=kernels
    fi

    if [ $benchmark == "streamcluster" ]; then 
        sub_dir=kernels
    fi

    bin_dir=${base_dir}/${sub_dir}/${benchmark}/inst/${arch}.gcc-serial/bin
    run_dir=${base_dir}/${sub_dir}/${benchmark}/run/
    command_dir=${base_dir}/commands/${input_type}


    IFS=$'\n' read -d '' -r -a commands < ${command_dir}/${benchmark}.cmd
    count=0
    for input in "${commands[@]}"; do
        echo "[======= Benchmark: ${benchmark} =======]"
        if [[ ${input:0:1} != '#' ]]; then # allow us to comment out lines in the cmd files
            cd ${run_dir}
            cp ${bin_dir}/${benchmark} $run_dir
            cmd="time ./${benchmark} ${input}"
            echo "workload=[${cmd}]"
            eval ${cmd}
            rm ./${benchmark}                                                                                                                                        r
            ((count++))
        fi
    done
    echo ""
done

echo ""
echo "All Done!"
