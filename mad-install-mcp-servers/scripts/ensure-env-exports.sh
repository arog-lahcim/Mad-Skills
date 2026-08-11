#!/usr/bin/env bash
# Ensure empty export stubs for Mad Skills MCP env vars in a shell env file.
# Run by the agent (mad-install-mcp-servers). Does not write secret values.
#
# Hosts stay independent:
#   --host cursor  → CURSOR_* vars (Cursor ~/.cursor/mcp.json)
#   --host claude  → CLAUDE_* vars (Claude Desktop claude_desktop_config.json)
set -euo pipefail

CURSOR_VARS=(
  CURSOR_GITHUB_TOKEN
  CURSOR_GITLAB_TOKEN
  CURSOR_JIRA_URL
  CURSOR_JIRA_USERNAME
  CURSOR_JIRA_API_TOKEN
  CURSOR_CONFLUENCE_URL
  CURSOR_CONFLUENCE_USERNAME
  CURSOR_CONFLUENCE_API_TOKEN
)

CLAUDE_VARS=(
  CLAUDE_GITHUB_TOKEN
  CLAUDE_GITLAB_TOKEN
  CLAUDE_JIRA_URL
  CLAUDE_JIRA_USERNAME
  CLAUDE_JIRA_API_TOKEN
  CLAUDE_CONFLUENCE_URL
  CLAUDE_CONFLUENCE_USERNAME
  CLAUDE_CONFLUENCE_API_TOKEN
)

HOST=""
REQUIRED_VARS=()
MARKER_BEGIN=""
MARKER_END=""
RESTART_APP=""

usage() {
  cat <<'EOF'
Usage:
  ensure-env-exports.sh --host cursor|claude status
  ensure-env-exports.sh --host cursor|claude suggest
  ensure-env-exports.sh --host cursor|claude append --file PATH [--dry-run]

--host   Required. Selects which independent env var set to manage:
         cursor → CURSOR_* (Cursor MCP)
         claude → CLAUDE_* (Claude Desktop MCP)

status   Print set|MISSING for each required var (values never printed).
suggest  Print recommended env file and candidates for this shell/OS.
append   Append empty `export NAME=` stubs for vars that are MISSING in the
         environment and not already declared in PATH. Creates the file if needed.

Never pass secret values to this script; fill them by hand after append.
EOF
}

set_host() {
  local h="$1"
  case "$h" in
    cursor)
      HOST="cursor"
      REQUIRED_VARS=("${CURSOR_VARS[@]}")
      MARKER_BEGIN="# >>> mad-install-mcp-servers:cursor >>>"
      MARKER_END="# <<< mad-install-mcp-servers:cursor <<<"
      RESTART_APP="Cursor"
      ;;
    claude)
      HOST="claude"
      REQUIRED_VARS=("${CLAUDE_VARS[@]}")
      MARKER_BEGIN="# >>> mad-install-mcp-servers:claude >>>"
      MARKER_END="# <<< mad-install-mcp-servers:claude <<<"
      RESTART_APP="Claude Desktop"
      ;;
    *)
      printf 'error: --host must be cursor or claude (got: %s)\n' "$h" >&2
      usage >&2
      exit 2
      ;;
  esac
}

expand_path() {
  local p="$1"
  if [[ "$p" == ~* ]]; then
    p="${p/#\~/$HOME}"
  fi
  printf '%s\n' "$p"
}

shell_name() {
  local s
  s="$(basename "${SHELL:-}")"
  if [[ -z "$s" ]]; then
    s="$(ps -p $$ -o comm= 2>/dev/null | tr -d ' ' || true)"
  fi
  printf '%s\n' "${s:-unknown}"
}

candidate_files() {
  local sh
  sh="$(shell_name)"
  case "$sh" in
    zsh|-zsh)
      printf '%s\n' "$HOME/.zshenv" "$HOME/.zprofile" "$HOME/.zshrc"
      ;;
    bash|-bash)
      printf '%s\n' "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.bashrc"
      ;;
    *)
      printf '%s\n' "$HOME/.profile" "$HOME/.zshenv" "$HOME/.zprofile" "$HOME/.bashrc"
      ;;
  esac
}

recommended_file() {
  local f
  while IFS= read -r f; do
    if [[ -f "$f" ]]; then
      printf '%s\n' "$f"
      return 0
    fi
  done < <(candidate_files)
  candidate_files | head -n1
}

var_is_set() {
  local name="$1"
  [[ -n "${!name-}" ]]
}

file_declares_var() {
  local file="$1" name="$2"
  [[ -f "$file" ]] || return 1
  grep -Eq "^[[:space:]]*(export[[:space:]]+)?${name}=" "$file"
}

cmd_status() {
  local v
  local missing=0
  printf 'host=%s\n' "$HOST"
  for v in "${REQUIRED_VARS[@]}"; do
    if var_is_set "$v"; then
      printf '%s=set\n' "$v"
    else
      printf '%s=MISSING\n' "$v"
      missing=$((missing + 1))
    fi
  done
  printf 'missing_count=%s\n' "$missing"
  printf 'shell=%s\n' "$(shell_name)"
}

cmd_suggest() {
  local rec f
  rec="$(recommended_file)"
  printf 'host=%s\n' "$HOST"
  printf 'shell=%s\n' "$(shell_name)"
  printf 'recommended=%s\n' "$rec"
  printf 'candidates:\n'
  while IFS= read -r f; do
    if [[ -f "$f" ]]; then
      printf '  %s (exists)\n' "$f"
    else
      printf '  %s (missing)\n' "$f"
    fi
  done < <(candidate_files)
  printf 'note=On macOS, prefer ~/.zshenv so login and non-interactive shells see the vars; fully quit and reopen %s after editing. GUI apps may not inherit terminal-only env.\n' "$RESTART_APP"
}

vars_to_append() {
  local file="$1"
  local v
  for v in "${REQUIRED_VARS[@]}"; do
    if var_is_set "$v"; then
      continue
    fi
    if file_declares_var "$file" "$v"; then
      continue
    fi
    printf '%s\n' "$v"
  done
}

cmd_append() {
  local file="" dry_run=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --file)
        file="${2-}"
        shift 2
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      *)
        printf 'Unknown argument: %s\n' "$1" >&2
        usage >&2
        exit 2
        ;;
    esac
  done

  if [[ -z "$file" ]]; then
    printf 'error: --file PATH is required\n' >&2
    exit 2
  fi

  file="$(expand_path "$file")"

  local -a pending=()
  local v
  while IFS= read -r v; do
    [[ -n "$v" ]] && pending+=("$v")
  done < <(vars_to_append "$file")

  if [[ ${#pending[@]} -eq 0 ]]; then
    printf 'host=%s\n' "$HOST"
    printf 'file=%s\n' "$file"
    printf 'action=noop\n'
    printf 'detail=no missing undeclared vars\n'
    exit 0
  fi

  local block
  block="$(
    {
      printf '%s\n' "$MARKER_BEGIN"
      printf '# Fill values below; do not commit secrets. Restart %s after saving.\n' "$RESTART_APP"
      for v in "${pending[@]}"; do
        printf 'export %s=\n' "$v"
      done
      printf '%s\n' "$MARKER_END"
    }
  )"

  if [[ "$dry_run" -eq 1 ]]; then
    printf 'host=%s\n' "$HOST"
    printf 'file=%s\n' "$file"
    printf 'action=dry-run\n'
    printf 'would_append:\n%s\n' "$block"
    exit 0
  fi

  mkdir -p "$(dirname "$file")"
  if [[ -f "$file" ]] && [[ -s "$file" ]]; then
    if [[ "$(tail -c1 "$file" | wc -l | tr -d ' ')" -eq 0 ]]; then
      printf '\n' >>"$file"
    fi
    printf '\n%s\n' "$block" >>"$file"
  else
    printf '%s\n' "$block" >"$file"
  fi

  printf 'host=%s\n' "$HOST"
  printf 'file=%s\n' "$file"
  printf 'action=appended\n'
  printf 'appended_vars=%s\n' "${pending[*]}"
  printf 'detail=fill empty export values, then fully quit and reopen %s\n' "$RESTART_APP"
}

parse_global_args() {
  local -a rest=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host)
        set_host "${2-}"
        shift 2
        ;;
      -h|--help|help)
        usage
        exit 0
        ;;
      *)
        rest+=("$1")
        shift
        ;;
    esac
  done
  if [[ -z "$HOST" ]]; then
    printf 'error: --host cursor|claude is required\n' >&2
    usage >&2
    exit 2
  fi
  set -- "${rest[@]}"
  local cmd="${1-}"
  shift || true
  case "$cmd" in
    status) cmd_status ;;
    suggest) cmd_suggest ;;
    append) cmd_append "$@" ;;
    "")
      usage
      exit 2
      ;;
    *)
      printf 'Unknown command: %s\n' "$cmd" >&2
      usage >&2
      exit 2
      ;;
  esac
}

parse_global_args "$@"
