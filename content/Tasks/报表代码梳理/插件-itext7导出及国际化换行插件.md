## ICU 换行

### 概念

> [ICU - International Components for Unicode](https://icu.unicode.org/home)  
> [ICU Documentation | ICU is a mature, widely used set of C/C++ and Java libraries providing Unicode and Globalization support for software applications. The ICU User Guide provides documentation on how to use ICU.](https://unicode-org.github.io/icu/)

首先要理解 icu 的概念。如上文中所讲，icu 即为 unicode 编码的国际化组件。

#### 特点

> [!info]  
> Here are a few highlights of the services provided by ICU:
> 
> - Code Page Conversion: Convert text data to or from Unicode and nearly any other character set or encoding. ICU's conversion tables are based on charset data collected by IBM over the course of many decades, and is the most complete available anywhere.
>         
>     - Collation: Compare strings according to the conventions and standards of a particular language, region or country. ICU's collation is based on the Unicode Collation Algorithm plus locale-specific comparison rules from the [Common Locale Data Repository](http://www.unicode.org/cldr/), a comprehensive source for this type of data.
>         
>     - Formatting: Format numbers, dates, times and currency amounts according the conventions of a chosen locale. This includes translating month and day names into the selected language, choosing appropriate abbreviations, ordering fields correctly, etc. This data also comes from the Common Locale Data Repository.
>         
>     - Time Calculations: Multiple types of calendars are provided beyond the traditional Gregorian calendar. A thorough set of timezone calculation APIs are provided.
>         
>     - Unicode Support: ICU closely tracks the Unicode standard, providing easy access to all of the many Unicode character properties, Unicode Normalization, Case Folding and other fundamental operations as specified by the [Unicode Standard](http://www.unicode.org/).
>         
>     - Regular Expression: ICU's regular expressions fully support Unicode while providing very competitive performance.
>         
>     - Bidi: support for handling text containing a mixture of left to right (English) and right to left (Arabic or Hebrew) data.
>         
>     - Text Boundaries: Locate the positions of words, sentences, paragraphs within a range of text, or identify locations that would be suitable for line wrapping when displaying the text.

这里非常重要的一点是最后一个说明， **Text Boundaries**

- 文本边界：定位文本范围内的单词、句子、段落的位置，或者识别显示文本时适合换行的位置。

#### 使用范围

> [who use ICU](https://icu.unicode.org/home#h.f9qwubthqabj)

- Products from Google
	- Web Search, Google+, Chrome/Chrome OS, Android, Adwords, Google Finance, Google Maps, Blogger, Google Analytics, Google Groups, and others.
- Products from Apple
	- macOS (OS & applications), iOS (iPhone, iPad, iPod touch), watchOS & tvOS, Safari for Windows & other Windows applications and related support, Apple Mobile Device Support in iTunes for Windows.
- Products from Microsoft
	- Windows Bridge for iOS ([link](https://developer.microsoft.com/windows/bridges/ios)), Windows 10 - Creators Update, Visual Studio 2017 [Electron], Visual Studio Code [Electron], ChakraCore

可以看到使用的范围很广，被广泛用于其他软件中。

#### 前端效果

刚好 7 个字  
![500](../../../Attachments/a06045f11668edb564797befb08ac1ef_MD5.png)  
刚好 7 个字 + ‘:’  
![500](../../../Attachments/f1d5ec05e89dd50cb16b222a25f8afb1_MD5.png)

## ICU 定制逻辑

### 分行效果和前端保持一致

> [!note]  
> 每行如果只有一个空格，前端不处理空格，如果是多个连续的空格，则处理为 `&nbsp;`

`com.fr.third.text.TextWrapHelper.Lines#add`  
`com.fr.stable.CommonCodeUtils#replaceBlankToHtmlBlank`

### Padding 效果和前端保持一致

> [!note]  
> Padding 小于 2，则置为 0

`com.fr.base.PaddingConvertUtils#paddingRightPT2PX`  
`com.fr.base.Style#contentStyle2class(java.util.Map, java.lang.Object)`

## 问题

### 问题：单选框不显示

![455](../../../Attachments/1e9fdddf81b18e5210b8491a09d5ca52_MD5.png)

要搞清楚这个问题，首先比较重要的是，这个是怎么实现的单选框呢？  
是通过背景图片。见下图

![525](../../../Attachments/9c7090a7e60f692f8097e2d78a1bfbc6_MD5.png)

这里首先引用的是 /com/fr/fs/resources/xxx 的图片。正是因为这个图片消失，所以导致的这个问题。  
这个图片在哪里呢？在 [engine-platform](https://code.fineres.com/users/harrison/repos/engine-platform/browse)  
在 fr 切换成 gradle 工程的时候，把这个工程去掉，所以导致有些图片加载不到。
