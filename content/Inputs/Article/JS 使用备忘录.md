---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

### JS 的 sort 方法，需要返回 int 类型

正确写法

```js
['a','b','c'].sort((a,b)=> a > b ? 1 : -1)
```

错误写法

```js
['a','b','c'].sort((a,b) => a > b)
```

### JS 语法糖 -？

```js
// 定义
onContext?: (context: string) => void

// 使用方式
onContext?.(text)
```

### JS 语法糖 -…

**user**: js 中 …abc 的语法糖，忽略掉不想要的属性

**chatgpt**: 在 JavaScript 中，使用 …abc 这个语法糖可以将一个数组或对象展开成一组参数或属性。如果想要忽略掉某些属性，可以使用对象解构的语法来达到目的，例如：

```
const { ignoreProp, …rest } = obj;
```

这将忽略掉 obj 对象中的 ignoreProp 属性，并将剩余的属性存储在 rest 对象中。如果是数组的话，可以使用 Array.prototype.slice 方法来实现类似的效果，例如：

```
const [ignoreItem, …rest] = arr.slice(1);
```

这将忽略掉数组中的第一个元素，并将剩余的元素存储在 rest 数组中。