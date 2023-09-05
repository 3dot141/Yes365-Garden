---
aliases: []
created_date: 2023-08-25 16:00
draft: false
summary: ''
tags:
- dev
---

_**全新升级的 Triple 协议**_

_Cloud Native_

在微服务协议选型方面我们看到越来越多的应用从 Dubbo2 TCP 二进制协议迁移到 Dubbo3 Triple 协议 (兼容 gRPC)，以充分利用 Triple 的高效、全双工、Streaming 流式通信模型等能力；Triple+HTTP/2 的组合很好的解决了后端服务穿透性等问题，但在阿里及众多社区企业的实践中，我们发现基于 Triple 构建的微服务对于前端设备接入成本仍然比较高，用户需要通过网关协议转换来接入 Triple 后端服务（类似之前 Dubbo2 泛化调用），对于开发测试、运维等成本都非常高。  

基于以上背景，我们对 Dubbo3 中的 Triple 协议进行了全面升级：<font color="#ff0000">Triple 协议是 Dubbo3 设计的基于 HTTP 的 RPC 通信协议规范，它完全兼容 gRPC 协议，支持 Request-Response、Streaming 流式等通信模型，可同时运行在 HTTP/1 和 HTTP/2 之上。</font>

你可以使用 cURL 等标准 HTTP 工具访问 Triple 协议发布的服务。

```properties
curl \
    --header "Content-Type: application/json" \
    --data '{"sentence": "Hello Dubbo."}' \
    https://host:port/org.apache.dubbo.sample.GreetService/sayHello
```

基于 Triple 协议，你可以轻松地构建 Dubbo 后端微服务体系，由于 Triple 面向 HTTP 协议的易用性设计，前端设备如 Web、Mobile、标准 HTTP 等可以更轻松的接入后端体系，同时，Triple 与 gRPC 协议完全兼容性可实现与 gRPC 体系的互通。

![](Attachments/4f5ec5267e23093e6b087046dd3a1563_MD5.png)

Dubbo 框架提供了 Triple 协议的多种语言实现，它们可以帮助你构建浏览器、gRPC 兼容的 HTTP API 接口：你只需要定义一个标准的 Protocol Buffer 格式的服务并实现业务逻辑，Dubbo 负责帮助生成语言相关的 Server Stub、Client Stub，并将整个调用流程无缝接入如路由、服务发现等 Dubbo 体系。针对某些语言版本，Dubbo 框架还提供了更贴合语言特性的编程模式，即不绑定 IDL 的服务定义与开发模式，比如在 Dubbo Java 中，你可以选择使用 Java Interface 和 Pojo 类定义 Dubbo 服务，并将其发布为基于 Triple 协议通信的微服务。

_**协议设计目标与适用场景**_

_Cloud Native_

基于 Triple 协议，你可以实现以下目标：

**当 Dubbo 作为 Client 时**

Dubbo Client 可以访问 Dubbo 服务端 (Server) 发布的 Triple 协议服务，同时还可以访问标准的 gRPC 服务端。

- 调用标准 gRPC 服务端，发送 Content-type 为标准 gRPC 类型的请求：application/grpc, application/grpc+proto, and application/grpc+json
    
- 调用 Dubbo 服务端，发送 Content-type 为 Triple 类型的请求：application/json, application/proto, application/triple+wrapper

**当 Dubbo 作为 Server 时**  

Dubbo Server 默认将同时发布对普通 HTTP、gRPC 协议的支持，Triple 协议可以同时工作在 HTTP/1、HTTP/2 之上。因此，Dubbo Server 可以处理 Dubbo 客户端发过来的 Triple 协议请求，可以处理标准的 gRPC 协议请求，还能处理 cURL、浏览器发送过来的 HTTP 请求。以 Content-type 区分就是：

- 处理 gRPC 客户端发送的 Content-type 为标准 gRPC 类型的请求：application/grpc、application/grpc+proto、application/grpc+json
    
- 处理 Dubbo 客户端发送的 Content-type 为 Triple 类型的请求：application/json、application/proto、application/grpc+wrapper
    
- 处理 cURL、浏览器等发送的 Content-type 为 Triple 类型的请求：application/json、application/proto、application/grpc+wrapper

**示例场景**

Triple 协议按照 gRPC Spec 原生全量支持 Content-Type: application/grpc 协议的通信。基于此模式，Triple Client 可以调用任意的 gRPC Server，反之亦然。

![](Attachments/b8fc63b29ef1196b94a0464ccdbb7250_MD5.png)

Triple 协议支持基于 json 这种通用格式，将任意服务暴露到外部，任何支持标准 HTTP 协议的客户端（如 cURL、浏览器、终端）都可以直接发起调用，无需任何协议转换。

![](Attachments/74212ece85248fd7caf4d2192f1a2f61_MD5.png)

Triple 支持将 Java 友好的 Hessian、Kryo 等序列化封装在 HTTP 协议之上，从网络层看来就是一个标准的 HTTP 协议报文，天然兼容任何支持 HTTP 协议的 WAF、Gateway 等，可以很好地复用当前网络层的基础设施。

![](Attachments/0cc8b9e964ea2b9c8844652d8288d3d1_MD5.png)

_**协议规范（Specification）**_

_Cloud Native_

请在此查看 Triple 协议规范详情 Triple Specification**\[****1\]**。

_**与 gRPC 协议的关系详解**_

_Cloud Native_

上面提到 Triple 完全兼容 gRPC 协议，那既然 gRPC 官方已经提供了多语言的框架实现，为什么 Dubbo 还要通过 Triple 重新实现一遍那？核心目标主要有以下两点：

- 首先，在协议设计上，Dubbo 参考 gRPC 与 gRPC-Web 两个协议设计了自定义的 Triple 协议：Triple 是一个基于 HTTP 传输层协议的 RPC 协议，它完全兼容 gRPC 的同时可运行在 HTTP/1、HTTP/2 之上。
    
- 其次，Dubbo 框架在每个语言的实现过程中遵循了符合框架自身定位的设计理念，相比于 grpc-java、grpc-go 等框架库，Dubbo 协议实现更简单、更纯粹，尝试在实现上规避 gRPC 官方库中存在的一系列问题。

gRPC 本身作为 RPC 协议规范非常优秀，但原生的 gRPC 库实现在实际使用存在一系列问题，包括实现复杂、绑定 IDL、难以调试等，Dubbo 在协议设计与实现上从实践出发，很好的规避了这些问题：

- 原生的 gRPC 实现受限于 HTTP/2 交互规范，无法为浏览器、HTTP API 提供交互方式，你需要额外的代理组件如 grpc-web、grpc-gateway 等才能实现。在 Dubbo 中，你可以直接用 curl、浏览器访问 Triple 协议服务.
    
- gRPC 官方库强制绑定 Protocol Buffers，唯一的开发选择就是使用 IDL 定义和管理服务，这对于一些多语言诉求不强的用户是一个非常大的使用负担。Dubbo 则在支持 IDL 的同时，为 Java、Go 等提供了语言特有的服务定义与开发方式。
    
- 在开发阶段，以 gRPC 协议发布的服务非常难以调试，你只能使用 gRPC 特定的工具来进行，很多工具都比较简陋 & 不成熟。而从 Dubbo3 开始，你可以直接使用 curl | jq 或者 Chrome 开发者工具来调试你的服务，直接传入 JSON 结构体就能调用服务。
    
- 首先，gRPC 协议库有超过 10 万行代码的规模，但 Dubbo (Go、Java、Rust、Node.js 等) 关于协议实现部分仅有几千行代码，这让代码维护和问题排查变得更简单。
    
- 谷歌提供的 gRPC 实现库没有使用主流的第三方或语言官方协议库，而是选择自己维护了一套实现，让整个维护与生态扩展变得更加复杂。比如 grpc-go 自己维护了一套 HTTP/2 库而不是使用的 go 官方库。Dubbo 使用了官方库的同时，相比 gRPC 自行维护的 http 协议库维持了同一性能水准。
    
- gRPC 库仅仅提供了 RPC 协议实现，需要你做很多额外工作为其引入服务治理能力。而 Dubbo 本身是不绑定协议的微服务开发框架，内置 HTTP/2 协议实现可以与 Dubbo 服务治理能力更好的衔接在一起。

**实现更简单**  

Dubbo 框架实现专注在 Triple 协议自身，而对于底层的网络通信、HTTP/2 协议解析等选择依赖那些经过长期检验的网络库。比如 Dubbo Java 基于 Netty 构建，而 Dubbo Go 则是直接使用的 Go 官方 HTTP 库。

Dubbo 提供的 Triple 协议实现非常简单，对应 Dubbo 中的 Protocol 组件实现，你可以仅仅花一下午时间就搞清楚 Dubbo 协议的代码实现。

**大规模生产环境检验**

自 Dubbo3 发布以来，Triple 协议已被广泛应用于阿里巴巴以及众多社区标杆企业，尤其是一些代理、网关互通场景。一方面 Triple 通过大规模生产实践被证实可靠稳定，另一方面 Triple 的简单、易于调试、不绑定 IDL 的设计也是其得到广泛应用的重要因素。

**原生多协议支持**

当以 Dubbo 框架为服务端对外发布服务时，可以做到在同一端口原生支持 Triple、gRPC 和 HTTP/1 协议，这意味着你可以用多种形式访问 Dubbo 服务端发布的服务，所有请求形式最终都会被转发到相同的业务逻辑实现，这给你提供了更大的灵活性。

Dubbo 完全兼容 gRPC 协议及相关特性包括 streaming、trailers、error details 等，你选择直接在 Dubbo 框架中使用 Triple 协议（另外，你也可以选择使用原生的 gRPC 协议），然后你就可以直接使用 Dubbo 客户端、curl、浏览器等访问你发布的服务。在与 gRPC 生态互操作性方面，任何标准的 gRPC 客户端，都可以正常访问 Dubbo 服务；Dubbo 客户端也可以调用任何标准的 gRPC 服务，这里有提供的互操作性示例**\[****2\]**

以下是使用 cURL 客户端访问 Dubbo 服务端 Triple 协议服务的示例：

```properties
curl \
    --header "Content-Type: application/json" \
    --data '{"sentence": "Hello Dubbo."}' \
    https://host:port/org.apache.dubbo.sample.GreetService/sayHello
```

**一站式服务治理接入**  

我们都知道 Dubbo 有丰富的微服务治理能力，比如服务发现、负载均衡、流量管控等，这也是我们使用 Dubbo 框架开发应用的优势所在。要想在 Dubbo 体系下使用 gRPC 协议通信，有两种方式可以实现，一种是直接在 Dubbo 框架中引入 gRPC 官方发布的二进制包，另一种是在 Dubbo 内原生提供 gRPC 协议兼容的源码实现。

相比于第一种引入二进制依赖的方式，Dubbo 框架通过内置 Triple 协议实现的方式，原生支持了 gRPC 协议，这种方式的优势在于源码完全由自己掌控，因此协议的实现与 Dubbo 框架结合更为紧密，能够更灵活的接入 Dubbo 的服务治理体系。

_**多语言实现**_

_Cloud Native_

基于 Triple 协议设计，我们计划为尽可能多的语言提供轻量的 RPC 协议实现，让 Triple 协议互通可以完整的覆盖多套语言栈，与 gRPC 兼容且具备更好的易用性。同时，Dubbo 会继续在一些被广泛用于微服务开发的语言（如Java、Go等）提供完善的微服务治理能力，让 Dubbo 成为一套可以连接前后端的微服务开发体系。

当前，Dubbo Java 语言已经在 3.3.0-triple-SNAPSHOT 版本完成了以上 Triple 协议升级的初步目标，具体可在 samples/dubbo-samples-triple-unary 示例中体验_（可点击阅读原文跳转到示例链接）_。

Triple 协议同步推进中的多语言实现还包括：Go、Node.js、Rust 等后端实现，Javascript Web 端实现。

**Java 语言**  

在 Dubbo Java 库实现中，除了 IDL 方式外，你可以使用 Java Interface 方式定义服务，这对于众多熟悉 Dubbo 体系的 Java 用户来说，可以大大降低使用 gRPC 协议的成本。

另外，Java 版本的协议实现在性能上与 grpc-java 库基本持平，甚至某些场景下比 grpc-java 性能表现还要出色。而这一切还是建立在 Dubbo 版本协议的实现复杂度远小于 gRPC 版本的情况下，因为 grpc-java 维护了一套定制版本的 HTTP/2 协议实现。

仓库地址：_https://github.com/apache/dubbo_

**Go 语言实现**

Dubbo Go 推荐 IDL 开发模式，通过 Dubbo 配套的 protoc 插件生成 stub 代码，你只需要提供对应的业务逻辑实现即可，你可以通过 curl、浏览器访问 Dubbo Go 发布的 gRPC 服务。

仓库地址：_https://github.com/apache/dubbo-go/_

**Rust**  

Dubbo Rust 已经完整实现了 gRPC 协议兼容部分，目前正在推进 HTTP/1 等模式下的 unary RPC 调用支持。

仓库地址：_https://github.com/apache/dubbo-rust/_

**Node.js**  

Node.js 语言已经完整实现了 gRPC 协议兼容部分，目前正在推进 HTTP/1 等模式下的 unary RPC 调用支持。

仓库地址：_https://github.com/apache/dubbo-js/_

**Web**  

通过 Dubbo 提供的 Javascript 客户端库，让你可以编写运行在浏览器中的前端页面，在浏览器侧直接发起对后端 Dubbo 服务的请求调用。

仓库地址：_https://github.com/apache/dubbo-js/_

_**总结**_

_Cloud Native_

欢迎大家持续关注，对这部分建设感兴趣的开发者，请搜索钉钉群号：37290003945 加入 ApacheDubbo 社区交流群持续关注各个项目开发进展，探索构建基于 HTTP 的高效且具备高度易用性的项目。

**相关链接：**   

\[1\] Triple Specification

_https://cn.dubbo.apache.org/zh-cn/overview/reference/protocols/triple-spec/_

\[2\] 互操作性示例

_https://github.com/apache/dubbo-samples/tree/triple-protocol-sample-0719/2-advanced/dubbo-samples-triple-grpc_

**参考阅读：** 

- [Dubbo3.0 阿里大规模实践解析——URL 重构](http://mp.weixin.qq.com/s?__biz=MzAwMDU1MTE1OQ==&mid=2653559077&idx=1&sn=7d3ad5c10d863b857545f8e4b5c6d52e&chksm=813988bdb64e01abf1da6539fa122454dd600a18cf8e8fbf91bd3abb99e32c4f11c0ec63e5e2&scene=21#wechat_redirect)  
- [日均调用4亿次！百递云•API开放平台高可用架构系统构建实践](http://mp.weixin.qq.com/s?__biz=MzAwMDU1MTE1OQ==&mid=2653561913&idx=1&sn=bb346c8afb181081e8dc8a3f773baa45&chksm=8139b5a1b64e3cb7add3b2d535bbf423c98fcc461528b8c6c8148709f7e11ef23b295752b8ab&scene=21#wechat_redirect)
- [BUG越改越多？微信团队用自动化测试化险为夷](http://mp.weixin.qq.com/s?__biz=MzAwMDU1MTE1OQ==&mid=2653561879&idx=1&sn=def8137c5fb4e7f979189bcd987dbff6&chksm=8139b58fb64e3c99cb41353d887c8ed19c8942b006d76579cc98d252d873684e9becff76d67d&scene=21#wechat_redirect)
    
- [哔哩哔哩大规模AI模型推理实践](http://mp.weixin.qq.com/s?__biz=MzAwMDU1MTE1OQ==&mid=2653561861&idx=1&sn=e009488f7ca1265826b769a7c7a92e9a&chksm=8139b59db64e3c8b188a689c45bf6e2120ecfdf51f25f4b0d460f570f0d38d7515112d72ff40&scene=21#wechat_redirect)  

本文由高可用架构转载。技术原创及架构实践文章，欢迎通过公众号菜单「联系我们」进行投稿