---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

## client, page, screen

https://segmentfault.com/a/1190000002405897

https://stackoverflow.com/questions/6073505/what-is-the-difference-between-screenx-y-clientx-y-and-pagex-y

只有页面存在滚动条时，clientX 不等于 pageX  
元素内部的滚动条，不影响 clientX 和 pageX

## BoundingClientRect

https://developer.mozilla.org/zh-CN/docs/Web/API/Element/getBoundingClientRect

## selenium moveToElement

offset 到底是从 top-left corner 还是 center of view  
取决于用的 w3c 还是 json wire protocol  
chrome 75 之前用的 jwp, 之后用的 w3c.

https://github.com/mozilla/geckodriver/issues/789  
https://github.com/SeleniumHQ/selenium/issues/4847  
https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidmoveto