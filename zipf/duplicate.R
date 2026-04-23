#!/usr/bin/env Rscript

library(ggplot2)
library(dplyr)

# ===================== 读取并预处理数据 =====================
# 读取你的文件（替换成你的文件路径，比如"your_data.txt"）
df <- read.table("GCF_cluster_phylogroup.tsv", header = TRUE, sep = "\t", stringsAsFactors = FALSE)

# 步骤1：统计每个Cluster的基因组数量（即重复数）
cluster_counts <- df %>% 
  group_by(Cluster_ID) %>% 
  summarise(duplicate_count = n(), .groups = "drop")  # duplicate_count = 该Cluster的基因组数（重复数）

# 步骤2：将重复数合并回原数据框
df <- df %>% 
  left_join(cluster_counts, by = "Cluster_ID")

# 步骤3：按「重复数+Phylogroup」统计总基因组数
plot_data <- df %>% 
  group_by(duplicate_count, Phylogroup) %>% 
  summarise(genome_count = n(), .groups = "drop")

# ===================== 定义配色 =====================
group_colors <- c(
  "A" = "#4874cb", 
  "B1" = "#ee822f", 
  "B2" = "#f2ba02", 
  "C" = "#75bd42", 
  "D" = "#30c0b4",
  "E" = "#e54c5e", 
  "F" = "#254380", 
  "G" = "#9e4c0d", 
  "others" = "#467128", 
  "Shig" = "#917001"
)

# ===================== 绘制堆叠柱状图 =====================
ggplot(plot_data, aes(x = factor(duplicate_count), y = genome_count, fill = Phylogroup)) +
  # 堆叠柱状图核心
  geom_bar(stat = "identity", width = 0.8) +
  # 配色映射
  scale_fill_manual(values = group_colors) +
  # 坐标轴标签
  labs(
    x = "The Number of Duplicates of the Genome",
    y = "Count of Genomes",
    fill = "Phylogroup"
  ) +
  # 主题调整
  theme_classic() +
  theme(
    # 坐标轴字体
    axis.title.x = element_text(size = 12, face = "bold"),
    axis.title.y = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 10),
    # 图例位置
    legend.position = "right",
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9)
  ) +
  # 可选：如果重复数太多，X轴标签旋转避免重叠
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ===================== 保存图片 =====================
ggsave("genome_duplicate.png", width = 12, height = 8, dpi = 300)
ggsave("genome_duplicate.eps", width = 12, height = 8)