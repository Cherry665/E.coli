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
# 第一步
# 创建 MinHash 草图
cd /scratch/wangq/cl/E.coli
find $(pwd)/data -name "*.fna" > all_fna_list.txt
mkdir -p chunk_lists
split -l 2000 -d -a 2 all_fna_list.txt chunk_lists/chunk_

bsub < script/mash_lsf.sh

## 合并结果
mash paste all_genome.msh part_*.msh

# 计算遗传距离
bsub < script/mash_dist.sh

# 聚类
bsub < script/hnsm_cluster.sh
wc -l result/cluster0.004.tsv
# 3923 result/cluster0.04.tsv

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
}' cluster0.004.tsv > cluster_GCF.tsv
sed -i 's/ /\t/g' cluster_GCF.tsv
wc -w cluster_GCF.tsv
# 40470 cluster_GCF.tsv

# 提取只有一列的行
mkdir -p NR
cd /scratch/wangq/cl/E.coli
awk -F'\t' 'NF == 1' result/cluster_GCF.tsv > NR/cluster_0.004_NR.txt
wc -l NR/cluster_0.004_NR.txt
# 2221 NR/cluster_0.004_NR.txt

# 提取多于一列的行
awk -F'\t' 'NF > 1' result/cluster_GCF.tsv > result/cluster_GCF_many.tsv
wc -l result/cluster_GCF_many.tsv
# 1702 result/cluster_GCF_many.tsv

# 形成只有两列的比对文件
cd ~/E.coli
python3 script/pairs_genome.py -i result/cluster_GCF_many.tsv -o result/pairs_genome.tsv

# 第二步
# 序列比对
cd /scratch/wangq/cl/E.coli
split -n l/35 -d -a 2 pairs_genome.tsv sub_pairs_

# 出现 core 文件可反向再执行一次
bsub < script/redundant1.sh

# 聚类
awk '{print $1"\t"$2"\t"$3}' result/result.list > result/divergent.tsv
hnsm cluster --mode dbscan --eps 0.0001 -i result/divergent.tsv -o result/cluster0.0001.tsv

# 选择代表性菌株
python script/rep_strains.py -i result/divergent.tsv -c result/cluster0.0001.tsv  -o output/rep_strains.txt

```
## ClermonTyping
```bash
# 生成所有基因组的绝对路径列表
cd /scratch/wangq/cl/E.coli/ClermonTyping
find /scratch/wangq/cl/E.coli/data -name "*.fna" > all_genomes.list
# 拆分成 10 个小文件
split -l 4047 -d --additional-suffix=.list all_genomes.list task_list_

bsub < ClermonTyping_run.sh
# 合并
find results_part_* -name "*_result.txt" -size +0c -exec cat {} + > total_phylogroups.txt
cut -f 1,5 total_phylogroups.txt > phylogroup_clean.txt

Rscript pie.R phylogroup_clean.txt phylogroup_pie_40470
# 去冗余后的绘图同上
```
