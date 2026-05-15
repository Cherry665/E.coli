library(reshape2)
library(data.table)

# 1. 读取数据：增加 select 参数，只取第 1, 2, 3 列
df <- fread("mash/22389_mash_distance.tsv", 
            header = FALSE, 
            select = c(1, 2, 3)) 

colnames(df) <- c("Item1", "Item2", "Distance")

# 2. 使用 acast 转化为矩阵
dist_matrix <- reshape2::acast(df, Item1 ~ Item2, value.var = "Distance", fill = 0)

# 3. 转换为对称矩阵
dist_matrix <- as.matrix(dist_matrix)
dist_matrix[lower.tri(dist_matrix)] <- t(dist_matrix)[lower.tri(dist_matrix)]

# 4. 输出为 CSV
write.csv(dist_matrix, "22389_mash_distance.csv", quote = FALSE)