#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
PROJECT_FILE="$PROJECT_DIR/project.godot"
ENV_FILE="$PROJECT_DIR/.agent/godot-agent.env"
LOG_DIR="$PROJECT_DIR/.godot/agent-logs"

if [[ ! -f "$PROJECT_FILE" ]]; then
  printf 'ERROR: project.godot not found in %s\n' "$PROJECT_DIR" >&2
  exit 2
fi

if [[ -f "$ENV_FILE" ]]; then
  # This file is repository-controlled configuration and may contain shell commands.
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

find_godot() {
  if [[ -n "${GODOT_BIN:-}" ]]; then
    command -v "$GODOT_BIN" 2>/dev/null || {
      [[ -x "$GODOT_BIN" ]] && printf '%s\n' "$GODOT_BIN" && return 0
      return 1
    }
    return 0
  fi

  local candidate
  for candidate in godot godot4 godot-mono godot4-mono; do
    if command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"
      return 0
    fi
  done
  return 1
}

GODOT="$(find_godot || true)"
if [[ -z "$GODOT" ]]; then
  printf 'ERROR: Godot editor binary not found. Set GODOT_BIN or add godot to PATH.\n' >&2
  exit 3
fi

mkdir -p "$LOG_DIR"
rm -f "$LOG_DIR"/*.log

FAILURES=0
STEPS=()

record() {
  STEPS+=("$1")
}

run_step() {
  local name="$1"
  shift
  printf '\n== %s ==\n' "$name"
  if "$@"; then
    record "PASS: $name"
  else
    local status=$?
    record "FAIL($status): $name"
    FAILURES=$((FAILURES + 1))
  fi
}

run_shell_step() {
  local name="$1"
  local command_text="$2"
  printf '\n== %s ==\n%s\n' "$name" "$command_text"
  if (cd "$PROJECT_DIR" && bash -lc "$command_text"); then
    record "PASS: $name"
  else
    local status=$?
    record "FAIL($status): $name"
    FAILURES=$((FAILURES + 1))
  fi
}

scan_log() {
  local log_file="$1"
  [[ -f "$log_file" ]] || return 0

  local pattern='SCRIPT ERROR:|Parse Error:|(^|[[:space:]])ERROR:|Failed loading resource|Cannot open file|Invalid call|Invalid access|Unhandled exception|Build FAILED|Tests failed'
  local matches
  matches="$(grep -Ein "$pattern" "$log_file" || true)"

  if [[ -n "${GODOT_ALLOWED_LOG_REGEX:-}" && -n "$matches" ]]; then
    matches="$(printf '%s\n' "$matches" | grep -Ev "$GODOT_ALLOWED_LOG_REGEX" || true)"
  fi

  if [[ -n "$matches" ]]; then
    printf 'Detected failure-like log lines in %s:\n%s\n' "$log_file" "$matches" >&2
    return 1
  fi
}

printf 'Project: %s\n' "$PROJECT_DIR"
printf 'Godot: %s\n' "$GODOT"
"$GODOT" --version || true

if command -v git >/dev/null 2>&1 && git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  run_step "git diff --check" git -C "$PROJECT_DIR" diff --check
  printf '\nChanged files:\n'
  git -C "$PROJECT_DIR" status --short || true
else
  record "SKIP: git diff check (not a Git worktree)"
fi

if [[ -n "${GODOT_FORMAT_CHECK_COMMAND:-}" ]]; then
  run_shell_step "format check" "$GODOT_FORMAT_CHECK_COMMAND"
else
  record "SKIP: format check (not configured)"
fi

if [[ -n "${GODOT_LINT_COMMAND:-}" ]]; then
  run_shell_step "lint" "$GODOT_LINT_COMMAND"
else
  record "SKIP: lint (not configured)"
fi

IMPORT_LOG="$LOG_DIR/import.log"
run_step "Godot import" "$GODOT" --headless --path "$PROJECT_DIR" --import --verbose --log-file "$IMPORT_LOG"
if ! scan_log "$IMPORT_LOG"; then
  record "FAIL: import log scan"
  FAILURES=$((FAILURES + 1))
else
  record "PASS: import log scan"
fi

collect_changed_gd() {
  if command -v git >/dev/null 2>&1 && git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    {
      git -C "$PROJECT_DIR" diff --name-only --diff-filter=ACMRT -- '*.gd'
      git -C "$PROJECT_DIR" diff --cached --name-only --diff-filter=ACMRT -- '*.gd'
      git -C "$PROJECT_DIR" ls-files --others --exclude-standard -- '*.gd'
    } | awk 'NF' | sort -u
  fi
}

CHANGED_GD=()
while IFS= read -r changed_script; do
  [[ -n "$changed_script" ]] && CHANGED_GD+=("$changed_script")
done < <(collect_changed_gd || true)
if (( ${#CHANGED_GD[@]} > 0 )); then
  for relative_path in "${CHANGED_GD[@]}"; do
    script_path="$PROJECT_DIR/$relative_path"
    [[ -f "$script_path" ]] || continue
    safe_name="$(printf '%s' "$relative_path" | tr '/\\ :' '____')"
    parse_log="$LOG_DIR/parse-$safe_name.log"
    run_step "parse $relative_path" "$GODOT" --headless --path "$PROJECT_DIR" --script "$script_path" --check-only --log-file "$parse_log"
    if ! scan_log "$parse_log"; then
      record "FAIL: parse log scan $relative_path"
      FAILURES=$((FAILURES + 1))
    fi
  done
else
  record "SKIP: changed GDScript parse (no changed .gd files detected)"
fi

if find "$PROJECT_DIR" -path "$PROJECT_DIR/.godot" -prune -o -type f \( -name '*.csproj' -o -name '*.sln' \) -print | grep -q .; then
  BUILD_LOG="$LOG_DIR/csharp-build.log"
  run_step "Godot C# solution build" "$GODOT" --headless --path "$PROJECT_DIR" --editor --build-solutions --quit --log-file "$BUILD_LOG"
  if ! scan_log "$BUILD_LOG"; then
    record "FAIL: C# build log scan"
    FAILURES=$((FAILURES + 1))
  fi
else
  record "SKIP: C# build (no .csproj/.sln detected)"
fi

if [[ -n "${GODOT_TEST_COMMAND:-}" ]]; then
  run_shell_step "automated tests" "$GODOT_TEST_COMMAND"
else
  record "SKIP: automated tests (GODOT_TEST_COMMAND not configured)"
fi

SMOKE_FRAMES="${GODOT_SMOKE_FRAMES:-3}"
SMOKE_LOG="$LOG_DIR/runtime-smoke.log"
if [[ -n "${GODOT_SMOKE_SCENE:-}" ]]; then
  run_step "runtime smoke: $GODOT_SMOKE_SCENE" "$GODOT" --headless --path "$PROJECT_DIR" --scene "$GODOT_SMOKE_SCENE" --quit-after "$SMOKE_FRAMES" --log-file "$SMOKE_LOG"
elif grep -Eq '^run/main_scene=("[^"]+"|uid://[^[:space:]]+)' "$PROJECT_FILE"; then
  run_step "runtime smoke: Main Scene" "$GODOT" --headless --path "$PROJECT_DIR" --quit-after "$SMOKE_FRAMES" --log-file "$SMOKE_LOG"
else
  record "SKIP: runtime smoke (Main Scene and GODOT_SMOKE_SCENE are unset)"
fi

if [[ -f "$SMOKE_LOG" ]]; then
  if ! scan_log "$SMOKE_LOG"; then
    record "FAIL: runtime smoke log scan"
    FAILURES=$((FAILURES + 1))
  else
    record "PASS: runtime smoke log scan"
  fi
fi

printf '\n== Summary ==\n'
printf '%s\n' "${STEPS[@]}"
printf '\nLogs: %s\n' "$LOG_DIR"

if (( FAILURES > 0 )); then
  printf 'Validation failed with %d failing check(s).\n' "$FAILURES" >&2
  exit 1
fi

printf 'Validation completed without detected failures. Review skipped checks and add visual/interaction verification when required.\n'
