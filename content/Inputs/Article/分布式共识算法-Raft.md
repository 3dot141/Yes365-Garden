---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

## 开源实现

- Etcd(Go 语言实现）
- Soft-Jraft(Java 语言，阿里开源)
- 百度工程师开源的 Java 实现
	- [https://github.com/wenweihu86/raft-java](https://xie.infoq.cn/link?target=https%3A%2F%2Fgithub.com%2Fwenweihu86%2Fraft-java)  
- 支付宝工程师实现
	- [https://github.com/xnnyygn/xraft](https://xie.infoq.cn/link?target=https%3A%2F%2Fgithub.com%2Fxnnyygn%2Fxraft)

## 应用

- Raft 算法的应用：
    - 分布式KV系统，etcd
    - 微服务基础设施，consul

## 简介

Raft 会先选举出 leader，leader 完全负责 replicated log 的管理。leader 负责接受所有客户端更新请求，然后复制到 follower 节点，并在“安全”的时候执行这些请求。如果 leader 故障，followes 会重新选举出新的 leader。

Raft 是一个非 **[拜占庭](分布式共识问题-拜占庭将军问题.md)** 的一致性算法，即所有通信是正确的而非伪造的。N 个结点的情况下（N 为奇数）可以最多容忍 (N−1)/2 个结点故障。

## 基本知识

### 复制状态机

共识算法的实现一般是基于复制状态机（Replicated state machines），何为复制状态机：

> If two identical, **deterministic** processes begin in the same state and get the same inputs in the same order, they will produce the same output and end in the same state.

   简单来说：**相同的初识状态 + 相同的输入 = 相同的结束状态**。引文中有一个很重要的词`deterministic`，就是说不同节点要以相同且确定性的函数来处理输入，而不要引入一些不确定的值，比如本地时间等。如何保证所有节点 `get the same inputs in the same order`，使用replicated log是一个很不错的注意，log具有持久化、保序的特点，是大多数分布式系统的基石。

  因此，可以这么说，在raft中，leader将客户端请求（command）封装到一个个log entry，将这些log entries复制（replicate）到所有follower节点，然后大家按相同顺序应用log entry中的command，则状态肯定是一致的。

[NaN](Attachments/688f57bf42f7b01c27747fa27812773d_MD5.png)

如上图，在这个server中记录了日志 `x<-3,y<-1,y-9`(第二步)，那么日志发送给其他server之后(第二步)，其他server的状态也会和这个一致(第三步).

结合数据库来看，数据库会产生日志，实际上就是状态机中的 log 模块，数据库之间同步的时候，会先把日志部分同步到其他机器上，通过 raft 协议认证过日志之后(主要是在第二步)，就可以应用到数据库当中。

### 三种角色

- Leader: 响应客户端的请求，同步数据
- Candidate: Leader选举时的状态，获得多数选票可担任Leader
- Follower: 初始启动状态，接收日志同步请求并响应

### 三种远程过程调用(RPC)

- RequestVote RPC : 用于Candidate收集选票
- AppendEntries RPC: Leader日志复制或发送心跳(不含日志项)
- InstallSnapshot RPC: Leader 通过此 RPC 发送快照给 Follower

## 领导选举

在了解了算法的基本工作流程之后，就让我们开始解决其中会遇到的问题，首先就是 Leader 如何而来。

### 初次选举

在算法刚开始时，所有结点都是 Follower，每个结点都会有一个定时器，每次收到来自 Leader 的信息就会更新该定时器。该定时器是**随机定时**

![490](Attachments/16cf56007f8f4ba2aabc77c1c7080f72_MD5.gif)

如果定时器超时，说明一段时间内没有收到 Leader 的消息，那么就可以认为 Leader 已死或者不存在，那么该结点就会转变成 Candidate，意思为准备竞争成为 Leader。

成为 Candidate 后结点会向所有其他结点发送请求投票的请求（RequestVote），其他结点在收到请求后会判断是否可以投给他并返回结果。Candidate 如果收到了半数以上的投票就可以成为 Leader，成为之后会立即并在任期内定期发送一个心跳信息通知其他所有结点新的 Leader 信息，并用来重置定时器，避免其他结点再次成为 Candidate。

如果 Candidate 在一定时间内没有获得足够的投票，那么就会进行一轮新的选举，直到其成为 Leader,或者其他结点成为了新的 Leader，自己变成 Follower。

### 再次选举

再次选举会在两种情况下发生。

![460](Attachments/1f8257d894ab7de213f7a85bb390521b_MD5.gif)

第一种情况是 Leader 下线，此时所有其他结点的计时器不会被重置，直到一个结点成为了 Candidate，和上述一样开始一轮新的选举选出一个新的 Leader。

![520](Attachments/97008a98b6fbae6cf9a6805acf838cc9_MD5.gif)

第二种情况是某一 Follower 结点与 Leader 间通信发生问题，导致发生了分区，这时没有 Leader 的那个分区就会进行一次选举。这种情况下，因为要求获得多数的投票才可以成为 Leader，因此只有拥有多数结点的分区可以正常工作。而对于少数结点的分区，即使仍存在 Leader，但由于写入日志的结点数量不可能超过半数因此不可能提交操作。这解释了为何 Raft 至多容忍 (N−1)/2 个结点故障。

![490](Attachments/4b9287f4b555846b5298a8563078129c_MD5.png)

这解释了每个结点会如何在三个状态间发生变化。

### 任期 Term

Leader 的选举引出了一个新的概念——**任期**（Term）。

![495](Attachments/00cfe7207bda01da96e3669dda307b80_MD5.png)

每一个任期以一次选举作为起点，所以当一个结点成为 Candidate 并向其他结点请求投票时，会将自己的 Term 加 1，表明新一轮的开始以及旧 Leader 的任期结束。所有结点在收到比自己更新的 Term 之后就会更新自己的 Term 并转成 Follower，而收到过时的消息则拒绝该请求。

在一次成功选举完成后，Leader 会负责管理所有结点直至任期结束。如果没有产生新的 Leader 就会开始一轮新的 Term。任期在 Raft 起到了类似时钟的功能，用于检测信息是否过期。

### 投票限制 (Election Restriction)

在投票时候，所有服务器采用先来先得的原则，在一个任期内只可以投票给一个结点，得到超过半数的投票才可成为 Leader，从而保证了一个任期内只会有一个 Leader 产生（**Election Safety**）。

在 Raft 中日志只有从 Leader 到 Follower 这一流向，所以需要保证 Leader 的日志必须正确，即必须拥有所有已在多数节点上存在的日志，这一步骤由投票来限制。

![485](Attachments/962d13329ea3b0ad18cedeb54cd660bb_MD5.png)

投票由一个称为 RequestVote 的 RPC 调用进行，请求中除了有 Candidate 自己的 term 和 id 之外，还要带有自己最后一个日志条目的 index 和 term。接收者收到后首先会判断请求的 term 是否更大，不是则说明是旧消息，拒绝该请求。如果任期更大则开始判断日志是否更加新。日志 Term 越大则越新，相同那么 index 较大的认为是更加新的日志。接收者只会投票给拥有相同或者更加新的日志的 Candidate。 ^oh4coo

由于只有日志在被多数结点复制之后才会被提交并返回，所以如果一个 Candidate 并不拥有最新的已被复制的日志，那么他不可能获得多数票，从而保证了 Leader 一定具有所有已被多数拥有的日志（**Leader Completeness**），在后续同步时会将其同步给所有结点。

#### 总结

- 在任一任期内，单个节点最多只能投一票
- 候选人知道的信息不能比自己的少（这一部分，后面介绍log replication和safety的时候会详细介绍）
- first-come-first-served 先来先得

### 定时器时间

定时器时间的设定实际上也会影响到算法性能甚至是正确性。试想一下这样一个场景，Leader 下线，有两个结点同时成为 Candidate，然后由于网络结构等原因，每个结点都获得了一半的投票，因此无人成为 Leader 进入了下一轮。然而在下一轮由于这两个结点同时结束，又同时成为了 Candidate，再次重复了之前的这一流程，那么算法就无法正常工作。

为了解决这一问题，Raft 采用了一个十分“艺术”的解决方法，随机定时器长短（例如 150-300ms）。通过这一方法避免了两个结点同时成为 Candidate，即使发生了也能快速恢复。这一长短必须长于 Leader 的心跳间隔，否则在正常情况下也会有 Candidate 出现导致算法无法正常工作。

## 日志复制

当有了 leader，系统应该进入对外工作期了。客户端的一切请求来发送到 leader，leader 来调度这些并发请求的顺序，并且保证 leader 与 followers 状态的一致性。raft 中的做法是，将这些请求以及执行顺序告知 followers。leader 和 followers 以相同的顺序来执行这些请求，保证状态一致。

### 流程

每个节点上的日志复制流程有是怎么样的呢？

- 复制：某个日志把写入到Follower的日志中
- 提交：如果当前任期内的日志项被多数节点写入，则可以变为提交状态。此状态下日志项不再被修改
- 应用：将已经提交的日志项应用到状态机，会真正影响节点状态

![360](Attachments/d347372097046c5ccb727e95000ed728_MD5.png)

不难看到，logs 由顺序编号的 log entry 组成，每个 log entry 除了包含 command，还包含产生该 log entry 时的 leader term。从上图可以看到，五个节点的日志并不完全一致，raft 算法为了保证高可用，并不是强一致性，而是**最终一致性**，leader 会不断尝试给 follower 发 log entries，直到所有节点的 log entries 都相同。

### 复制过程

当系统（leader）收到一个来自客户端的写请求，到返回给客户端，整个过程从 leader 的视角来看会经历以下步骤 

1. 客户端将包含一条指令的请求发送到 Leader 上 
2. Leader 把这条指令作为日志项附加到本地的日志中，并发送 AppendEntriesRPC 给其他服务器，复制日志项 
3. Follower 返回复制结果给 Leader 
4. 当 Leader 认为这个日志项已经被多数节点复制，那么在提交此日志项并将这条日志项应用到状态机后，**会返回给客户端**

可以看到日志的提交过程有点类似[两阶段提交(2PC)](分布式事务.md#方案 )，不过与2PC 的区别在于，**leader 只需要大多数（majority）节点的回复即可**，这样只要超过一半节点处于工作状态则系统就是可用的。一旦向客户端返回成功消息，那么系统就必须保证 log（其实是 log 所包含的 command）**在任何异常的情况下都不会发生回滚** 。

示意图如下：

![490](Attachments/980090470c8fa395bf98c8f80920a033_MD5.png)

#### 例子

1. 首先，我在 S2 节点发起 request(只能对 leader 发起 request)。这时候 Leader 会把这条指令附加到本地的日志中，但并未提交(虚线框) 
2. 然后，S2 向其他节点发送者条日志，其他节点收到之后，都把这条日志加到本中，但是没有提交(虚线框) 
3. Follower 把成功复制的结果返回给 Leader，Leader 收到了4票，认为这个日志项已经被多数节点复制 
4. Leader 把这项日志应用到状态机(变成实线框)，并将结果返回给客户端。 
5. Leader 给 Follower 发信息，意思是说我已经提交成功并应用了，你们也可以提交了，因此 Follower 也相继提交并应用了 

![485](Attachments/ab68af5e76d72d6dacdf9991626cbeae_MD5.gif)

### 前提

Raft 保证了如下几点：

- Leader 绝不会覆盖或删除自己的日志，只会追加 （**Leader Append-Only**） ^mbe468
- 如果两个日志的 index 和 term 相同，那么这两个日志相同 （**Log Matching**） ^gfcdpb
- 如果两个日志相同，那么他们之前的日志均相同
	- 在复制日志项的时候，会携带上一个日志项的index和term序号，如果不匹配，会一直查找，直到匹配了才把日志复制过来 

第一点主要是因为选举时的限制，根据 Leader Completeness，成为 Leader 的结点里的日志一定拥有所有已被多数节点拥有的日志条目，所以先前的日志条目很可能已经被提交，因此不可以删除之前的日志。

第二点主要是因为一个任期内只可能出现一个 Leader，而 Leader 只会为一个 index 创建一个日志条目，而且一旦写入就不会修改，因此保证了日志的唯一性。

第三点是因为在写入日志时会检查前一个日志是否一致。换言之就是，如果写入了一条日志，那么前一个日志条目也一定一致，从而递归的保证了前面的所有日志都一致。从而也保证了当一个日志被提交之后，所有结点在该 index 上提交的内容是一样的（**State Machine Safety**）。

### 可能出现不一致的场景

我们举几个例子，下图 a-f 是 follower 可能出现的场景(不是说有6个 follower)

![](Attachments/25ee2ba877c5cbb07a48221650b52592_MD5.png)

#### **日志项缺失**

- a 在收到(6,9)之后宕机 , 示意图如下图所示(不是完全匹配)
    
    ![510](Attachments/f6bff6bd9afeb16111201407a96cc7a2_MD5.gif)
    
- b 在收到(4,4)之后宕机，后面几个 term 一直没有恢复 

#### **日志项多余**

- c 作为 follower 收到了来自 leader 的(6,11)日志之后，Leader 宕机，而此时其他节点可能还没收到 
- d 可能本来就是 Leader，接收了来自客户端的两次请求之后，还没把信息传递出去，就宕机了，再选举得到的新 Leader 已经不是它了，因此不会有 Term7 的信息 

示意图如下:

![505](Attachments/70204f824fabab0fb356c4480f5d0a29_MD5.gif)

#### **日志项不匹配**

- e 收到(4,6)(4,7)之后宕机，示意图如下所示： 
    - ![525](Attachments/e9ce7cbaea35402509240a382157fe73_MD5.gif)
- f 多收到任期2,3的日志项，但是都没有提交成功。这时候 f 宕机，系统选取了新的 leader，开启 term4。由于之前 term2、3没有提交成功，导致该 term 的日志没有写入多数节点，导致 term4的 leader 没有 term2、3的日志项  

那么如果出现了不一致的情况，此时Leader首先会进行要如何解决？首先要知道的一个原则：**Leader不会覆盖或者删除自己的日志**

- **日志项缺失**
    - Leader 会从最新的日志开始发起，因为每条日志都会保留上一条日志的 index 和 term 序号，因此可以和上一条做比较。如果 Folloer 没有找到对应的日志项，就会拒绝。 
    - Leader 发现拒绝接受的消息，就会向前逐个排查，直到 Follower 最终找到与 Leader 对应的相同位置， 
    - 然后，Leader 把条该日志之后的所有日志全部发送给 follow，让其同步，覆盖掉不匹配的日志项 
- **日志项多余**
    - Leader 发现 follower 的日志项比自己多，会发送信息给 follower 让他同步我自己的日志项。这是一个强制性的同步，既然选择了 leader，就一定要让 folloer 和 leader 一致 
- 日志项不匹配的操作逻辑和日志项缺失一样

可能有人说一个一个找会比较麻烦，那么可以进行一些优化，比如三个三个找，或者按照任期向前搜索

最终的结果是日志必须按照顺序记录的如下图：

![500](Attachments/d347372097046c5ccb727e95000ed728_MD5.png)

### 日志复制 RPC

接下来我们就可以看到 Raft 实际中是如何做到日志同步的。这一过程由一个称为 AppendEntries 的 RPC 调用实现，Leader 会给每个 Follower 发送该 RPC 以追加日志，请求中除了当前任期 term、Leader 的 id 和已提交的日志 index，还有将要追加的日志列表（空则成为心跳包），前一个日志的 index 和 term。

![495](Attachments/7d63cf21d0216d57457d4946828373de_MD5.png)

当接收到该请求后，会先检查 term，如果请求中的 term 比自己的小说明已过期，拒绝请求。之后会对比先前日志的 index 和 term，如果一致，那么由前提可知前面的日志均相同，那么就可以从此处更新日志，将请求中的所有日志写入自己的日志列表中，否则返回 false。如果发生 index 相同但 term 不同则清空后续所有的日志，以 Leader 为准。最后检查已提交的日志 index，对可提交的日志进行提交操作。

对于 Leader 来说会维护 nextIndex[] 和 matchIndex[] 两个数组，分别'记录了每个 Follower 下一个将要发送的日志 index 和已经匹配上的日志 index。每次成为 Leader 都会初始化这两个数组，前者初始化为 Leader 最后一条日志的 index 加 1，后者初始化为 0。每次发送 RPC 时会发送 nextIndex[i] 及之后的日志，成功则更新两个数组，否则减少 nextIndex[i] 的值重试，重复这一过程直至成功。

> 这里减少 nextIndex 的值有不同的策略，可以每次减一，也可以减一个较大的值，或者是跨任期减少，用于快速找到和该结点相匹配的日志条目。实际中还有可能会定期存储日志，所以当前日志列表中并不会太大，可以完整打包发给对方，这一做法比较适合新加入集群的结点。

### 日志提交限制

只要日志在多数结点上存在，那么 Leader 就可以提交该操作。但是 Raft 额外限制了 Leader 只对自己任期内的日志条目适用该规则，先前任期的条目只能由当前任期的提交而间接被提交。

![525](Attachments/cc981ae4ef64a960cd7de12a2e4016a0_MD5.png)

例如论文中图 8 这一 corner case。  
一开始如 (a) 所示，之后 S1 下线，  
(b) 中 S5 从 S3 和 S4 处获得了投票成为了 Leader 并收到了一条来自客户端的消息，之后 S5 下线。  
(c) 中 S1 恢复并成为了 Leader，并且将日志复制给了多数结点，之后进行了一个致命操作，将 index 为 2 的日志提交了，然后 S1 下线。  
(d) 中 S5 恢复，并从 S2、S3、S4 处获得了足够投票，然后将已提交的 index 为 2 的日志覆盖了。
- 因为![分布式共识算法-Raft](分布式共识算法-Raft.md#^oh4coo)

为了解决这个问题，Raft 只允许提交自己任期内的日志，从而日志 2 只能像 (e) 中由于日志 3 同步而被间接提交，避免了 Follower 中由于缺少新任期的日志，使得 S5 能够继续成为 Leader。

## Safety

在上面提到只要日志被复制到 majority 节点，就能保证不会被回滚，即使在各种异常情况下，这根 leader election 提到的选举约束有关。在这一部分，主要讨论 raft 协议在各种各样的异常情况下如何工作的。 

衡量一个分布式算法，有许多属性，如

- safety：nothing bad happens,
- liveness： something good eventually happens.

任何系统模型下，都需要满足safety属性，即在任何情况下，系统都不能出现不可逆的错误，也不能向客户端返回错误的内容。比如，raft保证被复制到大多数节点的日志不会被回滚，那么就是safety属性。而raft最终会让所有节点状态一致，这属于liveness属性。

Raft 协议会保证以下属性 

| 性质                                 | 描述                                                                                                 | 问题                        | 解决                   |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------- | --------------------------- | ---------------------- |
| 选举安全原则(Election Safty)         | 一个任期内最多允许一个Leader                                                                         | Split Vote                  | 随机选举时间，多次选举 |
| Leader只追加原则(Leader Apeend-Only) | Leader永远不会覆盖或者删除自己的日志，它只会增加日志项                                               | 日志不一致                  | 强制Follower与其一致   |
| 日志匹配原则(Log Match)              | 如果两个日志在相同的索引位置上的日志项的任期号相同，那么就认为这个日志项索引位置之前的日志也完全相同 | 日志不一致                  | 日志复制，一致性检验   |
| Leader完全原则(Leader Completeness)  | 如果一个日志项在一个给定任期内被提交，那么这个日志项一定会出现在所有任期号更大的Leader中             | 无法判断某个entry是否被提交 | 选举限制+推迟提交      |
| 状态机安全原则(State Machine Safety) | 如果一个节点已经将给定索引位置的日志项应用到状态机中，则所有其他节点不会再该索引位置应用不同的日志项 | 反证法                      | 反证法                 |

- 相关的具体使用见 
	- ![分布式共识算法-Raft](分布式共识算法-Raft.md#^mbe468)
	- ![分布式共识算法-Raft](分布式共识算法-Raft.md#^gfcdpb)
	- ![分布式共识算法-Raft#投票限制 Election Restriction](分布式共识算法-Raft.md#投票限制%20Election%20Restriction)

## 参考

[「图解Raft」让一致性算法变得更简单 - ZingLix Blog](https://zinglix.xyz/2020/06/25/raft/)  
[Raft | Jason‘s Blog](https://jasonxqh.github.io/2022/06/10/Raft/)