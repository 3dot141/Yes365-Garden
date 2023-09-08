---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

## Dubbo 框架架构

![495](Attachments/bea274c783934db10c32b145bbf32341_MD5.png)

## Proxy 层

`Proxy` 的创建过程

- `org.apache.dubbo.config.ReferenceConfig#createProxy`
- `org.apache.dubbo.rpc.service.GenericService#$invoke` 创建的 Proxy 继承 GenericService
	- `org.apache.dubbo.rpc.filter.GenericFilter` 执行过滤的时候则会匹配 $invoke

## Serialize 层

- `SerializeSecurityManager` 序列化安全控制
- `org.apache.dubbo.common.serialize.hessian2.Hessian2FactoryManager#Hessian2FactoryManager` Hessian 的具体实践

## Invoker 层

- `DubboInvoker`
	- `org.apache.dubbo.remoting.exchange.support.DefaultFuture.TimeoutCheckTask#TimeoutCheckTask` 时间轮判断是否超时

## Transporter 层核心实现：编解码与线程模型一文打尽

### AbstractPeer 抽象类

首先，我们来看 AbstractPeer 这个抽象类，它同时实现了 Endpoint 接口和 ChannelHandler 接口，如下图所示，它也是 AbstractChannel、AbstractEndpoint 抽象类的父类。

![Drawing 0.png|525](Attachments/2d6c580e994b5b057a86c1038a90cc09_MD5.png)

AbstractPeer 继承关系

> Netty 中也有 ChannelHandler、Channel 等接口，但无特殊说明的情况下，这里的接口指的都是 Dubbo 中定义的接口。如果涉及 Netty 中的接口，会进行特殊说明。

AbstractPeer 中有四个字段：一个是表示该端点自身的 URL 类型的字段，还有两个 Boolean 类型的字段（closing 和 closed）用来记录当前端点的状态，这三个字段都与 Endpoint 接口相关；第四个字段指向了一个 ChannelHandler 对象，AbstractPeer 对 ChannelHandler 接口的所有实现，都是委托给了这个 ChannelHandler 对象。从上面的继承关系图中，我们可以得出这样一个结论：AbstractChannel、AbstractServer、AbstractClient 都是要关联一个 ChannelHandler 对象的。

### Server 类

![495](Attachments/ebfd0b35f3dfdd11a032d3a32a515c86_MD5.png)