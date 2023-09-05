---
aliases: []
created_date: 2023-09-04 16:47
draft: false
summary: ''
tags:
- dev
---

> [【Git】：git rebase和git merge有什么区别？ | JoyoHub](https://joyohub.com/2020/04/06/git-rebase/)

- git rebase 和 git merge 都是 Git 用来合并分支代码基本命令
- 在 Git 工作流中，两者作用一致，但是原理上却不相同
- 另外，git rebase 为什么在某些场景下会被限制使用呢？

> Github issues: [https://github.com/littlejoyo/Blog/issues/](https://github.com/littlejoyo/Blog/issues/)

# [](#1 -场景模拟 "1.场景模拟")1.场景模拟

假设当前我们有 master 和 feature 分支，当你在专用分支上开发新 feature 时，然后另一个团队成员在 master 分支提交了新的 commits，这种属于正常的 Git 工作场景。如下图：

![](Attachments/4d8bb832b0c043486616d736381e8254_MD5.png)

现在，假设在 master 分支上的新提交与你正在开发的 feature 相关，需要 master 分支将新提交的记录合并到你的 feature 分支中。

当我们需要对分支代码进行合并的时候，一般会使用下面两个命令：

- git merge
    
- git rebase

>  **git rebase** 和 **git merge** 这两个命令都旨在将更改代码从一个分支合并到另一个分支，但二者的合并方式却有很大的不同。

# [](#2 -git-merge "2.git merge")2.git merge

使用 git merge 命令将 `master` 分支合并到 `feature` 分支中：

```sql
git checkout feature
```

缩写为一句代码就是：

```sql
git merge feature master
```

![](Attachments/e7564aea5135f8907f54a86854ca1a90_MD5.png)

由上图可知，git merge 会在 `feature` 分支中新增一个新的 **merge commit** ，然后将两个分支的历史联系在一起

- 使用 merge 是很好的方式，因为它是一种 **非破坏性的** 操作，对现有分支不会以任何方式被更改。
    
- 另一方面，这也意味着 `feature` 分支每次需要合并上游更改时，它都将产生一个额外的合并提交。
    
- 如果 master 提交非常活跃，这可能会严重污染你的 `feature` 分支历史记录。不过这个问题可以使用高级选项 `git log` 来缓解

# [](#3 -git-rebase "3.git rebase")3.git rebase

使用 git rebase 命令将 `master` 分支合并到 `feature` 分支中：

```sql
git checkout feature
```

缩写为一句代码就是：

```sql
git rebase feature master
```

![](Attachments/650e23e820c606f05590370ceda64be8_MD5.png)

- rebase 会将整个 `feature` 分支移动到 `master` 分支的 **顶端** ，从而有效地整合了所有 master 分支上的提交。
    
- 但是，与 merge 提交方式不同，rebase 通过为原始分支中的每个提交创建全新的 commits 来重写项目历史记录,特点是仍然会在 `feature` 分支上形成线性提交
    
- rebase 的主要好处是可以获得更清晰的项目历史。首先，它消除了 git merge 所需的不必要的合并提交；其次，正如你在上图中所看到的，rebase 会产生完美线性的项目历史记录，你可以在 feature 分支上没有任何分叉的情况下一直追寻到项目的初始提交。  
 **git rebase 原理再深入：** 

将 `master` 分支代码合并到 `feature` 上：

![](Attachments/daa812dbcc61591715ad008b84a67d5f_MD5.png)

- 这边需要强调一个概念： **reapply(重放)** ，使用 rebase 并不是简单地好像你用 **ctrl-x/ctrl-v** 进行剪切复制一样
    
- rebase 会依次地将你所要操作的分支的所有提交应用到目标分支上

合并过程如下图：

![](Attachments/acd6712b3a67f2480133554880ea635e_MD5.png)

从上图可以看出，在对特征分支进行 rebase 之后，其等效于创建了新的提交。并且老的提交也没有被销毁，只是简单地不能再被访问或者使用。

> 实际上在执行 rebase 的时候，有两个隐含的注意点：

1.在重放之前的提交的时候， **Git 会创建新的提交** ，也就是说即使你重放的提交与之前的一模一样 Git 也会将之 **当做新的独立的提交** 进行处理。

1. **Git rebase 并不会删除老的提交** ，也就是说你在对某个分支执行了 rebase 操作之后，老的提交仍然会存放在.git 文件夹的 objects 目录下。

如果想要在线进行 Git 工作场景的模拟，可以到此 [Git Online](https://learngitbranching.js.org/?locale=zh_CN)

# [](#4 -如何选择 git-merge 和 git-rebase "4.如何选择 git merge 和 git rebase?")4.如何选择 git merge 和 git rebase?

根据上面的对比可知:

- **git merge** 优点是分支代码合并后不破坏原分支的代码提交记录，缺点就是会产生额外的提交记录并进行两条分支的合并，
    
- **git rebase** 优点是无须新增提交记录到目标分支，rebase 后可以将对象分支的提交历史续上目标分支上，形成线性提交历史记录，进行 review 的时候更加直观
    
- git merge 如果有多人进行开发并进行分支合并，会形成复杂的合并分支图，如下图：

![](Attachments/e335bc7e0a0563c5c37f6ee03ea93623_MD5.png)

> 问题：既然 rebase 如此有用，那么可以使用 rebase 完全取代 merge 吗？ 答案：不能！

git rebase 的黄金原则：

- **不能在一个共享的分支上进行 Git rebase 操作。**  
 **总结：** 

- 融合代码到公共分支的时使用 `git merge`,而不用 `git rebase`
    
- 融合代码到个人分支的时候使用 `git rebase`，可以不污染分支的提交记录，形成简洁的线性提交历史记录。

# [](#5 -rebase 的黄金原则 "5.rebase 的黄金原则")5.rebase 的黄金原则

> 问题：为什么不能再一个共享的分支上进行 Git rebase 操作呢？

所谓共享的分支，即是指那些存在于远端并且允许团队中的其他人进行 Pull 操作的分支，比如我们 Git 工作的 master 分支就是最常见的公共分支。

假设现在 Bob 和 Anna 在同一个项目组中工作，项目所属的仓库和分支大概是下图这样：

![](Attachments/500c977d5808b46ab5a7143cb954b2de_MD5.png)

现在 Bob 为了图一时方便打破了原则，正巧这时 Anna 在特征分支上进行了新的提交，此时的结构图大概是这样的：

![](Attachments/92d88493be79c9531add86c93a2ae08d_MD5.png)

当 Bob 推送自己的分支到远端的时候，现在的分支情况如下：

![](Attachments/2effd1917c088de00ce84637cc719db1_MD5.png)

然后呢，当 Anna 也进行推送的时候，她会得到如下的提醒，Git 提醒 Anna 她本地的版本与远程分支并不一致，需要向远端服务器拉取代码进行同步：

![](Attachments/8f64e9ed0fb496c041662f68963702d8_MD5.png)

在 Anna 提交之前，分支中的 Commit 序列是如下这样的：

```sql
A--B--C--D'   origin/feature // GitHub
```

在进行 Pull 操作之后，Git 会进行自动地合并操作，结果大概是这样的：

![](Attachments/8b62a67e5db8f5fa567704ab690a1d34_MD5.png)

这个第 M 个提交即代表着合并的提交，也就是 Anna 本地的分支与 Github 上的特征分支最终合并的点，现在 Anna 解决了所有的合并冲突并且可以 Push 她的代码，在 Bob 进行 Pull 之后，每个人的 Git Commit 结构为：

![](Attachments/a6a1300380f6afb4615d0c619a8ab3be_MD5.png)

看到上面这个混乱的流线图，相信你对于 Rebase 和所谓的黄金准则也有了更形象深入的理解。

> 假设下还有一哥们 Emma，第三个开发人员，在他进行了本地 Commit 并且 Push 到远端之后，仓库变为了：

![](Attachments/184e761dec8b9ce3a530374bc2f3cea4_MD5.png)

- 这还只是仅有几个人，一个特征分支的项目因为误用 rebase 产生的后果。如果你团队中的每个人都对公共分支进行 rebase 操作，那么后果就是乱成一片。
    
- 另外，相信你也注意到，在远端的仓库中存有大量的重复的 Commit 信息，这会大大浪费我们的存储空间。
    
- 因此， **不能在一个共享的分支上进行 Git rebase 操作,避免出现项目分支代码提交记录错乱和浪费存储空间的现象。**  

# [](#6 -使用 rebase 合并多次提交记录 "6.使用 rebase 合并多次提交记录")6.使用 rebase 合并多次提交记录

> rebase 和 merge 不同的作用还有一个就是合并分支多次提交记录。

在分支开发的过程中，我们常常会出现为了调试程序而多次提交代码记录，但是这些记录的共同目的都是为了解决某一个需求，所以，是否可以将这些记录合并起来为一个新的记录会更方便进行代码的 review 呢？  
 **git rebase 提供了合并记录的作用**  
下面是一个合并的案例过程：

1.尝试合并分支的最近 4 次提交纪录

```plain
git rebase -i HEAD~4
```

2.这时候，会自动进入 vi 编辑模式：

![](Attachments/fee19fe8ad457672e92ac4bc9ee2efce_MD5.png)

进入编辑模式，第一列为操作指令，第二列为 commit 号，第三列为 commit 信息。

- pick：保留该 commit；
    
- reword：保留该 commit 但是修改 commit 信息；
    
- edit：保留该 commit 但是要修改 commit 内容；
    
- squash：将该 commit 和前一个 commit 合并；
    
- fixup：将该 commit 和前一个 commit 合并，并不保留该 commit 的 commit 信息；
    
- exec：执行 shell 命令；
    
- drop：删除该 commit。

按照如上命令来修改你的提交记录：

```plain
p 799770a add article
```

成功合并了四条记录为一条：

![](Attachments/fc87b7f73e09a870e7ad63df15b24708_MD5.png)

如果保存的时候，你碰到了这个错误：

```plain
error: cannot 'squash' without a previous commit
```

说明你在合并记录的时候顺序错误了，压缩顺序应该是从下往上，而不是从上往下，否则就会触发上面的错误。也就是以新记录为准。

例如上面的例子写成了这样就是出现错误：

```plain
s 799770a add article
```

中途出现异常退出了 vi 窗口，执行下面命令可以返回编辑窗口：

```plain
git rebase --edit-todo
```

继续编辑合并记录的操作，修改完保存一下：

```plain
git rebase --continue
```

# [](#7 -git-pull-–rebase 的应用 "7.git pull –rebase 的应用")7.git pull –rebase 的应用

## [](#7 -1-场景介绍 "7.1 场景介绍")7.1 场景介绍

同事都基于 git flow 工作流的话都会从 `develop` 拉出分支进行并行开发，这里的分支可能是多到数十个，然后彼此在进行自己的逻辑编写，时间可能需要几天或者几周。

在这期间你可能需要时不时的需要 pull 下远程 develop 分支上的同事的提交。这是个好的习惯，这样下去就可以避免你在一个无用的代码上进行长期的开发，回头来看这些代码不是新的代码。甚至是会面临很多冲突需要解决，而这个时候你可能还需要对冲突的部分代码进行测试和问题解决，你在有些时候 pull 代码的时候会有这样的一个提示：

![](Attachments/f2ad8c692eed7fdc89fb28139b7fa538_MD5.png)

通常习惯性的你可能会，”esc ：wq“，直接默认 commit 注释。然后你的 commit log 就多了一笔很不好看的 log。

![](Attachments/6d9902bfff8bc2baff90732d333d4014_MD5.png)

## [](#7 -2-如何移除多余的 merge-commit "7.2 如何移除多余的 merge commit")7.2 如何移除多余的 merge commit

> 很简单，只要你在 pull 时候需要习惯性的加上—rebase 参数，这样可以避免很多问题。

`git pull --rebase` 可以免去分支中出现大量的 merge commit，基本原理就像上面 rebase 一样，合并过程会直接融合到目标分支的顶端，形成线性历史提交。

## [](#7 -3-分析过程 "7.3 分析过程")7.3 分析过程

1.正常情况下的分支 commit 路线并且当前 develop 分支上有三个 commit。

2.现在我们两个项目开始启动，需要分别拉出两个分支独立开发，提交过程如图：

![](Attachments/817d516a59e717a163f401eb072a13b3_MD5.png)

3.我们分别 checkout –b 出来两个分支，独立开发互不干扰。正常情况下，如果这两个分支的改动都没有冲突的时候，一切都很顺利的。

4.我在 develop\_newfeature\_authorcheck 里修改了点东西，push 到 develop。然后 checkout 到 develop\_newfeature\_apiwrapper。

5.当我再 git pull，这将会把 develop\_newfeature\_authorcheck 分支的修改直接拉下来于本地代码 merge，且产生一个 commit，也就是 merge commit。

![](Attachments/e6518489419388ec3efe5f92ac8d583b_MD5.png)

6.使用 `git pull –rebase` 产生的提交结果就完全不一样,rebase 并不会产生一个 commit 提交，而是会将你的 E commit 附加到 D commit 的结尾处。在看 commit log 时，不会多出你所不知道的 commit 出来。其实此处的 F commmit 是无意义的，它只是一个 merge commit。

![](Attachments/3a5743175c1873df9bb2b59f5626dfca_MD5.png)

> 很明显，git pull –rebase 会使 commit 看起来很自然,因为代码都有一个前后依赖，看起来更加的直观。

### [](#注意 ： "注意：")注意：

在公共的分支上，例如 `master` 仍然要遵守 rebase 黄金原则，不用使用 `git pull --rabase` 进行代码的拉取，更改代码的历史提交记录。

参考资料：[https://segmentfault.com/a/1190000005937408](https://segmentfault.com/a/1190000005937408)