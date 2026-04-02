#!/bin/bash
#BSUB -J mash_dist
#BSUB -q serial
#BSUB -n 23
#BSUB -R span[hosts=1]
#BSUB -o mash_dist.out
#BSUB -e mash_dist.err
#BSUB -R rusage[mem=10GB]

mkdir -p result

mash dist -p 23 all_genome.msh all_genome.msh >> result/mash_distance.tsv