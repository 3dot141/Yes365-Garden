---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

原理见 [gzip 压缩算法原理](gzip%20压缩算法原理.md)  
排查案例见 [Nginx 和 Tomcat 的 gzip 压缩](Nginx%20和%20Tomcat%20的%20gzip%20压缩.md)

## http 压缩过程

浏览器发送Http request 给Web服务器,  request 中有`Accept-Encoding: gzip, deflate`。 (告诉服务器， 浏览器支持gzip压缩)

Web服务器接到request后， 生成原始的Response, 其中有原始的Content-Type和Content-Length。

Web服务器通过Gzip，来对Response进行编码， 编码后header中有Content-Type和Content-Length(压缩后的大小)， 并且增加了`Content-Encoding:gzip`.  然后把Response发送给浏览器。

浏览器接到Response后，根据`Content-Encoding:gzip`来对Response 进行解码。 获取到原始response后， 然后显示出网页。

![|535](Attachments/6c9939e8b3601b0dfac787c4b77c8c69_MD5.png)

> [!note]
> 1. 这里 gzip 是被浏览器自动解压的。 
> 	1. 见 chrome-dev-tools，是可以直接展示出来的。
> 	2. ![](Attachments/3ef129cc1ec1f8c95a157e8e9f7b1268_MD5.png)
> 2. 如果仅仅是请求中附带 `content-encoding` 是没有用的。服务器不会自动解压的。
> 3. 类似 `HttpClient` 这种请求库，影响 gzip 的时候，是不会自动解压的。
> 	1. `return HttpClients.custom().setConnectionManager(clientConnectionManager).disableContentCompression().build();`
> 	2. HttpClient 默认处理解压缩。