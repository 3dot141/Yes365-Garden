---
aliases: []
created_date: 2023-08-25 16:00
draft: false
summary: ''
tags:
- dev
---

## 1 宕机概要

======

1.1 定义
------

向服务器的请求都没有响应或者响应非常慢。

> 前端界面的崩溃并非宕机。

1.2 分类
------

- 进程闪退
    - 内部崩溃
    - 外部终止
- 线程锁死或者无限等待
- 内存溢出

下面分别进行详解

2 进程闪退
======

2.1 内部崩溃
--------

JVM 发生内部崩溃，必然会生成"hs\_err\_pid"开头的文件。

下面讲一种常见情况:

- 无法申请内存，显示 `commit_memory` 错误

```java

Current thread (0x00007f3e40013000):  JavaThread "Unknown thread" [_thread_in_vm, id=11408, stack(0x00007f3e49983000,0x00007f3e49a84000)]
 
Stack: [0x00007f3e49983000,0x00007f3e49a84000],  sp=0x00007f3e49a82360,  free space=1020k
Native frames: (J=compiled Java code, j=interpreted, Vv=VM code, C=native code)
V  [libjvm.so+0x9a32da]  VMError::report_and_die()+0x2ea
V  [libjvm.so+0x497f7b]  report_vm_out_of_memory(char const*, int, unsigned long, char const*)+0x9b
V  [libjvm.so+0x81fcce]  os::Linux::commit_memory_impl(char*, unsigned long, bool)+0xfe
V  [libjvm.so+0x820219]  os::pd_commit_memory(char*, unsigned long, unsigned long, bool)+0x29
V  [libjvm.so+0x819faa]  os::commit_memory(char*, unsigned long, unsigned long, bool)+0x2a
V  [libjvm.so+0x99eae9]  VirtualSpace::expand_by(unsigned long, bool)+0x1c9
V  [libjvm.so+0x99ec6d]  VirtualSpace::initialize(ReservedSpace, unsigned long)+0xcd
V  [libjvm.so+0x57962f]  CardGeneration::CardGeneration(ReservedSpace, unsigned long, int, GenRemSet*)+0x11f
V  [libjvm.so+0x46ceed]  ConcurrentMarkSweepGeneration::ConcurrentMarkSweepGeneration(ReservedSpace, unsigned long, int, CardTableRS*, bool, FreeBlockDictionary<FreeChunk>::DictionaryChoice)+0x5d
V  [libjvm.so+0x57a906]  GenerationSpec::init(ReservedSpace, int, GenRemSet*)+0x106
V  [libjvm.so+0x56afe4]  GenCollectedHeap::initialize()+0x344
V  [libjvm.so+0x9751aa]  Universe::initialize_heap()+0xca
V  [libjvm.so+0x976379]  universe_init()+0x79
V  [libjvm.so+0x5b1d25]  init_globals()+0x65
V  [libjvm.so+0x95dc6d]  Threads::create_vm(JavaVMInitArgs*, bool*)+0x1ed
V  [libjvm.so+0x639fe4]  JNI_CreateJavaVM+0x74

```

这一般是因为 `Xmx` 设置过大，超过系统可用内存，JVM 申请内存失败。

比如服务器总内存 32G ，同时运行多个程序,程序 A 配了 20GXmx,其他程序也配了 20G Xmx ，Linux 的交换空间也没有设置，这时候如果其他程序用满 20G 内存那么服务的可用内存必然低于 12G，这时如果 Tomcat 需要大于 12G 的内存就很容易发生该错误，直接宕机!

### 解决方案

- 减少 Xmx 值使得所有的综合不超过服务器物理内存
- 调整 Xms=Xmx
- 服务器不要运行其他不必要的东西
- 配置一部分 swap 空间（虚拟内存）

2.2 外部终止
--------

如果找不到"hs\_err\_pid"开头的文件，那么这个进程的闪退必然是被从外部终止的。

### 2.2.1 OOMKiller

java 长期内存占用过高，系统需要内存使用的时候没有内存，Linux 的 oomkiller 机制会干掉最低优先级的内存

检查 /var/logs/message ， /var/logs/dmesg 或者对应日期文件，看看有没有类似下面的内容，日志有时间可以判断  
![](Attachments/18c4bcd21c8bd74564d7243dc7a02197_MD5.png)

### 2.2.2 SSH 注销

检查/var/log/auth.log，/var/log/secure 或者对应日期的文件，检查宕机的时间点有没有  
![](Attachments/9b25136280b48dfd7197e1ff13066cea_MD5.png)
  
时间吻合，那么宕机原因即可确认。

### 解决方案

使用 nohup 命令在后台运行启动程序，检查 ssh 注销原因

### 2.2.3 其他人为因素

不是很好判断，需要给 shell 加上操作记录

3 死/无限等待
==================================================================================================

- 表现  
    系统无法访问时，当前 cpu 占用非常低

使用 jstack 命令输出线程堆栈即可

```java
jstack pid >> 1.txt

or

jstack -F pid >> 1.txt

```

都行,或者用 jprofiler 工具看堆栈，或者其他任何可以拿到堆栈的工具都可以， java 的堆栈就是 java 方法调用的路径，可以定位一些简单的问题

4 内存溢出
======

- 现象  
    CPU 全部占满，内存达到配置 Xmx 最大值

4.1 CPU 占满缘由
-----------

并不是 CPU 不够用，而是涉及到 JVM 的 GC 机制，大部分情况来说 CPU 都是过剩的

JVM 使用 GC 的方法来回收没有被引用的内存块，在当前的回收机制中，回收器是并发进行的，回收的线程个数有一个公式：

当 CPU 核心数

- 小于 8  
    1 个核心对应一个 gc 线程
- 大于 8  
    gc 的线程数= 8 + ((N - 8) * 5/8)

N 代表核心的数量，这是默认的 gc 线程创建公式

```bash
threads = N <= 8 ? N : (8 + ((N - 8) * 5/8))
```

当然也可以通过参数 `-XX:ParallelCMSThreads=20` 来配置 GC 线程数，就不会使用默认的设置，默认情况下不要调整，因为调了也没什么卵用，最多在宕机的时候 cpu 占用按照你设定的值来。

当发生内存溢出的时候，或者快要内存溢出的时候，不一定是内存溢出，JVM 发现内存不够了，就会 GC，所有线程开始工作，暂停 JVM 运行，开始回收，如果回收到内存了，ok，jvm 可以正确继续执行，

这也就是为什么有时候配置内存溢出的参数没有自动生成 dump 的原因，因为他能运行，但是比较慢，所以没有 OOM，就不会生成 dump，

如果没有回收到什么内存，gc 会循环持续执行，这就导致了 cpu 全部占满的现象，所以说内存溢出的时候，一定伴随 cpu 占满（按照设置或者公式计算的线程量）

4.2 JVM 内存分配机制
-------------

在说说 JVM 怎么分配内存的，大家都知道给客户配置 Xmx 参数和 xms 参数，Xmx 代表的是最大堆内存，xms 代表的是最小堆内存，至于 permsize 就和这些都没有关系，不能算在内存溢出，遇到抛错 outofmemory permsize 什么的调大就行了

permsize 是一个被 jvm 也抛弃的参数只存在 1.7 之前的 jdk 中，是用来保存 java 的 class 等内容的存储空间，1.8 被 metaspace 替代

这个内存怎么不回收的啊，一问都是在任务管理器看的!这个地方是看不到内存回收的，或者说他也会回收，但是可能要等个好几天才会回收一次，可以忽略这种机制的存在

### 形而上学

#### WC 论

如果把内存比喻成茅坑，操作系统 64g 内存就是一共 64 个茅坑，那么 JVM 的内存回收相当于茅坑调度系统，每个 gc 线程相当于调度系统派出去的茅坑检查员，给 jvm 设置了 Xms=2g， Xmx=32g，那么程序启动，jvm 直接占了两个茅坑，任务管理器看到内存占用 2g，即使没人上厕所，JVM 也不会把坑还给操作系统。

假设一个人上厕所 10 秒，一开始的时候 20 秒有一个人来上厕所，那么 jvm 通过茅坑检查员发现哎两个坑总有一个是空的，维持茅坑数量不变，内存的占用一直是 2g，过了些时候，来的人开始增多了，变成 5 秒有一个人来上厕所，茅坑检查员向 JVM 汇报有人开始有排队了，两个坑位很紧张，不行要多弄几个坑才行，于是，jvm 向系统又申请了两个坑，任务管理器可以看到内存占用变成了 4 个 G，这时候又突然发生压力增大，变成了 1 秒来一个人，4 个坑肯定不够啊，于是 jvm 又把内存扩容到 10-11g，现在够用了，任务管理器会看到内存一直维持在 10-11g，终于大家都上完厕所了，没人排队了，茅坑都空出来了。  
但是，jvm 是个霸道总裁，被他占的东西，除非死不然不会吐出来的，所以任务管理器里面看到内存还是 10-11g 不会降低，除非 jvm 死了，实际没有任何内存占用（所以不要再说内存不回收的问题，这个内存的回收不回收和宕机是没有直接关系的）

如果这时候突然一下子来了很多很多人，比如一下子来了 64 个人要上厕所，这时候会怎样了，JVM 把他的所有的茅坑检查员都派出去检查啊，然后发现完蛋了茅坑不够用啊，申请到 32 个都不够用啊，于是 jvm 的特派茅坑检查员就一个坑一个坑的拍，一个坑一个坑的催，结果呢，检查员在催，大家就拉不出来了，上厕所的时间无限期延长，外面的人要进去，里面的人出不来，BOOM，厕所就不响应了，后面来的人都拉裤子了。

#### 怎么解决?

- 换个茅坑管理员，更好的调度茅坑检查员和分配茅坑，这就有了 G1 回收器，茅坑越多效果越好，目前 JDK 情况内存大于 10G 的情况 G1 的效果好于 CMS，低于 10G 的情况下不如 CMS
- 从源头控制人员，不要一下子来这么多人（申请内存），也就是常见的不要让业务查大量数据占内存。

而上面讲的线程锁死的情况要做类比的话，就是 32 个坑呗 32 个人占了，还死活不肯出来，导致后面排队的人失去响应了。

### 没有味道的比喻

解释一下 java 的面向对象和对象引用:  
一栋大楼，10 层共 1000 个工位 （类比物理内存）。  
包给一个二房东中介公司 Z （jvm）。  
中介公司和大楼物业谈好弹性缴费，租多少出去收多少钱。

Z 公司先一下租 300 个位置 （类比 Xms）省钱，  
Z 公司和物业谈好最多租 600 个位置（类比 Xmx）。  
Z 公司找到了公司 A(200 人)来这里就占用了 200 个工位 （类比一次数据查询）。

公司 A 是一个大的对象，每个人类比最小的单元格，每个小团队也是一个对象，个人被小团队引用，小团队又被更上级的比如产品，比如大技术支持大团队引用，大团队又被公司引用，最终公司这个大对象占用了 200 工位，类比下来 200 个工位内存不释放的根就是这个公司在这儿上班。

这时候公司 A 倒闭了，200 个工位就空出来了(内存释放)。

- 内存溢出宕机是什么情况呢？  
    找 Z 公司租工位的公司，总工位超过了 600，总不能坐大腿上上班啊，于是物业不会给 Z 工位的，合同写的好好的，Z 公司不满足客户需求，运作不起来破产倒闭。
    
- 经常遇到的申请内存失败的崩溃是什么情况？  
    物业是个滑头，不止找了 Z 公司一家中介，还有 Y 公司也是做中介的(类比两个 JVM)。都承诺 Z 和 Y 公司都是最多可以租 600 个位置。初始都租的 300 个位置，大家相处融洽，随着公司不停入住，矛盾出现了：  
    Y 公司效益比较好，先找了公司，已经占了 600 位置；  
    这时候 Z 公司的效益也上来了，也要增加工位 （类比申请内存），这时候物业根本没有位置能给他。于是 Z 公司运转不下去，破产倒闭

5 总结
====

宕机分析的目的就是要找到占用内存的东西，把他找出来，找出他的原因，然后把它改掉。JVM 的内存对象分配相当于一颗树，所有的对象都被层层引用，直到 GCRoot 根节点，如果没有根节点的引用，这个对象是完全可以直接释放掉的，大部分也是因为 gcRoot 存在的对象过多导致的宕机，当然也不排除可以使用已经回收的对象来分析，由于生成 dump 的时间不精确，可能他生成的时候，对应的大组件已经回收了，但是 jvm 缓过来还需要一些时间，所以还是处于大量 gc 的状态，这时候只能通过对于引用的检索找到最多的引用对象来进行分析