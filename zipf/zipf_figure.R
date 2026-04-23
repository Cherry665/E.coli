#!/usr/bin/env Rscript

library(tidyverse)
library(scales) 

# 读取用于绘图的原始分布数据
data <- read_tsv("genome_count.tsv", show_col_types = FALSE)

# 重新拟合曲线以获取参数 C 和 s 
fit_data <- data %>% slice(1:5)
zipf_law <- function(r, C, s) { return(C / r^s) }
fit <- nls(Count ~ zipf_law(Number, C, s), 
           data = fit_data, 
           start = list(C = 10000, s = 1), 
           control = nls.control(maxiter = 100))

C <- coef(fit)["C"]
s <- coef(fit)["s"]

# 计算理论拟合值并加入数据框
data <- data %>%
  mutate(Fitted = zipf_law(Number, C, s))

# 使用 ggplot2 绘制双对数坐标图
cat("开始绘制双对数坐标图...\n")

p <- ggplot(data, aes(x = Number, y = Count)) +
  
  # 实际数据点：设置透明度和颜色，类似图中的蓝绿色
  geom_point(color = "#00BFC4", alpha = 0.7, size = 1.5) +
  
  # 拟合理论线：画出幂律分布的直线
  geom_line(aes(y = Fitted), color = "#F8766D", linetype = "dashed", linewidth = 1) +
  
  # 转换 X 轴和 Y 轴为 Log10，并使用 10^x 的科学格式
  scale_x_log10(
    breaks = trans_breaks("log10", function(x) 10^x),
    labels = trans_format("log10", math_format(10^.x))
  ) +
  scale_y_log10(
    breaks = trans_breaks("log10", function(x) 10^x),
    labels = trans_format("log10", math_format(10^.x))
  ) +
  
  # 添加对数坐标轴特有的小刻度线 (bottom 和 left)
  annotation_logticks(sides = "bl") + 
  
  # 轴标签
  labs(x = "Rank of gene cluster", y = "Number of genomes") +
  
  theme_classic() +
  theme(
    axis.text = element_text(size = 12, color = "black"),
    axis.title = element_text(size = 14, face = "bold"),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
    axis.line = element_blank() # 去除重复轴线
  )

# 导出图片
ggsave("Zipf_plot.pdf", plot = p, width = 6, height = 5)
ggsave("Zipf_plot.png", plot = p, width = 6, height = 5, dpi = 300)
