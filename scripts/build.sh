#!/bin/bash

source_dir="$1"

./copy.sh "$source_dir" ../
cd ../

# 拉取最新代码
git pull

# 添加所有修改到暂存区
git add .

# 检查 git 状态
status=$(git status --porcelain)

# 如果 git 状态为空，则没有需要 commit 的内容
if [[ -z "$status" ]]; then
  echo "没有需要 commit 的内容"
  exit 0
fi

# 如果 git 状态不为空，则有需要 commit 的内容
echo "有需要 commit 的内容:"
echo "$status"

# 提交代码，使用传递的参数作为提交消息
git commit -m "publish blogs"
# 推送到远程仓库
git push

exit 1
