#!/bin/bash

# 获取当前脚本的绝对路径
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# 切换到主目录
cd "$script_dir/../"
echo "[cd] $script_dir/../"

echo "[git] backup start"
# 添加所有修改到暂存区
git add .
# 检查 git 状态
status=$(git status --porcelain)
# 如果 git 状态为空，则没有需要 commit 的内容
if [[ -z "$status" ]]; then
  echo "no commits exit "
else
  # 如果 git 状态不为空，则有需要 commit 的内容
  echo "commits: "
  echo "$status"
  # 提交代码，使用传递的参数作为提交消息
  git commit -m "publish blogs"
  # 拉取最新代码
  git pull
  # 推送到远程仓库
  git push  
fi
echo "[git] backup complete"

# deploy
echo "[deploy] do vercel deploy"
vercel --prod