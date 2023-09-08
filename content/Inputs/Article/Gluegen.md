---
aliases: []
created_date: 2023-08-25 09:38
draft: false
summary: ''
tags:
- dev
---

> [Gluegen](https://jogamp.org/gluegen/www/)

GlueGen is a compiler for function and data-structure declarations, generating Java™ and JNI C code offline at compile time and allows using native libraries within your Java™ application.  
GlueGen 是一个用于函数和数据结构声明的编译器，可在编译时离线生成 Java™ 和 JNI C 代码，并允许在 Java™ 应用程序中使用本机库。

It reads ANSI C header files and separate configuration files which provide control over many aspects of the glue code generation. GlueGen uses a complete ANSI C parser and an internal representation (IR) capable of representing all C types to represent the APIs for which it generates interfaces. It has the ability to perform significant transformations on the IR before glue code emission.  
它读取 ANSI C 头文件和单独的配置文件，这些文件提供对粘合代码生成的许多方面的控制。 GlueGen 使用完整的 ANSI C 解析器和能够表示所有 C 类型的内部表示 (IR) 来表示它为其生成接口的 API。它能够在胶水代码发射之前对 IR 执行重大转换。

GlueGen can produce native foreign function bindings to Java™ as well as [map native data structures](https://jogamp.org/gluegen/doc/GlueGen_Mapping.html#struct-mapping) to be fully accessible from Java™ including potential calls to [embedded function pointer](https://jogamp.org/gluegen/doc/GlueGen_Mapping.html#struct-function-pointer-support).  
GlueGen 可以生成与 Java™ 的本机外部函数绑定，以及映射本机数据结构以从 Java™ 完全访问，包括对嵌入式函数指针的潜在调用。

GlueGen supports [registering Java™ callback methods](https://jogamp.org/gluegen/doc/GlueGen_Mapping.html#java-callback-from-native-c-api-support) to receive asynchronous and off-thread native toolkit events, where a generated native callback function dispatches the events to Java™.  
GlueGen 支持注册 Java™ 回调方法以接收异步和线程外本机工具包事件，其中生成的本机回调函数将事件分派到 Java™。

GlueGen also supports [producing an OO-Style API mapping](https://jogamp.org/gluegen/doc/GlueGen_Mapping.html#oo-style-api-interface-mapping) like [JOGL's incremental OpenGL Profile API levels](https://jogamp.org/jogl/doc/uml/html/index.html).  
GlueGen 还支持生成 OO 风格的 API 映射，例如 JOGL 的增量 OpenGL Profile API 级别。

GlueGen is capable to bind low-level APIs such as the Java™ Native Interface (JNI) and the AWT Native Interface (JAWT) back up to the Java programming language.  
GlueGen 能够将 Java™ 本机接口 (JNI) 和 AWT 本机接口 (JAWT) 等低级 API 绑定到 Java 编程语言。

Further, GlueGen supports generating `JNI_OnLoad(..)` for dynamic and `JNI_OnLoad_{LibraryBasename}(..)` for static libraries via [`LibraryOnLoad LibraryBasename`](https://jogamp.org/gluegen/doc/GlueGen_Mapping.html#libraryonload-librarybasename-for-jni_onload-), which also provides `JVMUtil_GetJNIEnv(..)` to resolve the `JNIEnv*` as used by [Java™ callback methods](https://jogamp.org/gluegen/doc/GlueGen_Mapping.html#java-callback-from-native-c-api-support).  
此外，GlueGen 支持通过“LibraryOnLoad LibraryBasename”生成动态库的“JNI_OnLoad(..)”和静态库的“JNI_OnLoad_{LibraryBasename}(..)”，它还提供“JVMUtil_GetJNIEnv(..)”来解析“JNIEnv*” ` 由 Java™ 回调方法使用。

GlueGen utilizes [JCPP](https://jogamp.org/cgit/jcpp.git/about/), migrated C preprocessor written in Java™.  
GlueGen 利用 JCPP，这是用 Java™ 编写的迁移的 C 预处理器。

GlueGen is used for the JogAmp projects [JOAL](https://jogamp.org/joal/www/), [JOGL](https://jogamp.org/jogl/www/) and [JOCL](https://jogamp.org/jocl/www/).  
GlueGen 用于 JogAmp 项目 JOAL、JOGL 和 JOCL。