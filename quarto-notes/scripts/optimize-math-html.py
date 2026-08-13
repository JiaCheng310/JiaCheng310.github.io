#!/usr/bin/env python3
"""Make Quarto's MathJax output faster while preserving formula support."""

from __future__ import annotations

import argparse
from pathlib import Path
import re


PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = PROJECT_ROOT / "_site"
MATHJAX_URL = "https://cdn.jsdelivr.net/npm/mathjax@4.1.3/tex-chtml.js"
LEGACY_POLYFILL_URL = (
    "https://cdnjs.cloudflare.com/polyfill/v3/polyfill.min.js?features=es6"
)
PRECONNECT_MARKER = 'rel="preconnect" href="https://cdn.jsdelivr.net"'
PRECONNECT_TAGS = (
    '<link rel="preconnect" href="https://cdn.jsdelivr.net" crossorigin>\n'
    '<link rel="dns-prefetch" href="//cdn.jsdelivr.net">\n'
)
PRECONNECT_TAGS_RE = re.compile(
    r'^[ \t]*<link\s+rel=["\'](?:preconnect|dns-prefetch)["\']\s+'
    r'href=["\'](?:https:)?//cdn\.jsdelivr\.net["\'](?:\s+crossorigin)?\s*>[ \t]*\r?\n?',
    re.MULTILINE,
)

POLYFILL_TAG_RE = re.compile(
    r"^[ \t]*<script\b(?=[^>]*\bsrc=[\"']"
    + re.escape(LEGACY_POLYFILL_URL)
    + r"[\"'])[^>]*>\s*</script>[ \t]*\r?\n?",
    re.MULTILINE,
)
MATHJAX_TAG_RE = re.compile(
    r"<script\b(?=[^>]*\bsrc=[\"']"
    + re.escape(MATHJAX_URL)
    + r"[\"'])[^>]*>\s*</script>"
)
ANY_MATHJAX_URL_RE = re.compile(
    r"https://cdn\.jsdelivr\.net/npm/mathjax@[^\"'\s<]+"
)
MATH_ELEMENT_RE = re.compile(r'class=["\'][^"\']*\bmath\b[^"\']*["\']')


def optimized_html(html: str, path: Path) -> str:
    """Return optimized HTML for one rendered page."""
    if MATHJAX_URL not in html:
        return html

    html = POLYFILL_TAG_RE.sub("", html)

    # Quarto listings can propagate the MathJax dependency onto a page that
    # contains no formulas. Remove it there; if formulas are added later, the
    # generated math elements make this branch stop applying automatically.
    if MATH_ELEMENT_RE.search(html) is None:
        html = MATHJAX_TAG_RE.sub("", html)
        return PRECONNECT_TAGS_RE.sub("", html)

    if PRECONNECT_MARKER not in html:
        script = MATHJAX_TAG_RE.search(html)
        if script is None:
            raise RuntimeError(f"MathJax script tag not found: {path}")
        html = html[: script.start()] + PRECONNECT_TAGS + html[script.start() :]

    return html


def process_site(check_only: bool) -> None:
    """Optimize all rendered pages and enforce the expected resource policy."""
    if not OUTPUT_DIR.is_dir():
        raise RuntimeError(f"Rendered site not found: {OUTPUT_DIR}")

    html_paths = sorted(OUTPUT_DIR.rglob("*.html"))
    if not html_paths:
        raise RuntimeError(f"No rendered HTML files found in {OUTPUT_DIR}")

    math_pages = 0
    for path in html_paths:
        original = path.read_text(encoding="utf-8")
        optimized = optimized_html(original, path)

        if check_only and optimized != original:
            raise RuntimeError(f"Rendered math HTML is not optimized: {path}")
        if not check_only and optimized != original:
            path.write_text(optimized, encoding="utf-8")

        if LEGACY_POLYFILL_URL in optimized:
            raise RuntimeError(f"Legacy polyfill remains: {path}")

        mathjax_urls = set(ANY_MATHJAX_URL_RE.findall(optimized))
        unexpected_urls = mathjax_urls - {MATHJAX_URL}
        if unexpected_urls:
            urls = ", ".join(sorted(unexpected_urls))
            raise RuntimeError(f"Unexpected MathJax URL in {path}: {urls}")

        if MATHJAX_URL in optimized:
            math_pages += 1
            if optimized.count(PRECONNECT_MARKER) != 1:
                raise RuntimeError(f"Expected one jsDelivr preconnect: {path}")

    if check_only:
        if math_pages == 0:
            raise RuntimeError("No MathJax pages found after rendering")

        notes_index_path = OUTPUT_DIR / "index.html"
        if not notes_index_path.is_file():
            raise RuntimeError(f"Notes homepage not found: {notes_index_path}")
        notes_index = notes_index_path.read_text(encoding="utf-8")
        if ANY_MATHJAX_URL_RE.search(notes_index):
            raise RuntimeError("The formula-free Notes homepage still loads MathJax")

    action = "Verified" if check_only else "Optimized"
    print(f"{action} {math_pages} MathJax pages across {len(html_paths)} HTML files.")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify rendered HTML without modifying it",
    )
    args = parser.parse_args()
    process_site(check_only=args.check)


if __name__ == "__main__":
    main()
