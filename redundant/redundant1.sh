#!/bin/bash
BASE_DIR="/scratch/wangq/cl/E.coli"
for i in {00..34}; do
    INPUT="$BASE_DIR/result/sub_pairs_$i"
    OUTPUT="$BASE_DIR/NR1/nr_$i"

    [ ! -f "$INPUT" ] && continue

    # 提交到 LSF 系统
    # -R "select[hname != 'c52n04']" : 排除 c52n04 这个节点（无法正常运行）
    bsub -J "redundant_$i" \
         -q mpi \
         -n 24 \
         -R "span[hosts=1]" \
         -R "select[hname != 'c52n04']" \
         -R "rusage[mem=20GB]" \
         -o "$BASE_DIR/logs/redundant_$i.out" \
         -e "$BASE_DIR/logs/redundant_$i.err" \
         "bash $BASE_DIR/script/redundant.sh -i $INPUT -o $OUTPUT"
done
