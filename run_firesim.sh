#!/bin/bash

# Input flags
gc_kernel=none

while getopts k: flag
do
	case "${flag}" in
		k) gc_kernel=${OPTARG};;
	esac
done

input_type=simmedium
path_firesim=/home/centos/firesim
path_parsec=/home/centos/parsec_gc
workload_name=parsec

path_firesim_sw=${path_firesim}/sw/FireMarshal
path_firesim_sw_workloads=${path_firesim_sw}/gc-${workload_name}-workloads/gc-${workload_name}/overlay/root
path_firesim_workloads=${path_firesim}/deploy/workloads/gc-parsec


path_parsec_pkgs=${path_parsec}/pkgs

cd ${path_firesim_sw_workloads}
if [ -r "pkgs" ]; then
    cmd="rm -rf ${path_firesim_sw_workloads}/pkgs"
    echo "${cmd}"
    eval ${cmd}
fi

cd ${path_firesim_workloads}
cmd="rm -rf ${path_firesim_workloads}/*"
echo "${cmd}"
eval ${cmd}

cd ${path_parsec_pkgs}
cmd="./build_parsec.sh -k ${gc_kernel}"
echo "${cmd}"
eval ${cmd}

cd ${path_firesim_sw_workloads}
cmd="rm -rf pkgs"
echo "${cmd}"
eval ${cmd}

cd ${path_parsec}
cmd="cp -rf pkgs ${path_firesim_sw_workloads}"
echo "${cmd}"
eval ${cmd}

cd ${path_firesim_sw_workloads}
cmd="./simplify_parsec.sh"
echo "${cmd}"
eval ${cmd}


cd ${path_firesim_sw}
cmd="./marshal clean gc-${workload_name}-workloads/gc-${workload_name}.json"
echo "${cmd}"
eval ${cmd}

cmd="./marshal build gc-${workload_name}-workloads/gc-${workload_name}.json"
echo "${cmd}"
eval ${cmd}

# cmd="./marshal launch gc-${workload_name}-workloads/gc-${workload_name}.json"
# echo "${cmd}"
# eval ${cmd}

cd images
cd gc-${workload_name}
cmd="cp -rf gc-${workload_name}-bin gc-${workload_name}.img ${path_firesim_workloads}"
echo "${cmd}"
eval ${cmd}

cmd="firesim launchrunfarm && firesim infrasetup && firesim runworkload"
echo "${cmd}"
eval ${cmd}

cmd="echo yes | firesim terminaterunfarm"
echo "${cmd}"
eval ${cmd}

# cmd="sudo poweroff -f"
# echo "${cmd}"
# eval ${cmd}