---
title: 位置编码学习笔记（一）：Sinusoidal
description: 简要介绍绝对位置编码和Sinusoidal位置编码
date: 2026-05-16
slug: positional-encoding-sinusoidal-1
tags:
  - "#位置编码"
  - "#BERT"
draft: false
math: true
---
## 一、为什么需要位置编码

目前主流的LLM都选用了位置编码为输入添加先验信息，尽管这是一种再平常不过的操作（至少从现在看来），但其背后的原因还是值得追问的。

### 1.Attention的置换不变性

在BERT中，我们使用的是双向注意力，此时一个句子的token是同时送入模型，没有因果掩码。这会导致句子在模型看来是无序的，具体而言，我们要把 $x_1,x_2,...,x_L$ 送入模型 $f$ ，计算得到位置 $n$ 的输出 $y_n$ ，根据注意力机制的公式：
$$
y_n = f(q_n,x_1,x_2,...,x_L) = \frac{\sum_{m=1}^Le^{q_n\cdot k_m}v_m}{\sum_{m=1}^Le^{q_n\cdot k_m}}
\tag{1}
$$这就会出现：

$$
y_n = f(q_n,x_1,x_2,...,x_p,...,x_q,...,x_n) = f(q_n,x_1,x_2,...,x_q,...,x_p,...,x_n)
$$

即任意交换送入token的位置关系，输出不变，这就是**Attention的置换不变性**。

![[Pasted image 20260517111610.png]]

但这种“优美”的数学性质并不是我们希望其保留下来的，最简单的例子是：

$$
\text{“我打狗”与“狗打我”}
$$

二者的语序不同，其含义也截然不同了。我们希望模型可以学习到这种语序信息，为此加入了位置编码破坏他的置换不变性。

### 2.先验信息

位置编码的另一个作用，是加入对Attention的先验认知，或者赋予Attention学习到这些先验认知性质的能力。

 像RNN、CNN这类模型，本质上就是把“越近的Token越重要”的先验融入到了架构中，使其可以不用位置编码并且将复杂度降低到线性。
 
 然而，先验都是人为的、有偏的，我们应该给予模型更大的自由，让其从信息而非架构中得到先验。下面要讲的Sinusoidal位置编码就隐含了“token越近，embedding越相似”的先验假设；BERT所用的位置编码同样是绝对位置编码，但它是随机初始化然后作为参数来学习的，也就是说它没有作出相近的假设，但允许模型学到这个性质（如果模型认为有必要的话）。
 
### 3.NoPE？

我们前面提到的是双向注意力架构的BERT，一个显而易见的是：单向注意力通过因果掩码，隐含了位置信息（因为只能利用之前的信息计算当前位置输出）。我们关心的是，这种隐含的位置信息有多强。

单向注意力的计算公式如下：

$$
y_n = f(q_n,x_1,...,x_L) = \frac{\sum^n_{m=1}e^{q_n\cdot k_m}v_m}{\sum^n_{m=1}e^{q_n\cdot k_m}}
$$

就是把 $(1)$ 式中的 $L$ 换成了 $n$ ，这一结果依赖于 $x_1,...,x_L$ 的顺序，因此不具有置换不变性，那么这种位置信息能够给模型多强的先验？

[《Transformer Language Models without Positional Encodings Still Learn Positional Information》](https://papers.cool/arxiv/2203.16634)这篇论文做了相关的实验，他们利用探针检测了随层数变化，每个 token 的 hidden state 隐含位置信息的偏差：

 ![[Pasted image 20260517140903.png]]
 
 NoPE的模型在前几层一开始没有位置信息，但在大约 4 层内误差快速下降，即这一过程中模型借助因果掩码逐步学到了位置信息，而后期所有的位置编码误差都上升了，这与[《The Bottom-up Evolution of Representations in the Transformer: A Study with Machine Translation and Language Modeling Objectives》](https://papers.cool/arxiv/1909.01380)中揭示的现象也一致：到了深层，模型已经提取了高度抽象的语义信息，关注前面词的精确位置对于预测下一个词不再有直接的帮助，因此“遗忘”了这些信息。