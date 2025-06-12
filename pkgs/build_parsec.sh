#!/bin/bash

# Ensure we're on the RISC-V branch in both main repo and submodule
echo "Ensuring correct branch setup..."

# Switch to main repository root
cd /home/zhejiang/FireGuard_V2

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

# Return to the build script directory
cd pkgs
echo "Branch setup complete."

gc_kernel=none

rm -f *.o
rm -f *.riscv

# Input flags
while getopts k: flag
do
	case "${flag}" in
		k) gc_kernel=${OPTARG};;
	esac
done

input_type=simmedium

export PATH_GC_KERNELS="/home/centos/gc_kernel/"
export PATH_MS_KERNELS="/home/centos/asplos22-minesweeper-reproduce/lib"

export PATH_PKGS=$PWD

cd $PATH_GC_KERNELS
make clean

make gc_main_${gc_kernel}
make malloc

make initialisation_${gc_kernel}
cp initialisation_${gc_kernel}.riscv $PATH_PKGS


if [[ $gc_kernel == minesweeper ]]; then
    # cd $PATH_GC_KERNELS
    # make clean
    # make gc_main_none

    cd $PATH_PKGS
    cp ${PATH_MS_KERNELS}/libjemalloc.so ./
    cp ${PATH_MS_KERNELS}/libminesweeper.so ./
    cp /home/centos/asplos22-minesweeper-reproduce/lib/* /home/lb_ms
fi


BENCHMARKS=(blackscholes bodytrack dedup ferret fluidanimate streamcluster freqmine swaptions x264)

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

if [[ $gc_kernel == minesweeper ]]; then
    rm /home/lb_ms/*
fi


echo ""
echo "All Done!"