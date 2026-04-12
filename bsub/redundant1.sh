#!/bin/bash
#BSUB -J redundant1
#BSUB -q fat_384
#BSUB -n 80
#BSUB -R span[hosts=1]
#BSUB -o redundant1.out
#BSUB -e redundant1.err
#BSUB -R rusage[mem=20GB]

bash script/redundant.sh -i result/pairs_genome.tsv  -o NR