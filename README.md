# Jiacheng Zhang's personal website

This repository powers [jiacheng310.github.io](https://jiacheng310.github.io/).

The homepage uses the MIT-licensed [PRISM](https://github.com/xyjoey/PRISM) academic website template. Notes are authored separately with Quarto and published under `/notes/`.

## Local development

The homepage requires Node.js 22 or newer.

```bash
npm ci
npm run dev
```

Personal details and page content live in `content/`. The profile image and favicon live in `public/`.

## Production build

```bash
npm run build
quarto render quarto-notes
```

GitHub Actions combines the exported PRISM site with the rendered Quarto Notes and deploys the result to GitHub Pages after changes are pushed to `main`.
