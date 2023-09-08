---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

想要查看一些被增强过的类的字节码，或者一些 AOP 框架的生成类，就需要 dump 出运行时的 Java 进程里的字节码。

从运行的 java 进程里 dump 出运行中的类的 class 文件的方法：

1. 用 agent attatch 到进程，然后利用 Instrumentation 和 ClassFileTransformer 就可以获取到类的字节码了。
2. 用 sd-jdi.jar 里的工具。sd-jdi.jar 里自带的的 sun.jvm.hotspot.tools.jcore.ClassDump 就可以把类的 class 内容 dump 到文件里。

ClassDump 里可以设置两个 System properties：

1. sun.jvm.hotspot.tools.jcore.filter         Filter 的类名
2. sun.jvm.hotspot.tools.jcore.outputDir    输出的目录

sd-jdi.jar 里有一个 sun.jvm.hotspot.tools.jcore.PackageNameFilter，可以指定 Dump 哪些包里的类。PackageNameFilter 里有一个 System property 可以指定过滤哪些包：sun.jvm.hotspot.tools.jcore.PackageNameFilter.pkgList。

可以通过这样子的命令来使用：

sudo java -classpath "$JAVA_HOME/lib/sa-jdi.jar" -Dsun.jvm.hotspot.tools.jcore.filter=sun.jvm.hotspot.tools.jcore.PackageNameFilter -Dsun.jvm.hotspot.tools.jcore.PackageNameFilter.pkgList=cn.sf  sun.jvm.hotspot.tools.jcore.ClassDump

使用起来比较麻烦。在 sa-jdi.jar 里，还有一个图形化的工具 HSDB，也可以用来查看运行的的字节码。sudo java -classpath "$JAVA_HOME/lib/sa-jdi.jar" sun.jvm.hotspot.HSDB