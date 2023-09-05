---
aliases: []
created_date: 2023-08-29 15:24
draft: false
summary: ''
tags:
- dev
---

# @link vs @code

Many Javadoc descriptions reference other methods and classes. This can be achieved most effectively using the @link and @code features.  
许多 Javadoc 描述引用其他方法和类。使用@link 和@code 功能可以最有效地实现这一点。

The @link feature creates a visible hyperlink in generated Javadoc to the target. The @link target is one of the following forms:  
@link 功能在生成的 Javadoc 中创建指向目标的可见超链接。 @link 目标是以下形式之一：

```
/**
 - First paragraph.
 - <p>
 - Link to a class named 'Foo': {@link Foo}.
 - Link to a method 'bar' on a class named 'Foo': {@link Foo#bar}.
 - Link to a method 'baz' on this class: {@link #baz}.
 - Link specifying text of the hyperlink after a space: {@link Foo the Foo class}.
 - Link to a method handling method overload {@link Foo#bar(String,int)}.  
 */  
public …
```

The @code feature provides a section of fixed-width font, ideal for references to methods and class names. While @link references are checked by the Javadoc compiler, @code references are not.  
@code 功能提供了一段固定宽度的字体，非常适合引用方法和类名。虽然 @link 引用由 Javadoc 编译器检查，但 @code 引用则不然。

Only use @link on the first reference to a specific class or method. Use @code for subsequent references. This avoids excessive hyperlinks cluttering up the Javadoc.  
仅在第一次引用特定类或方法时使用@link。使用@code进行后续引用。这可以避免过多的超链接使 Javadoc 变得混乱。

Do not use @link in the punch line. The first sentence is used in the higher level Javadoc. Adding a hyperlink in that first sentence makes the higher level documentation more confusing. Always use @code in the first sentence if necessary. @link can be used from the second sentence/paragraph onwards.  
不要在妙语中使用@link。第一句用于更高级别的 Javadoc。在第一句话中添加超链接会使更高级别的文档更加混乱。如有必要，请始终在第一句中使用@code。 @link 可以从第二句/段落开始使用。

Do not use @code for null, true or false. The concepts of null, true and false are very common in Javadoc. Adding @code for every occurrence is a burden to both the reader and writer of the Javadoc and adds no real value.  
不要使用 @code 表示 null、true 或 false。 null、true 和 false 的概念在 Javadoc 中非常常见。为每个事件添加 @code 对于 Javadoc 的读者和作者来说都是一种负担，并且没有增加任何实际价值。