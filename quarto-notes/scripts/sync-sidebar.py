#!/usr/bin/env python3
"""Sync Quarto sidebar entries from folder names and note titles.

The script keeps the current high-level note parts, reads numbered child
folders such as "1.问题建模与优化" as chapter sections, and writes every page
entry as:

  - text: "<frontmatter title>"
    href: "<relative path>"

The chapter order is determined by the leading number in each folder name.
"""

from __future__ import annotations

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "_quarto.yml"
PARTS = [
    ("Part 1: 机器人学", "robotics"),
    ("Part 2: 深度学习", "deep-learning"),
    ("Part 3: 强化学习", "reinforcement-learning"),
    ("Part 4: 论文精读", "paper-reading"),
]


def read_title(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return path.stem

    parts = text.split("---", 2)
    if len(parts) < 3:
        return path.stem

    for line in parts[1].splitlines():
        match = re.match(r"^\s*title\s*:\s*(.+?)\s*$", line)
        if match:
            title = match.group(1).strip()
            return title.strip("\"'")

    return path.stem


def quote(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def page_entry(rel_path: str, indent: int) -> list[str]:
    title = read_title(ROOT / rel_path)
    spaces = " " * indent
    return [
        f"{spaces}- text: {quote(title)}",
        f"{spaces}  href: {quote(rel_path)}",
    ]


def qmd_files(directory: str) -> list[str]:
    base = ROOT / directory
    files = []
    for path in sorted(base.glob("*.qmd"), key=lambda p: p.name.lower()):
        if path.name.startswith("_"):
            continue
        files.append(path.relative_to(ROOT).as_posix())
    return files


def sort_key(path: Path) -> tuple[int, str]:
    match = re.match(r"^(\d+)[.．](.*)$", path.name)
    if match:
        return int(match.group(1)), match.group(2)

    return 10_000, path.name


def chapter_dirs(directory: str) -> list[Path]:
    base = ROOT / directory
    return sorted(
        [
            path
            for path in base.iterdir()
            if path.is_dir() and re.match(r"^\d+[.．].+", path.name)
        ],
        key=sort_key,
    )


def section_files(path: Path) -> list[str]:
    return [
        item.relative_to(ROOT).as_posix()
        for item in sorted(path.glob("*.qmd"), key=lambda p: p.name.lower())
        if not item.name.startswith("_") and item.name != "index.qmd"
    ]


def remaining_files(directory: str, used: set[str]) -> list[str]:
    return [
        path
        for path in qmd_files(directory)
        if path not in used and not path.endswith("/index.qmd")
    ]


def add_page(lines: list[str], rel_path: str, indent: int, used: set[str]) -> None:
    lines.extend(page_entry(rel_path, indent))
    used.add(rel_path)


def add_section(lines: list[str], title: str, files: list[str], indent: int, used: set[str]) -> None:
    if not files:
        return

    spaces = " " * indent
    lines.append(f"{spaces}- section: {quote(title)}")
    lines.append(f"{spaces}  contents:")
    for rel_path in files:
        add_page(lines, rel_path, indent + 4, used)


def build_sidebar_contents() -> list[str]:
    lines: list[str] = []
    used: set[str] = set()

    add_page(lines, "index.qmd", 6, used)

    for part_title, directory in PARTS:
        lines.append(f"      - section: {quote(part_title)}")
        lines.append("        contents:")

        index_path = f"{directory}/index.qmd"
        if (ROOT / index_path).exists():
            add_page(lines, index_path, 10, used)

        for chapter_dir in chapter_dirs(directory):
            add_section(lines, chapter_dir.name, section_files(chapter_dir), 10, used)

        add_section(lines, "未分类", remaining_files(directory, used), 10, used)

    return lines


def sync_config() -> None:
    lines = CONFIG.read_text(encoding="utf-8").splitlines()

    sidebar_index = None
    contents_index = None
    for index, line in enumerate(lines):
        if line == "  sidebar:":
            sidebar_index = index
        elif sidebar_index is not None and line == "    contents:":
            contents_index = index
            break

    if contents_index is None:
        raise RuntimeError("Could not find website.sidebar.contents in _quarto.yml")

    new_lines = lines[: contents_index + 1]
    new_lines.extend(build_sidebar_contents())
    CONFIG.write_text("\n".join(new_lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    sync_config()
