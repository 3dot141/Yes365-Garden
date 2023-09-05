---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

[登录 - 知识管理](https://kms.fineres.com/pages/viewpage.action?pageId=277491010)

# 迷惑 1- 应用在 DEBUG 后可以再次启动

背景：

测试有一个 [BUG](https://work.fineres.com/browse/REPORT-79356)， 我就想远程 DEBUG，每次 DEBUG 就没问题，不 DEBUG 就有问题

思考点：

DEBUG 的区别就是，会占据端口，但是开端口是在 Client 上，为什么 DEBUG 连接后就没问题呢。  
[多进程可以监听同一端口吗](https://cloud.tencent.com/developer/article/1485911)

结论：  
`SO_REUSEADDR` 不允许处于 listen 状态的地址重复使用，  
`SO_REUSEPORT` 允许，同时，SO_REUSEPORT 参数还会把新来的 tcp 连接负载均衡到各个 listen socket 上，为我们 tcp 服务器编程，提供了一种新的模式。  
所以， Java 远程 Debug 是开了一个 `SO_REUSEADDR` 的 `socket` 端口