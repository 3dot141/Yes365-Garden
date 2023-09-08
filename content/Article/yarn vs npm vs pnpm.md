---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

![|525](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/55865fd68d6b46c38d4aa97181246f58~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

前段时间换了新的开发环境之后，一个中型管理系统项目在安装 node module 时，每个人本地 npm install 和 yarn 时总是出各种不同问题，经常安装不成功或者成功之后无法运行，排查起来非常困难，删除重装的老套路也经常失败，让人非常烦恼！！！

想起前段时间经常听到 pnpm 的新的包管理方式，今天研究了一下它的机制，看是否可以用得起来。

现在本地试了一下，直接就安装成功了，且包大小比 npm 安装的包要小一些，看了“神光的编程秘籍”公号的文章，照猫画虎也补充一下学习过程；

npm 安装机制与他的前世今生
---------------

按照包管理工具的发展历史，从 npm2 开始讲起：

### 从 npm2 开始

#### npm/yarn install 原理

执行 npm/yarn install 之后，包如何到达项目 node\_modules 当中。其次，node\_modules 内部如何管理依赖。

执行命令后，首先会构建依赖树，然后针对每个节点下的包，会经历下面四个步骤:

  - 1. 将依赖包的版本区间解析为某个具体的版本号  
\- 2. 下载对应版本依赖的 tar 包到本地离线镜像  
\- 3. 将依赖从离线镜像解压到本地缓存  
\- 4. 将依赖从缓存拷贝到当前目录的 node\_modules 目录

然后，对应的包就会到达项目的 node\_modules 当中。

那么，这些依赖在 node\_modules 内部是什么样的目录结构呢，换句话说，项目的依赖树是什么样的呢？

在 npm1、npm2 中呈现出的是嵌套结构，比如下面这样:

node\_modules

└─ foo

   ├─ index.js

   ├─ package.json

   └─ node\_modules

      └─ bar

         ├─ index.js

         └─ package.json

那么 A 和 B 同时依赖 C，C 这个包会被安装在哪里呢？C 的版本相同和版本不同时安装会有什么差异呢？package.json 中包的前后顺序对于安装时有什么影响吗？今天就来一起研究一下。

#### A 和 B 同时依赖 C

假如有 A 和 B 两个包，两个包都依赖 C 这个包，npm 2 会依次递归安装 A 和 B 两个包及其子依赖包到 node\_modules 中。执行完毕后，我们会看到 ./node\_modules 这层目录只含有这两个子目录：

node\_modules/ 

├─┬ A 

│ ├── C 

├─┬ B 

│ └── C 

如果使用 npm 3 来进行安装的话，./node\_modules 下的目录将会包含三个子目录：

node\_modules/ 

├─┬ A 

├─┬ B 

├─┬ C 

为什么会出现这样的区别呢？这就要从 npm 的工作方式说起了：

### npm 2 和 npm 3 模块安装机制的差异

虽然目前最新的 npm 版本是 npm 6，但 从 npm 3 开始的版本中实现了目录打平，与其他版本相比差别较大。因此，让我们具体看下这两个版本的差异​。

#### npm2 递归树形依赖结构

npm 2 在安装依赖包时，采用简单的递归安装方法。执行 npm install 后，npm 根据 dependencies 和 devDependencies 属性中指定的包来确定第一层依赖，npm 2 会根据第一层依赖的子依赖，递归安装各个包到子依赖的 node\_modules 中，直到子依赖不再依赖其他模块。执行完毕后，我们会看到 ./node\_modules 这层目录中包含有我们 package.json 文件中所有的依赖包，而这些依赖包的子依赖包都安装在了自己的 node\_modules 中 ，形成递归树形的依赖树结构。

![|525](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/76db004671fc4aac83726eb22722e921~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

这样的目录有较为明显的好处：

​ 1）层级结构非常明显，可以清楚的在第一层的 node\_modules 中看到我们安装的所有包的子目录；

​ 2）在已知自己所需包的名字以及版本号时，可以复制粘贴相应的文件到 node\_modules 中，然后手动更改 package.json 中的配置；

​ 3）如果想要删除某个包，只需要简单的删除 package.json 文件中相应的某一行，然后删除 node\_modules 中该包的目录；

但是这样的层级结构也有较为明显的缺陷，当我的 A，B，C 三个包中有相同的依赖 D 时，执行 npm install 后，D 会被重复下载三次，而随着我们的项目越来越复杂，node\_modules 中的依赖树也会越来越复杂，像 D 这样的包也会越来越多，造成了大量的冗余；在 windows 系统中，甚至会因为目录的层级太深导致文件的路径过长，触发文件路径不能超过 280 个字符的错误；

​ 为了解决以上问题，npm 3 的 node\_modules 目录改成了更为扁平状的层级结构，尽量把依赖以及依赖的依赖平铺在 node\_modules 文件夹下共享使用。

### npm 3 部分拉平

npm 3 会遍历所有的节点，逐个将模块放在 node\_modules 的第一层，当发现有重复模块时，则丢弃， 如果遇到某些依赖版本不兼容的问题，则继续采用 npm 2 的处理方式，前面的放在 node\_modules 目录中，后面的放在依赖树中。举个例子： A，B，依赖 D(v 0.0.1)，C 依赖 D(v 0.0.2):

![|525](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/3688933d00d7479482c6fc9313502aee~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

但是 npm 3 会带来一个新的问题：由于在执行 npm install 的时候，按照 package.json 里依赖的顺序依次解析，上图如果 C 的顺序在 A，B 的前边，node\_modules 树则会改变，会出现下边的情况：

![|525](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/e2996d2ac10b49ef81310c4ca63b98cf~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

由此可见，npm 3 并未完全解决冗余的问题，甚至还会带来新的问题。

### 为什么会出现 package-lock.json 呢？

#### package.json 的不足之处

npm install 执行后，会生成一个 node\_modules 树，在理想情况下， 希望对于同一个 package.json 总是生成完全相同 node\_modules 树。在某些情况下，确实如此。但在多数情况下，npm 无法做到这一点。有以下两个原因：

1）某些依赖项自上次安装以来，可能已发布了新版本 。比如：A 包在团队中第一个人安装的时候是 1.0.5 版本，package.json 中的配置项为 A: '^1.0.5' ；团队中第二个人把代码拉下来的时候，A 包的版本已经升级成了 1.0.8，根据 package.json 中的 semver-range version 规范，此时第二个人 npm install 后 A 的版本为 1.0.8； 可能会造成因为依赖版本不同而导致的 bug；

2）针对 1）中的问题，可能有的小伙伴会想，把 A 的版本号固定为 A: '1.0.5' 不就可以了吗？但是这样的做法其实并没有解决问题， 比如 A 的某个依赖在第一个人下载的时候是 2.1.3 版本，但是第二个人下载的时候已经升级到了 2.2.5 版本，此时生成的 node\_modules 树依旧不完全相同 ，固定版本只是固定来自身的版本，依赖的版本无法固定。

#### 针对 package.json 不足的解决方法

为了解决上述问题以及 npm 3 的问题，在 npm 5.0 版本后，npm install 后都会自动生成一个 package-lock.json 文件 ，当包中有 package-lock.json 文件时，npm install 执行时，如果 package.json 和 package-lock.json 中的版本兼容，会根据 package-lock.json 中的版本下载；如果不兼容，将会根据 package.json 的版本，更新 package-lock.json 中的版本，已保证 package-lock.json 中的版本兼容 package.json。

#### package-lock.json 文件结构

package-lock.json 文件中的 name、version 与 package.json 中的 name、version 一样，描述了当前包的名字和版本，dependencies 是一个对象，该对象和 node\_modules 中的包结构一一对应，对象的 key 为包的名称，值为包的一些描述信息，主要的结构如下：

* version ：包版本，即这个包当前安装在 node\_modules 中的版本
* resolved ：包具体的安装来源
* integrity ：包 hash 值，验证已安装的软件包是否被改动过、是否已失效
* requires ：对应子依赖的依赖，与子依赖的 package.json 中 dependencies 的依赖项相同
* dependencies ：结构和外层的 dependencies 结构相同，存储安装在子依赖 node\_modules 中的依赖包

需要注意的是，并不是所有的子依赖都有 dependencies 属性，只有子依赖的依赖和当前已安装在根目录的 node\_modules 中的依赖冲突之后，才会有这个属性。

#### package-lock.json 文件的作用

* 在团队开发中，确保每个团队成员安装的依赖版本是一致的，确定一棵唯一的 node\_modules 树；
* node\_modules 目录本身是不会被提交到代码库的，但是 package-lock.json 可以提交到代码库，如果开发人员想要回溯到某一天的目录状态，只需要把 package.json 和 package-lock.json 这两个文件回退到那一天即可 。
* 由于 package-lock.json 和 node\_modules 中的依赖嵌套完全一致，可以更加清楚的了解树的结构及其变化。
* 在安装时，npm 会比较 node\_modules 已有的包，和 package-lock.json 进行比较，如果重复的话，就跳过安装 ，从而优化了安装的过程。

依赖的区别与使用场景
----------

npm 目前支持以下几类依赖包管理包括

* dependencies
* devDependencies
* optionalDependencies 可选择的依赖包
* peerDependencies 同等依赖
* bundledDependencies 捆绑依赖包

下面我们来看一下这几种依赖的区别以及各自的应用场景：

### dependencies

dependencies 是无论在开发环境还是在生产环境都必须使用的依赖，是我们最常用的依赖包管理对象，例如 React，Loadsh，Axios 等，通过 npm install XXX 下载的包都会默认安装在 dependencies 对象中，也可以使用 npm install XXX --save 下载 dependencies 中的包。

### devDependencies

devDependencies 是指可以在开发环境使用的依赖，例如 eslint，debug 等，通过 npm install packageName --save-dev 下载的包都会在 devDependencies 对象中。

dependencies 和 devDependencies 最大的区别是在打包运行时，执行 npm install 时默认会把所有依赖全部安装，但是如果使用 npm install --production 时就只会安装 dependencies 中的依赖，如果是 node 服务项目，就可以采用这样的方式用于服务运行时安装和打包，减少包大小。

### optionalDependencies

optionalDependencies 指的是可以选择的依赖，当你希望某些依赖即使下载失败或者没有找到时，项目依然可以正常运行或者 npm 继续运行的时，就可以把这些依赖放在 optionalDependencies 对象中，但是 optionalDependencies 会覆盖 dependencies 中的同名依赖包，所以不要把一个包同时写进两个对象中。

optionalDependencies 就像是我们的代码的一种保护机制一样，如果包存在的话就走存在的逻辑，不存在的就走不存在的逻辑。

### peerDependencies

peerDependencies 用于指定你当前的插件兼容的宿主必须要安装的包的版本？举个例子🌰：我们常用的 react 组件库 [ant-design@3.x](https://link.juejin.cn?target=mailto%3Aant-design%403.x "mailto:ant-design@3.x") 的 [package.json](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fant-design%2Fant-design%2Fblob%2Fmaster%2Fpackage.json%23L37%20%22https://github.com/ant-design/ant-design/blob/master/package.json#L37%22 "https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fant-design%2Fant-design%2Fblob%2Fmaster%2Fpackage.json%23L37%20%22https://github.com/ant-design/ant-design/blob/master/package.json#L37%22") 中的配置如下：

```
"peerDependencies": { 

  "react": ">=16.9.0", 

  "react-dom": ">=16.9.0" 

 }, 
```

假设我们创建了一个名为 project 的项目，在此项目中我们要使用 [ant-design@3.x](https://link.juejin.cn?target=mailto%3Aant-design%403.x "mailto:ant-design@3.x") 这个插件，此时我们的项目就必须先安装 React >= 16.9.0 和 React-dom >= 16.9.0 的版本。 ​

在 npm 2 中，当我们下载 [ant-design@3.x](https://link.juejin.cn?target=mailto%3Aant-design%403.x "mailto:ant-design@3.x") 时，peerDependencies 中指定的依赖会随着 [ant-design@3.x](https://link.juejin.cn?target=mailto%3Aant-design%403.x "mailto:ant-design@3.x") 一起被强制安装，所以我们不需要在宿主项目的 package.json 文件中指定 peerDependencies 中的依赖，但是在 npm 3 中，不会再强制安装 peerDependencies 中所指定的包，而是通过警告的方式来提示我们，此时就需要手动在 package.json 文件中手动添加依赖；

### bundledDependencies

这个依赖项也可以记为 bundleDependencies，与其他几种依赖项不同，他不是一个键值对的对象，而是一个数组，数组里是包名的字符串，例如：

```
{ 

  "name": "project", 

  "version": "1.0.0", 

  "bundleDependencies": \[ 

    "axios",  

    "lodash" 

  \] 

} 
```

当使用 npm pack 的方式来打包时，上述的例子会生成一个 project-1.0.0.tgz 的文件，在使用了 bundledDependencies 后，打包时会把 Axios 和 Lodash 这两个依赖一起放入包中，之后有人使用 npm install project-1.0.0.tgz 下载包时，Axios 和 Lodash 这两个依赖也会被安装。需要注意的是安装之后 Axios 和 Lodash 这两个包的信息在 dependencies 中，并且不包括版本信息。

```
"bundleDependencies": \[ 

    "axios", 

    "lodash" 

  \], 

  "dependencies": { 

    "axios": "\*", 

    "lodash": "\*" 

  }, 
```

如果我们使用常规的 npm publish 来发布的话，这个属性是不会生效的，所以日常情况中使用的较少。

yarn
----

上面我们说 npm2 的 node\_modules 是嵌套的。

这样其实是有问题的，多个包之间难免会有公共的依赖，这样嵌套的话，同样的依赖会复制很多次，会占据比较大的磁盘空间。

这个还不是最大的问题，致命问题是 windows 的文件路径最长是 260 多个字符，这样嵌套是会超过 windows 路径的长度限制的。

当时 npm 还没解决，社区就出来新的解决方案了，就是 yarn：

yarn 是怎么解决依赖重复很多次，嵌套路径过长的问题的呢？

铺平。所有的依赖不再一层层嵌套了，而是全部在同一层，这样也就没有依赖重复多次的问题了，也就没有路径过长的问题了。

我们用 yarn 安装下 yarn add express：

这时候 node\_modules 就是这样了：

![|520](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/4494cc1e8eec4cbcb2905d8df278b760~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

全部铺平在了一层，展开下面的包大部分是没有二层 node\_modules 的：

![|525](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0ae666f30987483caf02f882cacd5561~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

当然也有的包还是有 node\_modules 的，比如这样：

![|525](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/26a0b6c970c54f21a6900633b3515f84~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

为什么还有嵌套呢？

因为一个包是可能有多个版本的，提升只能提升一个，所以后面再遇到相同包的不同版本，依然还是用嵌套的方式。

npm 后来升级到 3 之后，也是采用这种铺平的方案了，和 yarn 很类似：

![|525](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/275dff97cfe149b7ab0f8e677ad99ac1~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

yarn 和 npm 都采用了铺平的方案，这种方案就没有问题了么？

npm5+、yarn 扁平化管理依赖问题
-------------------

1. 依赖结构的不确定性。
2. 扁平化算法本身的复杂性很高，耗时较长。
3. 项目中仍然可以非法访问没有声明过依赖的包

#### 1.依赖结构的不确定性。

第一点中的不确定性是什么意思？这里来详细解释一下。

假如现在项目依赖两个包 foo 和 bar，这两个包的依赖又是这样的:

![|525](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/318b312542c24eca921e3c4243f150c4~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

那么 npm/yarn install 的时候，通过扁平化处理之后，究竟是这样

![|525](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/ddd7bb71bfb4470f849f7e984f4d68f5~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

还是这样？

![|520](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/516c407e3c654b61a010b563462c811d~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

答案是: 都有可能。取决于 foo 和 bar 在 package.json 中的位置，如果 foo 声明在前面，那么就是前面的结构，否则是后面的结构。

这就是为什么会产生依赖结构的不确定问题，也是 lock 文件诞生的原因，无论是 package-lock.json(npm 5.x 才出现) 还是 yarn.lock，都是为了保证 install 之后都产生确定的 node\_modules 结构。

尽管如此，npm/yarn 本身还是存在扁平化算法复杂和 package 非法访问的问题，影响性能和安全。

### 3.项目中仍然可以非法访问没有声明过依赖的包

也就是幽灵依赖，也就是你明明没有声明在 dependencies 里的依赖，但在代码里却可以 require 进来。

这个也很容易理解，因为都铺平了嘛，那依赖的依赖也是可以找到的。

但是这样是有隐患的，因为没有显式依赖，万一有一天别的包不依赖这个包了，那你的代码也就不能跑了，因为你依赖这个包，但是现在不会被安装了。

这就是幽灵依赖的问题。

而且还有一个问题，就是上面提到的依赖包有多个版本的时候，只会提升一个，那其余版本的包不还是复制了很多次么，依然有浪费磁盘空间的问题。

那社区有没有解决这些问题的思路呢？当然有，这不是 pnpm 就出来了嘛。

那 pnpm 是怎么解决问题的呢？

pnpm
----

官网： [pnpm.io/zh/6.x/moti…](https://link.juejin.cn?target=https%3A%2F%2Fpnpm.io%2Fzh%2F6.x%2Fmotivation "https://pnpm.io/zh/6.x/motivation")

### pnpm 特性概览

#### 1\. 速度快

pnpm 安装包的速度究竟有多快？先以 React 包为例来对比一下:

![|515](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/1b25a597efb54da9aa250ca6f998f5d0~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

可以看到，作为黄色部分的 pnpm，在绝多大数场景下，包安装的速度都是明显优于 npm/yarn，速度会比 npm/yarn 快 2-3 倍。

#### 2\. 高效利用磁盘空间

pnpm 内部使用基于内容寻址的文件系统来存储磁盘上所有的文件，这个文件系统出色的地方在于:

* 不会重复安装同一个包。用 npm/yarn 的时候，如果 100 个项目都依赖 lodash，那么 lodash 很可能就被安装了 100 次，磁盘中就有 100 个地方写入了这部分代码。但在使用 pnpm 只会安装一次，磁盘中只有一个地方写入，后面再次使用都会直接使用 hardlink(硬链接，不清楚的同学详见这篇文章 ([www.cnblogs.com/itech/archi…](https://link.juejin.cn?target=https%3A%2F%2Fwww.cnblogs.com%2Fitech%2Farchive%2F2009%2F04%2F10%2F1433052.html))%25E3%2580%2582 "https://www.cnblogs.com/itech/archive/2009/04/10/1433052.html))%E3%80%82")
* 即使一个包的不同版本，pnpm 也会极大程度地复用之前版本的代码。举个例子，比如 lodash 有 100 个文件，更新版本之后多了一个文件，那么磁盘当中并不会重新写入 101 个文件，而是保留原来的 100 个文件的 hardlink，仅仅写入那一个新增的文件。

#### 3\. 支持 monorepo

随着前端工程的日益复杂，越来越多的项目开始使用 monorepo。之前对于多个项目的管理，我们一般都是使用多个 git 仓库，但 monorepo 的宗旨就是用一个 git 仓库来管理多个子项目，所有的子项目都存放在根目录的 packages 目录下，那么一个子项目就代表一个 package。如果你之前没接触过 monorepo 的概念，建议仔细看看这篇文章 ([www.perforce.com/blog/vcs/wh…](https://link.juejin.cn?target=https%3A%2F%2Fwww.perforce.com%2Fblog%2Fvcs%2Fwhat-monorepo)%25E4%25BB%25A5%25E5%258F%258A%25E5%25BC%2580%25E6%25BA%2590%25E7%259A%2584 "https://www.perforce.com/blog/vcs/what-monorepo)%E4%BB%A5%E5%8F%8A%E5%BC%80%E6%BA%90%E7%9A%84") monorepo 管理工具 lerna([github.com/lerna/lerna…](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Flerna%2Flerna%23readme)%25EF%25BC%258C%25E9%25A1%25B9%25E7%259B%25AE%25E7%259B%25AE%25E5%25BD%2595%25E7%25BB%2593%25E6%259E%2584%25E5%258F%25AF%25E4%25BB%25A5%25E5%258F%2582%25E8%2580%2583%25E4%25B8%2580%25E4%25B8%258B "https://github.com/lerna/lerna#readme)%EF%BC%8C%E9%A1%B9%E7%9B%AE%E7%9B%AE%E5%BD%95%E7%BB%93%E6%9E%84%E5%8F%AF%E4%BB%A5%E5%8F%82%E8%80%83%E4%B8%80%E4%B8%8B") babel 仓库 ([github.com/babel/babel…](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Fbabel%2Fbabel)%25E3%2580%2582 "https://github.com/babel/babel)%E3%80%82")

pnpm 与 npm/yarn 另外一个很大的不同就是支持了 monorepo，体现在各个子命令的功能上，比如在根目录下 pnpm add A -r, 那么所有的 package 中都会被添加 A 这个依赖，当然也支持 --filter 字段来对 package 进行过滤。

#### 4\. 安全性高

之前在使用 npm/yarn 的时候，由于 node\_module 的扁平结构，如果 A 依赖 B， B 依赖 C，那么 A 当中是可以直接使用 C 的，但问题是 A 当中并没有声明 C 这个依赖。因此会出现这种非法访问的情况。但 pnpm 脑洞特别大，自创了一套依赖管理方式，很好地解决了这个问题，保证了安全性，具体怎么体现安全、规避非法访问依赖的风险的，后面再来详细说说。

### pnpm 依赖管理方式

创建非扁平化的 node\_modules 文件夹 [​](https://link.juejin.cn?target=https%3A%2F%2Fpnpm.io%2Fzh%2F6.x%2Fmotivation%23%25E5%2588%259B%25E5%25BB%25BA%25E9%259D%259E%25E6%2589%2581%25E5%25B9%25B3%25E5%258C%2596%25E7%259A%2584-node_modules-%25E6%2596%2587%25E4%25BB%25B6%25E5%25A4%25B9%2520%2522%25E6%25A0%2587%25E9%25A2%2598%25E7%259B%25B4%25E9%2593%25BE%2522 "https://pnpm.io/zh/6.x/motivation#%E5%88%9B%E5%BB%BA%E9%9D%9E%E6%89%81%E5%B9%B3%E5%8C%96%E7%9A%84-node_modules-%E6%96%87%E4%BB%B6%E5%A4%B9%20%22%E6%A0%87%E9%A2%98%E7%9B%B4%E9%93%BE%22")

![|525](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/6ec5de413b2c4e899d3922d2d481c806~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

使用 npm 或 Yarn 安装依赖项时，所有包都被提升到模块目录的根目录。 因此，项目可以访问到未被添加进当前项目的依赖。

默认情况下，pnpm 使用软链的方式将项目的直接依赖添加进模块文件夹的根目录。

回想下 npm3 和 yarn 为什么要做 node\_modules 扁平化？不就是因为同样的依赖会复制多次，并且路径过长在 windows 下有问题么？

那如果不复制呢，比如通过 link。

首先介绍下 link，也就是软连接，这是操作系统提供的机制，硬连接就是同一个文件的不同引用，而软链接是新建一个文件，文件内容指向另一个路径。当然，这俩链接使用起来是差不多的。

如果不复制文件，只在全局仓库保存一份 npm 包的内容，其余的地方都 link 过去呢？

这样不会有复制多次的磁盘空间浪费，而且也不会有路径过长的问题。因为路径过长的限制本质上是不能有太深的目录层级，现在都是各个位置的目录的 link，并不是同一个目录，所以也不会有长度限制。

没错，pnpm 就是通过这种思路来实现的。

再把 node\_modules 删掉，然后用 pnpm 重新装一遍，执行 pnpm install。

你会发现它打印了这样一句话：

![|495](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/9289c3cca25d475aac7287616c5c090c~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

包是从全局 store 硬连接到虚拟 store 的，这里的虚拟 store 就是 node\_modules/.pnpm。

我们打开 node\_modules 看一下：

![|525](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/6f4494103d924fb7acc15fa11c264adf~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

确实不是扁平化的了，依赖了 express，那 node\_modules 下就只有 express，没有幽灵依赖。

展开 .pnpm 看一下：

![|525](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/391723546d2f4e8e88d73d41e23210f6~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

所有的依赖都在这里铺平了，都是从全局 store 硬连接过来的，然后包和包之间的依赖关系是通过软链接组织的。

比如 .pnpm 下的 expresss，这些都是软链接，

![|500](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/d1174036b4324f95afe0530cc5fa964c~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

也就是说，所有的依赖都是从全局 store 硬连接到了 node\_modules/.pnpm 下，然后之间通过软链接来相互依赖。

这就是 pnpm 的实现原理，它最大的优点是节省磁盘空间，一个包全局只保存一份，剩下的都是软硬连接。

第二个优点就是快，因为通过链接的方式而不是复制，自然会快。

这也是它所标榜的优点：

* 相比 npm2 的优点就是不会进行同样依赖的多次复制。
* 相比 yarn 和 npm3+ 呢，那就是没有幽灵依赖，也不会有没有被提升的依赖依然复制多份的问题。

#### pnpm 安装 express 案例

还是以安装 express 为例，我们新建一个目录，执行:

pnpm init -y

然后执行:

pnpm install express

我们再去看看 node\_modules:

.pnpm

.modules.yaml

express

我们直接就看到了 express，但值得注意的是，这里仅仅只是一个软链接，不信你打开看看，里面并没有 node\_modules 目录，如果是真正的文件位置，那么根据 node 的包加载机制，它是找不到依赖的。那么它真正的位置在哪呢？

我们继续在 .pnpm 当中寻找:

```
▾ node\_modules

  ▾ .pnpm

    ▸ [accepts@1.3.7](https://link.juejin.cn?target=mailto%3Aaccepts%401.3.7 "mailto:accepts@1.3.7")

    ▸ [array-flatten@1.1.1](https://link.juejin.cn?target=mailto%3Aarray-flatten%401.1.1 "mailto:array-flatten@1.1.1")

    ...

    ▾ [express@4.17.1](https://link.juejin.cn?target=mailto%3Aexpress%404.17.1 "mailto:express@4.17.1")

      ▾ node\_modules

        ▸ accepts

        ▸ array-flatten

        ▸ body-parser

        ▸ content-disposition

        ...

        ▸ etag

        ▾ express

          ▸ lib

            History.md

            index.js

            LICENSE

            package.json

            Readme.md
```

好家伙！竟然在 .pnpm/express@4.17.1/node\_modules/express 下面找到了!

随便打开一个别的包:

![|520](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/06b042cc52f54965a36695681f68e805~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

好像也都是一样的规律，都是@version/node\_modules/这种目录结构。并且 express 的依赖都在.pnpm/express@4.17.1/node\_modules 下面，这些依赖也全都是软链接。

再看看.pnpm，.pnpm 目录下虽然呈现的是扁平的目录结构，但仔细想想，顺着软链接慢慢展开，其实就是嵌套的结构！

```
▾ node\_modules

  ▾ .pnpm

    ▸ [accepts@1.3.7](https://link.juejin.cn?target=mailto%3Aaccepts%401.3.7 "mailto:accepts@1.3.7")

    ▸ [array-flatten@1.1.1](https://link.juejin.cn?target=mailto%3Aarray-flatten%401.1.1 "mailto:array-flatten@1.1.1")

    ...

    ▾ [express@4.17.1](https://link.juejin.cn?target=mailto%3Aexpress%404.17.1 "mailto:express@4.17.1")

      ▾ node\_modules

        ▸ accepts  -> ../accepts@1.3.7/node\_modules/accepts

        ▸ array-flatten -> ../array-[flatten@1.1.1](https://link.juejin.cn?target=mailto%3Aflatten%401.1.1 "mailto:flatten@1.1.1")/node\_modules/array-flatten

        ...

        ▾ express

          ▸ lib

            History.md

            index.js

            LICENSE

            package.json

            Readme.md
```

将包本身和依赖放在同一个 node\_module 下面，与原生 Node 完全兼容，又能将 package 与相关的依赖很好地组织到一起，设计十分精妙。

现在我们回过头来看，根目录下的 node\_modules 下面不再是眼花缭乱的依赖，而是跟 package.json 声明的依赖基本保持一致。即使 pnpm 内部会有一些包会设置依赖提升，会被提升到根目录 node\_modules 当中，但整体上，根目录的 node\_modules 比以前还是清晰和规范了许多。

### 详解安全性高

不知道你发现没有，pnpm 这种依赖管理的方式也很巧妙地规避了非法访问依赖的问题，也就是只要一个包未在 package.json 中声明依赖，那么在项目中是无法访问的。

但在 npm/yarn 当中是做不到的，那你可能会问了，如果 A 依赖 B， B 依赖 C，那么 A 就算没有声明 C 的依赖，由于有依赖提升的存在，C 被装到了 A 的 node\_modules 里面，那我在 A 里面用 C，跑起来没有问题呀，我上线了之后，也能正常运行啊。不是挺安全的吗？

还真不是。

第一，你要知道 B 的版本是可能随时变化的，假如之前依赖的是 [C@1.0.1](https://link.juejin.cn?target=mailto%3AC%401.0.1 "mailto:C@1.0.1")，现在发了新版，新版本的 B 依赖 [C@2.0.1](https://link.juejin.cn?target=mailto%3AC%402.0.1 "mailto:C@2.0.1")，那么在项目 A 当中 npm/yarn install 之后，装上的是 2.0.1 版本的 C，而 A 当中用的还是 C 当中旧版的 API，可能就直接报错了。

第二，如果 B 更新之后，可能不需要 C 了，那么安装依赖的时候，C 都不会装到 node\_modules 里面，A 当中引用 C 的代码直接报错。

还有一种情况，在 monorepo 项目中，如果 A 依赖 X，B 依赖 X，还有一个 C，它不依赖 X，但它代码里面用到了 X。由于依赖提升的存在，npm/yarn 会把 X 放到根目录的 node\_modules 中，这样 C 在本地是能够跑起来的，因为根据 node 的包加载机制，它能够加载到 monorepo 项目根目录下的 node\_modules 中的 X。但试想一下，一旦 C 单独发包出去，用户单独安装 C，那么就找不到 X 了，执行到引用 X 的代码时就直接报错了。

这些，都是依赖提升潜在的 bug。如果是自己的业务代码还好，试想一下如果是给很多开发者用的工具包，那危害就非常严重了。

npm 也有想过去解决这个问题，指定 `--global-style` 参数即可禁止变量提升，但这样做相当于回到了当年嵌套依赖的时代，一夜回到解放前，前面提到的嵌套依赖的缺点仍然暴露无遗。

npm/yarn 本身去解决依赖提升的问题貌似很难完成，不过社区针对这个问题也已经有特定的解决方案: dependency-check，地址: [github.com/dependency-…](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Fdependency-check-team%2Fdependency-check "https://github.com/dependency-check-team/dependency-check")

但不可否认的是，pnpm 做的更加彻底，独创的一套依赖管理方式不仅解决了依赖提升的安全问题，还大大优化了时间和空间上的性能。

### pnpm 与 node 版本兼容表 [​](https://link.juejin.cn?target=https%3A%2F%2Fpnpm.io%2Fzh%2F6.x%2Finstallation%23%25E5%2585%25BC%25E5%25AE%25B9%25E6%2580%25A7%2520%2522%25E6%25A0%2587%25E9%25A2%2598%25E7%259B%25B4%25E9%2593%25BE%2522 "https://pnpm.io/zh/6.x/installation#%E5%85%BC%E5%AE%B9%E6%80%A7%20%22%E6%A0%87%E9%A2%98%E7%9B%B4%E9%93%BE%22")

以下是各版本 pnpm 与各版本 Node.js 之间的支持表格。

![|525](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/4b80a6ef95aa42e79331ce3001579645~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

### 日常使用命令

说了这么多，估计你会觉得 pnpm 挺复杂的，是不是用起来成本很高呢？

恰好相反，pnpm 使用起来十分简单，如果你之前有 npm/yarn 的使用经验，甚至可以无缝迁移到 pnpm 上来。不信我们来举几个日常使用的例子。

#### pnpm install

跟 npm install 类似，安装项目下所有的依赖。但对于 monorepo 项目，会安装 workspace 下面所有 packages 的所有依赖。不过可以通过 --filter 参数来指定 package，只对满足条件的 package 进行依赖安装。

当然，也可以这样使用，来进行单个包的安装:

```arduino
// 安装 axios

pnpm install axios

// 安装 axios 并将 axios 添加至 devDependencies

pnpm install axios -D

// 安装 axios 并将 axios 添加至 dependencies

pnpm install axios -S

```

当然，也可以通过 --filter 来指定 package。

#### pnpm update

根据指定的范围将包更新到最新版本，monorepo 项目中可以通过 --filter 来指定 package。

#### pnpm uninstall

在 node\_modules 和 package.json 中移除指定的依赖。monorepo 项目同上。举例如下:

```css
// 移除 axios

pnpm uninstall axios --filter package-a

```

#### pnpm link

将本地项目连接到另一个项目。注意，使用的是硬链接，而不是软链接。如:

```
pnpm link ../../axios
```

另外，对于我们经常用到 `npm run/start/test/publish`，这些直接换成 pnpm 也是一样的，不再赘述。更多的使用姿势可参考官方文档: [pnpm.js.org/en/](https://link.juejin.cn?target=https%3A%2F%2Fpnpm.js.org%2Fen%2F "https://pnpm.js.org/en/")

可以看到，虽然 pnpm 内部做了非常多复杂的设计，但实际上对于用户来说是无感知的，使用起来非常友好。并且，现在作者现在还一直在维护，目前 npm 上周下载量已经有 10w +，经历了大规模用户的考验，稳定性也能有所保障。

因此，综合来看，pnpm 是一个相比 npm/yarn 更优的方案，期待未来 pnpm 能有更多的落地。

### 总结

pnpm 最近经常会听到，可以说是爆火。本文我们梳理了下它爆火的原因：

npm2 是通过嵌套的方式管理 node\_modules 的，会有同样的依赖复制多次的问题。

npm3+ 和 yarn 是通过铺平的扁平化的方式来管理 node\_modules，解决了嵌套方式的部分问题，但是引入了幽灵依赖的问题，并且同名的包只会提升一个版本的，其余的版本依然会复制多次。

pnpm 则是用了另一种方式，不再是复制了，而是都从全局 store 硬连接到 node\_modules/.pnpm，然后之间通过软链接来组织依赖关系。

这样不但节省磁盘空间，也没有幽灵依赖问题，安装速度还快，从机制上来说完胜 npm 和 yarn。

pnpm 就是凭借这个对 npm 和 yarn 降维打击的。

### 另附常见安装错误

#### 问题 1：运行 pnpm install 报错 ERR\_PNPM\_INVALID\_OVERRIDE\_SELECTOR

```
pnpm: Cannot parse the "//" [selector](https://link.juejin.cn?target=https%3A%2F%2Fso.csdn.net%2Fso%2Fsearch%3Fq%3Dselector%26spm%3D1001.2101.3001.7020 "https://so.csdn.net/so/search?q=selector&spm=1001.2101.3001.7020") in the overrides\\n at parsePkgSelector
```

解决方法：

package.json 下的 resolutions 删除 “//”所在行，如下图：

![|525](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/38d43c5a88184ecfae99f8286725a7a8~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

#### 问题 2：假设您在运行 pnpm install 时遇到以下错误：

```
C:\\src>pnpm install

internal/modules/cjs/loader.js:883

  throw err;

  ^

Error: Cannot find module 'C:\\Users\\Bence\\AppData\\Roaming\\npm\\pnpm-global\\4\\node\_modules\\pnpm\\bin\\pnpm.js'

←\[90m    at Function.Module.\_resolveFilename (internal/modules/cjs/loader.js:880:15)←\[39m

←\[90m    at Function.Module.\_load (internal/modules/cjs/loader.js:725:27)←\[39m

←\[90m    at Function.executeUserEntryPoint \[as runMain\] (internal/modules/run\_main.js:72:12)←\[39m

←\[90m    at internal/main/run\_main\_module.js:17:47←\[39m {

  code: ←\[32m'MODULE\_NOT\_FOUND'←\[39m,

  requireStack: \[\]

}
```

首先，尝试通过运行： which pnpm 来找到 pnpm 的位置。 如果您使用的是 Windows，请在 Git Bash 中运行此命令。 您将获得 pnpm 命令的位置，例如：

```
$ which pnpm

/c/Program Files/nodejs/pnpm
```

现在您应该已经知道了 pnpm CLI 的所在目录。打开该目录并删除所有与 pnpm 相关的文件（如 pnpm.cmd、 pnpx.cmd、 pnpm 等）。 完成后，再次安装 pnpm。现在，它应该正按照预期工作。

参考文献
----

package.json 官方文档 ([docs.npmjs.com/files/packa…](https://link.juejin.cn?target=https%3A%2F%2Fdocs.npmjs.com%2Ffiles%2Fpackage.json%23peerdependencies "https://docs.npmjs.com/files/package.json#peerdependencies"))

package-lock-json 官方文档 ([docs.npmjs.com/configuring…](https://link.juejin.cn?target=https%3A%2F%2Fdocs.npmjs.com%2Fconfiguring-npm%2Fpackage-lock-json.html%23requires "https://docs.npmjs.com/configuring-npm/package-lock-json.html#requires"))

npm 文档总结 ([juejin.im/post/684490…](https://juejin.im/post/6844903582337237006#heading-0 "https://juejin.im/post/6844903582337237006#heading-0"))

npm-pack ([www.npmjs.cn/cli/pack/](https://link.juejin.cn?target=https%3A%2F%2Fwww.npmjs.cn%2Fcli%2Fpack%2F "https://www.npmjs.cn/cli/pack/"))

npm 依赖管理中被忽略的那些细节 ([juejin.cn/post/686432…](https://juejin.cn/post/6864323316912488455 "https://juejin.cn/post/6864323316912488455"))

[pnpm 是凭什么对 npm 和 yarn 降维打击的](https://link.juejin.cn?target=https%3A%2F%2Fsegmentfault.com%2Fa%2F1190000042266656 "https://segmentfault.com/a/1190000042266656")([mp.weixin.qq.com/s/bLthdXlmu…](https://link.juejin.cn?target=https%3A%2F%2Fmp.weixin.qq.com%2Fs%2FbLthdXlmu8wtC3ScAaZ3Kg "https://mp.weixin.qq.com/s/bLthdXlmu8wtC3ScAaZ3Kg"))

关于现代包管理器的深度思考——为什么现在我更推荐 pnpm 而不是 npm/yarn?([mp.weixin.qq.com/s/aCS4Ku34n…]( https://link.juejin.cn?target=https%3A%2F%2Fmp.weixin.qq.com%2Fs%2FaCS4Ku34nDe3A-WT5hdx7A " https://mp.weixin.qq.com/s/aCS4Ku34nDe3A-WT5hdx7A" ))