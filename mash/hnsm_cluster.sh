#!/bin/bash
#BSUB -J hnsm_cluster
#BSUB -q serial
#BSUB -n 23
#BSUB -R span[hosts=1]
#BSUB -o hnsm_cluster.out
#BSUB -e hnsm_cluster.err
#BSUB -R rusage[mem=10GB]


hnsm cluster --mode dbscan --eps 0.004 result/mash_distance.tsv -o result/cluster0.004.tsv