---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

> [Font Setup - OpenJDK Wiki](https://wiki.openjdk.org/pages/viewpage.action?pageId=17957183)

Some devices do not have the Linux `fontconfig` package, which, by default, JavaFX uses to find fonts. The `fontconfig` package is not installed if the following command returns no result:

```$ find /usr/lib -name libfontconfig.so -o -name libfontconfig.so.1  ```

Fontconfig provides for a powerful means of identifying and finding installed fonts. It is usually associated with X11, but does not require it.

On the target device that does not have `fontconfig`,it is possible to configure JavaFX to find and use fonts. Follow these steps to set up fonts for JavaFX. The fonts used in the examples can be found in a full JDK distribution under ./jre/lib/fonts

翻译一下

OpenJDK 使用 `fontconfig` 寻找字体，如果没有该 package, 你可以配置 JavaFX 来进行查找和使用字体。

## 联想知识

[Linux fontconfig 的字体匹配机制 - 双猫CC](https://catcat.cc/post/2020-10-31/)