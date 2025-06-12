#!/bin/bash

# Ensure we're on the RISC-V branch in both main repo and submodule
echo "Ensuring correct branch setup for benchmark execution..."

# Switch to main repository root
REPO_ROOT="/home/zhejiang/FireGuard_V2"
cd "$REPO_ROOT"

# Ensure main repository is on RISC-V branch
echo "Checking out RISC-V branch in main repository..."
git checkout RISC-V

# Ensure submodule is initialized and updated
echo "Updating submodule..."
git submodule update --init --recursive

# Switch to submodule and ensure it's on RISC-V branch
echo "Checking out RISC-V branch in parsec-benchmark submodule..."
cd Software/linux/parsecv3/parsec-benchmark
git checkout RISC-V 2>/dev/null || {
    echo "RISC-V branch not found in submodule, creating it..."
    git checkout -b RISC-V
}

# Return to the run script directory
cd pkgs
echo "Branch setup complete."

gc_kernel=none

# Input flags
while getopts k: flag
do
	case "${flag}" in
		k) gc_kernel=${OPTARG};;
	esac
done

input_type=simmedium
arch=amd64-linux # Revist: currently is the arch of the host machine


BENCHMARKS=(blackscholes bodytrack dedup facesim ferret fluidanimate freqmine streamcluster swaptions x264)
base_dir=$PWD

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
            rm ./${benchmark}
            ((count++))
        fi
    done
    echo ""
done

echo ""
echo "All Done!"
