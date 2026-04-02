#!/bin/bash
#BSUB -J mash_job_array[1-21]       # 定义任务阵列，1 到 21 号任务
#BSUB -n 24                         # 每个子任务申请 24 个核心
#BSUB -R "span[hosts=1]"            # 确保 24 个核在同一个计算节点上
#BSUB -R "rusage[mem=40GB]"         # 每个任务申请 40GB 内存
#BSUB -o logs/mash_%J_%I.out        # 标准输出日志 (%J 是作业 ID, %I 是阵列索引)
#BSUB -e logs/mash_%J_%I.err        # 错误日志
#BSUB -q serial                     # 指定队列名

# 创建日志目录
mkdir -p logs

# 获取当前任务对应的文件列表
# 对应 chunk_00, chunk_01 等文件名
INDEX=$(printf "%02d" $((LSB_JOBINDEX - 1)))
LIST_FILE="chunk_lists/chunk_${INDEX}"

echo "Processing list: $LIST_FILE on host $(hostname)"

# 执行 Mash Sketch
mash sketch -k 21 -s 10000 -l -p 24 "$LIST_FILE" -o "part_${LSB_JOBINDEX}"
