#!/bin/bash

input_type=simsmall
arch=amd64-linux # Revist: currently is the arch of the host machine


BENCHMARKS=(blackscholes bodytrack dedup facesim ferret fluidanimate freqmine streamcluster swaptions x264)
base_dir=$PWD

for benchmark in ${BENCHMARKS[@]}; do
    sub_dir=apps
    if [ $benchmark == "dedup" ]; then 
        sub_dir=kernels
    fi

    if [ $benchmark == "streamcluster" ]; then 
        sub_dir=kernels
    fi

    bin_dir=${base_dir}/${sub_dir}/${benchmark}/inst/${arch}.gcc/bin
    run_dir=${base_dir}/${sub_dir}/${benchmark}/run/
    command_dir=${base_dir}/commands/${input_type}


    IFS=$'\n' read -d '' -r -a commands < ${command_dir}/${benchmark}.cmd
    count=0
    for input in "${commands[@]}"; do
        echo "[======= Benchmark: ${benchmark} =======]"
        if [[ ${input:0:1} != '#' ]]; then # allow us to comment out lines in the cmd files
            cd ${run_dir}
            cp ${bin_dir}/${benchmark} $run_dir
            cmd="time taskset -c 0 ./${benchmark} ${input}"
            echo "workload=[${cmd}]"
            eval ${cmd}
            rm ./${benchmark}
            ((count++))
        fi
    done
    echo ""
done

echo ""
echo "All Done!"