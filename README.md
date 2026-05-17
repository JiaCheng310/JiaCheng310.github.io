# Jiacheng's blog

这是一个基于 Hugo 架构的个人博客项目，视觉风格参考了 PaperMod。

## 目录结构

```text
.
├── archetypes/
├── assets/
├── content/
│   ├── about.md
│   ├── search.md
│   └── posts/
├── layouts/
├── static/
├── hugo.yaml
├── OBSIDIAN.md
└── obsidian/
```

## 写作方式

推荐直接用 Obsidian 打开项目根目录，然后在 `content/posts/` 下写文章。

新文章最简单的结构是：

```text
content/posts/my-new-post/index.md
content/posts/my-new-post/cover.png
```

文章模板见：

- [OBSIDIAN.md](./OBSIDIAN.md)
- [obsidian/blog-post-template.md](位置编码（一）：Sinusoidal.md)

## 发布流程

写完内容后执行：

```bash
git add .
git commit -m "发布新文章"
git push
```

推送到 `main` 后，GitHub Actions 会自动构建并发布到 GitHub Pages。

## 本地预览

本地预览需要安装 Hugo，然后运行：

```bash
hugo server
```

如果你还没安装 Hugo，也可以先继续写作，等需要本地预览时再安装。
