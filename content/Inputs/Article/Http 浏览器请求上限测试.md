---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

HTTP协议  
HTTP0.9、HTTP1.0每个请求单独建立一个TCP连接，请求完成连接断开；  
HTTP1.1可以持久连接，TCP建立连接后不会立即关闭，多个请求可以复用同一个TCP连接，同时请求可以并行，但是不同浏览器对并行次数有个数限制，以下是各个浏览器的并发次数；

![](Attachments/3e0684e7845c9b2fbcb2bd4b76722c67_MD5.png)

HTTP2发送请求时，既不需要排队发送，也不需要排队返回，降低了传输时间；  
HTTP/2.0理论上可以在一个TCP连接上发送无数个HTTP请求，而这些HTTP请求在浏览器看来，只是一个连接，所以避免了同源并发个数限制的问题。  
- ![Http 发展历史#HTTP2 0的多路复用和HTTP1 X中的长连接复用有什么区别？](Http%20发展历史.md#HTTP2%200的多路复用和HTTP1%20X中的长连接复用有什么区别？)

HTTP3目前还在草案阶段，使用 QUIC（Quic UDP Internet Connection）是谷歌制定的一种基于UDP的低时延的互联网传输层协议。替换 TCP，彻底规避了 TCP 传输的效率问题。  

## 测试

如下代码示例，定义一个 HTML 并在页面打开时加载 8 张图片。

```html
<!-- connection.html -->
<html>
  <body>
    <img src="/test1.jpg" alt="" />
    <img src="/test2.jpg" alt="" />
    <img src="/test3.jpg" alt="" />
    <img src="/test4.jpg" alt="" />
    <img src="/test5.jpg" alt="" />
    <img src="/test6.jpg" alt="" />
    <img src="/test7.jpg" alt="" />
    <img src="/test8.jpg" alt="" />
  </body>
</html>
```

![](Attachments/bad091dde91ac55e655cd6bbe6e1f4fb_MD5.png)

![](Attachments/b8bb2420ffc9c290b77fc52741031fb9_MD5.png)

查看源码，可以看到

```js
// https://chromium.googlesource.com/chromium/src/+/65.0.3325.162/net/socket/client_socket_pool_manager.cc#44
// Default to allow up to 6 connections per host. Experiment and tuning may
// try other values (greater than 0).  Too large may cause many problems, such
// as home routers blocking the connections!?!?  See http://crbug.com/12066.
int g_max_sockets_per_group[] = {
  6,  // NORMAL_SOCKET_POOL
  255 // WEBSOCKET_SOCKET_POOL
};
```

**即 chrome 同时最多 6 个 http 请求, 255 个 websocket 请求**。  
http 请求， 也是 tcp 连接数量。