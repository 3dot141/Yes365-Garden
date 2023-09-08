---
aliases: []
created_date: 2023-08-24 19:31
draft: false
summary: ''
tags:
- dev
---

> JVM 进行 GC 操作时，通过标记整理算法，对象的内存地址会变么？

当对象的实际地址发生变化时，简单来说，JVM 会将指向该地址的一个或多个变量所使用的引用地址进行更新，从而达到在“不知不觉”中移动了对象的效果。

JVM 规范中只规定了引用类型是指向对象的引用，并没有限制具体的实现。  
因此，不同虚拟机的实现方式可能不同。通常有两种实现形式：句柄访问和直接指针访问。

### 句柄访问  

先来看一张图，句柄访问的形式是堆空间维护一个句柄池，对象引用中保存的是对象的句柄位置。在堆中的句柄包含对象的实例数据和类型数据的真实地址。

这种形式的实现好处很明显，引用中保存的对象句柄地址相对稳定（不变），当 GC 操作移动对象时只用维护句柄池中存储的信息即可，特别是多个变量都引用同一个句柄池中的句柄时，可以减少更新变量存储的引用，同时确保变量的地址不变。  
缺点就是多了一次中转，访问效率会有影响。

![525](Attachments/c891d561aa8515b4564c03fda730cbea_MD5.png)

### 直接指针访问  

直接指针访问省去了中间的句柄池，对象引用中保持的直接是对象地址。

这种方式很明显节省了一次指针定位的开销，访问速度快。但是当GC发生对象移动时，变量中保持的引用地址也需要维护，如果多个变量指向一个地址，需要更新多次。 **Hot Spot虚拟机** 便是基于这种方式实现的。

![525](Attachments/146d811d3255ae6ae660dca5e457fd93_MD5.png)

## 验证

我们先通过一个实例来验证一下 GC 前后对象地址和 hashcode 值的变化。在项目中引入 [2023-08-24#JOL 依赖类库](../../Daily/2023/2023-08-24.md#JOL%20依赖类库)

```
<dependency>
    <groupId>org.openjdk.jol</groupId>
    <artifactId>jol-core</artifactId>
    <version>0.10</version>
</dependency>
```

验证代码如下：

```
public class TestHashCode {

    public static void main(String[] args) {
        Object obj = new Object();
        long address = VM.current().addressOf(obj);
        long hashCode = obj.hashCode();
        System.out.println("before GC : The memory address is " + address);
        System.out.println("before GC : The hash code is " + hashCode);

        new Object();
        new Object();
        new Object();

        System.gc();

        long afterAddress = VM.current().addressOf(obj);
        long afterHashCode = obj.hashCode();
        System.out.println("after GC : The memory address is " + afterAddress);
        System.out.println("after GC : The hash code is " + afterHashCode);
        System.out.println("---------------------");

        System.out.println("memory address = " + (address == afterAddress));
        System.out.println("hash code = " + (hashCode == afterHashCode));
    }
}
```

上述代码执环境为Hotspot虚拟机，执行时如果未出现GC，则可将JVM参数设置的小一点，比如可以设置为16M：-Xms16m -Xmx16m -XX:+PrintGCDetails。

执行上述代码，打印日志如下：

```
before GC : The memory address is 31856020608
before GC : The hash code is 2065530879
after GC : The memory address is 28991167544
after GC : The hash code is 2065530879
---------------------
memory address = false
hash code = true
```

上面的控制台信息可以看出，GC 前后对象的地址的确变了，但 hashCode 却并未发生变化。同时也可以看出 hashcode 的值与内存地址的值是完全不一样的, 和预期 [JVM HashCode 与内存地址的关系#6 种 hashCode 算法](JVM%20HashCode%20与内存地址的关系.md#6%20种%20hashCode%20算法) 符合一致