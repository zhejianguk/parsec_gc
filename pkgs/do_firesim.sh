
#!/bin/bash



BENCHMARKS=(blackscholes bodytrack dedup ferret fluidanimate freqmine streamcluster swaptions x264)
base_dir=$PWD



for benchmark in ${BENCHMARKS[@]}; do
    echo "benchmark: $benchmark"
    echo "------------------------------------------"

    ./build_parsec.sh -k sanitiser -b $benchmark
    echo "------------------------------------------"
    echo ""
    
    cd /home/zhejiang/FireGuard_V2/Software/linux/parsecv3/firemarshal-workloads
    echo "get bin"
    echo "------------------------------------------"
    ./get_bins.sh
    echo "------------------------------------------"
    cd /home/zhejiang/firesim/sw/FireMarshal
    
    echo "build_kernel"
    ./build_kernel.sh
    echo "------------------------------------------"

    echo "run_firesim"
    firesim infrasetup
    echo "------------------------------------------"
    firesim runworkload

    echo "------------------------------------------"
    echo "terminaterunfarm"
    firesim terminaterunfarm

    cd $base_dir
done

echo ""
echo "All Done!"
