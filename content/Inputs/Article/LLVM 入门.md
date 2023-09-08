---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

## 背景

传统的编译器通常分为三个部分，前端（frontEnd），优化器（Optimizer）和后端（backEnd）. 在编译过程中，前端主要负责词法和语法分析，将源代码转化为抽象语法树；优化器则是在前端的基础上，对得到的中间代码进行优化，使代码更加高效；后端则是将已经优化的中间代码转化为针对各自平台的机器代码。

### GCC  

GCC（GNU Compiler Collection，GNU 编译器套装），是一套由 GNU 开发的编程语言编译器。GCC 原名为 GNU C 语言编译器，因为它原本只能处理 C语言。GCC 快速演进，变得可处理 C++、Fortran、Pascal、Objective-C、Java 以及 Ada 等他语言。

### LLVM  

LLVM （Low Level Virtual Machine，底层虚拟机)）提供了与编译器相关的支持，能够进行程序语言的编译期优化、链接优化、在线编译优化、代码生成。简而言之，可以作为多种编译器的后台来使用。

它最初的编写者，是一位叫做 Chris Lattner(Chris Lattner's Homepage)的大神，硕博期间研究内容就是关于编译器优化的东西，发表了很多论文，博士论文是提出一套在编译时、链接时、运行时甚至是闲置时的优化策略，与此同时，LLVM 的基本思想也就被确定了，这也让他在毕业前就在编译器圈子小有名气。

而在这之前，Apple 公司一直使用 gcc 作为编译器，后来 GCC 对 Objective-C 的语言特性支持一直不够，Apple 自己开发的 GCC 模块又很难得到 GCC 委员会的合并，所以老乔不开心。等到 Chris Lattner 毕业时，Apple 就把他招入靡下，去开发自己的编译器，所以 LLVM 最初受到了 Apple 的大力支持。

LLVM 最初设计时，因为只想着做优化方面的研究，所以只是想搭建一套虚拟机，所以当时这个的全称叫 Low Level Virtual machine，后来因为要变成编译器了么，然后官方就放弃了这个称呼，不过 LLVM 的简称还是保留下来了。

### LLVM2.0 - Clang  

因为 LLVM 只是一个编译器框架，所以还需要一个前端来支撑整个系统，所以 Apple 又拨款拨人一起研发了 Clang，作为整个编译器的前端，Clang 用来编译 C、C++和 Objective-C。所以当我接触 Apple 编译器时，当时的帖子里都说使用 Clang/LLVM 来和 gcc 做对比，当然是在代码优化、速度和敏捷性上比 gcc 强不少。

一个是 gcc 评价它在代码诊断方面和 Clang 的比较(ClangDiagnosticsComparison - GCC Wiki)  
一个是 Clang 评价它和 gcc（以及其他几个开源编译器）的优缺点(http://clang.llvm.org/comparison.html)，还是很客观的。

## LLVM 介绍

![515](Attachments/25cf33fd4ee252c347be877239e30e54_MD5.png)

这个图是 Clang/LLVM 的简单架构。最初时，LLVM 的前端是 GCC，后来 Apple 还是立志自己开发了一套 Clang 出来把 GCC 取代了，不过现在带有 Dragon Egg 的 GCC 还是可以生成 LLVM IR，也同样可以取代 Clang 的功能，我们也可以开发自己的前端，和 LLVM 后端配合起来，实现我们自定义的编程语言的编译器。 

LLVM IR 是 LLVM 的中间表示，这是 LLVM 中很重要的一个东西，介绍它的文档就一个，[LLVM Language Reference Manual](https://llvm.org/docs/LangRef.html) （大多数的优化都依赖于 LLVM IR 展开。我把 Opt 单独画在一边，是为了简化图的内容，因为 LLVM 的一个设计思想是优化可以渗透在整个编译流程中各个阶段，比如编译时、链接时、运行时等。 

> [!note]-  
> LLVM IR 的全称是 Low Level Virtual Machine Intermediate Representation,中文意为低级别虚拟机中间表示形式。  
> LLVM IR是LLVM编译器基础架构中的中间表示(IR)格式。它具有以下主要特点:  
> - 对目标机器无关,可以针对不同的处理器体系结构进行优化和代码生成。  
> - 以低级变量寄存器形式表达,易于进行各种优化。  
> - 设计上的简洁和紧凑,降低了解析和处理的复杂性。  
> - 具有丰富的元数据支持,方便优化和调试。  
>   
> 所以总体来说,LLVM IR是一个低级、通用、优化友好的中间表示格式,它为LLVM编译器基础设施提供了统一的优化和代码生成接口。开发人员可以使用LLVM编译器将高级语言代码优化并翻译成特定目标平台的机器代码。

在 LLVM 中，IR 有三种表示，一种是可读的 IR，类似于汇编代码，但其实它介于高等语言和汇编之间，这种表示就是给人看的，磁盘文件后缀为.ll；第二种是不可读的二进制 IR，被称作位码（bitcode），磁盘文件后缀为.bc；第三种表示是一种内存格式，只保存在内存中，所以谈不上文件格式和文件后缀，这种格式是 LLVM 之所以编译快的一个原因，它不像 gcc，每个阶段结束会生成一些中间过程文件，它编译的中间数据都是这第三种表示的 IR。三种格式是完全等价的，我们可以在 Clang/LLVM 工具的参数中指定生成这些文件（默认不生成，对于非编译器开发人员来说，也没必要生成），可以通过 llvm-as 和 llvm-dis 来在前两种文件之间做转换。 

能注意到中间有个 LLVM IR linker，这个是 IR 的链接器，而不是 gcc 中的那个链接器。为了实现链接时优化，LLVM 在前端（Clang）生成单个代码单元的 IR 后，将整个工程的 IR 都链接起来，同时做链接时优化。 

LLVM backend 就是 LLVM 真正的后端，也被称为 LLVM 核心，包括编译、汇编、链接这一套，最后生成汇编文件或者目标码。这里的 LLVM compiler 和 gcc 中的 compiler 不一样，这里的 LLVM compiler 只是编译 LLVM IR。

### 与 gcc 的关系  

如果是像我这样从gcc过来的人，会不容易完全理解他们的结构对应关系。

gcc 的编译器，输入是源代码，输出是汇编代码，相当于是 LLVM 中 Clang 一级加上 IR linker 再加上 LLVM compiler 中的生成汇编代码部分（Clang 输出可执行文件的一条龙过程，不会生成汇编文件，内部全部走中间表示，生成汇编码和生成目标文件是并列的。 

gcc 的汇编器，输入是汇编代码，输出是目标文件，相当于是 LLVM 中的 llvm-mc（这是另一个工具，Clang 一条龙默认不走这个工具，但会调用相同的库来做汇编指令的下降和发射）。 

gcc 的链接器，输入是目标文件，输出是最终可执行文件，相当于 LLVM 中的 Linker，现在 LLVM Linker 还在开发中（已释出，叫 lld，但仍然不成熟），所以 Clang 驱动程序调起来的链接器还是系统链接器，可以选择使用 gcc 的 ld（这块会很快变，LLVM 社区必然会在 lld 成熟后默认换上去，大家可以自行验证）。