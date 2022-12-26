#!/bin/bash

input_type=simmedium


BENCHMARKS=(blackscholes bodytrack)

cmd="parsecmgmt -a clean -p all"
eval ${cmd}
cmd="parsecmgmt -a fulluninstall -p all"
eval ${cmd}


for benchmark in ${BENCHMARKS[@]}; do

    cmd="parsecmgmt -a build -p ${benchmark}"
    eval ${cmd}

    cmd="parsecmgmt -a run -p ${benchmark} -i ${input_type}"
    eval ${cmd}

done

echo ""
echo "All Done!"