## 1.2 浮点数： 

符号位 + 阶码位 + 尾数位

1. 零值检测
2. 对阶操作
3. 尾数求和
4. 结果规格化
5. 结果舍入

高精度保存 - 数组保存小数部分的数据  
数据库保存小数 - decimal 类型

## 1.5 TCP/IP

TCP FLAG 位  
SYN (Synchronize Sequence Numbers), ACK (Acknowledgement),  
FIN (Finish), URG,PSH,RST  
都以置为 1 为有效

TCP 连接的建立是通过文件描述符 （File Descriptor , fd) 完成。  
fd 的数量由服务端进程和操作系统锁支持的最大文件句柄数决定。

```java
ulimit -n # 单个进程可以打开文件句柄的数量。

lsof -n | awk 'print $2}' | sort|uniq -c | sort -nr | more # 当前系统各个进程产生了多少句柄。
```

连接为什么要 3 次握手  
主要目的： 1. 信息对等 - 只有双方都确定 4 类消息才能建立连接 2. 防止超时 - 导致脏连接

断开的 4 次挥手  
这里有两个关键状态：

1. CLOSE_WAIT 被动关闭的机器
2. TIME_WAIT 主动关闭的机器 ， 等待 2MSL 后进入 CLOSED 状态。

目的：

1. 确认被动关闭方可以顺利进入 CLOSED 状态。 （结束状态）
2. **防止失效请求** - todo

减少 TIME_WAIT 的等待时间

```java
/etc/sysctl.conf
net.ipv4.tcp_fin_timeout = 30 (建议小于 30)
/sbin/sysctl -p # 让参数生效

netstat -n | awk '/^tcp/ {++S[$NF]} END {for (a in s) print a, S[a]}' # 查看各连接状态的计数情况。
```

连接池  
数据库连接池的连接数是由 fd 数量限制。默认是 1024 个

优化操作：  
1 - 7

## 1.6 CIA 原则

1. 保密性 (Confidentiality)
2. 完整性 (Integrity)
3. 可用性 (Availability)

## 2.1 OOP 理念

Object:  
我是谁 ： getClass(). toString()  
我从哪里来 ： Object(). clone()  
我到哪里去 ： finalize()  
世界是否因你而不同： hashCode() equals()  
与他人如何协作： wait(), notify()

抽象类： 里氏替换原则. (Liskov Substitution Principle, LSP)  
接口：接口隔离原则

## 2.3 类关系

依赖： 组合与聚合外的单向弱引用关系。比如使用另一个类的属性、方法、或以其作为方法的参数输入，或以其作为方法的返回值输出。

## 2.4 方法

### 2.4.1 参数预处理

1. 入参保护
2. 参数校验
    1. 调用频度低的方法
    2. 执行时间开销很大胡
    3. 需要极高稳定性和可用性的方法
    4. 对外提供的噶月入块
    5. 敏感权限入口。
3. 不需要
    1. 极有可能被循环调用的方法
    2. 底层调用频度较高的方法。

## 2.7 包装数据类型

除 Float 和 Double 外，都会缓存。

VM options -XX:AutoBoxCacheMax = xxx. 修改 Integer 缓存范围。

1. 所有的 pojo 类属性必须使用包装类型。
2. RPC 方法的返回值和参数必须使用包装数据类型。
3. 所有的**局部变量**推荐使用基本数据类型。

## 4.3 内存布局

Metaspace (元空间)  
JDK 8 之后， Perm 区， 也就是永久代被淘汰，  
字符串常量被移至堆内存。  
其他的内容包括类元信息，字段，静态属性、方法、常量都移至元空间。

## 5.3 npe 异常

推荐方法的返回值可以为 null . 不强制返回空集合或者空对象。  
但是必须添加注释充分说明什么情况下会返回 null 值。

防止 npe 一定是调用方的责任。需要调用方事先判断。

## 5.4 日志记录

1. 考虑日志的级别
2. 避免无效的日志打印
    1. 设置合理的生命周期。清理过期的日志
    2. 避免重复打印，再日志文件中设置 additivity =false
3. 区别对待错误日志。 -- todo
    1. Error = 系统逻辑错误， 异常， 或者违反重要的业务规则
    2. Warn = 除 Error 外的其他。
4. 保证记录内容完整
    1. 记录时一定要输出异常堆栈 `logger.error("xx" + e.getMessage(), e)
    2. 日志中的对象实例，一定要覆写 tostring() 方法。

## Cow 种族

## ThreadLocal

## 8.1 单元测试的基本原则

AIR : Automatic , Independent , Repeatable

保证交付质量： 需要符合 BCDE 原则：

1. B: Border 边界值测试： 包括循环边界、特殊取值、特殊时间点、数据顺序。
2. C: Correct 正确的输入，并得到预期的结果。
3. D：Design , 与设计文档相结合，来编写单元测试。
4. E: Error ， 单元测试的目标是证明程序有错，而不是程序无错。需要有一些强制的错误输入，（非法数据、异常流程、非业务允许输入）

Mock : 

1. 功能因素
2. 时间因素
3. 环境因素
4. 数据因素
5. 其他因素

## 8.2 覆盖率

1. 粗粒度的覆盖
    1. 类覆盖
    2. 方法覆盖
2. 细粒度的覆盖
    1. 行覆盖
    2. 分支覆盖
    3. 条件判定覆盖
    4. 条件组合覆盖

    junit5 需要 jdk8  
    assertJ 需要 

    ## 9.2 如何推动落地
    5. 立法透明
    6. 执法坚定
        1. 如何判断是否违反规约。
            1. 自动化工具
            2. 人工 review
        2. 如何进行奖惩
            1. 数据分析作为考核的工具。
    7. 组织支持。
