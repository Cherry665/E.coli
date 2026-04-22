#!/bin/bash
#BSUB -J clermont[0-9]       
#BSUB -q mpi
#BSUB -n 24                         
#BSUB -R "span[hosts=1]"            
#BSUB -R "rusage[mem=20GB]"         
#BSUB -o logs/out.%J   
#BSUB -e logs/err.%J

# --- 定位列表 ---
INDEX=$(printf "%02d" $LSB_JOBINDEX)
MY_LIST="task_list_${INDEX}.list"
MY_BASE_DIR="results_part_${INDEX}"
mkdir -p "$MY_BASE_DIR"

# --- 定义处理函数 ---
process_single_genome() {
    local FASTA_PATH=$1
    local BASE_DIR=$2
    local SAMPLE_NAME=$(basename "$(dirname "$FASTA_PATH")")

    # 执行分型
    /scratch/wangq/cl/E.coli/ClermonTyping/clermonTyping.sh --fasta "$FASTA_PATH" --name "$SAMPLE_NAME" --minimal
    
    if [ -f "${SAMPLE_NAME}/${SAMPLE_NAME}_phylogroups.txt" ]; then
        awk -v sn="$SAMPLE_NAME" 'BEGIN{OFS="\t"} {$1=sn; print}' "${SAMPLE_NAME}/${SAMPLE_NAME}_phylogroups.txt" > "${BASE_DIR}/${SAMPLE_NAME}_result.txt"
    fi

    rm -rf "$SAMPLE_NAME"
}

export -f process_single_genome

# --- 启动并行 ---
parallel -j 23 process_single_genome {} "$MY_BASE_DIR" :::: "$MY_LIST"