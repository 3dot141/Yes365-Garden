---
aliases: []
created_date: 2023-08-25 16:00
draft: false
summary: ''
tags:
- dev
---

**概念**
------

* **SEO**: 搜索引擎优化（Search Engine Optimization）。是一种利用搜索引擎规则，提高网站在搜索引擎内自然排名的技术。对大多数搜索引擎，不识别 JavaScript 内容，只识别 HTML 内容。
* **SPA**：单页面应用（single page application）。动态重写当前的页面来与用户交互，而不需要重新加载整个页面。单页应用做到了前后端分离，后端只负责处理数据提供接口，页面逻辑和页面渲染都交给了前端。CSR、SSR、Prerender 都是基于 SPA。
* **CSR**：客户端渲染 (Client Side Render)。渲染过程全部交给浏览器进行处理，服务器不参与任何渲染。页面初始加载的 HTML 文档中无内容，需要下载执行 JS 文件，由浏览器动态生成页面，并通过 JS 进行页面交互事件与状态管理。
* **SSR**：服务端渲染 (Server Side Render)。DOM 树在服务端生成，而后返回给前端。即当前页面的内容是服务器生成好一次性给到浏览器的进行渲染的。
* **Prerender**：预渲染。打包的阶段就预先渲染页面，所以在请求到 index.html 时 就已经是渲染过的内容。
* **同构**：客户端渲染和服务器端渲染的结合，在服务器端执行一次，用于实现服务器端渲染（首屏直出），在客户端再执行一次，用于接管页面交互 (绑定事件)，核心解决 SEO 和首屏渲染慢的问题。采用同构思想的框架：`Nuxt.js`（基于 Vue）、`Next.js`（基于 React）。

接下来，我们分别通过三张流程图来加深对 CSR、SSR、Prerender 的理解。

CSR（客户端渲染）
--------------

![525](../Attachments/5838e8abd1f69620af0842c8e9d4ca18.jpg)

**渲染流程**：浏览器请求 url --> 服务器返回 index.html(空 body、白屏) --> 再次请求 bundle.js、路由分析 --> 浏览器渲染

bundle.js 体积越大，会导致浏览器白屏时间越长。

SSR（服务端渲染）
--------------

![525](../Attachments/98f3816acb3b09c3806a4adf9da28d44.jpg)  
![525](../Attachments/dcae27851e100da0d27a7b1cedd71c08.jpg)

**渲染流程**：

* 阶段一：浏览器请求 url --> 服务器路由分析、执行渲染 --> 服务器返回 index.html(实时渲染的内容，字符串) --> 浏览器渲染
* 阶段二：浏览器请求 bundle.js --> 服务器返回 bundle.js --> 浏览器路由分析、生成虚拟 DOM --> 比较 DOM 变化、绑定事件 --> 二次渲染

尽管服务器渲染第一阶段的流程图很长，但是因为服务器渲染速度很快，因此实际耗时与客户端渲染几乎相同。  
第一阶段结束时，服务器端返回渲染结果，用户即可看到首屏。而对于客户端渲染，需要等待一次脚本下载时间，以及在客户端的渲染时间。由于客户端的硬件以及网络条件的差异，这两段时间开销可能十分显著。  
客户渲染与服务器渲染第二阶段基本一致。所不同的是，服务器渲染流程中，在客户端生成 vdom 后，并不会重新渲染，而是比较现有 dom 的 checksum 来决定是否重新渲染。

**原理**：基于 `Virtual DOM` 实现了客户端与服务端的同构渲染。

* 在服务器，我可以操作 JavaScript 对象，判断环境是服务器环境，我们把虚拟 DOM 映射成字符串输出；
* 在客户端，我也可以操作 JavaScript 对象，判断环境是客户端环境，我就直接将虚拟 DOM 映射成真实 DOM，完成页面挂载。

**Prerender（预渲染）**
------------------

![|525](../Attachments/679a73f7a71fbd61e06b81d86c046001.jpg)

**渲染流程**：浏览器请求 url --> 服务器返回 index.html(预渲染的内容、内联 bundle.js) --> 浏览器渲染 --> 再次请求 bundle.js --> 二次渲染

打包后的 html 是这个样子的：

```text
<html>
    <head>
        <link href="/static/css/app.feedaff.min.css" rel="stylesheet">
    </head>
    <body>
        <div>...内容</div>
    </body>
    <script src="/static/js/2.22fca29f.chunk.js"></script>
    <script src="/static/js/main.a9f5ef89.chunk.js"></script>
</html>

```

预渲染需要借助插件 `PrerenderSPAPlugin` 来预先指定需要渲染的页面。在 webpack 里设置如下：

```text
new PrerenderSPAPlugin({
  staticDir: path.join(__dirname, "../", "build"),
  routes: ["/"]
});

```

**原理**：`Prerender` 就是利用 Chrome 官方出品的 `Puppeteer` 工具，对页面进行爬取。  
在 `Webpack` 构建阶段的最后，在本地启动一个 `Puppeteer` 的服务，访问配置了预渲染的路由，然后将 `Puppeteer` 中渲染的页面输出到 HTML 文件中，并建立路由对应的目录。  
所以预渲染的缺点除了需要插件支持以外，由于渲染是在打包阶段，如果页面上有实时更新的数据，则在渲染时显示的不是最新的数据。

打包的时候就预先渲染页面，所以在请求到 index.html 就已经是渲染过的内容。

可以看出，**SSR 和 Prerender 的最大区别** 就在于，`Prerender 是静态的，SSR 是动态的，SSR 会在服务端实时构建出对应的 DOM`。

**注意点**
-------

1. 如果 **页面无数据，或者是纯静态页面，建议使用 Prerender**，这是一种通过预览打包的方式构建页面，也不会增加服务器负担，但其他情况并不推荐。如果 **页面数据请求多，又对 SEO 和加载速度有需求的，建议使用 SSR**。
2. 对于高操作需求的项目来说，CSR 可能更加适合，页面显示元素即绑定了操作，而 SSR 和 Prerender 虽然会提前显示页面，但此时页面元素无法操作，仍需要下载完 bundle.js 进行事件绑定才能执行。
3. 客户端渲染中，用户的浏览器中永远只存在一个 Store，服务器端的 Store 是所有用户都要用的，共享 Store 是有问题的，需要 **为每个用户提供一个独立的 Store**。
4. vue 的生命周期钩子函数中， 只有 `beforeCreate` 和 `created` 会在服务器端渲染 (SSR) 过程中被调用，这就是说在这两个钩子函数中的代码以及除了 vue 生命周期钩子函数的全局代码，都将会在服务端和客户端两套环境下执行。  
    在 beforeCreate，created 生命周期以及全局的执行环境中调用特定的 api 前需要判断执行环境。
5. 在客户端到 SSR 服务器的请求中，客户端是携带有 cookie 数据的。但是在 SSR 服务器请求后端接口的过程中，却是没有相应的 cookie 数据的。因此在 SSR 服务器进行接口请求的时候，我们需要手动拿到客户端的 cookie 传给后端服务器。
6. vue 有两种路由模式，一种是 hash 模式，就是我们经常用的#/hasha/hashb 这种，还有一种是 history 模式，就是/historya/historyb 这种。因为 hash 模式的路由提交不到服务器上，因此 ssr 的路由需要采用 history 的方式。