---
title: 位置编码学习笔记（一）：为什么我们需要位置编码
description: 介绍为什么需要PE以及NoPE
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
$$

这就会出现：

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
 
### 3.NoPE

我们前面提到的是双向注意力架构的BERT，一个显而易见的是：单向注意力通过因果掩码，隐含了位置信息（因为只能利用之前的信息计算当前位置输出）。我们关心的是，这种隐含的位置信息有多强。

单向注意力的计算公式如下：

$$
y_n = f(q_n,x_1,...,x_L) = \frac{\sum^n_{m=1}e^{q_n\cdot k_m}v_m}{\sum^n_{m=1}e^{q_n\cdot k_m}}
$$

就是把 $(1)$ 式中的 $L$ 换成了 $n$ ，这一结果依赖于 $x_1,...,x_L$ 的顺序，因此不具有置换不变性，那么这种位置信息能够给模型多强的先验？

[《Transformer Language Models without Positional Encodings Still Learn Positional Information》](https://papers.cool/arxiv/2203.16634)这篇论文做了相关的实验，他们利用探针检测了随层数变化，每个 token 的 hidden state 隐含位置信息的误差：

 ![[Pasted image 20260517140903.png]]
 
 NoPE的模型在前几层一开始没有位置信息，但在大约 4 层内误差快速下降，即这一过程中模型借助因果掩码逐步学到了位置信息，而后期所有的位置编码误差都上升了，这与[《The Bottom-up Evolution of Representations in the Transformer: A Study with Machine Translation and Language Modeling Objectives》](https://papers.cool/arxiv/1909.01380)中揭示的现象也一致：到了深层，模型已经提取了高度抽象的语义信息，关注前面词的精确位置对于预测下一个词不再有直接的帮助，因此“遗忘”了这些信息。


### 4.Nope的数学依据

下面笔者参考[《Latent Positional Information is in the Self-Attention Variance of Transformer Language Models Without Positional Embeddings》](https://papers.cool/arxiv/2305.13571)来解释这个位置信息是怎么隐含的：

考虑一串输入 $\{x_m\}_{m=1}^L$ ，假设每个 $x_m \sim \mathcal{N}(0, \sigma^2)\in \mathbb{R}^d$，我们可以计算：

$$
\begin{aligned}
\bar{x}_{m,:} &= \frac{\sum_{i=1}^{d} x_{mi}}{d},\\
S(x_{m,:}) &= \frac{\sum_{i=1}^{d}(x_{mi}-\bar{x}_{m,:})^2}{d}
\end{aligned}
$$

 $x_m$ 首先会经过Layer Normalization：

$$
e_m  =\frac{x_{mi}-\bar{x}_{m,:}}{\sqrt{S(x_{m,:})}}\cdot \gamma+\beta
\approx  
\frac{x_{mi}-\mathbb{E}[x_{mi}]}{\sqrt{\operatorname{Var}[x_{mi}]}}  
\sim  
\mathcal{N}(0,1)
$$

其中 $\gamma = 1, \beta = 0$ ，约等号成立是因为：在大数定律下，即只要维度 $d$ 足够大，归一化后的特征 $e_m$ 就会服从标准正态分布（与位置无关）。

接下来，特征通过权重矩阵投影生成 Query, Key, Value：

$$q_m = W_q e_m, \quad k_m = W_k e_m, \quad v_m = W_v e_m$$

一般地，取 $W_{q/k/v}\in \mathbb{R}^{\frac{d}{H}\times d}\sim  \mathcal{N}(0,\sigma^2)$ ，此处的 $H$ 指多头注意力的头数。

我们以 $q_m$ 为例看看均值和协方差阵怎么变化：

由于 $W_q$ 和 $e_m$ 是独立的，我们可以对期望进行分解：

$$
\mathbb{E}[q_m] = \mathbb{E}[W_q e_m] = \mathbb{E}[W_q] \mathbb{E}[e_m] = 0 \times 0 = 0
$$

进而对于协方差阵：

$$
Cov(q_m) = \mathbb{E}[(W_q e_m)(W_q e_m)^\top] =  \mathbb{E}[W_q e_me_m^\top W_q^\top] 
$$

我们关注 $W_q e_me_m^\top W_q^\top \in \mathbb{R}^{\frac{d}{H}\times\frac{d}{H}}$ 这坨东西，不妨设 $r_i^\top$ 是矩阵 $W_q$ 的第 $i$ 行元素，则协方差矩阵里面 $(i,j)$ 的元素可以写成：

$$
 \mathbb{E}[r_i^\top e_me_m^\top r_j] = \mathbb{E}[\text{Tr}(r_i^\top e_me_m^\top r_j)] = \mathbb{E}[\text{Tr}(r_j r_i^\top e_me_m^\top )] = \text{Tr}(\mathbb{E}[r_j r_i^\top][ e_me_m^\top ])
 \tag{2}
$$

其中，
- 第一个等号是因为 $r_i^\top e_me_m^\top r_j$ 是一个标量，它的期望就是迹的期望
- 第二个等号是因为迹具有循环不变性：$\text{Tr}(ABC) = \text{Tr}(CAB)$。
- 第三个等号是因为迹和期望都是线性的，并且 $W_q$ 与 $e_m$ 无关

当且仅当 $i = j$ 时有  $\mathbb{E}[r_j r_i^\top] = \sigma^2 I_d$，由于 $e_m$ 的方差为1，显然  $\mathbb{E}[e_me_m^\top] = I_d$

因此上式有：

$$
\text{Tr}(\mathbb{E}[r_j r_i^\top][ e_me_m^\top ]) = \text{Tr}((\mathbb{I}_{i=j} \sigma^2 I_d) \cdot I_d) = \mathbb{I}_{i=j} \sigma^2 \text{Tr}(I_d)
$$

因此投影后的元素 $q_m$ 的协方差矩阵 

$$
Cov(q_m) = (\sigma^2d)I
$$ 
下面就要通过自注意力来计算分数：

$$
l_{mn} = \langle q_m, k_n \rangle = q_m^\top k_n,\quad m\geq n
$$

同样地，我们计算下协方差阵：
$$
\begin{aligned}
\operatorname{cov}&(l_{mn}, l_{mp}) \\
&= \mathbb{E}[(\mathbf{e}_m^\top \mathbf{W}_q^\top \mathbf{W}_k \mathbf{e}_n)(\mathbf{e}_m^\top \mathbf{W}_q^\top \mathbf{W}_k \mathbf{e}_p)^\top] \\
&= \mathbb{E}[\operatorname{Tr}(\mathbf{e}_m^\top \mathbf{W}_q^\top \mathbf{W}_k \mathbf{e}_n \mathbf{e}_p^\top \mathbf{W}_k^\top \mathbf{W}_q \mathbf{e}_m)] \\
&= \mathbb{E}[\operatorname{Tr}(\mathbf{e}_m \mathbf{e}_m^\top \mathbf{W}_q^\top \mathbf{W}_k \mathbf{e}_n \mathbf{e}_p^\top \mathbf{W}_k^\top \mathbf{W}_q)] \\
&= \operatorname{Tr}(\mathbb{E}[\mathbf{e}_m \mathbf{e}_m^\top]\mathbb{E}[\mathbf{W}_q^\top \mathbf{W}_k \mathbf{e}_n \mathbf{e}_p^\top \mathbf{W}_k^\top \mathbf{W}_q]) \\
&= \mathbb{E}[\operatorname{Tr}(\mathbf{e}_n \mathbf{e}_p^\top \mathbf{W}_k^\top \mathbf{W}_q \mathbf{W}_q^\top \mathbf{W}_k)] \\
&= \operatorname{Tr}(\mathbb{E}[\mathbf{e}_n \mathbf{e}_p^\top]\mathbb{E}[\mathbf{W}_k^\top \mathbf{W}_q \mathbf{W}_q^\top \mathbf{W}_k]) \\
&= (\mathbf{1}_{n=p})\operatorname{Tr}(\mathbb{E}[\mathbf{W}_q \mathbf{W}_q^\top]\mathbb{E}[\mathbf{W}_k \mathbf{W}_k^\top]) \\
&= (\mathbf{1}_{n=p})\operatorname{Tr}\left((\frac{d}{H}\sigma^2 \cdot \mathbf{I})(\frac{d}{H}\sigma^2 \cdot \mathbf{I})\right) \\
&= (\mathbf{1}_{n=p})\frac{d^3\sigma^4}{H^2}
\end{aligned}
$$

而由于缩放因子的存在，我们可以重写方差为：

$$
\mathbb{V}\left[\frac{l_{mn}}{\sqrt{d/H}}\right] = \frac{\mathbb{V}[l_{mn}]}{(\sqrt{d/H})^2} = \frac{\frac{d^3\sigma^4}{H^2}}{\frac{d}{H}} = \frac{d^2\sigma^4}{H}
$$

由于初始化的方差 $\sigma^2$ 极小，这意味着所有输入到 Softmax 的得分（Logits）几乎是没有波动的，大家都紧紧挤在一起（接近于 0）。这导致：

$$
a_{mn} = \frac{\exp(l_{mn})}{\sum_{i=1}^m \exp(l_{mi})} \approx  \frac{1}{m}
$$

因此注意力的计算就近似成了一个求平均的操作：

$$
y_m \approx W_o \left( \frac{1}{m} \sum_{i=1}^m v_i \right)
$$
这里的 $v_i$ 是拼接后长度为 $d$ 的全量 Value 向量，通过类似式 $(2)$ 的推导，可以得到这个输出的方差包含了位置信息 $m$ ，这也是NoPE隐含位置信息的由来

尽管上面的推导中还有许多不严谨的地方，例如需要满足很强的分布假设，但大致给了我们NoPE为什么可以隐含位置信息的理由：各个 $y_m$ 的直观区别就是求平均的 $v_i$ 的个数，而不同数量的平均导致的最直接的变化量就是方差


### 5.小结

上面部分我们介绍了NoPE，尽管不人为地增加位置编码，"Causal LLM + NoPE"模型仍然可以学习或者说感知到输入的位置信息，那为什么我们还是需要位置编码呢？

一、NoPE实现的是类似于乘性的绝对位置编码，并且它只是将位置信息压缩到单个标量中，所以这是一种非常弱的位置编码；

二、单个标量能表示的信息有限，当输入长度增加时，位置编码会越来越紧凑以至于难以区分。例如当 $n$ 足够大时，$\sqrt{n}$ 与 $\sqrt{n+1}$ 难以区分。

三、主流的观点认为相对位置编码更适合自然语言，既然NoPE实现的是绝对位置编码，所以效率上自然不如再给模型额外补充上相对位置编码。

四、NoPE既没有给模型添加诸如远程衰减之类的先验，看上去也没有赋予模型学习到这种先验的能力，当输入长度足够大可能就会出现注意力不集中的问题。
