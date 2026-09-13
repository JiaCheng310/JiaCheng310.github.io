# Jiacheng Zhang's personal website

This repository powers [jiacheng310.github.io](https://jiacheng310.github.io/).

The homepage is a lightweight static HTML/CSS site inspired by
[Seohong Park's website](https://seohong.me/) and
[Jon Barron's academic website template](https://github.com/jonbarron/jonbarron.github.io).
Notes are authored separately with Quarto and published under `/notes/`.

## Local development

```bash
python3 -m http.server --directory site 8000
```

The active homepage lives in `site/`. Its profile image is
`site/images/profile.jpg`.

## Production build

```bash
quarto render quarto-notes
```

GitHub Actions copies the static homepage, renders the Quarto Notes, and
deploys the combined result to GitHub Pages after changes are pushed to
`main`.
