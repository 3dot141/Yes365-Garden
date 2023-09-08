---
aliases: []
created_date: 2023-08-31 18:18
draft: false
summary: ''
tags:
- dev
---

> 遇到一个转发、重定向的问题。加固一下自己的理解

## 定义

Forward（转发）的定义和特点：

- Forward 是服务器端的一种行为，服务器接收到请求后，将请求转发给另一个资源进行处理，然后将响应返回给客户端。
- 在 Forward 过程中，客户端是不知道请求被转发到了其他资源，它仅与初始请求的 URL 交互。
- Forward 通常在同一个服务器内部进行，可以是在不同的 Servlet 或 JSP 之间进行转发。
- Forward 保持了原始请求的属性（如请求参数、请求头等），在转发过程中共享这些信息，因此可以在多个资源之间共享数据。

Redirect（重定向）的定义和特点：

- Redirect 是服务器端的一种行为，服务器接收到请求后，返回一个特殊的响应状态码（通常是 302 Found）和一个新的 URL，告诉客户端将请求重定向到该新的 URL。
- 在收到重定向响应后，客户端会自动发送一个新的请求到新的 URL，从而完成页面的跳转。
- Redirect 可以在不同的服务器之间进行，因为它是通过向客户端发送响应来实现的。
- Redirect 不会保持原始请求的属性，因为它是实际上重新发送了一个新的请求。

区别总结：

- Forward 是服务器内部的行为，不会告诉客户端请求是否被转发，而 Redirect 是通过向客户端发送响应来告诉客户端请求要重定向到新的 URL。
- Forward 不会改变客户端的 URL，而 Redirect 会将客户端的 URL 改变为新的 URL。
- Forward 可以在相同服务器内的不同资源之间进行，而 Redirect 可以在不同服务器之间进行。
- Forward 保持了原始请求的属性，而 Redirect 不保持原始请求的属性。

在实际应用中，选择 Forward 还是 Redirect 取决于具体的需求和场景。Forward 适用于在服务器内部资源之间共享数据和处理请求，而 Redirect 适用于需要将请求重定向到不同的 URL 或服务器的情况，例如页面跳转或身份验证。

## Tomcat 源码

### Forward

- ApplicationDispatcher.forward(ServletRequest, ServletResponse) (org.apache.catalina.core)
	- ApplicationDispatcher.doForward(ServletRequest, ServletResponse)(2 usages) (org.apache.catalina.core)
		- ApplicationDispatcher.processRequest(ServletRequest, ServletResponse, State) (org.apache.catalina.core)

```java file:processRequest
state.outerRequest.setAttribute(
                            Globals.DISPATCHER_REQUEST_PATH_ATTR,
                            getCombinedPath());
                    state.outerRequest.setAttribute(
                            Globals.DISPATCHER_TYPE_ATTR,
                            DispatcherType.FORWARD);
                    invoke(state.outerRequest, response, state);
```

### include

`include` 和 `forward` 是在 Servlet 中用于请求转发的两种不同方式。它们之间有以下区别：

1. 行为：
    - `include`：将另一个 Servlet 的响应包含到当前 Servlet 的响应中，然后将合并后的响应一起发送给客户端。当前 Servlet 的执行会继续，但响应的内容会增加。
    - `forward`：直接将请求转发给另一个 Servlet 进行处理，并将该 Servlet 的响应作为最终响应返回给客户端。当前 Servlet 的执行会终止，不会继续执行。
2. 客户端可见性：
    - `include`：客户端不知道请求被包含到了其他 Servlet，它只会接收到最终合并后的响应结果。
    - `forward`：客户端是不知道请求被转发到了其他 Servlet 的，它只会接收到转发到的 Servlet 的响应。
3. 请求属性：
    - `include`：在请求被包含到其他 Servlet 时，可以共享请求属性（如参数、属性等）。
    - `forward`：在请求被转发到其他 Servlet 时，可以共享请求属性。
4. URL 和路径：
    - `include`：URL 不会改变，客户端仍然看到的是原始请求的 URL。
    - `forward`：URL 会改变为转发目标 Servlet 的 URL。
5. 控制权：
    - `include`：当前 Servlet 保持控制权，它会继续执行并发送响应。
    - `forward`：控制权转移到目标 Servlet，当前 Servlet 的执行终止。

选择使用 `include` 还是 `forward` 取决于具体的需求和场景。一般来说：
- 如果需要将多个 Servlet 的输出合并成一个响应，并保持当前 Servlet 的控制权，可以使用 `include`。
- 如果需要将请求完全转发给另一个 Servlet 进行处理，并且不需要继续执行当前 Servlet，可以使用 `forward`。

### Forward vs Include

```java file:forward
        try {
	        // 清空缓存
            response.resetBuffer();
        } catch (IllegalStateException e) {
            throw e;
        }

        // Set up to handle the specified request and response
        State state = new State(request, response, false);

        if (WRAP_SAME_OBJECT) {
            // Check SRV.8.2 / SRV.14.2.5.1 compliance
            checkSameObjects(request, response);
        }

        wrapResponse(state);
        // Handle an HTTP named dispatcher forward
        if ((servletPath == null) && (pathInfo == null)) {

            ApplicationHttpRequest wrequest =
                (ApplicationHttpRequest) wrapRequest(state);
            HttpServletRequest hrequest = state.hrequest;
            wrequest.setRequestURI(hrequest.getRequestURI());
            wrequest.setContextPath(hrequest.getContextPath());
            wrequest.setServletPath(hrequest.getServletPath());
            wrequest.setPathInfo(hrequest.getPathInfo());
            wrequest.setQueryString(hrequest.getQueryString());
			
			// 传入原生的响应
            processRequest(request,response,state);
        }
```

```java file:include
        // Set up to handle the specified request and response
        State state = new State(request, response, true);

        if (WRAP_SAME_OBJECT) {
            // Check SRV.8.2 / SRV.14.2.5.1 compliance
            checkSameObjects(request, response);
        }

        // Create a wrapped response to use for this request
        wrapResponse(state);

        // Handle an HTTP named dispatcher include
        if (name != null) {

            ApplicationHttpRequest wrequest = (ApplicationHttpRequest) wrapRequest(state);
            wrequest.setAttribute(Globals.NAMED_DISPATCHER_ATTR, name);
            if (servletPath != null) {
                wrequest.setServletPath(servletPath);
            }
            wrequest.setAttribute(Globals.DISPATCHER_TYPE_ATTR, DispatcherType.INCLUDE);
            wrequest.setAttribute(Globals.DISPATCHER_REQUEST_PATH_ATTR, getCombinedPath());
		    
		    // 直接传递包装后的 request, response, 从而让本地的 req,res 依然可以继续响应。
            invoke(state.outerRequest, state.outerResponse, state);

```

### Redirect

#### 说明

> [307 Temporary Redirect - HTTP | MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/307)

[HTTP](https://developer.mozilla.org/en-US/docs/Glossary/HTTP) **`307 Temporary Redirect`** redirect status response code indicates that the resource requested has been temporarily moved to the URL given by the [`Location`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Location) headers.  
HTTP `307 Temporary Redirect` 重定向状态响应代码表示请求的资源已暂时移动到 `Location` 标头指定的 URL。

The method and the body of the original request are reused to perform the redirected request. In the cases where you want the method used to be changed to [`GET`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/GET), use [`303 See Other`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/303) instead. This is useful when you want to give an answer to a [`PUT`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/PUT) method that is not the uploaded resources, but a confirmation message (like "You successfully uploaded XYZ").  
原始请求的方法和正文被重用来执行重定向的请求。如果您希望将所使用的方法更改为 `GET` ，请改用 `303 See Other` 。当您想要给 `PUT` 方法提供一个答案，该答案不是上传的资源，而是一条确认消息（例如“您已成功上传 XYZ”）时，这非常有用。

The only difference between `307` and [`302`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/302) is that `307` guarantees that the method and the body will not be changed when the redirected request is made. With `302`, some old clients were incorrectly changing the method to [`GET`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/GET): the behavior with non-`GET` methods and `302` is then unpredictable on the Web, whereas the behavior with `307` is predictable. For `GET` requests, their behavior is identical.  
`307` 和 `302` 之间的唯一区别是 `307` 保证在发出重定向请求时方法和正文不会改变。对于 `302` ，一些旧客户端错误地将方法更改为 `GET` ：非 `GET` 方法和 `302` 的行为是不可预测的在网络上，而 `307` 的行为是可以预测的。对于 `GET` 请求，它们的行为是相同的。

#### 源码

```java

    public void sendRedirect(String location, int status) throws IOException {
        if (isCommitted()) {
            throw new IllegalStateException(sm.getString("coyoteResponse.sendRedirect.ise"));
        }

        // Ignore any call from an included servlet
        if (included) {
            return;
        }

		// 重置缓存
        // Clear any data content that has been buffered
        resetBuffer(true);

        // Generate a temporary redirect to the specified location
        try {
            String locationUri;
            // Relative redirects require HTTP/1.1
            if (getRequest().getCoyoteRequest().getSupportsRelativeRedirects() &&
                    getContext().getUseRelativeRedirects()) {
                locationUri = location;
            } else {
                locationUri = toAbsolute(location);
            }

			// 设置状态码
            setStatus(status);
			// 设置重定向的位置
            setHeader("Location", locationUri);
            if (getContext().getSendRedirectBody()) {
                PrintWriter writer = getWriter();
                writer.print(sm.getString("coyoteResponse.sendRedirect.note",
                        Escape.htmlElementContent(locationUri)));
                flushBuffer();
            }
        } catch (IllegalArgumentException e) {
            log.warn(sm.getString("response.sendRedirectFail", location), e);
            setStatus(SC_NOT_FOUND);
        }

        // Cause the response to be finished (from the application perspective)
        setSuspended(true);
    }

```