#!/usr/bin/env bash
#
# Validate the quality-tools marketplace before committing.
#
#   ./scripts/validate.sh
#
# Two passes:
#
#   1. `claude plugin validate` on the marketplace and every kit. This is the
#      authoritative check — manifest schema, skill and agent frontmatter,
#      version agreement between marketplace.json and each plugin.json. It
#      reports problems as warnings and still exits 0; we treat any warning as
#      a failure, because this script is a gate.
#
#   2. Three gaps the official validator does not cover:
#        - a `source` pointing at a directory that does not exist
#        - a kit on disk that no marketplace entry publishes
#        - a skill or agent whose frontmatter `name` disagrees with its path
#
# Structure only. A green run says nothing about whether a skill triggers or
# does the right thing — for that, install the kit from a local clone and try
# to provoke it with the phrases in its description.
#
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

failed=0

# --- pass 1: the official validator ---------------------------------------
if command -v claude >/dev/null 2>&1; then
  targets=(".")
  for kit in plugins/*/; do
    [ -d "$kit" ] && targets+=("${kit%/}")
  done

  for target in "${targets[@]}"; do
    output=$(claude plugin validate "$target" 2>&1)
    status=$?
    # A clean run prints "✔ Validation passed" and nothing else of note.
    # Match on that rather than grepping for "warning"/"error", which would
    # also hit a skill legitimately named something like error-handling.
    if [ $status -ne 0 ] \
      || ! printf '%s' "$output" | grep -q '✔ Validation passed' \
      || printf '%s' "$output" | grep -q 'with warnings'; then
      printf '%s\n\n' "$output"
      failed=1
    fi
  done
else
  echo "  warn  'claude' is not on PATH — skipped official manifest validation"
  echo "        (schema and frontmatter checks did not run)"
  echo
fi

# --- pass 2: what the official validator misses ---------------------------
python3 - <<'PY' || failed=1
import json
import re
import sys
from pathlib import Path

ROOT = Path.cwd()
errors = []
warnings = []

marketplace_path = ROOT / ".claude-plugin" / "marketplace.json"
try:
    marketplace = json.loads(marketplace_path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as exc:
    print(f"  FAIL  .claude-plugin/marketplace.json: {exc}")
    sys.exit(1)

# Every published source must resolve to a real plugin directory.
published = set()
for index, entry in enumerate(marketplace.get("plugins", [])):
    label = entry.get("name") or f"plugins[{index}]"
    if entry.get("name"):
        published.add(entry["name"])

    source = entry.get("source")
    if not source:
        errors.append(f"marketplace.json → {label}: no 'source'")
        continue

    plugin_dir = (ROOT / source).resolve()
    if not plugin_dir.is_dir():
        errors.append(f"marketplace.json → {label}: source '{source}' does not exist")
    elif not (plugin_dir / ".claude-plugin" / "plugin.json").is_file():
        errors.append(f"marketplace.json → {label}: '{source}' has no .claude-plugin/plugin.json")

# Every kit on disk must be published, or it ships to nobody.
plugins_dir = ROOT / "plugins"
# Skip hidden directories — tooling drops things like .claude/ or .DS_Store
# beside the kits, and they are not kits.
kits = (
    sorted(p for p in plugins_dir.iterdir() if p.is_dir() and not p.name.startswith("."))
    if plugins_dir.is_dir()
    else []
)
if not kits:
    warnings.append("plugins/ contains no kits")

FM_NAME = re.compile(r"^name:\s*(.+?)\s*$", re.MULTILINE)


def frontmatter_name(path):
    """First `name:` in the frontmatter block, or None if there is no block."""
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    for line in lines[1:]:
        if line.strip() == "---":
            break
        match = FM_NAME.match(line)
        if match:
            return match.group(1).strip("\"'")
    return None


skills = agents = commands = 0

for kit in kits:
    if kit.name not in published:
        errors.append(f"plugins/{kit.name}: on disk but no marketplace entry publishes it")
    if not (kit / "README.md").is_file():
        warnings.append(f"plugins/{kit.name}: no README.md")

    for skill_dir in sorted((kit / "skills").glob("*")):
        if not skill_dir.is_dir() or skill_dir.name.startswith("."):
            continue
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.is_file():
            errors.append(f"plugins/{kit.name}/skills/{skill_dir.name}: no SKILL.md")
            continue
        skills += 1
        name = frontmatter_name(skill_md)
        if name and name != skill_dir.name:
            errors.append(
                f"{skill_md.relative_to(ROOT)}: frontmatter name '{name}' "
                f"does not match directory '{skill_dir.name}'"
            )

    for kind in ("agents", "commands"):
        for path in sorted((kit / kind).glob("*.md")):
            if kind == "agents":
                agents += 1
            else:
                commands += 1
            name = frontmatter_name(path)
            if name and name != path.stem:
                errors.append(
                    f"{path.relative_to(ROOT)}: frontmatter name '{name}' "
                    f"does not match filename '{path.stem}'"
                )

for message in warnings:
    print(f"  warn  {message}")
for message in errors:
    print(f"  FAIL  {message}")

if errors:
    print(f"\n{len(errors)} structural problem(s).")
    sys.exit(1)

print(
    f"Structure OK — {len(kits)} kit(s), {skills} skill(s), "
    f"{agents} agent(s), {commands} command(s)."
)
PY

if [ "$failed" -ne 0 ]; then
  echo
  echo "✗ Not ready to commit."
  exit 1
fi

echo "✔ Ready to commit."
