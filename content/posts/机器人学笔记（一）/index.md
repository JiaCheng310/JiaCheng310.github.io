---
title: 机器人学笔记（一）：优化问题求解
description: 几种常见的优化算法
date: 2026-06-04
slug:
tags:
  - 机器人学
  - 优化问题
draft: false
math: true
---
在传统机器人控制中，我们可以把任务看作最小化代价函数：$$
\min_x ​c(x)
$$ 其中 $x$ 是机器人的相关参数，例如关节角等。举例而言，假如我们想要机械臂去抓取物品，一个简化的代价函数是：
$$
c(x) = \frac{1}{2}\|f^{\text{ee}}(x) - \mu\|^2
$$
其中 $x$ 是关节角，$f^{\mathrm{ee}}(x)$ 是由关节角算出来的末端位置，$\mu$ 是目标位置。这个代价越小，说明机械臂末端越接近目标，从而离我们的任务实现越近。

本文会先介绍几种优化算法，后续我们将用这些算法去解决机器人学问题。

## Gradient Descent

梯度下降是一种最常见的优化算法，先考虑如下的单变量情况：

我们从一个随机的猜测 $x_1$ 开始优化，在第 $k$ 步 $x_k$ 时，我们想要更新它为 $x_k + \Delta x_k$ ，对代价函数进行一阶泰勒展开：

$$
 c(x_k+\Delta x_k) \approx c(x_k) + c^\prime(x_k)\Delta x_k
$$
![[Pasted image 20260604155608.png|250]]

如图所示，此处的 $c^\prime(x_k)$ 为正数，沿着这个方向的 $c(x)$ 有增长的趋势。但我们的目标是让其最小化，因此 $x_k$ 走的方向应当和 $c^\prime(x)$ 的方向相反，那么 $\Delta x_k$ 的一个选择是：
$$
\Delta x_k = -\alpha c^\prime(x_k)
$$
其中 $\alpha$ 是学习率（步长）恒正。

多维 $x$ 的情况，只需要把导数换成梯度即可：

$$
\begin{aligned}
&c(x_k+\Delta x_k)\approx c(x_k)+\Delta x_k^\top g(x_k)\\~\\
&g(x_k)=\left.\frac{\partial c}{\partial x}\right|_{x_k}\\~\\
&x_{k+1} = x_k - \alpha g(x_k)
\end{aligned}
$$


## Newton's Method

牛顿法引入了代价函数的二阶信息来优化，同样以一维情况为例，在 $x_k$ 处进行二阶的泰勒展开：

$$
c(x_k+\Delta x_k) \approx c(x_k) + c^\prime(x_k)\Delta x_k + \frac{1}{2}c^{\prime\prime}(x_k)\Delta x^2_k
$$
![[Pasted image 20260604163902.png | 250]]


观测右式，我们利用了二次函数在局部近似代价函数 $c(x)$ ，如果 $c^{\prime\prime}(x_k)>0$ ，则这个局部二次函数是下凸的，有极小值。 一个直观的想法是：局部二次函数的极小值可以作为原函数极小值的猜测。

而由于局部二次函数的极小值有解析解，我们可以直接对 $\Delta x_k$ 求导令其为 $0$：

$$
c^\prime(x_k) + c^{\prime\prime}(x_k)\Delta x_k = 0
$$

从而得到下一步更新：
$$
x_{k+1} = x_{k}-\frac{c^\prime(x_k)}{c^{\prime\prime}(x_k)}
$$

一维情况下，这也可以看作是每步学习率不同的梯度下降。

然而，假如 $c^{\prime\prime}(x_k) \leq 0$  ，我们该怎么更新呢：

![[Pasted image 20260604195838.png|250]]

此时我们没法再直接用上述的牛顿法更新，以图中 $c^{\prime\prime}(x_k)<0$ 为例，局部二次函数的开口向下，还用上述的方法更新只会让代价函数更大，因此实际操作中，会将 $c^{\prime\prime}(x_k)$ 替换成一个很小的正数，从而保证我们的更新是可信的。


**另一种理解**牛顿法的方式是从零点问题出发，假设我们想要求解 $f(x) =0$ ，即寻找函数零点。在第$k$ 步 $x_k$ 时，作切线局部近似：
$$
y = f(x_k) + f^\prime(x_k)(x-x_k)
$$
该切线与坐标轴的交点即零点为：
$$
x_{k+1} = x_k - \frac{f(x_k)}{f^\prime(x_k)}
$$
将其作为下一步的猜测，继续更新。
![[Pasted image 20260604165427.png|300]]

那么我们最小化代价函数 $c(x)$ 的问题可以转化为求解 $c^\prime(x) =0$ 的零点问题，因此更新使用：
$$
x_{k+1} = x_{k} - \frac{c^{\prime}(x_k)}{c^{\prime\prime}(x_k)}
$$
对于**多维的牛顿法**，叙述如下：
$$
c(x_k+\Delta x_k) \approx c(x_k) + \Delta x_k^\top g(x_k) + \frac{1}{2}\Delta x_k^\top H(x_k) \Delta x_k
$$

其中，$g(x_k) = \left.\frac{\partial c}{\partial x}\right|_{x_k}$ ，$H(x_k) = \left.\frac{\partial^2 c}{\partial x^2}\right|_{x_k}$ 。和一维的情况类似，我们希望 $H(x_k)$ 是正定的，从而局部二次函数下凸，具有良好的优化性质：

$$
g(x_k) + H(x_k)\Delta x_k =0 
$$
因此解得：
$$
x_{k+1} = x_{k} -H^{-1}(x_k)g(x_k)
$$
![[Pasted image 20260604195401.png|500]]

实际操作中需要在每一步更新检查 Hessian 矩阵是否正定，由于矩阵正定性不那么容易满足，往往会通过正则化来保证：取一个较大的正数 $\lambda$ ，令 $H_{new} = H +\lambda I$ 正定，再利用上述公式更新：

$$
x_{k+1} = x_{k} -(H+\lambda I)^{-1}g(x_k)
$$

## Gauss-Newton Algorithm

**Gauss-Newton**算法可以看作是牛顿法的一种特殊情况，它擅长处理代价函数 

$$
c(x) =\|f(x)\|^2 = f(x)^\top f(x) = \sum_{i=1}^N f^2_i(x)
$$

的情况，即最小化 $c(x)$ 可以被看作最小化某个函数平方。下面我们先推导这种情况的梯度和Hessian 矩阵：
$$
\frac{\partial c}{\partial x_j} = \sum_{i=1}^N\frac{\partial}{\partial x_j}f_i^2(x)= 2\sum_{i=1}^Nf_i(x)\frac{\partial}{\partial x_j}f_i(x)
$$
定义Jacobian矩阵：
$$
J(x)=\frac{\partial f}{\partial x} = \begin{bmatrix}
\frac{\partial f_1}{\partial x_1} & \cdots & \frac{\partial f_1}{\partial x_n} \\
\vdots & \ddots & \vdots \\
\frac{\partial f_N}{\partial x_1} & \cdots & \frac{\partial f_N}{\partial x_n}
\end{bmatrix}
$$
则梯度可以写成：
$$
g(x) = 2J^\top(x)f(x)
$$
进一步考虑 Hessian矩阵元素：
$$
\frac{\partial^2 c}{\partial x_k\partial x_j} = 2\sum_{i=1}^N(\frac{\partial f_i}{\partial x_k}\frac{\partial f_i}{\partial x_j} +f_i\frac{\partial^2 f_i}{\partial x_k\partial x_j})
$$
则：

$$
H(x) = 2J^\top(x)J(x) + 2\sum_{i=1}^Nf_i(x)H_i(x)
$$
其中 $H_i(x)$ 是每个函数 $f_i(x)$ 的 Hessian 矩阵。Gauss-Newton与牛顿法的不同就在于，它忽略了第二项的影响，直接近似 Hessian 矩阵为：
$$
H(x) \approx 2J^\top(x)J(x)
$$
忽略后一项的原因主要有两点：
- 在最优点 $x^*$ 附近，$f_i(x)$ 较小
- 如果 $f_i(x)$ 近似线性，那么 $H_i(x)$ 较小

这也带来了两点好处：
- 计算更简便，不用考虑复杂的二阶导
- $J^\top(x)J(x)$ 是半正定的，比 $H(x)$ 更稳定

根据上述的牛顿法，更新可以写成：

$$
\begin{aligned}
x_{k+1} &= x_{k} - H^{-1}(x_k)g(x_k)\\
&=x_k - (2J^\top(x_k)J(x_k))^{-1}2J^\top(x_k)f(x_k)\\
& = x_k -(J^\top(x_k)J(x_k))^{-1}J^\top(x_k)f(x_k)
\end{aligned}
$$

## Least square

考虑更特殊的情形，代价函数 $c(x)$ 可以被表示为线性误差的平方：
$$
c(x) = \|Ax-b\|^2 = (Ax-b)^\top(Ax-b)
$$
此时求导：
$$
\frac{\partial c}{\partial x} = 2A^\top Ax - 2A^\top b= 2A^\top(Ax-b) = 0
$$
从而可以求得：
$$
x = (A^\top A)^{-1}A^\top b = A^\dagger b
$$




