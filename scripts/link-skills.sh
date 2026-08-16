#!/usr/bin/env bash
# Link each mad-*/ skill folder into a chosen target directory (one symlink per
# skill). Idempotent: re-running replaces existing symlinks to point at the
# current clone. Safe to run from any Mad-Skills checkout, and useful when
# adding additional skill repositories side-by-side.
#
# Run from the Mad-Skills clone root (or pass an absolute path to this script).
# Real files/directories at the target name are left untouched (conflict; exit 1);
# there is no --force — move or remove the conflicting path, then re-run.
#
# Usage:
#   ./scripts/link-skills.sh --target ~/.warp/skills
#   ./scripts/link-skills.sh --target ~/.agents/skills --dry-run
#   ./scripts/link-skills.sh --target ~/.warp/skills --source /path/to/Other-Skills
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

TARGET=""
SOURCE="$ROOT"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: link-skills.sh --target DIR [--source DIR] [--dry-run]

--target DIR   Required. Where to place per-skill symlinks (e.g.
               ~/.warp/skills or ~/.agents/skills). Created if missing.
--source DIR   Directory containing mad-*/SKILL.md children. Defaults to the
               root of this repository; use it to link a different checkout or
               an additional skills repo (only folders named mad-* are linked).
--dry-run      Print what would be linked without writing anything.

The script links each mad-* skill folder individually so each SKILL.md sits at
<target>/<skill-name>/SKILL.md. Existing symlinks at the same name are replaced
(see ln -sfn); real directories or files at the target are left untouched and
reported as conflicts.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="${2-}"
      shift 2
      ;;
    --source)
      SOURCE="${2-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  printf 'error: --target DIR is required\n' >&2
  usage >&2
  exit 2
fi

# Expand ~ and relative paths.
if [[ "$TARGET" == ~* ]]; then
  TARGET="${TARGET/#\~/$HOME}"
fi
if [[ "$SOURCE" == ~* ]]; then
  SOURCE="${SOURCE/#\~/$HOME}"
fi
SOURCE="$(cd -P "$SOURCE" 2>/dev/null && pwd || printf '%s' "$SOURCE")"

if [[ ! -d "$SOURCE" ]]; then
  printf 'error: source directory does not exist: %s\n' "$SOURCE" >&2
  exit 2
fi

skills=()
while IFS= read -r skill_md; do
  dir="$(dirname "$skill_md")"
  name="$(basename "$dir")"
  # Only mad-* skill folders (matches INSTALL.md / README link guidance).
  case "$name" in
    mad-*) skills+=("$dir") ;;
  esac
done < <(find "$SOURCE" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | sort)

if [[ ${#skills[@]} -eq 0 ]]; then
  printf 'error: no mad-*/SKILL.md skill folders found under %s\n' "$SOURCE" >&2
  exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf 'mode=dry-run\n'
else
  mkdir -p "$TARGET"
fi

linked=0
conflicts=0
for dir in "${skills[@]}"; do
  name="$(basename "$dir")"
  link_path="$TARGET/$name"

  if [[ -e "$link_path" || -L "$link_path" ]]; then
    # Only replace symlinks; leave real files/dirs alone.
    if [[ -L "$link_path" ]]; then
      current="$(readlink "$link_path")"
      # readlink returns the literal target; normalise relative to $TARGET.
      if [[ "$current" != /* ]]; then
        current="$(cd -P "$TARGET" && cd -P "$(dirname "$current")" && pwd)/$(basename "$current")"
      fi
      if [[ "$current" == "$dir" ]]; then
        printf 'skip %s -> %s (already linked)\n' "$name" "$dir"
        continue
      fi
      if [[ "$DRY_RUN" -eq 0 ]]; then
        ln -sfn "$dir" "$link_path"
      fi
      printf 'replace %s -> %s (was: %s)\n' "$name" "$dir" "$current"
      linked=$((linked + 1))
      continue
    fi
    printf 'conflict %s: target exists and is not a symlink: %s\n' "$name" "$link_path" >&2
    conflicts=$((conflicts + 1))
    continue
  fi

  if [[ "$DRY_RUN" -eq 0 ]]; then
    ln -sfn "$dir" "$link_path"
  fi
  printf 'link %s -> %s\n' "$name" "$dir"
  linked=$((linked + 1))
done

printf 'target=%s\n' "$TARGET"
printf 'source=%s\n' "$SOURCE"
printf 'linked=%s\n' "$linked"
printf 'conflicts=%s\n' "$conflicts"
printf 'total_skills=%s\n' "${#skills[@]}"

if [[ "$conflicts" -gt 0 ]]; then
  exit 1
fi
