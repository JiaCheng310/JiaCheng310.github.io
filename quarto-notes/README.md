# Jiacheng's Notes

This directory contains the Quarto source for the `/notes/` subsite.

## Local render

Install Quarto first, then run from the repository root:

```bash
quarto render quarto-notes
```

The rendered static site is written to:

```text
quarto-notes/_site/
```

Copy it into Hugo's static directory when previewing the full site:

```bash
mkdir -p static/notes
cp -R quarto-notes/_site/. static/notes/
```

Then preview the full Hugo site:

```bash
hugo server -D --noBuildLock
```

Open:

```text
http://localhost:1313/notes/
```

## Deployment

GitHub Actions installs Quarto, renders this subsite into `quarto-notes/_site/`, copies it to `static/notes/`, then builds Hugo.
