#!/usr/bin/env Rscript

library(ggplot2)

args <- commandArgs(trailingOnly = TRUE)
multpcr_phylogroup_file <- args[1]
pie_name <- args[2]

# 定义配色
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

# 统计分组数量
count_phylogroup_percentage <- function(multpcr_phylogroup_file) {
    df <- read.table(multpcr_phylogroup_file, sep = "\t", header = FALSE)
    phylo_counts <- as.data.frame(table(df$V2))
    colnames(phylo_counts) <- c("phylogroup", "count")
    return(phylo_counts)
}

count_data <- count_phylogroup_percentage(multpcr_phylogroup_file)
total <- sum(count_data$count) 

# 绘制饼图
pie <- ggplot(count_data, aes(x = "", y = count, fill = phylogroup)) +
  geom_bar(stat = "identity", color = "white", linewidth = 1) + 
  coord_polar(theta = "y") +
  scale_fill_manual(values = group_colors) +
  geom_text(aes(label = count),
            position = position_stack(vjust = 0.5),
            color = "white", size = 4, fontface = "bold") +
  ggtitle(paste0(total, " Genomes")) +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"), 
    legend.position = "right",
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9),
    legend.margin = margin(l = 10)
  ) +
  guides(fill = guide_legend(keyheight = 0.8, keywidth = 0.8)) +
  labs(fill = "Phylogroup")

ggsave(paste0(pie_name, ".png"), plot = pie, width = 140, height = 120, units = "mm", dpi=300)
ggsave(paste0(pie_name, ".eps"), plot = pie, width = 140, height = 120, units = "mm")