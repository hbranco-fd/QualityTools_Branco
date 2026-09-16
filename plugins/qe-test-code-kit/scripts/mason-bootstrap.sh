#!/usr/bin/env bash
# Mason knowledge-pack bootstrap (global install variant).
# Scaffolds the PER-REPO knowledge folder from _templates/ so the pastas + skeleton files
# exist the first time Mason runs in a repo. Idempotent; NEVER overwrites a FILLED pack.
# Safe to run by hand or from a SessionStart hook. It only scaffolds — the Mason agent then
# analyzes the repo, fills the skeletons, asks the human to confirm, and sets status: FILLED.
#
# NOTE: this script is installed globally (~/.claude/agents/QA/), so it is invoked from many
# different repos. Templates are read from THIS script's own directory (global, shared), but
# the generated knowledge pack is written into the CURRENT REPO's .claude/agents/QA/ (per-repo,
# matching what the Mason agent itself expects at the relative path
# .claude/agents/QA/cucumber-reference/).
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tpl="$script_dir/cucumber-reference/_templates"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
repo_name="$(basename "$repo_root")"

pack="$repo_root/.claude/agents/QA/cucumber-reference"
meta="$pack/.mason-meta"

# Already FILLED for this repo? Do nothing.
if [ -f "$meta" ] && grep -q '^status: FILLED$' "$meta" && grep -q "^repo: ${repo_name}$" "$meta"; then
  echo "Mason: knowledge pack already FILLED for '${repo_name}' — nothing to do."
  exit 0
fi

mkdir -p "$pack"

# Seed each knowledge file from its template if it does not exist yet.
seeded=0
for name in placeholder-and-fixtures steps-and-scenarios domain-and-framework; do
  if [ ! -f "$pack/$name.md" ] && [ -f "$tpl/$name.template.md" ]; then
    cp "$tpl/$name.template.md" "$pack/$name.md"
    echo "Mason: seeded $name.md from template"
    seeded=1
  fi
done

# Write meta as SCAFFOLDED unless a FILLED one already exists for this repo.
if [ ! -f "$meta" ] || ! grep -q '^status: FILLED$' "$meta" || ! grep -q "^repo: ${repo_name}$" "$meta"; then
  {
    echo "repo: ${repo_name}"
    echo "generated: $(date +%F)"
    echo "framework: <!-- FILL: detected by Mason -->"
    echo "delimiter: <!-- FILL: detected by Mason -->"
    echo "status: SCAFFOLDED"
  } > "$meta"
  echo "Mason: wrote ${meta#$repo_root/} (SCAFFOLDED)"
fi

[ "$seeded" = 0 ] && echo "Mason: skeleton files already present."
cat <<EOF

Next step: invoke the Mason agent (subagent_type: mason).
It will analyze '${repo_name}', fill the scaffolded knowledge files, ASK you to confirm any
ambiguous conventions (framework, delimiter, naming, how to run), then set status: FILLED.
EOF
