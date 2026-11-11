#!/usr/bin/env bash
# tilix-sessions.sh
# Lists active Tilix sessions: TTY, shell PID, working directory, and current command.
#
# Usage:
#   ./tilix-sessions.sh           # human-readable output
#   ./tilix-sessions.sh --json    # JSON output
#   ./tilix-sessions.sh --watch   # refresh every 2s
#
# Notes:
# - Works on Ubuntu 24.04 (and most distros).
# - Requires: pgrep, ps, readlink (procps + coreutils). All preinstalled.

set -euo pipefail

JSON=0
WATCH=0
for arg in "$@"; do
  case "$arg" in
    --json)  JSON=1 ;;
    --watch) WATCH=1 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# --- helpers ---------------------------------------------------------------

# Get the working directory of a PID (uses /proc, always present on Linux)
get_cwd() {
  local pid=$1
  readlink "/proc/$pid/cwd" 2>/dev/null || echo "?"
}

# Get the foreground process group of a TTY (what the user is "running")
# Falls back to the shell's child if TTY info isn't available.
get_foreground() {
  local tty=$1 shell_pid=$2
  if [[ -n "$tty" && "$tty" != "?" ]]; then
    local fg_pgid
    fg_pgid=$(ps -t "$tty" -o tpgid= 2>/dev/null | head -n1 | tr -d ' ')
    if [[ -n "${fg_pgid:-}" && "$fg_pgid" -gt 0 ]] 2>/dev/null; then
      local cmd
      cmd=$(ps -p "$fg_pgid" -o args= 2>/dev/null || true)
      [[ -n "$cmd" ]] && { echo "$cmd"; return; }
    fi
  fi
  # Fallback: last child of the shell
  local child
  child=$(pgrep -P "$shell_pid" 2>/dev/null | tail -n1 || true)
  if [[ -n "$child" ]]; then
    ps -p "$child" -o args= 2>/dev/null || echo "?"
  else
    echo "(idle shell)"
  fi
}

# Get TTY of a PID
get_tty() {
  ps -p "$1" -o tty= 2>/dev/null | tr -d ' ' || echo "?"
}

# Collect (shell_pid, tty, cwd, command) tuples
collect_sessions() {
  local tilix_pids
  tilix_pids=$(pgrep -x tilix 2>/dev/null || true)
  [[ -z "$tilix_pids" ]] && { echo "Tilix is not running." >&2; return 1; }

  # Known shells (extend as needed)
  local shells='^(bash|zsh|fish|sh|dash|ksh|tcsh|nu)$'

  # Build descendant list of every tilix process, then filter to shell processes.
  local all_desc
  all_desc=$(ps -e -o pid=,ppid=,comm=,args= 2>/dev/null)

  # Iterative BFS from tilix pids
  local -A children
  while read -r pid ppid comm args; do
    children[$ppid]+="$pid "
  done <<< "$all_desc"

  local queue=() shell_pids=()
  for tp in $tilix_pids; do queue+=("$tp"); done
  while ((${#queue[@]})); do
    local cur=${queue[0]}; queue=("${queue[@]:1}")
    local comm
    comm=$(ps -p "$cur" -o comm= 2>/dev/null || true)
    [[ -z "$comm" ]] && continue
    if [[ "$comm" =~ $shells ]]; then
      # Only keep shells that own a tty (skip short-lived helpers)
      local t
      t=$(get_tty "$cur")
      [[ "$t" != "?" && "$t" != "??" ]] && shell_pids+=("$cur")
    fi
    for c in ${children[$cur]:-}; do queue+=("$c"); done
  done

  # Dedupe & emit
  for pid in $(printf '%s\n' "${shell_pids[@]}" | sort -u); do
    local tty cwd cmd
    tty=$(get_tty "$pid")
    cwd=$(get_cwd "$pid")
    cmd=$(get_foreground "$tty" "$pid")
    printf '%s\t%s\t%s\t%s\n' "$pid" "$tty" "$cwd" "$cmd"
  done
}

# --- output ----------------------------------------------------------------

print_table() {
  local data=$1
  if [[ -z "$data" ]]; then
    echo "No active Tilix shells found."
    return
  fi
  printf '%-8s %-10s %-40s %s\n' "PID" "TTY" "DIRECTORY" "RUNNING"
  printf '%-8s %-10s %-40s %s\n' "-------" "----------" \
    "----------------------------------------" "-------"
  while IFS=$'\t' read -r pid tty cwd cmd; do
    # Truncate long dir/cmd for readability
    local dc="$cwd"; [[ ${#dc} -gt 40 ]] && dc="…${dc: -39}"
    local cc="$cmd"; [[ ${#cc} -gt 60 ]] && cc="${cc:0:57}…"
    printf '%-8s %-10s %-40s %s\n' "$pid" "$tty" "$dc" "$cc"
  done <<< "$data"
}

print_json() {
  local data=$1
  echo "["
  local first=1
  while IFS=$'\t' read -r pid tty cwd cmd; do
    [[ -z "$pid" ]] && continue
    [[ $first -eq 0 ]] && echo ","
    first=0
    # JSON-escape (basic)
    local jcwd jcmd
    jcwd=$(printf '%s' "$cwd" | sed 's/\\/\\\\/g; s/"/\\"/g')
    jcmd=$(printf '%s' "$cmd" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '  {"pid": %s, "tty": "%s", "cwd": "%s", "cmd": "%s"}' \
      "$pid" "$tty" "$jcwd" "$jcmd"
  done <<< "$data"
  echo
  echo "]"
}

run_once() {
  local data
  data=$(collect_sessions) || return 1
  if [[ $JSON -eq 1 ]]; then
    print_json "$data"
  else
    print_table "$data"
  fi
}

if [[ $WATCH -eq 1 ]]; then
  while true; do
    clear
    echo "Tilix sessions — $(date '+%H:%M:%S')  (Ctrl+C to exit)"
    echo
    run_once || true
    sleep 2
  done
else
  run_once
fi