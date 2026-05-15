#!/bin/bash
#BSUB -J distance
#BSUB -q mpi
#BSUB -n 24
#BSUB -R span[hosts=1]
#BSUB -o distance.out
#BSUB -e distance.err
#BSUB -R rusage[mem=20GB]


cd /scratch/wangq/cl/E.coli

nwr distance bac120/bac120.trim.newick --mode pairwise -I -o bac120/22389_bac120_distance.tsv