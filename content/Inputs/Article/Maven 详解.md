---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

## 配置

### Mirror

> [Maven – Guide to Mirror Settings](https://maven.apache.org/guides/mini/guide-mirror-settings.html)

With [Repositories](/guides/introduction/introduction-to-repositories.html) you specify from which locations you want to _download_ certain artifacts, such as dependencies and maven-plugins. Repositories can be [declared inside a project](../mini/guide-multiple-repositories.html), which means that if you have your own custom repositories, those sharing your project easily get the right settings out of the box. **However, you may want to use an alternative mirror for a particular repository without changing the project files.但是，您可能希望对特定存储库使用替代镜像而不更改项目文件。

Some reasons to use a mirror are:  
使用镜子的一些原因是：

- There is a synchronized mirror on the internet that is geographically closer and faster  
    网上有一个同步镜像，地理位置更近，速度更快
- You want to replace a particular repository with your own internal repository which you have greater control over  
    您希望将特定存储库替换为您自己的内部存储库，您可以更好地控制该内部存储库
- You want to run a [repository manager](https://maven.apache.org/repository-management.html) to provide a local cache to a mirror and need to use its URL instead  
    您想要运行存储库管理器来为镜像提供本地缓存，并且需要使用其 URL  

To configure a mirror of a given repository, you provide it in your settings file (`${user.home}/.m2/settings.xml`), giving the new repository its own `id` and `url`, and specify the `mirrorOf` setting that is the ID of the repository you are using a mirror of. For example, the ID of the main Maven Central repository included by default is `central`, so to use the different mirror instance, you would configure the following:

```


1.  <settings>
2.   ...
3.    <mirrors>
4.    <mirror>
5.    <id>other-mirror</id>
6.    <name>Other Mirror Repository</name>
7.    <url>https://other-mirror.repo.other-company.com/maven2</url>
8.    <mirrorOf>central</mirrorOf>
9.    </mirror>
10.    </mirrors>
11.   ...
12.  </settings>


```

Note that there can be at most one mirror for a given repository. In other words, you cannot map a single repository to a group of mirrors that all define the same `<mirrorOf>` value. Maven will not aggregate the mirrors but simply picks the first match. If you want to provide a combined view of several repositories, use a [repository manager](../../repository-management.html) instead.

The settings descriptor documentation can be found on the [Maven Local Settings Model Website](../../maven-settings/settings.html).

**Note**: The official Maven repository is at `https://repo.maven.apache.org/maven2` hosted by the Sonatype Company and is distributed worldwide via CDN.

A list of known mirrors is available in the [Repository Metadata](https://repo.maven.apache.org/maven2/.meta/repository-metadata.xml). These mirrors may not have the same contents and we don't support them in any way.

## 常见问题

### 问题一：Not a readable JAR artifact

删掉相关的 JAR 包，重新编译。