#!/bin/bash
#BSUB -J redundant1
#BSUB -q serial
#BSUB -n 23
#BSUB -R span[hosts=1]
#BSUB -o redundant1.out
#BSUB -e redundant1.err
#BSUB -R rusage[mem=10GB]

bash script/redundant.sh -i result/cluster_GCF.tsv  -o result