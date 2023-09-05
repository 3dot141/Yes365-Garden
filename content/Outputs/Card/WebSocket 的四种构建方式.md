---
aliases: []
created_date: 2023-08-25 16:00
draft: false
summary: ''
tags:
- dev
---

![](../../Attachments/81ce9641c12e6d29beb30f294c943aaa_MD5.jpg)

在上家公司做IM消息系统的时候，一直是使用 WebSocket 作为收发消息的基础组件，今天就和大家聊聊在 Java 中，使用 WebSocket 所常见的四种姿势，如果大家以后或者现在碰到有要使用 WebSoocket 的情况可以做个参考。

![](../../Attachments/cb4ffbfcbdd7d251e56e4fce9788fdaf_MD5.jpg)

上面的思维导图已经给大家列出了三种使用 WebSocket 的方式，下文会对它们的特点进行一一解读，不同的方式具有不同的特点，我们先按下不表。  
在这里，我想让大家思考一下我在思维导图中列举的第四种做 WebScoket 支持的方案可能是什么？不知道大家能不能猜对，后文将会给出答案。  

* * *

本文代码：以下仓库中 spring-websocket 模块，拉整个仓库下来后可在 IDEA Maven 工具栏中单独编译此模块。  

- [Github](https://link.zhihu.com/?target=https%3A//link.juejin.cn/%3Ftarget%3Dhttps%253A%252F%252Fgithub.com%252Frookie-ricardo%252Fspring-boot-learning-demo)
- [Gitee](https://link.zhihu.com/?target=https%3A//link.juejin.cn/%3Ftarget%3Dhttps%253A%252F%252Fgitee.com%252Fhe-erduo%252Fspring-boot-learning-demo)

WS简介  
在正式开始之前，我觉得有必要简单介绍一下 WebSocket 协议，引入任何一个东西之前都有必要知道我们为什么需要它？  
在 Web 开发领域，我们最常用的协议是 HTTP，HTTP 协议和 WS 协议都是基于 TCP 所做的封装，但是 HTTP 协议从一开始便被设计成请求 -> 响应的模式，所以在很长一段时间内 HTTP 都是只能从客户端发向服务端，并不具备从服务端主动推送消息的功能，这也导致在浏览器端想要做到服务器主动推送的效果只能用一些轮询和长轮询的方案来做，但因为它们并不是真正的全双工，所以在消耗资源多的同时，实时性也没理想中那么好。  
既然市场有需求，那肯定也会有对应的新技术出现，WebSocket 就是这样的背景下被开发与制定出来的，并且它作为 HTML5 规范的一部分，得到了所有主流浏览器的支持，同时它还兼容了 HTTP 协议，默认使用 HTTP 的80端口和443端口，同时使用 HTTP header 进行协议升级。  
和 HTTP 相比，WS 至少有以下几个优点：  

1. 使用的资源更少：因为它的头更小。
2. 实时性更强：服务端可以通过连接主动向客户端推送消息。
3. 有状态：开启链接之后可以不用每次都携带状态信息。

除了这几个优点以外，我觉得对于 WS 我们开发人员起码还要了解它的握手过程和协议帧的意义，这就像学习 TCP 的时候需要了解 TCP 头每个字节帧对应的意义一样。  
像握手过程我就不说了，因为它复用了 HTTP 头只需要在[维基百科](https://link.zhihu.com/?target=https%3A//link.juejin.cn/%3Ftarget%3Dhttps%253A%252F%252Fzh.wikipedia.org%252Fwiki%252FWebSocket)（阮一峰的文章讲的也很明白）上面看一下就明白了，像协议帧的话无非就是：标识符、操作符、数据、数据长度这些协议通用帧，基本都没有深入了解的必要，我认为一般只需要关心 WS 的操作符就可以了。  
WS 的操作符代表了 WS 的消息类型，它的消息类型主要有如下六种：  

1. **文本消息**
2. **二进制消息**
3. **分片消息**（分片消息代表此消息是一个某个消息中的一部分，想想大文件分片）
4. **连接关闭消息**
5. **PING 消息**
6. **PONG 消息**（PING的回复就是PONG）

那我们既然知道了 WS 主要有以上六种操作，那么一个正常的 WS 框架应当可以很轻松的处理以上这几种消息，所以接下来就是本文的中心内容，看看以下这几种 WS 框架能不能很方便的处理这几种 WS 消息。  

## 第一种方式: J2EE 方式  

先来 J2EE，一般我把 javax 包里面对 JavaWeb 的扩展都叫做 J2EE，这个定义是否完全正确我觉得没必要深究，只是一种个人习惯，而本章节所介绍的 J2EE 方式则是指 Tomcat 为 WS 所做的支持，这套代码的包名前缀叫做：javax.websocket。  
这套代码中定义了一套适用于 WS 开发的注解和相关支持，我们可以利用它和 Tomcat 进行WS 开发，由于现在更多的都是使用 SpringBoot 的内嵌容器了，所以这次我们就来按照 SpringBoot 内嵌容器的方式来演示。  
首先是引入 SpringBoot - Web 的依赖，因为这个依赖中引入了内嵌式容器 Tomcat：

```text
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
```

接着就是将一个类定义为 WS 服务器，这一步也很简单，只需要为这个类加上`@ServerEndpoint`注解就可以了，在这个注解中比较常用的有三个参数：WS路径、序列化处理类、反序列化处理类。

```text
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.TYPE})
public @interface ServerEndpoint {
    String value();

    String[] subprotocols() default {};

    Class<? extends Decoder>[] decoders() default {};

    Class<? extends Encoder>[] encoders() default {};

    Class<? extends Configurator> configurator() default Configurator.class;
}

```

接下来我们来看具体的一个 WS 服务器类示例：

```text
@Component
@ServerEndpoint("/j2ee-ws/{msg}")
public class WebSocketServer {

    //建立连接成功调用
    @OnOpen
    public void onOpen(Session session, @PathParam(value = "msg") String msg){
        System.out.println("WebSocketServer 收到连接: " + session.getId() + ", 当前消息：" + msg);
    }

    //收到客户端信息
    @OnMessage
    public void onMessage(Session session, String message) throws IOException {
        message = "WebSocketServer 收到连接：" + session.getId() +  "，已收到消息：" + message;
        System.out.println(message);
        session.getBasicRemote().sendText(message);
    }

    //连接关闭
    @OnClose
    public void onclose(Session session){
        System.out.println("连接关闭");
    }

}

```

在以上代码中，我们着重关心 WS 相关的注解，主要有以下四个：  

1. `@ServerEndpoint` ： 这里就像 RequestMapping 一样，放入一个 WS 服务器监听的 URL。
2. `@OnOpen` ：这个注解修饰的方法会在 WS 连接开始时执行。
3. `@OnClose` ：这个注解修饰的方法则会在 WS 关闭时执行。
4. `@OnMessage` ：这个注解则是修饰消息接受的方法，并且由于消息有文本和二进制两种方式，所以此方法参数上可以使用 String 或者二进制数组的方式，就像下面这样：

```text
    @OnMessage
    public void onMessage(Session session, String message) throws IOException {

    }

    @OnMessage
    public void onMessage(Session session, byte[] message) throws IOException {

    }

```

除了以上这几个以外，常用的功能方面还差一个分片消息、Ping 消息 和 Pong 消息，对于这三个功能我并没有查到相关用法，只在源码的接口列表中看到了一个 PongMessage 接口，有知道的读者朋友们有知道的可以在评论区指出。  
细心的小伙伴们可能发现了，示例中的 WebSocketServer 类还有一个 `@Component 注解`，这是由于我们使用的是内嵌容器，而内嵌容器需要被 Spring 管理并初始化，所以需要给 WebSocketServer 类加上这么一个注解，所以代码中还需要有这么一个配置：

```text
@Configuration
public class WebSocketConfig {

    @Bean
    public ServerEndpointExporter serverEndpointExporter() {
        return new ServerEndpointExporter();
    }
}

```

**Tips**：在不使用内嵌容器的时候可以不做以上步骤。

最后上个简陋的 WS 效果示例图，前端方面直接使用 HTML5 的 WebScoket 标准库，具体可以查看我的仓库代码：

![](../../Attachments/a7437638248c8192536f217ec821ff0d_MD5.jpg)

## 第二种方式: **Spring 方式**  

> 参考 [Getting Started | Using WebSocket to build an interactive web application](https://spring.io/guides/gs/messaging-stomp-websocket/)

第二部分来说 Spring 方式，Spring 作为 Java 开发界的老大哥，几乎封装了一切可以封装的，对于 WS 开发呢 Spring 也提供了一套相关支持，而且从使用方面我觉得要比 J2EE 的更易用。  
使用它的第一步我们先引入 `SpringBoot - WS` 依赖，这个依赖包也会隐式依赖 SpringBoot - Web 包：

```text
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-websocket</artifactId>
        </dependency>

```

第二步就是准备一个用来处理 WS 请求的 Handle了，Spring 为此提供了一个接口—— WebSocketHandler，我们可以通过实现此接口重写其接口方法的方式自定义逻辑，我们来看一个例子：

```text
@Component
public class SpringSocketHandle implements WebSocketHandler {

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        System.out.println("SpringSocketHandle, 收到新的连接: " + session.getId());
    }

    @Override
    public void handleMessage(WebSocketSession session, WebSocketMessage<?> message) throws Exception {
        String msg = "SpringSocketHandle, 连接：" + session.getId() +  "，已收到消息。";
        System.out.println(msg);
        session.sendMessage(new TextMessage(msg));
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
        System.out.println("WS 连接发生错误");
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus closeStatus) throws Exception {
        System.out.println("WS 关闭连接");
    }

    // 支持分片消息
    @Override
    public boolean supportsPartialMessages() {
        return false;
    }
}

```

上面这个例子很好的展示了 WebSocketHandler 接口中的五个函数，通过名字我们就应该知道它具有什么功能了：  

1. **afterConnectionEstablished**：连接成功后调用。
2. **handleMessage**：处理发送来的消息。
3. **handleTransportError：** WS 连接出错时调用。
4. **afterConnectionClosed**：连接关闭后调用。
5. **supportsPartialMessages**：是否支持分片消息。

以上这几个方法重点可以来看一下 handleMessage 方法，handleMessage 方法中有一个 `WebSocketMessage` 参数，这也是一个接口，我们一般不直接使用这个接口而是使用它的实现类，它有以下几个实现类：  

1. **BinaryMessage**：二进制消息体
2. **TextMessage**：文本消息体
3. **PingMessage：** Ping ****消息体
4. **PongMessage：** Pong ****消息体

但是由于 `handleMessage` 这个方法参数是`WebSocketMessage`，所以我们实际使用中可能需要判断一下当前来的消息具体是它的哪个子类，比如这样：

```text
    public void handleMessage(WebSocketSession session, WebSocketMessage<?> message) throws Exception {
        if (message instanceof TextMessage) {
            this.handleTextMessage(session, (TextMessage)message);
        } else if (message instanceof BinaryMessage) {
            this.handleBinaryMessage(session, (BinaryMessage)message);
        }
    }

```

但是总这样写也不是个事，为了避免这些重复性代码，Spring 给我们定义了一个`AbstractWebSocketHandler`，它已经封装了这些重复劳动，我们可以直接继承这个类然后重写我们想要处理的消息类型：

```text
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
    }

    protected void handleBinaryMessage(WebSocketSession session, BinaryMessage message) throws Exception {
    }

    protected void handlePongMessage(WebSocketSession session, PongMessage message) throws Exception {
    }

```

上面这部分都是对于 Handle 的操作，有了 Handle 之后我们还需要将它绑定在某个 URL 上，或者说监听某个 URL，那么必不可少的需要以下配置：

```text
@Configuration
@EnableWebSocket
public class SpringSocketConfig implements WebSocketConfigurer {

    @Autowired
    private SpringSocketHandle springSocketHandle;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(springSocketHandle, "/spring-ws").setAllowedOrigins("*");
    }
}

```

这里我把我的自定义 Handle 注册到 `"/spring-ws"` 上面并设置了一下跨域，在整个配置类上还要打上`@EnableWebSocket` 注解，用于开启 WS 监听。  
Spring 的方式也就以上这些内容了，不知道大家是否感觉 Spring 所提供的 WS 封装要比 J2EE 的更方便也更全面一些，起码我只要看 **WebSocketHandler** 接口就能知道所有常用功能的用法，所以对于 WS 开发来说我是比较推荐 Spring 方式的。  
最后上个简陋的 WS 效果示例图，前端方面直接使用 HTML5 的 WebScoket 标准库，具体可以查看我的仓库代码：

![](../../Attachments/d2abe75477d68301626add3c61b9c70d_MD5.jpg)

## 第三种方式：SocketIO 方式  

SocketIO 方式和上面两种有点不太一样，因为 SocketIO 诞生初就是为了兼容性作为考量的，前端的读者们应该对它更熟悉，因为它是一个 JS 库，我们先来看一下维基百科对它的定义：  
[http://Socket.IO](https://link.zhihu.com/?target=http%3A//Socket.IO) 是一个面向实时 web 应用的 JavaScript 库。它使得服务器和客户端之间实时双向的通信成为可能。他有两个部分：在浏览器中运行的客户端库，和一个面向Node.js的服务端库，两者有着几乎一样的API。  
[http://Socket.IO](https://link.zhihu.com/?target=http%3A//Socket.IO) 主要使用WebSocket协议。但是如果需要的话，[http://Socket.io](https://link.zhihu.com/?target=http%3A//Socket.io)可以回退到几种其它方法，例如Adobe Flash Sockets，JSONP拉取，或是传统的AJAX拉取，并且在同时提供完全相同的接口。  
所以我觉得使用它更多是因为兼容性，因为 HTML5 之后原生的 WS 应该也够用了，然而它是一个前端库，所以 Java 语言这块并没有官方支持，好在民间大神已经以 Netty 为基础开发了能与它对接的 Java 库： `netty-socketio`。  
不过我要先给大家提个醒，不再建议使用它了，不是因为它很久没更新了，而是因为它支持的 Socket-Client 版本太老了，截止到 2022-04-29 日，SocketIO 已经更新到 4.X 了，但是 NettySocketIO 还只支持 2.X 的 Socket-Client 版本。  
说了这么多，该教大家如何使用它了，第一步还是引入最新的依赖：

```text
        <dependency>
            <groupId>com.corundumstudio.socketio</groupId>
            <artifactId>netty-socketio</artifactId>
            <version>1.7.19</version>
        </dependency>

```

第二步就是配置一个 WS 服务：

```text
@Configuration
public class SocketIoConfig {

    @Bean
    public SocketIOServer socketIOServer() {
        com.corundumstudio.socketio.Configuration config = new com.corundumstudio.socketio.Configuration();

        config.setHostname("127.0.0.1");
        config.setPort(8001);
        config.setContext("/socketio-ws");
        SocketIOServer server = new SocketIOServer(config);
        server.start();
        return server;
    }

    @Bean
    public SpringAnnotationScanner springAnnotationScanner() {
        return new SpringAnnotationScanner(socketIOServer());
    }
}

```

大家在上文的配置中，可以看到设置了一些 Web 服务器参数，比如：端口号和监听的 path，并将这个服务启动起来，服务启动之后日志上会打印这样一句日志：

```text
[ntLoopGroup-2-1] c.c.socketio.SocketIOServer : SocketIO server started at port: 8001

```

这就代表启动成功了，接下来就是要对 WS 消息做一些处理了：

```text
@Component
public class SocketIoHandle {

    /**
     * 客户端连上socket服务器时执行此事件
     * @param client
     */
    @OnConnect
    public void onConnect(SocketIOClient client) {
        System.out.println("SocketIoHandle 收到连接：" + client.getSessionId());
    }

    /**
     * 客户端断开socket服务器时执行此事件
     * @param client
     */
    @OnDisconnect
    public void onDisconnect(SocketIOClient client) {
        System.out.println("当前链接关闭：" + client.getSessionId());
    }

    @OnEvent( value = "onMsg")
    public void onMessage(SocketIOClient client, AckRequest request, Object data) {
        System.out.println("SocketIoHandle 收到消息：" + data);
        request.isAckRequested();
        client.sendEvent("chatMsg", "我是 NettySocketIO 后端服务，已收到连接：" + client.getSessionId());
    }
}

```

我相信对于以上代码，前两个方法是很好懂的，但是对于第三个方法如果大家没有接触过 SocketIO 就比较难理解了，为什么`@OnEvent( value = "onMsg")`里面这个值是自定义的，这就涉及到 SocketIO 里面发消息的机制了，通过 SocketIO 发消息是要发给某个事件的，所以这里的第三个方法就是监听 发给`onMsg`事件的所有消息，监听到之后我又给客户端发了一条消息，这次发给的事件是：`chatMsg`，客户端也需要监听此事件才能接收到这条消息。  
最后再上一个简陋的效果图：

![](../../Attachments/f03c50694e2a482233dc2dc57e8f6174_MD5.jpg)

由于前端代码不再是标准的 HTML5 的连接方式，所以我这里简要贴一下相关代码，具体更多内容可以看我的代码仓库：

```text
    function changeSocketStatus() {
        let element = document.getElementById("socketStatus");
        if (socketStatus) {
            element.textContent = "关闭WebSocket";
            const socketUrl="ws://127.0.0.1:8001";
            socket = io.connect(socketUrl, {
                transports: ['websocket'],
                path: "/socketio-ws"
            });
            //打开事件
            socket.on('connect', () => {
                console.log("websocket已打开");
            });
            //获得消息事件
            socket.on('chatMsg', (msg) => {
                const serverMsg = "收到服务端信息：" + msg;
                pushContent(serverMsg, 2);
            });
            //关闭事件
            socket.on('disconnect', () => {
                console.log("websocket已关闭");
            });
            //发生了错误事件
            socket.on('connect_error', () => {
                console.log("websocket发生了错误");
            })
        }
    }

```

## 第四种方式: netty

第四种方式其实就是 Netty 了，Netty 作为 Java 界大名鼎鼎的开发组件，对于常见协议也全部进行了封装，所以我们可以直接在 Netty 中去很方便的使用 WebSocket，接下来我们可以看看 Netty 怎么作为 WS 的服务器进行开发。  
注意：以下内容如果没有 Netty 基础可能一脸蒙的进，一脸蒙的出，不过还是建议大家看看，Netty 其实很简单。  
第一步需要先引入一个 Netty 开发包，我这里为了方便一般都是 All In：

```text
        <dependency>
            <groupId>io.netty</groupId>
            <artifactId>netty-all</artifactId>
            <version>4.1.75.Final</version>
        </dependency>

```

第二步的话就需要启动一个 Netty 容器了，配置很多，但是比较关键的也就那几个：

```text
public class WebSocketNettServer {
    public static void main(String[] args) {

        NioEventLoopGroup boss = new NioEventLoopGroup(1);
        NioEventLoopGroup work = new NioEventLoopGroup();

        try {
            ServerBootstrap bootstrap = new ServerBootstrap();
            bootstrap
                    .group(boss, work)
                    .channel(NioServerSocketChannel.class)
                    //设置保持活动连接状态
                    .childOption(ChannelOption.SO_KEEPALIVE, true)
                    .localAddress(8080)
                    .handler(new LoggingHandler(LogLevel.DEBUG))
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) throws Exception {
                            ch.pipeline()
                                    // HTTP 请求解码和响应编码
                                    .addLast(new HttpServerCodec())
                                    // HTTP 压缩支持
                                    .addLast(new HttpContentCompressor())
                                    // HTTP 对象聚合完整对象
                                    .addLast(new HttpObjectAggregator(65536))
                                    // WebSocket支持
                                    .addLast(new WebSocketServerProtocolHandler("/ws"))
                                    .addLast(WsTextInBoundHandle.INSTANCE);
                        }
                    });

            //绑定端口号，启动服务端
            ChannelFuture channelFuture = bootstrap.bind().sync();
            System.out.println("WebSocketNettServer启动成功");

            //对关闭通道进行监听
            channelFuture.channel().closeFuture().sync();

        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            boss.shutdownGracefully().syncUninterruptibly();
            work.shutdownGracefully().syncUninterruptibly();
        }

    }
}

```

以上代码我们主要关心端口号和重写的 `ChannelInitializer` 就行了，里面我们定义了五个过滤器（Netty 使用责任链模式），前面三个都是 HTTP 请求的常用过滤器（毕竟 WS 握手是使用 HTTP 头的所以也要配置 HTTP 支持），第四个则是 WS 的支持，它会拦截 `/ws` 路径，最关键的就是第五个了过滤器它是我们具体的业务逻辑处理类，效果基本和 Spring 那部门中的 Handle 差不多，我们来看看代码：

```text
@ChannelHandler.Sharable
public class WsTextInBoundHandle extends SimpleChannelInboundHandler<TextWebSocketFrame> {

    private WsTextInBoundHandle() {
        super();
        System.out.println("初始化 WsTextInBoundHandle");
    }

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        System.out.println("WsTextInBoundHandle 收到了连接");
    }

    @Override
    protected void channelRead0(ChannelHandlerContext ctx, TextWebSocketFrame msg) throws Exception {

        String str = "WsTextInBoundHandle 收到了一条消息, 内容为：" + msg.text();

        System.out.println(str);

        System.out.println("-----------WsTextInBoundHandle 处理业务逻辑-----------");

        String responseStr = "{"status":200, "content":"收到"}";

        ctx.channel().writeAndFlush(new TextWebSocketFrame(responseStr));
        System.out.println("-----------WsTextInBoundHandle 数据回复完毕-----------");
    }

    @Override
    public void channelReadComplete(ChannelHandlerContext ctx) throws Exception {

        System.out.println("WsTextInBoundHandle 消息收到完毕");
        ctx.flush();
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        System.out.println("WsTextInBoundHandle 连接逻辑中发生了异常");
        cause.printStackTrace();
        ctx.close();
    }
}

```

这里面的方法我都不说了，看名字就差不多知道了，主要是看一下这个类的泛型：**TextWebSocketFrame**，很明显这是一个 WS 文本消息的类，我们顺着它的定义去看发现它继承了**WebSocketFrame**，接着我们去看它的子类：

![](../../Attachments/2db5e464840d3f6a145595519cb9facd_MD5.jpg)

一图胜千言，我想不用多说大家也都知道具体的类是处理什么消息了把，在上文的示例中我们是一定了一个文本 WS 消息的处理类，如果你想处理其他数据类型的消息，可以将泛型中的 **TextWebSocketFrame** 换成其他 **WebSocketFrame** 类就可以了 **。**  
至于为什么没有连接成功后的处理，这个是和 Netty 的相关机制有关，可以在 **channelActive** 方法中处理，大家有兴趣的可以了解一下 Netty。  
最后上个简陋的 WS 效果示例图，前端方面直接使用 HTML5 的 WebScoket 标准库，具体可以查看我的仓库代码：

![](../../Attachments/e36ae7f4e5d5d1633456e16c5c5e8472_MD5.jpg)

总结
--

**洋洋洒洒五千字，有了收获别忘赞。**  
在上文中，我总共介绍了四种在 Java 中使用 WS 的方式，从我个人使用意向来说我感觉应该是这样的：`Spring 方式 > Netty 方式 > J2EE 方式 > SocketIO 方式`，当然了，如果你的业务存在浏览器兼容性问题，其实只有一种选择：SocketIO。  
最后，我估计某些读者会去具体拉代码看代码，所以我简单说一下代码结构：

```text
├─java
│  └─com
│      └─example
│          └─springwebsocket
│              │  SpringWebsocketApplication.java
│              │  TestController.java
│              │
│              ├─j2ee
│              │      WebSocketConfig.java
│              │      WebSocketServer.java
│              │
│              ├─socketio
│              │      SocketIoConfig.java
│              │      SocketIoHandle.java
│              │
│              └─spring
│                      SpringSocketConfig.java
│                      SpringSocketHandle.java
│
└─resources
    └─templates
            J2eeIndex.html
            SocketIoIndex.html
            SpringIndex.html

```

代码结构如上所示，应用代码分成了三个文件夹，分别放着三种方式的具体示例代码，在资源文件夹下的 **templates** 文件夹也有三个 HTML 文件，就是对应三种示例的 HTML 页面，里面的链接地址和端口我都预设好了，拉下来直接单独编译此模块运行即可。  
我没有往里面放 Netty 的代码，是因为感觉 Netty 部分内容很少，文章示例中的代码直接复制就能用，后面如果写 Netty 的话会再开一个 Netty 模块用来放 Netty 相关的代码。  
好了，今天的内容就到这了，希望对大家有帮助的话可以帮我文章**点点赞**，GitHub 也**点点赞**，大家的点赞与评论都是我更新的不懈动力，下期见。

![](../../Attachments/6f7e7cf2aae787ede19329050b2deb72_MD5.jpg)