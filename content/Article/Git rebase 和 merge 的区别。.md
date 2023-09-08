---
aliases: []
created_date: 2023-09-04 16:47
draft: false
summary: ''
tags:
- dev
---

详见 [git rebase和 git merge有什么区别？](git%20rebase和%20git%20merge有什么区别？.md)

## 不同分支间的区别

merge 会插入一个 node, 链接到其他分支的提交上。多出 1 个 node ，但是会链接一条其他分支提交的线。  
rebase 会将其他分支的提交每一个都重新提交到该分支上。多出 n 个 node。

## 远程和本地仓库的区别

基本等同于上面，远程和本地即为不同的分支。  
区别是因为大家都是拉取同一个远程分支，所以只需要线性的提交记录即可。

## 推荐使用方案

当不同分支间合并时，需要用 merge  
- 当使用私有分支时，可以使用 rebase

当同一分支拉取时，使用 rebase