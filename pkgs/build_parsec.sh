#!/bin/bash

# Build script for PARSEC benchmarks with configurable compiler and GC kernel support
# Usage: ./build_parsec_r.sh [-c compiler] [-k kernel] [-i input] [-b benchmark]

# Default values
COMPILER="riscv"
GC_KERNEL="none" 
INPUT_SIZE="simmedium"
SPECIFIC_BENCHMARK=""

# All available benchmarks
BENCHMARKS=(blackscholes bodytrack dedup ferret fluidanimate streamcluster freqmine swaptions x264)

# Function to update parsec.json with the specified parameters
function update_parsec_json() {
    local parsec_json_path="/home/zhejiang/FireGuard_V2/Software/linux/parsecv3/firemarshal-workloads/parsecv3-workloads/parsec.json"
    
    # Build the command string
    local cmd_string="cd /root/pkgs && ./run_parsec.sh"
    
    # Add kernel parameter if not default
    if [ "$GC_KERNEL" != "none" ]; then
        cmd_string="$cmd_string -k $GC_KERNEL"
    fi
    
    # Add benchmark parameter if specified
    if [ -n "$SPECIFIC_BENCHMARK" ]; then
        cmd_string="$cmd_string -b $SPECIFIC_BENCHMARK"
    fi
    
    # Add poweroff command
    cmd_string="$cmd_string && poweroff -f"
    
    # Update the parsec.json file using Python for reliable JSON handling
    if [ -f "$parsec_json_path" ]; then
        python3 -c "
import json
import sys

try:
    with open('$parsec_json_path', 'r') as f:
        data = json.load(f)
    
    # Update the command in the first job
    if 'jobs' in data and len(data['jobs']) > 0:
        data['jobs'][0]['command'] = '$cmd_string'
    
    with open('$parsec_json_path', 'w') as f:
        json.dump(data, f, indent=4)
    
    print('✅ Updated parsec.json with command: $cmd_string')
except Exception as e:
    print(f'❌ Error updating parsec.json: {e}')
    sys.exit(1)
"
    else
        echo "❌ Warning: parsec.json not found at $parsec_json_path"
    fi
}

# Build and run benchmarks using bash with PARSEC environment
function run_benchmark() {
    local benchmark=$1
    
    echo "Building and running: $benchmark"
    
    # Export environment variables before running parsecmgmt
    export COMPILER_TYPE="$COMPILER"
    export GC_KERNEL_TYPE="$GC_KERNEL"
    export KERNELS_PATH="/home/zhejiang/FireGuard_V2/Software/linux/kernels"
    
    # Run PARSEC benchmark with bash environment
    bash -c "
        source ../env.sh
        echo 'Environment check:'
        echo '  CC: '\$CC
        echo '  CXX: '\$CXX
        echo '  COMPILER_TYPE: '\$COMPILER_TYPE
        echo '  PARSECPLAT: '\$PARSECPLAT
        parsecmgmt -a build -p $benchmark -c gcc-serial
        parsecmgmt -a run -p $benchmark -c gcc-serial -i $INPUT_SIZE
    "
    
    if [ $? -eq 0 ]; then
        echo "Completed: $benchmark"
    else
        echo "Failed: $benchmark"
    fi
}

# Parse command line arguments
while getopts "c:k:i:b:h" opt; do
    case $opt in
        c)
            COMPILER="$OPTARG"
            if [[ "$COMPILER" != "local" && "$COMPILER" != "riscv" ]]; then
                echo "Error: Invalid compiler type '$COMPILER'. Use 'local' or 'riscv'"
                exit 1
            fi
            ;;
        k)
            GC_KERNEL="$OPTARG"
            # Available kernels: none, pmc, sanitiser, ss, ss_mc, minesweeper
            if [[ ! "$GC_KERNEL" =~ ^(none|pmc|sanitiser|ss|ss_mc|minesweeper)$ ]]; then
                echo "Error: Invalid GC kernel '$GC_KERNEL'"
                echo "Available kernels: none, pmc, sanitiser, ss, ss_mc, minesweeper"
                exit 1
            fi
            ;;
        i)
            INPUT_SIZE="$OPTARG"
            if [[ ! "$INPUT_SIZE" =~ ^(simdev|simsmall|simmedium|simlarge|native)$ ]]; then
                echo "Error: Invalid input size '$INPUT_SIZE'"
                echo "Available sizes: simdev, simsmall, simmedium, simlarge, native"
                exit 1
            fi
            ;;
        b)
            SPECIFIC_BENCHMARK="$OPTARG"
            # Validate benchmark name
            if [[ ! " ${BENCHMARKS[@]} " =~ " ${SPECIFIC_BENCHMARK} " ]]; then
                echo "Error: Invalid benchmark '$SPECIFIC_BENCHMARK'"
                echo "Available benchmarks: ${BENCHMARKS[*]}"
                exit 1
            fi
            ;;
        h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -c COMPILER    Compiler type: 'local' or 'riscv' (default: riscv)"
            echo "  -k KERNEL      GC kernel: none, pmc, sanitiser, ss, ss_mc, minesweeper (default: none)"
            echo "  -i INPUT       Input size: simdev, simsmall, simmedium, simlarge, native (default: simmedium)"
            echo "  -b BENCHMARK   Specific benchmark to run: ${BENCHMARKS[*]} (default: all)"
            echo "  -h             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 -c local                    # Use local GCC compiler"
            echo "  $0 -c riscv -k pmc            # Use RISCV with PMC kernel"
            echo "  $0 -c local -i simsmall       # Use local GCC with small input"
            echo "  $0 -k sanitiser -b blackscholes # Use sanitiser kernel with blackscholes benchmark"
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            echo "Use -h for help"
            exit 1
            ;;
    esac
done

# Validate compiler and GC kernel combination
if [ "$COMPILER" = "local" ] && [ "$GC_KERNEL" != "none" ]; then
    echo "Error: Local compiler only supports GC_KERNEL='none'"
    echo "GC kernels contain RISCV-specific code incompatible with x86_64"
    exit 1
fi

# Check if RISCV tools are available when using RISCV compiler
if [ "$COMPILER" = "riscv" ]; then
    if [ ! -f "/usr/bin/riscv64-linux-gnu-gcc" ]; then
        echo "Error: RISCV toolchain not found"
        echo "Please install riscv64-linux-gnu-gcc and related tools"
        exit 1
    fi
fi

echo "=========================================="
echo "PARSEC Build Configuration:"
echo "Compiler: $COMPILER"
echo "GC Kernel: $GC_KERNEL"
echo "Input Size: $INPUT_SIZE"
if [ -n "$SPECIFIC_BENCHMARK" ]; then
    echo "Benchmark: $SPECIFIC_BENCHMARK"
else
    echo "Benchmark: All benchmarks"
fi
echo "=========================================="

# Update parsec.json with the specified parameters
update_parsec_json

# Build and run benchmarks
if [ -n "$SPECIFIC_BENCHMARK" ]; then
    # Run only the specified benchmark
    run_benchmark "$SPECIFIC_BENCHMARK"
else
    # Build and run each benchmark
    for benchmark in "${BENCHMARKS[@]}"; do
        run_benchmark "$benchmark"
        echo "------------------------------------------"
    done
fi

echo "=========================================="
echo "Build completed!"
echo "Compiler: $COMPILER"
echo "GC Kernel: $GC_KERNEL"
echo "Input Size: $INPUT_SIZE"
echo "==========================================" 