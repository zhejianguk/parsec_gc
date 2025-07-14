#!/bin/bash

gc_kernel=none

rm -f *.o
rm -f *.riscv

input_type=simmedium


# BENCHMARKS=(blackscholes bodytrack swaptions x264)
BENCHMARKS=(blackscholes bodytrack dedup facesim ferret fluidanimate freqmine streamcluster swaptions x264)

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
