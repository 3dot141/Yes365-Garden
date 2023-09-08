---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

## Class.forName VS LoadClass

**区别：**  
LoadClass 不初始化类。  
Class.forName 初始化类。

**tips:**  
只要出现了 xx.Class ， 这个 Class 就已经加入了 JVM 中。

## 静态代码块什么时候执行的。

装载 -- 链接 -- 初始化 -- 实例化。

初始化后 开始执行静态代码块。

## 对象初始化顺序

对象初始化，顺序：

1. 父类静态对象，静态代码块
2. 子类静态对象，静态代码块
3. 父类非静态对象，非静态代码块
4. 父类构造函数
5. 子类非静态对象，非静态代码块
6. 子类构造函数