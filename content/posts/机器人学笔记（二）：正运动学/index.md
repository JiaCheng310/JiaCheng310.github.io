---
title: 机器人学笔记（二）：正运动学（Forward Kinematics）
description: 平面机械臂的正运动学
date: 2026-06-04
slug:
tags:
  - 机器人学
  - 正运动学
draft: false
math: true
---
## Forward Kinematics

**Forward Kinematics(FK)** 是一种已知机器人每个关节状态，求解其末端位置和姿态的方法。本文以最简单的2D RR机械臂为例：

![[Pasted image 20260605133548.png|300]]

此例子中，我们已知两根杆的长度和关节角，想要求出末端的状态，注意我们不能仅仅用坐标系中的一个点来描述末端状态，同一个点可能有多个机械臂的状态对应，更一般的情况是三维机械臂，保持末端中心点不变情况下，可以有不同的朝向：

![[Pasted image 20260605134141.png|200]]

因此我们需要引入**姿态（Orientation）** 来描述机械臂的朝向，2D的情况我们可以先简单理解为位置+朝向角。

以上述的RR机械臂为例，转化为数学语言，我们已知机械臂的关节角 ：
$$
x = \begin{bmatrix}x_1\\x_2 \end{bmatrix}
$$
注意关节角的定义是指**当前关节相对于前一个关节的旋转角度**。

希望得到末端执行器的状态
$$
f^{\text{ee}}(x) =\begin{bmatrix}f_1^{\text{ee}}\\f_2^{\text{ee}}\\f_3^{\text{ee}}\end{bmatrix} =\begin{bmatrix}p_x\\p_y\\\phi \end{bmatrix}
$$
其中，$p_x$ 和 $p_y$ 是末端执行器的二维坐标，$\phi$ 是朝向角。在二维情况，这种描述可以唯一固定机械臂的末端状态。
![[Pasted image 20260605133548.png|300]]

显然我们有:
$$
\begin{aligned}
&f_1^{\text{ee}} = l_1\cos(x_1)+l_2\cos(x_1+x_2)\\
&f_2^{\text{ee}} = l_1\sin(x_1)+l_2\sin(x_1+x_2)\\
&f_3^{\text{ee}} = x_1+x_2
\end{aligned}
$$

一般地，对于2D多杆情况，假设机械臂有 $n$ 根杆，每根杆长和关节角可以被描述为：

$$
l = \begin{bmatrix} l_1\\l_2 \\ \vdots \\l_n\end{bmatrix},\qquad
x = \begin{bmatrix} x_1\\x_2 \\ \vdots \\x_n\end{bmatrix}
$$
则有：
$$
\begin{aligned}
&f_1^{\text{ee}} = l_1\cos(x_1)+l_2\cos(x_1+x_2) + l_3\cos(x_1+x_2+x_3)+\cdots = \sum_{i=1}^n l_i\cos(\sum_{j=1}^ix_j)\\
&f_2^{\text{ee}} = l_1\sin(x_1)+l_2\sin(x_1+x_2)+l_3\sin(x_1+x_2+x_3)+\cdots=\sum_{i=1}^n l_i\sin(\sum_{j=1}^ix_j)\\~\\
&f_3^{\text{ee}} = x_1+x_2+\cdots + x_n
\end{aligned}
$$
即：
$$
f^{\text{ee}}=\begin{bmatrix}l^\top\cos(Lx)\\l^\top\sin(Lx)\\1^\top x  \end{bmatrix}
$$
其中 $L\in \mathbb{R}^{n\times n}$ 是一个下三角全 $1$ 矩阵。

对于其中每根杆的末端姿态，我们只需要考虑它之前的杆即可：
$$
\hat{f}^{\text{ee}}=\begin{bmatrix}L\mathrm{diag}(l)\cos(Lx) &L\mathrm{diag}(l)\sin(Lx) & Lx\end{bmatrix}^\top
$$
此时第 $k$ 列表示第 $k$ 根杆的末端执行器状态。

可以使用 Matlab 绘图来体会正运动学的求解：

![[fk_3link.gif|400]]

```matlab

clear; clc; close all;

% 三根杆的长度
l1 = 0.3;
l2 = 0.5;
l3 = 0.8;   

T = 10;
dt = 0.03;
tList = 0:dt:T;

figure;
axis equal;
grid on;
xlim([-2 2]);
ylim([-2 2]);
xlabel("x");
ylabel("y");
hold on;

armLine = plot([0 0 0 0], [0 0 0 0], "-o", ...
    "LineWidth", 4, "MarkerSize", 8);
eeTrace = plot(nan, nan, "r-", "LineWidth", 1.5);

traceX = [];
traceY = [];

for t = tList
    % 三个关节角，随时间变化来模拟运动
    x1 = pi/4 * sin(1.0 * t);
    x2 = pi/3 * sin(1.7 * t);
    x3 = pi/6 * sin(0.8 * t);
    
    % 机械臂的基座位置，这里取原点
    start = [0; 0];
    
    % 杆1的末端
    p1 = [
        l1*cos(x1);
        l1*sin(x1)
    ];
    
    % 杆2的末端
    p2 = [
        l1*cos(x1) + l2*cos(x1+x2);
        l1*sin(x1) + l2*sin(x1+x2)
    ];
    
    % 杆3的末端
    p3 = [
        l1*cos(x1) + l2*cos(x1+x2) + l3*cos(x1+x2+x3);
        l1*sin(x1) + l2*sin(x1+x2) + l3*sin(x1+x2+x3)
    ];

    set(armLine, "XData", [start(1), p1(1), p2(1), p3(1)], ...
                 "YData", [start(2), p1(2), p2(2), p3(2)]);

    traceX(end+1) = p3(1);
    traceY(end+1) = p3(2);

    set(eeTrace, "XData", traceX, "YData", traceY);

    drawnow;
end
```
