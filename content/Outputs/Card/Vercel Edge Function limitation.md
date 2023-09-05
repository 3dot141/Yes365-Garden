---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

> [Vercel](Vercel.md)  
> [Edge Functions Overview | Vercel Docs](https://vercel.com/docs/concepts/functions/edge-functions) 

## Edge Function 边缘函数

Vercel's Edge Functions enable you to deliver dynamic, personalized content with the lightweight [Edge Runtime](https://edge-runtime.vercel.sh/).  
Vercel 的 Edge Functions 使您能够使用轻量级的 Edge Runtime 交付动态的、个性化的内容。

Our Edge Runtime is more performant and cost-effective than Serverless Functions on average. Edge Functions are deployed globally on our Edge Network, and can automatically execute in the region nearest to the user who triggers them. They also have no cold boots, which means they don't need extra time to start up before executing your code.  
平均而言，我们的 Edge Runtime 比 Serverless Functions 具有更高的性能和成本效益。 Edge Functions 在全球范围内部署在我们的 Edge Network 上，并且可以在离触发它们的用户最近的区域自动执行。它们也没有冷启动，这意味着它们在执行您的代码之前不需要额外的时间来启动。

Edge Functions are useful when you need to interact with data over the network as fast as possible, such as executing OAuth callbacks, responding to webhook requests, or interacting with an API that fails if a request is not completed within a short time limit.  
当您需要尽可能快地通过网络与数据交互时，Edge Functions 非常有用，例如执行 OAuth 回调、响应 webhook 请求，或者如果请求未在短时间内完成则与失败的 API 交互。

## Edge Runtime 边缘引擎

Edge Functions run on the Edge Runtime. Though the Edge Runtime does not expose all Node APIs, it does give you access to Web Standard APIs that make sense on the server.  
Edge Functions 在 Edge Runtime 上运行。尽管 Edge Runtime 不公开所有节点 API，但它确实允许您访问在服务器上有意义的 Web 标准 API。

It is built on top of the [V8 engine](https://v8.dev/), an open source, high performance JavaScript and Web Assembly engine that is written in C++. V8 powers Chrome and Node.js.  
它建立在 V8 引擎之上，V8 引擎是一种用 C++ 编写的开源、高性能 JavaScript 和 Web Assembly 引擎。 V8 为 Chrome 和 Node.js 提供支持。

## Problem 问题

简而言之，当配置了以下代码后，相关的方法即可作用 Edge Function 来调用，提升网络的访问速度。

```node.js
export const config = {  
  runtime: "edge",  
};
```

当我配置之后，在 Vercel 上进行 node 服务部署的时候，发现报错 `Illegal invocation`  
但是直接在本地运行是没有问题的，只有服务器上运行才有问题，打开日志，发现该服务使用了 **edge function** 的功能。  
仔细看了一下代码, 发现是运行到以下代码时，出现了问题。

```node.js
export async function POST(req: NextRequest) {
	await req.json()
}
```

百思不得解，原因是啥呢？  
查看相关的 API 文档 [Edge Functions API Reference | Vercel Docs](https://vercel.com/docs/concepts/functions/edge-functions/edge-functions-api#request) 和限制 [Edge Functions Limitations | Vercel Docs](https://vercel.com/docs/concepts/functions/edge-functions/limitations)  
并没有得到答案。但我猜测，是因为 `json()` 方法需要全量读取 `body` 里面的内容。  
所以，改写成以下写法

```node.js
export async function POST(req: NextRequest) {
	const bodyStream = req.body;  
	if (bodyStream == null) {  
	  throw new Error("request body is empty, please check it");  
	}  
	  
	const chunks = [];  
	// @ts-ignore  
	for await (const chunk of bodyStream) {  
	  chunks.push(chunk);  
	}  
	  
	const body = JSON.parse(Buffer.concat(chunks).toString());
	}
```

问题解决!!!

总结一下，即在 **Edge Function** 中不能使用 Request 的 json() 等需要阻塞耗时的方法。可能其他的方法也需要进行类似的改写。