---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

inDy（invokedynamic）是 java 7 引入的一条新的虚拟机指令，这是自 1.0 以来第一次引入新的虚拟机指令。到了 java 8 这条指令才第一次在 java 应用，用在 lambda 表达式中。 indy 与其他 invoke 指令不同的是它允许由应用级的代码来决定方法解析。所谓应用级的代码其实是一个方法，在这里这个方法被称为引导方法（Bootstrap Method），简称 BSM。BSM 返回一个 CallSite（调用点） 对象，这个对象就和 inDy 链接在一起了。以后再执行这条 inDy 指令都不会创建新的 CallSite 对象。CallSite 就是一个 MethodHandle（方法句柄）的 holder。方法句柄指向一个调用点真正执行的方法。

我对上面内容的解释，就是通过引导方法，创建相关的 methodHandle 执行环境，并组成 CallSite。然后等待字节码层面上的调用，也就是 inDy。

### MethodHandle

一个 java 方法的实体有四个构成：

- 方法名
- 签名 -- 参数列表和返回值
- 定义方法的类
- 方法体（代码）

```Shell
Object rcvr = "a";
try {
    MethodType mt = MethodType.methodType(int.class); // 方法签名
    MethodHandles.Lookup l = MethodHandles.lookup(); // 调用者，也就是当前类。调用者决定有没有权限能访问到方法
    MethodHandle mh = l.findVirtual(rcvr.getClass(), "hashCode", mt); //分别是定义方法的类，方法名，签名

    int ret;
    try {
        ret = (int)mh.invoke(rcvr); // 代码，第一个参数就是接收者, **理解上这一步就是 inDy**
        System.out.println(ret);
    } catch (Throwable t) {
        t.printStackTrace();
    }
} catch (IllegalArgumentException | NoSuchMethodException | SecurityException e) {
    e.printStackTrace();
} catch (IllegalAccessException x) {
    x.printStackTrace();
}
```

### Lambda 表达式 和 inDy

> 这里的主要方法和上文大同小异，但是核心是需要 1、创建匿名类并导入到 JVM 中。2、创建 CallSite

接下来就是执行 `LambdaMetafactory.metafactory` 方法了，它会创建一个匿名类，这个类是通过 [ASM](http://asm.ow2.org/) 编织字节码在内存中生成的，然后直接通过 unsafe 直接加载而不会写到文件里。不过可以通过下面的虚拟机参数让它运行的时候输出到文件

```Plain Text
-Djdk.internal.lambda.dumpProxyClasses=<path>
```

这个类是根据 lambda 的特点生成的，输出后可以看到，在这个例子中是这样的：

```Shell
import java.lang.invoke.LambdaForm.Hidden;

// $FF: synthetic class
final class LambdaTest$$Lambda$1 implements Runnable {
    private final String[] arg$1;

    private LambdaTest$$Lambda$1(String[] var1) {
        this.arg$1 = var1;
    }

    private static Runnable get$Lambda(String[] var0) {
        return new LambdaTest$$Lambda$1(var0);
    }

    @Hidden
    public void run() {
        LambdaTest.lambda$main$0(this.arg$1);
    }
}
```

然后就是创建一个 CallSite，绑定一个 MethodHandle，指向的方法其实就是生成的类中的静态方法 `LambdaTest$$Lambda$1.get$Lambda(String[])Runnable`。然后把调用点对象返回，到这里 BSM 方法执行完毕。