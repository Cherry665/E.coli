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

bsub < script/mash_sketch.sh

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
split -n l/40 -d -a 2 pairs_genome.tsv sub_pairs_

# 出现 core 文件可反向再执行一次
bsub < script/redundant1.sh

# 查看成功的比对数，共成功进行 16630042 次比对
wc -l /scratch/wangq/cl/E.coli/NR1/nr_*/result.list

for d in NR1/nr_*; do
    cat $d/result.list >> result.list
done

# 聚类
awk '{print $1"\t"$2"\t"$3}' result.list > NR/divergent.tsv
hnsm cluster --mode dbscan --eps 0.0001 NR/divergent.tsv -o NR/cluster0.0001.tsv
cat NR/cluster_0.004_NR.txt NR/cluster0.0001.tsv > NR/cluster0.0001_all.tsv

# 选择代表性菌株
python3 script/rep_strains.py -i NR/divergent.tsv -c NR/cluster0.0001.tsv  -o NR/rep_strains.txt
cat NR/cluster_0.004_NR.txt NR/rep_strains.txt > NR/strains_nr.txt
# 共 22389 个
```
## ClermonTyping
```bash
# 生成所有基因组的绝对路径列表
cd /scratch/wangq/cl/E.coli/ClermonTyping
find /scratch/wangq/cl/E.coli/data -name "*.fna" > all_genomes.list

# 拆分成 10 个小文件
split -l 4047 -d --additional-suffix=.list all_genomes.list task_list_
mkdir -p logs
bsub < ClermonTyping_run.sh

# 合并
find results_part_* -name "*_result.txt" -size +0c -exec cat {} + > total_phylogroups_40470.txt
awk -F'\t' '{print $1 "\t" $(NF-1)}' total_phylogroups_40470.txt > phylogroup_clean_40470.txt

# 绘图
Rscript pie.R phylogroup_clean_40470.txt phylogroup_pie_40470
# 去冗余后的类群分布同上
```

## zipf
```bash
cd /scratch/wangq/cl/E.coli
mkdir -p zipf
cd zipf

# 准备绘制重复频率分布特征图所需输入文件，并绘图
Rscript histogram_data.R ../NR/cluster0.0001_all.tsv ../ClermonTyping/phylogroup_clean_40470.txt
Rscript histogram.R

# 生成 genome_count.tsv 文件，用于绘制 zipf 图
echo -e "Number\tCount" > genome_count.tsv
awk -F'\t' '{print NF}' ../NR/cluster0.0001_all.tsv | sort -rn | awk '{print NR "\t" $1}' >> genome_count.tsv

# 拟合齐普夫定律模型，genome_count.tsv 和 zipf_data.R 在同一个目录下
Rscript zipf_data.R
Rscript zipf.R
```

## bac 120（核心基因）
```bash
cd /scratch/wangq/cl/E.coli
mkdir -p protein

# 提取蛋白序列
cat protein/strains.tsv |
        parallel --colsep '\t' --no-run-if-empty --linebuffer -k -j 1 '
            cat /scratch/wangq/cl/E.coli/data/{2}/protein.faa |
                grep "^>" |
                sed "s/^>//" |
                sed "s/'\''//g" |
                sed "s/\-\-//g" |
                perl -nl -e '\'' s/\s+\[.+?\]$//g; print; '\'' |
                sed "s/MULTISPECIES: //g" |
                perl -nl -e '\''
                    /^(\w+)\.(\d+)\s+(.+)$/ or next;
                    printf qq(%s.%s\t%s\t%s\n), $1, $2, qq({1}), $3;
                '\'' \
                >> protein/protein_detail.tsv

            cat /scratch/wangq/cl/E.coli/data/{2}/protein.faa
        ' |
        hnsm filter stdin -u |
        hnsm gz stdin -p 4 -o protein/pro.fa

# 3 列分别是蛋白ID、菌株ID、蛋白功能描述
cd protein
tsv-select -f 1,3 protein_detail.tsv | tsv-uniq | gzip > anno.tsv.gz
tsv-select -f 1,2 protein_detail.tsv | tsv-uniq | gzip > asmseq.tsv.gz
rm -f protein_detail.tsv

# 使用 95% 的覆盖率和 95% 的相似性进行蛋白聚类，选择代表蛋白
mmseqs easy-cluster pro.fa.gz rep tmp --threads 4 --remove-tmp-files -v 0 --min-seq-id 0.95 -c 0.95
# 使用 BGZF 格式压缩文件
hnsm gz rep_rep_seq.fasta -o rep_seq.fa

rm rep_all_seqs.fasta
rm rep_rep_seq.fasta

# 使用 80% 的覆盖率和 80% 的相似性进行蛋白聚类，定义蛋白家族
mmseqs easy-cluster rep_seq.fa.gz fam88 tmp --threads 8 --remove-tmp-files -v 0 --min-seq-id 0.8 -c 0.8

rm fam88_all_seqs.fasta
rm fam88_rep_seq.fasta

# 使用 80% 的覆盖率和 30% 的相似性进行蛋白聚类
mmseqs easy-cluster rep_seq.fa.gz fam38 tmp --threads 8 --remove-tmp-files -v 0 --min-seq-id 0.3 -c 0.8

rm fam38_all_seqs.fasta
rm fam38_rep_seq.fasta

# 构建本地蛋白序列数据库
cd /scratch/wangq/cl/E.coli
nwr seqdb -d protein/ --init --strain

nwr seqdb -d protein --size <(hnsm size protein/pro.fa.gz) --clust

nwr seqdb -d protein --anno <(gzip -dcf protein/anno.tsv.gz) --asmseq <(gzip -dcf protein/asmseq.tsv.gz)
nwr seqdb -d protein --rep f1=protein/fam88_cluster.tsv
nwr seqdb -d protein --rep f2=protein/fam38_cluster.tsv

# 导出细菌 bac120 标记集基因
nwr kb bac120 -o HMM

cp HMM/bac120.lst HMM/marker.lst

mkdir -p bac120

# 从代表蛋白序列库中，鉴定属于 bac120 标记集基因的序列
cat HMM/marker.lst |
    parallel --colsep '\t' --no-run-if-empty --linebuffer -k -j 8 "
        gzip -dcf protein/rep_seq.fa.gz |
            hmmsearch --cut_nc --noali --notextw HMM/hmm/{}.HMM - |
            grep '>>' |
            perl -nl -e ' m(>>\s+(\S+)) and printf qq(%s\t%s\t%s\n), q({}), \$1; '
    " > protein/bac120.tsv

nwr seqdb -d protein/ --rep f3=protein/bac120.tsv

# 提取属于 bac120 标记集基因的蛋白序列
echo "
    SELECT
        seq.name,
        asm.name,
        rep.f3
    FROM asm_seq
    JOIN rep_seq ON asm_seq.seq_id = rep_seq.seq_id
    JOIN seq ON asm_seq.seq_id = seq.id
    JOIN rep ON rep_seq.rep_id = rep.id
    JOIN asm ON asm_seq.asm_id = asm.id
    WHERE 1=1
        AND rep.f3 IS NOT NULL
    ORDER BY
        asm.name,
        rep.f3
    " |
    sqlite3 -tabs protein/seq.sqlite \
    > protein/seq_asm_f3.tsv


hnsm some protein/pro.fa.gz <(tsv-select -f 1 protein/seq_asm_f3.tsv | tsv-uniq) | hnsm dedup stdin | hnsm gz stdin -o bac120/bac120.fa

cp protein/seq_asm_f3.tsv bac120/seq_asm_f3.tsv

# 对每一个 Marker，提取对应的蛋白序列，放在一个文件夹中
cat HMM/marker.lst |
    parallel --no-run-if-empty --linebuffer -k -j 4 '
        echo >&2 "==> marker [{}]"

        mkdir -p bac120/{}

        hnsm some bac120/bac120.fa.gz <(
            cat bac120/seq_asm_f3.tsv |
                tsv-filter --str-eq "3:{}" |
                tsv-select -f 1 |
                tsv-uniq
            ) \
            > bac120/{}/{}.pro.fa
    '

# 利用 mafft 对每一个 Marker 进行序列比对
cat HMM/marker.lst |
    parallel --no-run-if-empty --linebuffer -k -j 8 '
        echo >&2 "==> marker [{}]"
        if [ ! -s bac120/{}/{}.pro.fa ]; then
            exit
        fi
        if [ -s bac120/{}/{}.aln.fa ]; then
            exit
        fi

        mafft --auto bac120/{}/{}.pro.fa > bac120/{}/{}.aln.fa
    '

# 将比对文件中的蛋白名改为菌株名
cat HMM/marker.lst |
while read marker; do
    echo >&2 "==> marker [${marker}]"
    if [ ! -s bac120/${marker}/${marker}.pro.fa ]; then
        continue
    fi

    if [ ! -s bac120/${marker}/${marker}.aln.fa ]; then
        continue
    fi

    cat bac120/seq_asm_f3.tsv |
        tsv-filter --str-eq "3:${marker}" |
        tsv-select -f 1-2 |
        hnsm replace -s bac120/${marker}/${marker}.aln.fa stdin \
        > bac120/${marker}/${marker}.replace.fa
done

# 将 Marker 的比对结果全部合并进一个文件
cat HMM/marker.lst |
while read marker; do
    if [ ! -s bac120/${marker}/${marker}.pro.fa ]; then
        continue
    fi
    if [ ! -s bac120/${marker}/${marker}.aln.fa ]; then
        continue
    fi

    cat bac120/${marker}/${marker}.replace.fa

    echo
done \
    > bac120/bac120.aln.fas

# 将基因片段的集合按菌株名串联起来
cat bac120/seq_asm_f3.tsv |
    cut -f 2 |
    tsv-uniq |
    sort |
    fasops concat bac120/bac120.aln.fas stdin -o bac120/bac120.aln.fa

trimal -in bac120/bac120.aln.fa -out bac120/bac120.trim.fa -automated1

FastTree -fastest -noml bac120/bac120.trim.fa > bac120/bac120.trim.newick

nwr distance bac120/bac120.trim.newick --mode pairwise -I -o bac120/22389_bac120_distance.tsv
```

## mash
```bash
cd /scratch/wangq/cl/E.coli
mkdir -p mash

cp ClermonTyping/22389_genomes.list mash/22389_genomes.list

mash sketch -k 21 -s 10000 -l -p 24 mash/22389_genomes.list -o mash/22389
mash dist -p 23 mash/22389.msh mash/22389.msh >> mash/22389_mash_distance.tsv
```

## fam88
```bash
cd /scratch/wangq/cl/E.coli
mkdir -p fam88
echo "
    SELECT
        seq.name,
        asm.name,
        rep.f1
    FROM asm_seq
    JOIN rep_seq ON asm_seq.seq_id = rep_seq.seq_id
    JOIN seq ON asm_seq.seq_id = seq.id
    JOIN rep ON rep_seq.rep_id = rep.id
    JOIN asm ON asm_seq.asm_id = asm.id
    WHERE 1=1
        AND rep.f1 IS NOT NULL
    ORDER BY
        asm.name,
        rep.f1
    " |
    sqlite3 -tabs protein/seq.sqlite \
    > protein/seq_asm_f88.tsv

# 在每一个大肠杆菌基因组中,计算 fam88 蛋白家族出现的次数矩阵
python3 fam88/famN_value.py -i protein/seq_asm_f88.tsv -o fam88/f88_value.tsv -r protein/f88.list

# 将之前生成的次数矩阵转化为两两菌株之间的遗传距离
hnsm similarity --mode jaccard --bin --dis fam88/f88_value.tsv -o fam88/22389_f88_distance.tsv
```

## 绘制聚类图
```bash
# 修改运行 3 次
cd /scratch/wangq/cl/E.coli
Rscript transfer.R

# 先将 phylogroup_clean_22389.txt 中的 GCF 号转换为菌株 ID
awk 'BEGIN{FS=OFS="\t"} NR==FNR{a[$1]=$2; next} ($2 in a){print $1, a[$2]}' \
    ClermonTyping/phylogroup_clean_22389.txt \
    protein/strains.tsv \
    > phylogroup_info.tsv

Rscript cluster_fig.R 22389_mash_distance.csv phylogroup_info.tsv mash_heatmap
Rscript cluster_fig.R 22389_bac120_distance.csv phylogroup_info.tsv bac120_heatmap
Rscript cluster_fig.R 22389_f88_distance.csv phylogroup_info.tsv f88_heatmap
```
