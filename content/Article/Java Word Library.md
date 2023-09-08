---
aliases: []
created_date: 2023-08-25 16:00
draft: false
summary: ''
tags:
- dev
---

> Java 的 word 库

- [Aspose.Words for Java](https://products.aspose.com/words/java/)
- [GitHub - plutext/docx4j: JAXB-based Java library for Word docx, Powerpoint pptx, and Excel xlsx files](https://github.com/plutext/docx4j)

## 限制对比

### docx4j

> 见 [docx4j-getting-started](../../Attachments/0be887df146b83b954defde572758bc6_MD5.pdf)

Docx4j can read/write docx documents created by or for Word 2007 or later, plus earlier versions which have the compatibility pack installed. (Same goes for xlsx spreadsheets and pptx presentations). The relevant parts of docx4j are generated from the ECMA schemas, with the addition of the key Microsoft proprietary extensions. For unsupported extensions, docx4j gracefully degrades to the specified 2007 substitutes. It is not really intended read/write Word 2003 XML documents, although package org.docx4j.convert.in.word2003xml is a proof of concept of importing such documents.

An effective approach is to use LibreOffice or OpenOffice (via jodconverter) to convert the doc to docx, which docx4j can then process. If you need to return a binary .doc, LibreOffice or OpenOffice/jodconverter can convert the docx back to .doc. With 8.2.0, docx4j can also convert binary .doc or RTF to docx, using Microsoft Word courtesy of documents4j. The sub-projects docx4j-documents4j-local and docx4j-documents4j-remote provide an interface to documents4j which is convenient for docx4j users.

> 只可以处理 07 上的版本，03 不支持。

### Aspose.Words

> 见 [System Requirements|Aspose.Words for Java](https://docs.aspose.com/words/java/system-requirements/#supported-operating-systems)

Any Operating System that can run the Java Runtime Environment (JRE) can run Aspose.Words for Java. The following table lists most, but not all, supported Operating Systems.  
任何可以运行 Java 运行时环境 (JRE) 的操作系统都可以运行 Aspose.Words for Java。下表列出了大多数（但不是全部）支持的操作系统。

## 功能对比

- [Aspose.Words or Docx4j|Aspose.Words for Java](https://docs.aspose.com/words/java/aspose-words-java-for-docx4j/)
	- Docx4j 是一个开源 (ASLv2) Java 库，用于创建和操作 Microsoft Open XML Word 格式的文档。它类似于 Microsoft Open XML SDK for Java。 Docx4j 使用 JAXB 创建内存中对象表示，您需要一段时间才能理解 JAXB 和 Open XML 文件结构。
	- Aspose.Words 是一个非常有用的文档处理库，它为所有 Microsoft Word 和其他文档格式提供了强大的支持。使用 Aspose.Words，您可以查看、生成、修改、转换、渲染和打印文档，而无需使用 Microsoft Word。

### Common Features

> [Release Aspose.Words Java for Docx4j - v1.0.0 · aspose-words/Aspose.Words-for-Java · GitHub](https://github.com/aspose-words/Aspose.Words-for-Java/releases/tag/Aspose.Words_Java_for_Docx4j-v1.0.0)

Examples for code comparison in **Aspose.Words** and **Docx4j**:

**Working with Bookmarks**

- [Add Bookmarks](http://www.aspose.com/docs/display/wordsjava/2.2.2.1+Add+Bookmarks)
- [Delete Bookmarks](http://www.aspose.com/docs/display/wordsjava/2.2.2.2+Delete+Bookmarks)

**Working with Document**

- [Accessing Document Properties](http://www.aspose.com/docs/display/wordsjava/2.2.1.1+Accessing+Document+Properties)
- [Convert Document to HTML](http://www.aspose.com/docs/display/wordsjava/2.2.1.2+Convert+Document+to+HTML)
- [Working with Comments](http://www.aspose.com/docs/display/wordsjava/2.2.1.3+Working+with+Comments)
- [Insert Image](http://www.aspose.com/docs/display/wordsjava/2.2.1.4+Insert+Image)
- [Merge Documents](http://www.aspose.com/docs/display/wordsjava/2.2.1.6+Merge+Documents)
- [Create New Document](http://www.aspose.com/docs/display/wordsjava/2.2.1.5+Create+New+Document)
- [Add Watermark in Document](http://www.aspose.com/docs/display/wordsjava/2.2.1.6+Add+Watermark+in+Document)
- [Insert Hyperlink to Document](http://www.aspose.com/docs/display/wordsjava/2.2.1.7+Insert+Hyperlink+to+Document)
- [Convert Document to PDF](http://www.aspose.com/docs/display/wordsjava/2.2.1.8+Convert+Document+to+PDF)
- [Insert Table of Contents in Document](http://www.aspose.com/docs/display/wordsjava/2.2.1.9+Insert+Table+of+Contents+in+Document)

**Working with Header and Footer**

- [Insert Header](http://www.aspose.com/docs/display/wordsjava/2.2.3.1+Insert+Header)
- [Insert Footer](http://www.aspose.com/docs/display/wordsjava/2.2.3.2+Insert+Footer)
- [Remove Header Footer from Documents](http://www.aspose.com/docs/display/wordsjava/2.2.3.3+Remove+Header+Footer+from+Documents)

### Missing Features of Docx4j

Examples for code with missing features in **Docx4j** in comparison with **Aspose.Words**:

**Working with Documents**

- [Clone Documents](http://www.aspose.com/docs/display/wordsjava/2.3.1.1+Clone+Documents)
- [Moving the Cursor in Document](http://www.aspose.com/docs/display/wordsjava/2.3.1.2+Moving+the+Cursor+in+Document)
- [Protect Documents](http://www.aspose.com/docs/display/wordsjava/2.3.1.3+Protect+Documents)
- [Check Format Compatibility](http://www.aspose.com/docs/display/wordsjava/2.3.1.4+Check+Format+Compatibility)
- [Working with Digital Signatures](http://www.aspose.com/docs/display/wordsjava/2.3.1.6+Working+with+Digital+Signatures)
- [Load Text File](http://www.aspose.com/docs/display/wordsjava/2.3.1.5+Load+Text+File)
- [Specify Default Fonts](http://www.aspose.com/docs/display/wordsjava/2.3.1.7+Specify+Default+Fonts)
- [Set Page Borders](http://www.aspose.com/docs/display/wordsjava/2.3.1.8+Set+Page+Borders)
- [Track Changes in Documents](http://www.aspose.com/docs/display/wordsjava/2.3.1.9+Track+Changes+in+Documents)
- [Using Control Characters](http://www.aspose.com/docs/display/wordsjava/2.3.1.10+Using+Control+Characters)

**Working with Tables**

- [Autofit Setting to Tables](http://www.aspose.com/docs/display/wordsjava/2.3.2.2+Autofit+Setting+to+Tables)
- [Joining Tables in Document](http://www.aspose.com/docs/display/wordsjava/2.3.2.1+Joining+Tables+in+Document)
- [Split Tables](http://www.aspose.com/docs/display/wordsjava/2.3.2.3+Split+Tables)
- [Repeat Table Header Rows on Pages](http://www.aspose.com/docs/display/wordsjava/2.3.2.4+Repeat+Table+Header+Rows+on+Pages)

**Mail Merge**

- [Mail Merge from XML Data Source](http://www.aspose.com/docs/display/wordsjava/2.3.3.1+Mail+Merge+from+XML+Data+Source)

## 其他对比

**容量大小**

- docx4j - 7mb
- aspose.words - 16mb
	- aspose.cells - 8mb
	- aspose.pdf - 75mb

**性能对比**
todo

## 总结

限制对比：
- 如果 aspose 的描述上没有问题，支持所有的版本，那么完胜

功能对比：
- 通用功能 aspose 的抽象更好一点儿。
- 功能丰富度 aspose 支持的更加的全面
	- 不支持的功能实现上，目前没有找到开源的方案

容量对比：
- aspose 的大小稍大。可以接受

性能对比：
- todo