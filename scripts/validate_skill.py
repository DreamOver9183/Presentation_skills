#!/usr/bin/env python3
"""Validate the presentation-skills skill and plugin bundle structure."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REQUIRED_BANNER = "正在使用Presentation_skills製作簡報"
EXPECTED_REFS = [
    "01-common-mistakes.md",
    "02-aesthetics.md",
    "03-information-backbone.md",
    "04-visualization.md",
    "05-logic-pyramid-scqa.md",
    "06-pitch-and-delivery.md",
    "07-worked-examples.md",
    "sources.md",
]


def parse_frontmatter(text: str) -> dict[str, str]:
    m = re.match(r"^---\r?\n(.*?)\r?\n---\r?\n", text, re.DOTALL)
    if not m:
        raise ValueError("Missing YAML frontmatter block (--- ... ---)")
    block = m.group(1)
    result: dict[str, str] = {}
    lines = block.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        kv = re.match(r"^([a-zA-Z0-9_-]+):\s*(.*)$", line)
        if kv:
            key, val = kv.group(1), kv.group(2).strip()
            if val in (">-", ">", "|", "|-"):
                folded: list[str] = []
                i += 1
                while i < len(lines) and (lines[i].startswith("  ") or not lines[i].strip()):
                    folded.append(lines[i].strip())
                    i += 1
                result[key] = " ".join(x for x in folded if x)
                continue
            result[key] = val.strip("\"'")
        i += 1
    return result


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    plugin_dir = root / "presentation-skills"
    skill_dir = (
        Path(sys.argv[1]).resolve()
        if len(sys.argv) > 1
        else plugin_dir / "skills" / "presentation-skills"
    )
    errors: list[str] = []

    # 1. Check plugin.json and rules/AGENTS.md
    plugin_json = plugin_dir / "plugin.json"
    if not plugin_json.is_file():
        errors.append(f"Missing plugin manifest: {plugin_json}")
    else:
        data = json.loads(plugin_json.read_text(encoding="utf-8"))
        if data.get("name") != "presentation-skills":
            errors.append(f"plugin.json name mismatch: {data.get('name')}")
        print(f"[OK] plugin.json: name={data.get('name')}, displayName={data.get('displayName')}")

    rule_md = plugin_dir / "rules" / "AGENTS.md"
    if not rule_md.is_file():
        errors.append(f"Missing plugin rule file: {rule_md}")
    else:
        rtext = rule_md.read_text(encoding="utf-8")
        if REQUIRED_BANNER not in rtext:
            errors.append("rules/AGENTS.md does not contain required banner string")
        print(f"[OK] rules/AGENTS.md ({len(rtext.encode('utf-8'))} bytes)")

    # 2. Check SKILL.md
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.is_file():
        errors.append(f"Missing SKILL.md at {skill_md}")
        for e in errors:
            print(f"[ERROR] {e}")
        return 1

    stext = skill_md.read_text(encoding="utf-8")
    slines = stext.splitlines()
    try:
        fm = parse_frontmatter(stext)
    except ValueError as exc:
        errors.append(str(exc))
        fm = {}

    name = fm.get("name", "")
    desc = fm.get("description", "")
    if not re.match(r"^[a-z0-9-]+$", name):
        errors.append(f"Invalid skill name '{name}' (must match ^[a-z0-9-]+$)")
    if not desc or len(desc) > 1024:
        errors.append(f"Invalid description length: {len(desc)} (must be 1..1024)")
    if REQUIRED_BANNER not in stext:
        errors.append(f"SKILL.md missing required banner: {REQUIRED_BANNER}")
    if len(slines) > 250:
        errors.append(f"SKILL.md too long: {len(slines)} lines (target <= 250)")

    print(
        f"[OK] SKILL.md: name={name}, desc_len={len(desc)}, "
        f"lines={len(slines)}, bytes={len(stext.encode('utf-8'))}"
    )

    # 3. Check relative links inside SKILL.md
    for m in re.finditer(r"\]\((\./references/[^)]+)\)", stext):
        rel = m.group(1)
        target = (skill_dir / rel).resolve()
        if not target.is_file():
            errors.append(f"Broken reference link in SKILL.md: {rel}")

    # 4. Check all 8 expected reference files and ensure no CJK compatibility radicals remain
    ref_dir = skill_dir / "references"
    compat_re = re.compile(r"[\u2F00-\u2FDF\uF900-\uFAFF]")
    for fname in EXPECTED_REFS:
        fpath = ref_dir / fname
        if not fpath.is_file():
            errors.append(f"Missing reference file: {fpath}")
            continue
        content = fpath.read_text(encoding="utf-8")
        size_b = len(content.encode("utf-8"))
        if size_b < 1500:
            errors.append(f"Reference file suspiciously small ({size_b} B): {fname}")
        bad_chars = compat_re.findall(content)
        if bad_chars:
            errors.append(f"Reference {fname} contains CJK compatibility chars: {set(bad_chars)}")
        print(f"[OK] references/{fname} ({size_b} bytes, {len(content.splitlines())} lines)")

    if errors:
        print("\nValidation FAILED:")
        for e in errors:
            print(f"  - {e}")
        return 1

    print("\nAll checks PASSED!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
