#!/bin/bash

input_type=simmedium


BENCHMARKS=(blackscholes bodytrack dedup facesim ferret fluidanimate freqmine streamcluster swaptions x264)

cmd="parsecmgmt -a fulluninstall -p all"
eval ${cmd}

for benchmark in ${BENCHMARKS[@]}; do



    cmd="parsecmgmt -a build -p ${benchmark}"
    eval ${cmd}

    cmd="parsecmgmt -a run -p ${benchmark} -i simmedium"
    eval ${cmd}

done

echo ""
echo "All Done!"