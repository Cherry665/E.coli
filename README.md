## 数据下载
成功下载 40470 个大肠杆菌基因组文件，有两个 GCF_001291365.1、GCF_012029685.1 被官方删除了  

```bash
mkdir -p E.coli
cd ~/E.coli
datasets download genome accession --inputfile GCF_id.txt --include genome,gff3,protein --dehydrated --filename genomes_dehydrated.zip
unzip genomes_dehydrated.zip -d my_genomes_data
datasets rehydrate --directory my_genomes_data/
```

## 两步法去冗余
```bash
# 创建 MinHash 草图
cd /scratch/wangq/cl/E.coli
find $(pwd)/data -name "*.fna" > all_fna_list.txt
mkdir -p chunk_lists
split -l 2000 -d -a 2 all_fna_list.txt chunk_lists/chunk_

## 提交任务
bsub < script/mash_lsf.sh

## 合并结果
mash paste all_genome.msh part_*.msh

# 计算遗传距离
bsub < script/mash_dist.sh

# 聚类
bsub < script/hnsm_cluster.sh
wc -l result/cluster0.005.tsv
# 2033 result/cluster0.005.tsv

# 清理并统计
cd /scratch/wangq/cl/E.coli/result
awk '{
    for (i=1; i<=NF; i++) {
        if ($i ~ /GCF_/) {
            split($i, a, "/");
            for (j in a) {
                if (a[j] ~ /^GCF_/) {
                    $i = a[j];
                    break;
                }
            }
        }
    }
    print $0
}' cluster0.005.tsv > cluster_GCF.tsv
sed -i 's/ /\t/g' cluster_GCF.tsv
wc -w cluster_GCF.tsv
# 40470 cluster_GCF.tsv

# 序列比对
cd /scratch/wangq/cl/E.coli
bsub < script/redundant1.sh

# 聚类
awk '{print $1"\t"$2"\t"$3}' result/result.list > result/divergent.tsv
hnsm cluster --mode dbscan --eps 0.0001 -i result/divergent.tsv -o result/cluster0.0001.tsv

# 选择代表性菌株
python script/rep_strains.py -i result/divergent.tsv -c result/cluster0.0001.tsv  -o output/rep_strains.txt

```

