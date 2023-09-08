---
aliases: []
created_date: 2023-08-25 09:38
draft: false
summary: ''
tags:
- dev
---

> [Getting Started | Next.js](https://beta.nextjs.org/docs/getting-started)

Next.js 是一个 SSR 框架。什么是 SSR 框架呢？见 [JS核心理论之《SPA、CSR、SSR、Prerender原理浅析》](JS核心理论之《SPA、CSR、SSR、Prerender原理浅析》.md#SSR（服务端渲染）)  
代码示例仓库见 [GitHub - 3dot141/ChatGPT-Next-Web: One-Click to deploy well-designed ChatGPT web UI on Vercel. 一键拥有你自己的 ChatGPT 网页服务。](https://github.com/3dot141/ChatGPT-Next-Web)

# Next.js

## 后台状态默认不保存

见代码

```js
let api = 1;  
  
export async function GET(req: NextRequest) {  
  try {  
    api++;  
	return NextResponse.json(`api ${api}`);
  } catch (e) {  
    console.error(e);  
    return NextResponse.json(`error is ${e}`);  
  }  
}
```

以上代码，理论上，每次访问 `api` 这个变量值都要 +1  
然而默认情况下，这个 `api` 并不会变更。始终是 1

### 解决方案

在文件头上写上如下代码

```js
export const dynamic = "force-dynamic";
```

而且需要是 production 环境， dev 不行。

见 [Segment Config Options | Next.js](https://beta.nextjs.org/docs/api-reference/segment-config)

- **`'force-dynamic'`**: Force dynamic rendering and dynamic data fetching of a layout or page by disabling all caching of `fetch` requests and always revalidating. This option is equivalent to:
    - `getServerSideProps()` in the `pages` directory.
    - Setting the option of every `fetch()` request in a layout or page to `{ cache: 'no-store', next: { revalidate: 0 } }`.
    - Setting the segment config to `export const fetchCache = 'force-no-store'`

> 然而并不能看懂。只知道这样能解决  
> 尴尬😅

## dynamic server usage

```js
const code = req.nextUrl.searchParams.get("code") as string;
```

使用 next 提供的这个方法时，报错

### 解决方案

I just added `export const dynamic = 'force-dynamic'` to my `page.tsx` file and it worked for me

Found the solution in the documentation [https://beta.nextjs.org/docs/api-reference/segment-config](https://beta.nextjs.org/docs/api-reference/segment-config)

> [next.js - Digest: DYNAMIC\_SERVER\_USAGE Nextjs 13 - Stack Overflow](https://stackoverflow.com/questions/75051613/digest-dynamic-server-usage-nextjs-13)  
> 一样不知道原因

## NextResponse.redirect 报错

> [reactjs - Next JS - Middlewares - Error: URLs is malformed. Please use only absolute URLs - Stack Overflow](https://stackoverflow.com/questions/71307896/next-js-middlewares-error-urls-is-malformed-please-use-only-absolute-urls)

我想在访问到这个请求后， 跳转到首页。所以写了一个方法

```js
const response = NextResponse.redirect(`/`);
```

报错如上。

### 解决方案

```javascript
export function middleware(req: NextRequest): NextResponse | null {
  const { pathname, origin } = req.nextUrl

  return NextResponse.redirect(`${origin}/about`)
}
```