---
aliases: []
created_date: 2023-09-04 16:18
draft: false
summary: ''
tags:
- dev
---

#ai 

> 对论文 Rethinking the Role of Demonstrations: What Makes In-Context Learning Work?的解读。其实也说不上解读，不过是读论文时的随手笔记罢了。  
> [Rethinking the Role of Demonstrations: What Makes In-Context Learning Work?](https://arxiv.org/abs/2202.12837) ~ [GitHub - Alrope123/rethinking-demonstrations](https://github.com/Alrope123/rethinking-demonstrations)

* MetaAI 与 University of Washington 的工作。一作 Sewon Min 近期创作了很多相关主题的高质量工作。

> 一作的近期的其它相关工作：  
> Noisy Channel Language Model Prompting for Few-Shot Text Classification ~ [https://arxiv.org/pdf/2108.04106.pdf](https://arxiv.org/pdf/2108.04106.pdf)  
> MetaICL: Learning to Learn In Context ~ [https://arxiv.org/pdf/2110.15943.pdf](https://arxiv.org/pdf/2110.15943.pdf)  
> 平时有些同学做了很多实验，一到写论文就什么都想往论文里放，感觉还是应该学习一下这篇文章作者的写法。这三篇文章 arxiv 的时间跨度只有 6 个月，中间还夹杂了圣诞节，并且很多实验甚至是有 overlap 的，基本可以判断为一作同时在做的几项工作。作者从不同的角度去分割了这些实验，讲出了三个故事，每个故事看起来都完整且独立，值得学习。

* 这篇文章没有很 fancy 的 model/design，而是通过一些列调研得到了一个很有意思的结论：**in-context learning 学习的并不是输入与标注之间的关联，而是通过展示数据形式，来激活预训练模型的能力。**
* 此外还有两个附带的结论：(1) 在 meta learning 的环境下，in-context learning 的这一特点更为明显；(2) 因为标签不重要，所以可以用无标注领域内数据做 in-context zero shot learning。

* * *

背景：in-context learning
----------------------

大规模预训练模型的 **无监督预测**：对预训练好的语言模型，输入测试数据的输入（x），直接通过语言模型预测输出（P(y|x)）。如下图所示。其中 minimal 是最简单的方式，mannual 是加入人工设计的部分。蓝色是需要预测的标签部分。这篇论文中，作者默认采用 Minimal 的方式处理测试数据。

![](Attachments/4474240a21a0397a5e9417209ff12c5e.jpg)

而 **in-context learning**，类似于上述的无监督预测，但在输入测试样例前输入少量标注数据。同样不需要参数调整，直接训练。相当于在无监督预测的基础上，引入如下前缀：

![](Attachments/bb77928d4d478d4bd64dfb2a934d9a0a.jpg)

而本文主要探究的，就是 in-context learning 中，模型究竟从加入的这段前缀中学到了什么。

实验设置
----

本文主要探究了 6 种不同的预训练模型，其中，MetaICL 采用了大量的下游任务以 in-context learning 的形式进行了元学习：

![](Attachments/c2246be32d831306b27fc9085d3576b6.jpg)

对于每个模型，作者采用了两种应用方式，即 direct 和 channel：

![](Attachments/f30ff2cf2e266517b65efd2e8e61cf4e.jpg)

作者一共探究了 26 个数据集，其中 16 个分类任务和 10 个多项选择任务。

![](Attachments/c8193afd9eb1db3798b92dcaa4b3027d.jpg)

在实验细节上，作者对于每个 instance，展示了 16 个标注样例。每组设置（26 个数据集\*6 个预训练模型\*2 组使用方式）用 5 个随机数种子跑了 5 遍。 作者在 airseq 13B 和 GPT-3 两个大模型上，出于算力的考虑只做了 6 个数据集，和 3 个随机数种子。

由于实验较多，作者一般仅汇报各种均值。

结论一、in-context learning 中，模型并没有学习输入和标签之间的对应关系
--------------------------------------------

通过给 in-context 的训练样本赋予随机标签，可以构建随机标注的设置。从下图中可以看出，无论是分类任务（上），还是多项选择任务（下），随机标注设置下（红）模型表现均和正确标注（黄）表现相当，且明显超过没有 in-context 样本的 zero-shot 设置（蓝）。

![](Attachments/1d568d124045cd5515bfdc3e1a065c5c.jpg)

这一点趋势，在改变随机标签的 in-context 样本比例，以及改变 in-context 样本数量时，都是保持的。选用人工设计的 in-context 展示形式（prompt），结论也不发生改变。

![](Attachments/898c65a039689c0be5f2f9a388d1cc76.jpg)  
![](Attachments/df8b82aa092daefc9d937c2a66bcd8d4.jpg)  
![](Attachments/df36fe8be6681e1e7d608613bdbd437d.jpg)

结论二、in-context learning 中，模型学到（激活）了输入数据、预测标签的分布，以及这种数据 +label 的语言表达形式。
-------------------------------------------------------------------

下图中，青绿色的柱子为用（从外部语料中）随机采样的句子替换输入句子的设置。可以看到，模型表现明显下降。因此，in-context learning 中，展示样本和测试样本在语料分布上的一致性比较中央。猜测模型很可能学到了展示样本的语言风格。

![](Attachments/7dabbb0055a06ed812c4f2c47d161d2e.jpg)

下图中，青绿色的柱子为用随机词汇替代展示样本中的标签。可以看到，模型表现明显下降。因此，in-context learning 中，展示样本中的标签内容与测试样本的标签内容的一致性是比较重要的。猜测模型很可能从展示样本中学到了标签词汇的分布。

![](Attachments/eae26bec8890ce881b07b1065a5c71a0.jpg)

下图中，分别用 labels only（深紫）和 no labels（深绿）来探索展示模式的差异对模型表现的影响。可以看到，模型相对于上面两图的 OOD setting 而言，都有了进一步的下降。这可以表明，除了领域内，输入和标签表达方式之外，in-context learning 中模型还会学习这种输入输出的语言模式。

![](Attachments/725a16ce60866c2125d1b261c764ea8d.jpg)

* * *
总结一
-----

### 在 in-context learning 下模型有没有学习？

作者认为，传统意义上的学习指模型建模输入样本和输出样本之间的关联（P(y|x) 或 P(x,y)∝P(x|y)）。**在这种意义下，in-context learning 并没有学习。**

然而，模型可以通过展示样例，中的输入、输出、及输入 + 输出的语言表达风格来提升表现。在一定程度上，这种利用前缀输入激活大模型语言表达建模能力的方式也算是一种学习。

因此，这也表明：

### 当前大模型具有的零监督学习能力远超预期

毕竟，学习表达形式、语言风格与标签形式，不需要标注数据的参与。大模型潜在地就具有了这种（分类）能力。

当然，反过来，也表明了 in-context learning 的局限在于，它不能真正建模输入和输出之间的关系，因此在一些输入输出之间的关系必然没有被无监督预训练任务所建模的下游任务而言，in-context learning 很可能失效。

> 不过，看起来目前大多数传统 NLP 的任务都不会满足上述“失效”设定。

## 总结二

为了更好地理解 ICL 的工作原理，清华大学、北京大学和微软的研究人员共同发表了一篇论文，将语言模型解释为 `元优化器`（meta-optimizer），并将 ICL 理解为一种隐性的（implicit）微调。

# in-context learning 到底在学啥？

- [How does in-context learning work?](http://ai.stanford.edu/blog/understanding-incontext/)
	- [【论文解读】in-context learning到底在学啥？ - 知乎](https://zhuanlan.zhihu.com/p/484999828)
	- [In-context learning综述](https://arxiv.org/pdf/2301.00234.pdf)
	- [github](https://github.com/dtsip/in-context-learning)
	- [In-Context Paperlist](https://github.com/dongguanting/In-Context-Learning_PaperList)