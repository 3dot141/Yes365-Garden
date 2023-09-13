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
rm -rf "$target_dir"/content/*

# 复制目录
directories=$(ls -l "$source_dir"/ | awk '/^d/ {print $NF}')
efor dir in $directories; do
  cp -r "$source_dir/$dir" "$target_dir"/content
done

cp -r "$source_dir"/Home.md "$target_dir"/content/index.md