---
title: 'Markdown Style Guide'
description: 'A reference post to verify prose, lists, code blocks, tables, and blockquotes.'
pubDate: '2026-03-14'
tags:
  - Markdown
  - Reference
---

This post exists mostly to test how common Markdown elements render inside the blog.

## Lists

- unordered lists should align cleanly
- spacing should stay consistent
- nested structure should remain readable

1. ordered lists need the same discipline
2. numbers should not fight the text

## Quote

> A good default style should make ordinary writing look finished.

## Code

```ts
export function clamp(value: number, min: number, max: number) {
	return Math.min(max, Math.max(min, value));
}
```

## Table

| Element | Purpose |
| --- | --- |
| Heading | establish hierarchy |
| List | compress related points |
| Code | show exact syntax |
