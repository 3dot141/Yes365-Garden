---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

HTTP 请求报头： Authorization  
HTTP响应报头： WWW-Authenticate  
HTTP认证基于质询/回应(challenge/response)的认证模式。

## **◆ 基本认证 basic authentication**　←　HTTP1.0提出的认证方法

客户端对于每一个realm，通过提供用户名和密码来进行认证的方式。

※　包含密码的明文传递

**基本认证步骤：**

 1. 客户端访问一个受http基本认证保护的资源。
 2. 服务器返回401状态，要求客户端提供用户名和密码进行认证。

	   401 Unauthorized  
	   WWW-Authenticate： Basic realm="WallyWorld"

 3. 客户端将输入的用户名密码用Base64进行编码后，采用非加密的明文方式传送给服务器。

	   Authorization: Basic xxxxxxxxxx.

 4. 如果认证成功，则返回相应的资源。如果认证失败，则仍返回401状态，要求重新进行认证。

**特记事项**

 1. Http是无状态的，同一个客户端对同一个realm内资源的每一个访问会被要求进行认证。
 2. 客户端通常会缓存用户名和密码，并和 authentication realm 一起保存，所以，一般不需要你重新输入用户名和密码。
	 1. **相关的信息存储在客户端内部，并不存储在 *storage* 里面，所以获取不到。**
	 2. 只能是服务器进行获取，并且要配置相应的拦截请求才可以。
 3. 以非加密的明文方式传输，虽然转换成了不易被人直接识别的字符串，但是无法防止用户名密码被恶意盗用。

## **◆ 摘要认证 digest authentication**　　　←　HTTP1.1提出的基本认证的替代方法

服务器端以nonce进行质询，客户端以用户名，密码，nonce，HTTP方法，请求的URI等信息为基础产生的response信息进行认证的方式。

※　不包含密码的明文传递

**摘要认证步骤：**

 1. 客户端访问一个受http摘要认证保护的资源。
 2. 服务器返回401状态以及nonce等信息，要求客户端进行认证。

HTTP/1.1 401 Unauthorized

WWW-Authenticate: **Digest**

realm="testrealm@host.com",

qop="auth,auth-int",

nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093",

opaque="5ccc069c403ebaf9f0171e9517f40e41"

 1. 客户端将以用户名，密码，nonce值，HTTP方法, 和被请求的URI为校验值基础而加密（默认为MD5算法）的摘要信息返回给服务器。

	   认证必须的五个情报：

 - realm ： 响应中包含信息
 - nonce ： 响应中包含信息
 - username ： 用户名
 - digest-uri ： 请求的 URI
 - response ： 以上面四个信息加上密码信息，使用MD5算法得出的字符串。

Authorization: **Digest**  
username="Mufasa",　 ←　客户端已知信息  
realm="testrealm@host.com", 　 ←　服务器端质询响应信息  
nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", 　←　服务器端质询响应信息  
uri="/dir/index.html", ←　客户端已知信息  
qop=auth, 　 ←　服务器端质询响应信息  
nc=00000001, ←　客户端计算出的信息  
cnonce="0a4f113b", ←　客户端计算出的客户端nonce  
**response="6629fae49393a05397450978507c4ef1", ←　最终的摘要信息 ha3**  
opaque="5ccc069c403ebaf9f0171e9517f40e41"　 ←　服务器端质询响应信息
 1. 如果认证成功，则返回相应的资源。如果认证失败，则仍返回401状态，要求重新进行认证。

**特记事项：**

 1. 避免将密码作为明文在网络上传递，相对提高了HTTP认证的安全性。
 2. 当用户为某个realm首次设置密码时，服务器保存的是以用户名，realm，密码为基础计算出的哈希值（ha1），而非密码本身。
 3. 如果qop=auth-int，在计算ha2时，除了包括HTTP方法，URI路径外，还包括请求实体主体，从而防止PUT和POST请求表示被人篡改。
 4. 但是因为nonce本身可以被用来进行摘要认证，所以也无法确保认证后传递过来的数据的安全性。

`※　nonce：随机字符串，每次返回401响应的时候都会返回一个不同的nonce。`  
`※　nounce：随机字符串，每个请求都得到一个不同的nounce。`  
  ※　MD5(Message Digest algorithm 5，信息摘要算法)  
 ① 用户名:realm:密码　⇒　ha1  
 ② HTTP方法:URI　⇒　ha2  
 ③ ha1:nonce:nc:cnonce:qop:ha2　⇒　ha3

## **◆ WSSE(WS-Security)认证　　←　扩展HTTP认证**

   WSSE UsernameToken

服务器端以nonce进行质询，客户端以用户名，密码，nonce，HTTP方法，请求的URI等信息为基础产生的response信息进行认证的方式。

※　不包含密码的明文传递

**WSSE认证步骤：**

 1、客户端访问一个受 WSSE 认证保护的资源。  
 2、服务器返回401状态，要求客户端进行认证。

HTTP/1.1 401 Unauthorized  
WWW-Authenticate: **WSSE**  
realm="testrealm@host.com",  
profile="UsernameToken" ←　服务器期望你用UsernameToken规则生成回应

※　UsernameToken规则：客户端生成一个nonce，然后根据该nonce，密码和当前日时来算出哈希值。

 3、客户端将生成一个 nonce 值，并以该 nonce 值，密码，当前日时为基础，算出哈希值返回给服务器。

Authorization: **WSSE** profile="UsernameToken"  
X-WSSE:UsernameToken  
username="Mufasa",  
PasswordDigest="Z2Y……",  
Nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093",  
Created="2010-01-01T09:00:00Z"

 4、如果认证成功，则返回相应的资源。如果认证失败，则仍返回401状态，要求重新进行认证。

**特记事项：**

 1. 避免将密码作为明文在网络上传递。
 2. 不需要在服务器端作设置。
 3. 服务器端必须保存密码本身，否则无法进行身份验证。