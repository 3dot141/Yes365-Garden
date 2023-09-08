---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

1. top 找出占用 CPU 高的进程 PID  
	![](Attachments/83e7b278c5325360dd01eb19aba8a2b5_MD5.png)
2. top -p PID -H 命令查出进程中占用 CPU 最高的线程
3. 根据线程 ID（需要十进制转成十六进制），从线程栈中找出步骤2查出的线程
	1. ![](Attachments/537d70ffbd7b53910525201d477e7f2f_MD5.png)
	2. printf 0x%x 43845
4. jstack -l PID 命令打印出线程栈