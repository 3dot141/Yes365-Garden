#!/bin/bash

# 获取当前脚本的绝对路径
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
echo "[copy]script_dir is $script_dir"

# 构建源目录的绝对路径
source_dir="$script_dir/../../TheBrain"
echo "[copy]source_dir is $source_dir"

# 构建目标目录的绝对路径
target_dir="$script_dir/../"
echo "[copy]target_dir is $target_dir"

copy_script="$script_dir/copy.sh"

# 执行拷贝操作
"$copy_script" "$source_dir" "$target_dir"