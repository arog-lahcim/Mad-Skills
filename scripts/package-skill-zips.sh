#!/usr/bin/env bash
# Package each skill directory into dist/<name>.zip plus dist/mad-skills-all.zip.
# Invoked by semantic-release prepareCmd. Safe to run locally for verification.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"

rm -rf "$DIST"
mkdir -p "$DIST"

skills=()
while IFS= read -r skill_md; do
  dir="$(dirname "$skill_md")"
  name="$(basename "$dir")"
  skills+=("$name")
done < <(find "$ROOT" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | sort)

if [[ ${#skills[@]} -eq 0 ]]; then
  printf 'error: no skill directories with SKILL.md found under %s\n' "$ROOT" >&2
  exit 1
fi

cd "$ROOT"
for name in "${skills[@]}"; do
  zip -r -q "$DIST/${name}.zip" "$name" -x "*.DS_Store" -x "*/.DS_Store"
  printf 'wrote %s\n' "$DIST/${name}.zip"
done

# Bundle all skill folders (not nested zips) for one-shot download/unpack.
zip -r -q "$DIST/mad-skills-all.zip" "${skills[@]}" -x "*.DS_Store" -x "*/.DS_Store"
printf 'wrote %s\n' "$DIST/mad-skills-all.zip"
printf 'skill_count=%s\n' "${#skills[@]}"
