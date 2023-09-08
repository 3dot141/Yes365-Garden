---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

> **Multipurpose Internet Mail Extensions** (**MIME**) is an [Internet standard](https://en.m.wikipedia.org/wiki/Internet_standard "Internet standard") that extends the format of [email](https://en.m.wikipedia.org/wiki/Email "Email") messages to support text in [character sets](https://en.m.wikipedia.org/wiki/Character_set "Character set") other than [ASCII](https://en.m.wikipedia.org/wiki/ASCII "ASCII"), as well as [attachments](https://en.m.wikipedia.org/wiki/Email_attachment "Email attachment") of audio, video, images, and application programs. Message bodies may consist of multiple parts, and header information may be specified in non-ASCII character sets. Email messages with MIME formatting are typically transmitted with standard protocols, such as the [Simple Mail Transfer Protocol](https://en.m.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol "Simple Mail Transfer Protocol") (SMTP), the [Post Office Protocol](https://en.m.wikipedia.org/wiki/Post_Office_Protocol "Post Office Protocol") (POP), and the [Internet Message Access Protocol](https://en.m.wikipedia.org/wiki/Internet_Message_Access_Protocol "Internet Message Access Protocol") (IMAP).  
> 多用途 Internet 邮件扩展 (MIME) 是一种 Internet 标准，它扩展了电子邮件的格式以支持 ASCII 以外的字符集文本以及音频、视频、图像和应用程序的附件。消息体可以由多个部分组成，并且标头信息可以用非ASCII字符集指定。具有 MIME 格式的电子邮件通常使用标准协议进行传输，例如简单邮件传输协议 (SMTP)、邮局协议 (POP) 和 Internet 消息访问协议 (IMAP)。

> The MIME standard is specified in a series of [requests for comments](https://en.m.wikipedia.org/wiki/Request_for_Comments "Request for Comments"): [RFC 2045](https://tools.ietf.org/html/rfc2045), [RFC 2046](https://tools.ietf.org/html/rfc2046), [RFC 2047](https://tools.ietf.org/html/rfc2047), [RFC 4288](https://tools.ietf.org/html/rfc4288), [RFC 4289](https://tools.ietf.org/html/rfc4289) and [RFC 2049](https://tools.ietf.org/html/rfc2049). The integration with SMTP email is specified in [RFC 1521](https://tools.ietf.org/html/rfc1521) and [RFC 1522](https://tools.ietf.org/html/rfc1522).  
> MIME 标准在一系列征求意见中指定：RFC 2045、RFC 2046、RFC 2047、RFC 4288、RFC 4289 和 RFC 2049。与 SMTP 电子邮件的集成在 RFC 1521 和 RFC 1522 中指定。

## Content-Type

### Common examples

From the IANA registry:[1](https://en.m.wikipedia.org/wiki/Media_type#cite_note-iana-1)

- `application/json`
- `application/ld+json` ([JSON-LD](https://en.m.wikipedia.org/wiki/JSON-LD "JSON-LD"))
- `application/msword` (.doc)
- `application/pdf`
- `application/sql`
- `application/vnd.api+json`
- `application/vnd.microsoft.portable-executable` (.efi)
- `application/vnd.ms-excel` (.xls)
- `application/vnd.ms-powerpoint` (.ppt)
- `application/vnd.oasis.opendocument.text` (.odt)
- `application/vnd.openxmlformats-officedocument.presentationml.presentation` (.pptx)
- `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` (.xlsx)
- `application/vnd.openxmlformats-officedocument.wordprocessingml.document` (.docx)
- `application/x-www-form-urlencoded`
- `application/xml`
- `application/zip`
- `application/zstd` (.zst)
- `audio/mpeg`
- `audio/ogg`
- `image/avif`
- `image/jpeg` (.jpg, .jpeg, .jfif, .pjpeg, .pjp) [[12]](https://en.m.wikipedia.org/wiki/Media_type#cite_note-12)
- `image/png`
- `image/svg+xml` (.svg)
- `model/obj` (.obj)
- `multipart/form-data`
- `text/plain`
- `text/css`
- `text/csv`
- `text/html`
- `text/javascript`(.js)
- `text/xml`

### form-data, x-www-urlencoded, raw

#### 重复读取

form-data 和 x-www-urlencoded 均可以通过下文重复读取。

```java
    /**
     * Returns a java.util.Map of the parameters of this request. Request parameters are extra information sent with the
     * request. For HTTP servlets, parameters are contained in the query string or posted form data.
     *
     * @return an immutable java.util.Map containing parameter names as keys and parameter values as map values. The
     *             keys in the parameter map are of type String. The values in the parameter map are of type String
     *             array.
     */
    Map<String,String[]> getParameterMap();
```

可以重复读取，直接通过 getParameterMap 即可读取

```java
protected void parseParameters() {
	// 是否已经读取 inputstream
	// 是否是 form-data
	// 是否是 x-www-urlencoded
}
```

raw 只可以通过 `getInputStream` 读取一次。

#### 传递内容  

form-data 可以传递文件，x-url-encoded 只可以传递 key-value

### application/oct-stream

The content-type should be whatever it is known to be, if you know it. `application/octet-stream` is defined as "arbitrary binary data" in RFC 2046, and there's a definite overlap here of it being appropriate for entities whose sole intended purpose is to be saved to disk, and from that point on be outside of anything "webby". Or to look at it from another direction; the only thing one can safely do with application/octet-stream is to save it to file and hope someone else knows what it's for.  
内容类型应该是已知的任何内容（如果您知道的话）。 `application/octet-stream` 在 RFC 2046 中被定义为“任意二进制数据”，这里有明确的重叠，它适用于其唯一预期目的是保存到磁盘的实体，并且从那时起就处于外部任何“威比”。或者从另一个方向看；人们可以安全地使用 application/octet-stream 做的唯一一件事就是将其保存到文件中并希望其他人知道它的用途。

## Content-Disposition

The original MIME specifications only described the structure of mail messages. They did not address the issue of presentation styles. The content-disposition header field was added in RFC 2183 to specify the presentation style. A MIME part can have:  
最初的 MIME 规范仅描述了邮件消息的结构。他们没有解决演示风格的问题。 RFC 2183 中添加了 content-disposition 标头字段来指定呈现样式。 MIME 部分可以具有：

- an **_inline_** content disposition, which means that it should be automatically displayed when the message is displayed, or  
    内联内容配置，这意味着它应该在显示消息时自动显示，或者
- an **_attachment_** content disposition, in which case it is not displayed automatically and requires some form of action from the user to open it.  
    附件内容配置，在这种情况下，它不会自动显示，需要用户采取某种形式的操作才能将其打开。

In addition to the presentation style, the field _Content-Disposition_ also provides parameters for specifying the name of the file, the creation date and modification date, which can be used by the reader's mail user agent to store the attachment.  
除了呈现样式之外，Content-Disposition字段还提供用于指定文件名、创建日期和修改日期的参数，读者的邮件用户代理可以使用这些参数来存储附件。

The following example is taken from RFC 2183, where the header field is defined:  
以下示例取自 RFC 2183，其中定义了标头字段：

```js
Content-Disposition: attachment; filename=genome.jpeg;  
  modification-date="Wed, 12 Feb 1997 16:29:51 -0500";
```

The filename may be encoded as defined in RFC 2231.  
文件名可以按照 RFC 2231 中的定义进行编码。

## Content-Transfer-Encoding

>根据 [rfc2045.txt](https://www.ietf.org/rfc/rfc2045.txt)
>
>encoding := "Content-Transfer-Encoding" ":" mechanism  
>mechanism := "7bit" / "8bit" / "binary" / "quoted-printable" / "base64" 

- Suitable for use with normal SMTP:  
    适合与普通 SMTP 一起使用：
    - **7bit** – up to 998 [octets](https://en.m.wikipedia.org/wiki/Octet_(computing) "Octet (computing)") per line of the code range 1..127 with CR and LF (codes 13 and 10 respectively) only allowed to appear as part of a CRLF line ending. This is the default value.  
        7 位 – 代码范围 1..127 的每行最多 998 个八位位组，其中 CR 和 LF（分别为代码 13 和 10）仅允许作为 CRLF 行结尾的一部分出现。这是默认值。
    - **[quoted-printable](https://en.m.wikipedia.org/wiki/Quoted-printable "Quoted-printable")** – used to encode arbitrary octet sequences into a form that satisfies the rules of 7bit. Designed to be efficient and mostly human-readable when used for text data consisting primarily of US-ASCII characters but also containing a small proportion of bytes with values outside that range.  
        Quoted-printable – 用于将任意八位字节序列编码为满足 7 位规则的形式。当用于主要由 US-ASCII 字符组成但也包含小部分值超出该范围的字节的文本数据时，设计为高效且大部分为人类可读的。
    - **[base64](https://en.m.wikipedia.org/wiki/Base64 "Base64")** – used to encode arbitrary octet sequences into a form that satisfies the rules of 7bit. Designed to be efficient for non-text 8 bit and binary data. Sometimes used for text data that frequently uses non-US-ASCII characters.  
        base64 – 用于将任意八位字节序列编码为满足 7 位规则的形式。专为高效处理非文本 8 位和二进制数据而设计。有时用于经常使用非 US-ASCII 字符的文本数据。
- Suitable for use with SMTP servers that support the [8BITMIME](https://en.m.wikipedia.org/wiki/8BITMIME "8BITMIME") SMTP extension (RFC 6152):  
    适用于支持 8BITMIME SMTP 扩展 (RFC 6152) 的 SMTP 服务器：
    - **8bit** – up to 998 octets per line with CR and LF (codes 13 and 10 respectively) only allowed to appear as part of a CRLF line ending.  
        8 位 – 每行最多 998 个八位位组，其中 CR 和 LF（分别为代码 13 和 10）仅允许作为 CRLF 行结尾的一部分出现。
- Suitable for use with SMTP servers that support the BINARYMIME SMTP extension (RFC 3030):  
    适合与支持 BINARYMIME SMTP 扩展 (RFC 3030) 的 SMTP 服务器一起使用：
    - **binary** – any sequence of octets.  
        二进制——任何八位位组序列。