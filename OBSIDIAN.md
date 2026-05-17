# Obsidian 写作流程

这个博客很适合用 Obsidian 在本地写作，现在项目已经改成 Hugo 架构。

## 推荐打开方式

把整个项目根目录作为一个 Obsidian vault 打开：

`/Users/jiachengzhang/Documents/personal-blog`

## 推荐的文章结构

建议每篇文章都单独放一个文件夹，位置在：

`content/posts/`

例如：

`content/posts/my-new-post/index.md`

如果这篇文章有图片，就把图片也放在同一个文件夹里：

`content/posts/my-new-post/cover.png`
`content/posts/my-new-post/diagram.png`

然后在文章中用相对路径引用：

```md
![示意图](./diagram.png)
```

如果想设置文章封面图，在 frontmatter 里写：

```md
heroImage: './cover.png'
```

这样做最方便，因为：

- Obsidian 本地可以直接预览图片
- Hugo 构建时能正确识别
- 每篇文章和自己的素材放在一起，不容易乱

## Obsidian 建议设置

推荐：

- 发布文章时尽量不要使用 `[[双链]]`
- 使用标准 Markdown 链接
- 图片和链接尽量使用相对路径

推荐这样写：

```md
![图片](./photo.png)
```

现在也兼容这种 Obsidian 粘贴语法：

```md
![[photo.png]]
```

也支持带说明文字的形式：

```md
![[photo.png|图片说明]]
```

不过最稳妥的前提仍然是：图片文件和文章放在同一个文章文件夹里，或者路径能相对当前文章正确找到。

## 写作流程

1. 复制 `obsidian/blog-post-template.md` 作为新文章模板
2. 在 `content/posts/你的文章-slug/` 下新建文件夹
3. 把文章保存成 `index.md`
4. 在 Obsidian 里写正文
5. 如果有图片，就放在同一个文件夹里
6. 本地预览时运行 `hugo server`
7. 发布时执行 `git add . && git commit -m "new post" && git push`

## 数学公式

如果一篇文章需要 LaTeX 公式，在文章 frontmatter 里加上：

```md
math: true
```

然后就可以直接写：

```md
行内公式：$E = mc^2$

块级公式：

$$
\int_a^b f(x)\,dx
$$
```

## 示例

推荐目录结构：

`content/posts/why-i-like-obsidian/index.md`
`content/posts/why-i-like-obsidian/cover.png`
`content/posts/why-i-like-obsidian/screenshot.png`

`index.md` 内容示例：

```md
---
title: "Why I Like Obsidian"
description: "A lightweight writing workflow for local-first blogging."
date: "2026-05-16"
tags:
  - Writing
  - Obsidian
---

这篇文章是在 Obsidian 里写的。

## 一个优点

本地写作和预览都很轻。

![编辑器截图](./screenshot.png)
```
