#!/bin/bash

# 获取当前脚本的绝对路径
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# 拷贝脚本
copy_sh="$script_dir/copy-brain.sh"
echo "[build] start copy"
# 执行拷贝操作
"$copy_sh"

# 发布脚本
publish_sh="$script_dir/publish.sh"
echo "[build] start publish"
# 执行发布操作
"$publish_sh"




