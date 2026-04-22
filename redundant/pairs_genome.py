#!/usr/bin/env python3
import argparse
from itertools import combinations

def main():
    parser = argparse.ArgumentParser(description="将聚类文件按行拆分为两两配对的两列格式")
    parser.add_argument("-i", "--input", required=True, help="输入的聚类文件")
    parser.add_argument("-o", "--output", required=True, help="输出的两列配对文件")
    args = parser.parse_args()

    pair_count = 0
    line_count = 0

    with open(args.input, 'r') as f_in, open(args.output, 'w') as f_out:
        for line in f_in:
            strains = line.strip().split()
            
            if len(strains) < 2:
                continue
            
            line_count += 1
            
            for strain1, strain2 in combinations(strains, 2):
                f_out.write(f"{strain1}\t{strain2}\n")
                pair_count += 1

    print(f"处理完成！")
    print(f"共读取了 {line_count} 个有效聚类。")
    print(f"共生成了 {pair_count} 对比对任务，已保存至 {args.output}。")

if __name__ == "__main__":
    main()