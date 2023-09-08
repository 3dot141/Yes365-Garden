---
aliases: []
created_date: 2023-08-24 14:49
draft: false
summary: ''
tags:
- dev
---

## 方案

通过 [WebSocket 的四种构建方式#第二种方式 Spring 方式](WebSocket%20的四种构建方式.md#第二种方式%20Spring%20方式)  
搭建 websocket 和 http 的服务器。

**结论**：在 tomcat 中可以通过一个端口正常访问 websocket 和 http 服务

## 原理

```java file:WsFilter

// 首先判断 tomcat 是否配置。
// 是则继续判断请求是否要升级 
        if (!sc.areEndpointsRegistered() || !UpgradeUtil.isWebSocketUpgradeRequest(request, response)) {
            chain.doFilter(request, response);
            return;
        }
```

走到 spring 的 `DispatcherServlet` 中

```java
				// Determine handler adapter for the current request.
				HandlerAdapter ha = getHandlerAdapter(mappedHandler.getHandler());

				// Process last-modified header, if supported by the handler.
				String method = request.getMethod();
				boolean isGet = HttpMethod.GET.matches(method);
				if (isGet || HttpMethod.HEAD.matches(method)) {
					long lastModified = ha.getLastModified(request, mappedHandler.getHandler());
					if (new ServletWebRequest(request, response).checkNotModified(lastModified) && isGet) {
						return;
					}
				}

				if (!mappedHandler.applyPreHandle(processedRequest, response)) {
					return;
				}

				// Actually invoke the handler.
				mv = ha.handle(processedRequest, response, mappedHandler.getHandler());
```

然后获取到注册的 `WebServletHandler` 从而走到对应的 `controller` 中。

## 结论

所以在同一个服务上， 比如都使用 tomcat 或者 spring， http 和 websocket 是完全可以共存的。  
不同服务上， 比如 spring 和 netty, 就完全不符合共存的逻辑。因为他们两都是服务。