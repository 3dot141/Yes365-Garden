---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

## 原因：

网站服务器为了防止 DoS 攻击，通常在防火墙里设置拦截 ICMP 报文，而 ping 报文正是 ICMP 报文的一种，当然 ping 不通了。

## 名称解析：

DoS 攻击：DoS 是 Denial of Service 的简称，即拒绝服务，造成 DoS 的攻击行为被称为 DoS 攻击，其目的是使计算机或网络无法提供正常的服务。最常见的 DoS 攻击有计算机网络宽带攻击和连通性攻击。

ICMP：ICMP（Internet Control Message Protocol）Internet 控制报文协议。它是 TCP/IP 协议簇的一个子协议，用于在 IP 主机、路由器之间传递控制消息。控制消息是指网络通不通、主机是否可达、路由是否可用等网络本身的消息。这些控制消息虽然并不传输用户数据，但是对于用户数据的传递起着重要的作用。

## 如果想 ping 通：

添加 ICMP 的安全组  
![在这里插入图片描述](https://img-blog.csdnimg.cn/20190903170919645.png)