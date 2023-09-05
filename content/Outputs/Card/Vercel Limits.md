---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

> [Vercel](Vercel.md)

vercel 是一个非常好的服务提供商，至少一开始，我是这么认为的。  
在使用 vercel 的过程中，逐渐发现 vercel 的一些限制。  
这里补充一下。

# Vercel Limits

顾名思义，vercel 是没有办法固定一个 ip 值的，这样的话，就容易导致，在需要对一些 ip 地址进行“白名单”“黑名单”限制时，vercel 的服务完全不可用。

非常的难受😣

在我对企业微信进行二开时，就遇到这个问题

```
"error is Error: not allow to access from your ip, hint: [1682059359480130799301353], from ip: 34.203.14.222, more info at https://open.work.weixin.qq.com/devtool/query?e=60020"
```

不能通过这个 ip 访问一些 api, 从而使我的思路破产💸。