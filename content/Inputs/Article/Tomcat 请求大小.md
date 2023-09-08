---
aliases: []
created_date: 2023-08-29 19:45
draft: false
summary: ''
tags:
- dev
---

> keyword: request 

## GET 请求

设置 Tomcat 的 server.xml。找到我们启动的端口，通常是8080，增加 maxHttpHeaderSize="102400"，值可以根据自身情况进行配置。

## POST 请求

与 get 相同，找到端口，配置 maxPostSize=-1 取消对 post 的限制。在 Tomcat 7.0.63之前，设置为 0或 -1，在7.0.63之后的版本中，设置为负数表示不限制。

### 注意

#### 绕过 Post 限制

However, since Servlet 3.0, if your application requires large file uploads, consider posting them as `multipart/form-data` and use the `@MultipartConfig` annotation (cf. [Jakarta EE tutorial](https://eclipse-ee4j.github.io/jakartaee-tutorial/#uploading-files-with-jakarta-servlet-technology)). The request parameters transmitted as files **do not count** towards the `maxPostSize` limit and are written to a temporary file whenever they are larger than a configurable limit.  
但是，从 Servlet 3.0 开始，如果您的应用程序需要上传大文件，请考虑将它们发布为 `multipart/form-data` 并使用 `@MultipartConfig` 注释（参见 Jakarta EE 教程）。作为文件传输的请求参数不计入 `maxPostSize` 限制，只要它们大于可配置的限制，就会写入临时文件。

Therefore you might approximately consider `maxPostSize` as the maximum heap memory required to store the parameters of a request.  
因此，您可以大致将 `maxPostSize` 视为存储请求参数所需的最大堆内存。

## 源码

`org.apache.catalina.connector.Request#parseParameters`

```java
	int maxPostSize = connector.getMaxPostSize();
	if ((maxPostSize >= 0) && (len > maxPostSize)) {
		Context context = getContext();
		// 这里可以看出来，只有开启 debug, 才能正常输出日志
		if (context != null && context.getLogger().isDebugEnabled()) {
			context.getLogger().debug(
					sm.getString("coyoteRequest.postTooLarge"));
		}
		checkSwallowInput();
		parameters.setParseFailedReason(FailReason.POST_TOO_LARGE);
		return;
	}
```

可以通过 `org.apache.catalina.connector.Request#getAttribute`  
然后传入

- `org.apache.catalina.Globals#PARAMETER_PARSE_FAILED_ATTR`
	- ![515](Attachments/f276355eb6a1cd9cfb02b753b894b1ea_MD5.png)
- `org.apache.catalina.Globals#PARAMETER_PARSE_FAILED_REASON_ATTR`
	- ![525](Attachments/067925b67ec1705c52bec1f62ede7928_MD5.png)

获取真实的原因

## Spring 请求大小配置

```
#文件请求大小
spring.server.MaxFileSize=300MB
spring.server.MaxRequestSize=500MB

spring.http.multipart.maxFileSize=10Mb
spring.http.multipart.maxRequestSize=10Mb
```