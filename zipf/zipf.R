#!/usr/bin/env Rscript

library(readr)
library(tidyverse)
library(ggrepel)  

# 读取数据
results <- read_tsv("zipf_result.tsv")

# 绘制KS检验P值图
ggplot(results, aes(x = rows, y = p_value)) +
  # 蓝色折线和散点
  geom_line(color = "#1f77b4", linewidth = 1) +
  geom_point(color = "#1f77b4", size = 2) +
  
  # 添加p=0.05的红色虚线
  geom_hline(yintercept = 0.05, color = "red", linetype = "dashed", linewidth = 0.8) +
  annotate("text", x = 5, y = 0.05, label = "p=0.05", color = "red", vjust = -0.5, size = 3.5) +
  
  # 添加显著性标注
  geom_text_repel(aes(label = significance), 
                  color = "black", 
                  size = 4,
                  nudge_y = 0.02,  
                  segment.size = 0,  
                  na.rm = TRUE) +
  
  # 设置坐标轴范围和标签
  scale_x_continuous(limits = c(5, 40), breaks = seq(5, 40, 5)) +
  scale_y_continuous(limits = c(0, 1.0), breaks = seq(0, 1.0, 0.2)) +
  
  # 坐标轴标签
  labs(x = "Rows", 
       y = "p-value") +
  
  theme_bw() +
  theme(
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    panel.grid.minor = element_blank(),
    axis.title.x = element_text(size = 12, face = "bold"),
    axis.title.y = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 10),
    panel.border = element_rect(linewidth = 1),
    plot.margin = margin(10, 10, 10, 10)
  )

ggsave("zipf_test.png", width = 8, height = 6, dpi = 300, bg = "white")