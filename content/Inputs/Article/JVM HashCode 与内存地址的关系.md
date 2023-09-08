---
aliases: []
created_date: 2023-08-24 19:31
draft: false
summary: ''
tags:
- dev
---

## 简介

最近在看 dubbo 源码时，经常看到 System.identityHashCode(obj) 的使用，想了解一下这个跟我们平常的 hashcode 方法又有啥异同，所以本篇简单的探讨一下。

## 概念

1、hashCode 是 java.lang.Object.hashCode() 或者 java.lang.System.identityHashCode(obj) 会返回的值。他是一个对象的身份标识。官方称呼为：标识哈希码（ identity hash code）。

2、哪些特点?  
1. 一个对象在其生命期中 identity hash code 必定保持不变；  
2. 如果 a == b，那么他们的 System.identityHashCode() 必须相等；  
如果他们的 System.identityHashCode() 不相等，那他们必定不是同一个对象（逆否命题与原命题真实性总是相同）；  
3. 如果 System.identityHashCode() 相等的话，并不能保证 a == b（毕竟这只是一个散列值，是允许冲突的）。  

3、有什么作用？  
加速对象去重：由特征 2 可知，只要判断出两个对象的 hashCode 不一致，就知道这两个对象不是同一个；又因为 hashCode()的性能比 " == "性能高得多，所以多数时候，用它来判断重复。

> 扩展：为啥 hashCode()性能高？  
> 因为 hashCode()的结果算出来后缓存起来，下次调用直接用不需要重新计算，提高性能

### identityHashCode

看官方提供的 API , 对 System.identityHashCode()的解释为 :  
public static int **identityHashCode** (\[Object\] x)

> 返回给定对象的哈希码，该代码与默认的方法 hashCode() 返回的代码一样，无论给定对象的类是否重写 hashCode()。null 引用的哈希码为 0。

### obj.hashcode()

> hashCode()方法是顶级类 Object 类的提供的一个方法，所有的类都可以进行对 hashCode 方法重写。这时 hash 值计算根据重写后的 hashCode 方法计算

### 异同

从上面的概念可以看出 identityHashCode 是根据 Object 类 hashCode()方法来计算 hash 值，无论子类是否重写了 hashCode()方法。而 obj.hashcode()是根据 obj 的 hashcode()方法计算 hash 值

### 验证

```
 @Test
    public void testHashCode() {
        TestExample example = new TestExample();
        int exampleCode = System.identityHashCode(example);
        int exampleCode2 = System.identityHashCode(example);
        int exampleHashcode = example.hashCode();
        System.out.println("example identityHashCode:" + exampleCode);
        System.out.println("example2 identityHashCode:" + exampleCode2);
        System.out.println("example Hashcode:" + exampleHashcode);
        String str = "dd";
        String str2 = "dd";
        int strCode = System.identityHashCode(str);
        int strHashCode = str.hashCode();
        int str2HashCode = str.hashCode();
        System.out.println("str identityHashCode:" + strCode);
        System.out.println("str hashcode:" + strHashCode);
        System.out.println("str2 hashcode:" + str2HashCode);
    }
输出：
example identityHashCode:1144748369
example2 identityHashCode:1144748369
example Hashcode:1144748369
str identityHashCode:340870931
str hashcode:3200
str2 hashcode:3200 
```

结果分析：  
（1）从上面样例可以看出，TestExample 对象没重写 HashCode()方法，所以两个都是调用 Object 的 HashCode()方法，自然结果一样。  
而 String 重写了 HashCode()方法，identityHashCode 和 HashCode 结果自然不一样。  
（2）str 和 str2 的 hashCode 是相同的，是因为 String 类重写了 hashCode 方法，它根据 String 的值来确定 hashCode 的值，所以只要值一样，hashCode 就会一样。

### hashCode 如何计算的？

JDK8 hashCode( )源码:  
进入 openjdk\jdk\\src\\share\classes\java\\lang 目录下，可以看到 Object.java 源码

```
public native int hashCode(); 
```

即该方法是一个本地方法，Java 将调用本地方法库对此方法的实现。由于 Object 类中有 JNI 方法调用，按照 JNI 的规则，应当生成 JNI 的头文件，在此目录下执行 **javah -jni java.lang.Object** 指令，将生成一个 **java_lang_Object.h** 头文件，  

![](Attachments/c7427442e80f2977160f440f263c9bf0_MD5.webp)

 **java\_lang\_Object.h** 头文件关于 hashcode 方法的信息如下所示：

```
/*
 * Class:     java_lang_Object
 * Method:    hashCode
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_java_lang_Object_hashCode
  (JNIEnv *, jobject); 
```

###### 1\. Object 对象的 hashCode()方法在 C 语言文件 Object.c 中实现

打开 openjdk\jdk\\src\\share\\native\java\\lang 目录，查看 Object.c 文件，可以看到 **hashCode()** 的方法被注册成有 **JVM_IHashCode** 方法指针来处理：

```
/*-
 *      Implementation of class Object
 *
 *      former threadruntime.c, Sun Sep 22 12:09:39 1991
 */

#include <stdio.h>
#include <signal.h>
#include <limits.h>

#include "jni.h"
#include "jni_util.h"
#include "jvm.h"
//使用了上面生成的java_lang_Object.h文件
#include "java_lang_Object.h"

static JNINativeMethod methods[] = {
    {"hashCode",    "()I",                    (void *)&JVM_IHashCode},//hashcode的方法指针JVM_IHashCode
    {"wait",        "(J)V",                   (void *)&JVM_MonitorWait},
    {"notify",      "()V",                    (void *)&JVM_MonitorNotify},
    {"notifyAll",   "()V",                    (void *)&JVM_MonitorNotifyAll},
    {"clone",       "()Ljava/lang/Object;",   (void *)&JVM_Clone},
}; 
```

###### 2.JVM_IHashCode 方法指针

在 openjdk\hotspot\\src\\share\\vm\\prims\\jvm.cpp 中定义，如下：

```
// java.lang.Object ///////////////////////////////////////////////

JVM_ENTRY(jint, JVM_IHashCode(JNIEnv* env, jobject handle))
  JVMWrapper("JVM_IHashCode");
  // as implemented in the classic virtual machine; return 0 if object is NULL
  return handle == NULL ? 0 : ObjectSynchronizer::FastHashCode (THREAD, JNIHandles::resolve_non_null(handle)) ;
JVM_END 
```

如上可以看出， **JVM_IHashCode** 方法中调用了 **ObjectSynchronizer::FastHashCode** 方法

###### 3\. ObjectSynchronizer **::** fashHashCode 方法的实现：

 **ObjectSynchronizer::fashHashCode()** 方法在 hotspot\\src\\share\\vm\runtime\\synchronizer.cpp

```
// hashCode() generation :
//
// Possibilities:
// * MD5Digest of {obj,stwRandom}
// * CRC32 of {obj,stwRandom} or any linear-feedback shift register function.
// * A DES- or AES-style SBox[] mechanism
// * One of the Phi-based schemes, such as:
//   2654435761 = 2^32 * Phi (golden ratio)
//   HashCodeValue = ((uintptr_t(obj) >> 3) * 2654435761) ^ GVars.stwRandom ;
// * A variation of Marsaglia's shift-xor RNG scheme.
// * (obj ^ stwRandom) is appealing, but can result
//   in undesirable regularity in the hashCode values of adjacent objects
//   (objects allocated back-to-back, in particular).  This could potentially
//   result in hashtable collisions and reduced hashtable efficiency.
//   There are simple ways to "diffuse" the middle address bits over the
//   generated hashCode values:
//
//最终生成hash的方法
static inline intptr_t get_next_hash(Thread * Self, oop obj) {
  intptr_t value = 0 ;
  if (hashCode == 0) {
     // This form uses an unguarded global Park-Miller RNG,
     // so it's possible for two threads to race and generate the same RNG.
     // On MP system we'll have lots of RW access to a global, so the
     // mechanism induces lots of coherency traffic.
     value = os::random() ;
  } else
  if (hashCode == 1) {
     // This variation has the property of being stable (idempotent)
     // between STW operations.  This can be useful in some of the 1-0
     // synchronization schemes.
     intptr_t addrBits = cast_from_oop<intptr_t>(obj) >> 3 ;
     value = addrBits ^ (addrBits >> 5) ^ GVars.stwRandom ;
  } else
  if (hashCode == 2) {
     value = 1 ;            // for sensitivity testing
  } else
  if (hashCode == 3) {
     value = ++GVars.hcSequence ;
  } else
  if (hashCode == 4) {
     value = cast_from_oop<intptr_t>(obj) ;
  } else {
     // Marsaglia's xor-shift scheme with thread-specific state
     // This is probably the best overall implementation -- we'll
     // likely make this the default in future releases.
     unsigned t = Self->_hashStateX ;
     t ^= (t << 11) ;
     Self->_hashStateX = Self->_hashStateY ;
     Self->_hashStateY = Self->_hashStateZ ;
     Self->_hashStateZ = Self->_hashStateW ;
     unsigned v = Self->_hashStateW ;
     v = (v ^ (v >> 19)) ^ (t ^ (t >> 8)) ;
     Self->_hashStateW = v ;
     value = v ;
  }

  value &= markOopDesc::hash_mask;
  if (value == 0) value = 0xBAD ;
  assert (value != markOopDesc::no_hash, "invariant") ;
  TEVENT (hashCode: GENERATE) ;
  return value;
}
//ObjectSynchronizer::FastHashCode方法的实现，该方法最终会返回hashcode
intptr_t ObjectSynchronizer::FastHashCode (Thread * Self, oop obj) {
  if (UseBiasedLocking) {
    // NOTE: many places throughout the JVM do not expect a safepoint
    // to be taken here, in particular most operations on perm gen
    // objects. However, we only ever bias Java instances and all of
    // the call sites of identity_hash that might revoke biases have
    // been checked to make sure they can handle a safepoint. The
    // added check of the bias pattern is to avoid useless calls to
    // thread-local storage.
    if (obj->mark()->has_bias_pattern()) {
      // Box and unbox the raw reference just in case we cause a STW safepoint.
      Handle hobj (Self, obj) ;
      // Relaxing assertion for bug 6320749.
      assert (Universe::verify_in_progress() ||
              !SafepointSynchronize::is_at_safepoint(),
             "biases should not be seen by VM thread here");
      BiasedLocking::revoke_and_rebias(hobj, false, JavaThread::current());
      obj = hobj() ;
      assert(!obj->mark()->has_bias_pattern(), "biases should be revoked by now");
    }
  }

  // hashCode() is a heap mutator ...
  // Relaxing assertion for bug 6320749.
  assert (Universe::verify_in_progress() ||
          !SafepointSynchronize::is_at_safepoint(), "invariant") ;
  assert (Universe::verify_in_progress() ||
          Self->is_Java_thread() , "invariant") ;
  assert (Universe::verify_in_progress() ||
         ((JavaThread *)Self)->thread_state() != _thread_blocked, "invariant") ;

  ObjectMonitor* monitor = NULL;
  markOop temp, test;
  intptr_t hash;
  markOop mark = ReadStableMark (obj);

  // object should remain ineligible for biased locking
  assert (!mark->has_bias_pattern(), "invariant") ;

  if (mark->is_neutral()) {
    hash = mark->hash();              // this is a normal header
    if (hash) {                       // if it has hash, just return it
      return hash;
    }
  //调用get_next_hash生成hashcode
    hash = get_next_hash(Self, obj);  // allocate a new hash code
    temp = mark->copy_set_hash(hash); // merge the hash code into header
    // use (machine word version) atomic operation to install the hash
    test = (markOop) Atomic::cmpxchg_ptr(temp, obj->mark_addr(), mark);
    if (test == mark) {
      return hash;
    }
    // If atomic operation failed, we must inflate the header
    // into heavy weight monitor. We could add more code here
    // for fast path, but it does not worth the complexity.
  } else if (mark->has_monitor()) {
    monitor = mark->monitor();
    temp = monitor->header();
    assert (temp->is_neutral(), "invariant") ;
    hash = temp->hash();
    if (hash) {
      return hash;
    }
    // Skip to the following code to reduce code size
  } else if (Self->is_lock_owned((address)mark->locker())) {
    temp = mark->displaced_mark_helper(); // this is a lightweight monitor owned
    assert (temp->is_neutral(), "invariant") ;
    hash = temp->hash();              // by current thread, check if the displaced
    if (hash) {                       // header contains hash code
      return hash;
    }
    // WARNING:
    //   The displaced header is strictly immutable.
    // It can NOT be changed in ANY cases. So we have
    // to inflate the header into heavyweight monitor
    // even the current thread owns the lock. The reason
    // is the BasicLock (stack slot) will be asynchronously
    // read by other threads during the inflate() function.
    // Any change to stack may not propagate to other threads
    // correctly.
  }

  // Inflate the monitor to set hash code
  monitor = ObjectSynchronizer::inflate(Self, obj);
  // Load displaced header and check it has hash code
  mark = monitor->header();
  assert (mark->is_neutral(), "invariant") ;
  hash = mark->hash();
  if (hash == 0) {
    hash = get_next_hash(Self, obj);
    temp = mark->copy_set_hash(hash); // merge hash code into header
    assert (temp->is_neutral(), "invariant") ;
    test = (markOop) Atomic::cmpxchg_ptr(temp, monitor, mark);
    if (test != mark) {
      // The only update to the header in the monitor (outside GC)
      // is install the hash code. If someone add new usage of
      // displaced header, please update this code
      hash = test->hash();
      assert (test->is_neutral(), "invariant") ;
      assert (hash != 0, "Trivial unexpected object/monitor header usage.");
    }
  }
  // We finally get the hash
  return hash;
} 
```

从上面代码可以看出生成 hash 最终由 get_next_hash 函数生成，该函数提供了基于某个 hashCode 变量值的六种方法。怎么生成最终值取决于 hashCode 这个变量值。

##### **6 种 hashCode 算法** 

0 - 使用 Park-Miller 伪随机数生成器（跟地址无关）  
1 - 使用地址与一个随机数做异或（地址是输入因素的一部分）  
2 - 总是返回常量 1 作为所有对象的 identity hash code（跟地址无关）  
3 - 使用全局的递增数列（跟地址无关）  
4 - 使用对象地址的“当前”地址来作为它的 identity hash code（就是当前地址）  
5 - 使用线程局部状态来实现 Marsaglia's xor-shift 随机数生成（跟地址无关）

##### **扩展补充：Xorshift 算法介绍** 

> Xorshift 随机数生成器是 George Marsaglia 发明的一类伪随机数生成器。它们通过和自己逻辑移位后的数进行异或操作来生成序列中的下一个数。这在现代计算机体系结构非常快。它们是线性反馈移位寄存器的一个子类，其简单的实现使它们速度更快且使用更少的空间。然而，必须仔细选择合适参数以达到长周期。  
> Xorshift 生成器是非密码安全的随机数生成器中最快的一种，只需要非常短的代码和状态。虽然它们没有进一步改进以通过统计检验，这个缺点非常著名且容易修改（Marsaglia 在原来的论文中指出），用复合一个非线性函数的方式，可以得到比如像 xorshift\+ 或 xorshift* 生成器。一个简单的 C 语言实现的 xorshift\+ 生成器通过了所有的 BigCrush 的测试（比 Mersenne Twister 算法和 WELL 算法的失败次数减少了一个数量级），而且在 x86 上产生一个随机数通常只需要不到十个时钟周期，多亏了指令流水线。

##### VM 到底用的是哪种方法？

在 openjdk\hotspot\\src\\share\\vm\runtime\\globals.hpp 定义  
JDK 8 和 JDK 9 默认值：

> product(intx, hashCode, 5,"(Unstable) select hashCode generation algorithm") ;

JDK 8 以前默认值：

> product(intx, hashCode, 0,"(Unstable) select hashCode generation algorithm") ;  
> 不同的 JDK，生成方式不一样。

注意：  
虽然方式不一样，但有个共同点：java 生成的 hashCode 和对象内存地址没什么关系。

###### 修改生成方法

HotSpot 提供了一个 VM 参数来让用户选择 identity hash code 的生成方式：  
`-XX:hashCode`

### 什么时候计算出来的

在 VM 里，Java 对象会在首次真正使用到它的 identity hash code（例如通过 Object.hashCode() / System.identityHashCode()）时调用 VM 里的函数来计算出值，然后会保存在对象里，后面对同一对象查询其 identity hash code 时总是会返回最初记录的值。  
因此，不是对象创建时。

对此以 Hotspot 为例，最直接的实现方式就是在对象的 header 区域中划分出来一部分（32位机器上是占用25位，64位机器上占用31）用来存储 hashcode 值。但这种方式会添加额外信息到对象中，而在大多数情况下 hashCode 方法并不会被调用，这就造成空间浪费。

那么JVM是如何进行优化的呢？当hashCode方法未被调用时，object header中用来存储hashcode的位置为0，只有当hashCode方法（本质上是System#identityHashCode）首次被调用时，才会计算对应的hashcode值，并存储到object header中。当再次被调用时，则直接获取计算好hashcode即可。  
 **上述实现方式就保证了即使 GC 发生，对象地址发生了变化，也不影响 hashcode 的值。比如在 GC 发生前调用了 hashCode 方法，hashcode 值已经被存储，即使地址变了也没关系；在 GC 发生后调用 hashCode 方法更是如此。** 

#### 验证

上面说了 hashcode 值的存储逻辑，那么是否可以从侧面证明一下呢？我们依旧采用 [JOL 依赖类库](../../Daily/2023/2023-08-24.md#JOL%20依赖类库) ，来写一个程序查看一下 hashCode 方法被调用之后，Object header 中信息的变化。

```
// 创建对象并打印JVM中对象的信息
Object person = new Object();
System.out.println(ClassLayout.parseInstance(person).toPrintable());
// 调用hashCode方法，如果重写了hashCode方法则调用System#identityHashCode方法
System.out.println(person.hashCode());
// System.out.println(System.identityHashCode(person));
// 再次打印对象JVM中的信息
System.out.println(ClassLayout.parseInstance(person).toPrintable());
```

执行上述程序，控制台打印如下：

```
java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                               VALUE
      0     4        (object header)                           01 00 00 00 (00000001 00000000 00000000 00000000) (1)
      4     4        (object header)                           00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4        (object header)                           e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

1898220577
java.lang.Object object internals:
 OFFSET  SIZE   TYPE DESCRIPTION                               VALUE
      0     4        (object header)                           01 21 8c 24 (00000001 00100001 10001100 00100100) (613163265)
      4     4        (object header)                           71 00 00 00 (01110001 00000000 00000000 00000000) (113)
      8     4        (object header)                           e5 01 00 f8 (11100101 00000001 00000000 11111000) (-134217243)
     12     4        (loss due to the next object alignment)
Instance size: 16 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total
```

复制

在调用hashCode方法前后，我们可以看到OFFSET为0的一行存储的值（Value），从原来的1变为613163265，也就是说将hashcode的值进行了存储。如果未调用对应方法，则不会进行存储 。

## 参考

[hashCode，一个实验引发的思考](https://zhuanlan.zhihu.com/p/28270828)