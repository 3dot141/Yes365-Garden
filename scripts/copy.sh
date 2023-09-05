#!/bin/bash

# 检查传递的参数数量
if [ "$#" -ne 2 ]; then
  echo "需要提供两个参数：源目录和目标目录"
  exit 1
fi

# 提取参数
source_dir="$1"
target_dir="$2"

# 执行命令
cp -r --preserve=timestamps "$source_dir"/*/ "$target_dir"/content
cp -r --preserve=timestamps "$source_dir"/Index.md "$target_dir"/content
