#!/usr/bin/env bash
set -euo pipefail

# backup-to-network-gitbash.sh
# Copy a configurable list of files/folders to a Windows network drive from Git Bash.
# - Reads sources from a config file (one path per line; # comments allowed).
# - Uses robocopy for directories (fast, resilient, supports mirror and dry-run).
# - Uses PowerShell Copy-Item for individual files.
# - Accepts POSIX-style (/c/Users/you/Documents) or Windows (C:\Users\you\Documents) paths.
#
# Usage:
#   ./backup-to-network-gitbash.sh -c /path/to/backup.conf -d //server/share/Backups [-n] [--mirror] [-l logfile] [-v]
#
# Example config (backup.conf):
#   # Lines starting with # are comments. Blank lines are ignored.
#   /c/Users/you/Documents
#   /c/Users/you/Pictures
#   /c/Users/you/notes/todo.txt
#
# Notes:
#   * Destination can be a drive letter (E:\Backups) or UNC (\\server\share\Backups)
#     You may also pass POSIX: //server/share/Backups or /e/Backups; we normalize it.
#   * Mirror mode deletes files at destination that no longer exist at source (use with care!).
#   * Dry-run shows what would change without writing anything.
#
# Exit codes:
#   0 success, non-zero on failure.

show_help() {
  cat <<'EOF'
Usage:
  backup-to-network-gitbash.sh -c CONFIG -d DESTINATION [options]

Required:
  -c, --config FILE         Path to config file (one source path per line)
  -d, --dest PATH           Destination directory (network drive or local path)

Options:
  -n, --dry-run             Show what would be copied; make no changes
      --mirror              Mirror mode for directories (equivalent to robocopy /MIR)
  -l, --log FILE            Write a log file (default: ./backup-YYYYmmdd-HHMMSS.log)
  -v, --verbose             Verbose output
  -h, --help                Show this help

CONFIG format:
  * One path per line. Comments (#) and blank lines ignored.
  * Paths may be POSIX (/c/Users/you/Docs) or Windows (C:\Users\you\Docs).

Examples:
  ./backup-to-network-gitbash.sh -c ~/backup.conf -d //nas/Backups -v
  ./backup-to-network-gitbash.sh -c ~/backup.conf -d 'E:\Backups' --mirror -n
EOF
}

CONFIG=""
DEST_IN=""
DRY_RUN=0
MIRROR=0
VERBOSE=0
LOGFILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--config) CONFIG=${2:-}; shift 2 ;;
    -d|--dest)   DEST_IN=${2:-}; shift 2 ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    --mirror)    MIRROR=1; shift ;;
    -l|--log)    LOGFILE=${2:-}; shift 2 ;;
    -v|--verbose) VERBOSE=1; shift ;;
    -h|--help)   show_help; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; show_help; exit 2 ;;
  esac
done

if [[ -z "${CONFIG}" || -z "${DEST_IN}" ]]; then
  echo "Error: --config and --dest are required." >&2
  show_help
  exit 2
fi

if [[ ! -f "${CONFIG}" ]]; then
  echo "Error: Config file not found: ${CONFIG}" >&2
  exit 3
fi

# Tools we rely on (should exist on modern Windows):
for TOOL in robocopy powershell.exe; do
  if ! command -v "$TOOL" >/dev/null 2>&1; then
    echo "Error: Required tool not found in PATH: $TOOL" >&2
    exit 4
  fi
done

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }
START_TS=$(date +"%Y%m%d-%H%M%S")
: "${LOGFILE:=./backup-${START_TS}.log}"

exec > >(tee -a "$LOGFILE") 2>&1

echo "[$(timestamp)] Starting backup (Git Bash)"
echo "Config:       ${CONFIG}"
echo "Destination:  ${DEST_IN}"
echo "Dry-run:      $([[ $DRY_RUN -eq 1 ]] && echo yes || echo no)"
echo "Mirror mode:  $([[ $MIRROR -eq 1 ]] && echo yes || echo no)"
echo "Verbose:      $([[ $VERBOSE -eq 1 ]] && echo yes || echo no)"
echo "Logfile:      ${LOGFILE}"
echo

# Normalize destination to Windows form for robocopy/PowerShell
to_windows_path() {
  local p="$1"
  # If path already looks like X:\ or \\server\share, keep it
  if [[ "$p" =~ ^[A-Za-z]:\\ ]] || [[ "$p" =~ ^\\\\ ]]; then
    echo "$p"
    return
  fi
  # Convert POSIX //server/share to \\server\share
  if [[ "$p" =~ ^//[^/]+/[^/]+ ]]; then
    # Replace leading // with \\ and subsequent / with \
    p="\\\\"${p#//}
    p="${p//\//\\}"
    echo "$p"
    return
  fi
  # Otherwise, assume POSIX path like /c/Users/you...
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$p"
  else
    # Fallback: naive conversion of /c/... -> C:\...
    if [[ "$p" =~ ^/([a-zA-Z])/(.*)$ ]]; then
      drive="${BASH_REMATCH[1]^}"
      rest="${BASH_REMATCH[2]}"
      echo "${drive}:\\${rest//\//\\}"
    else
      echo "$p"
    fi
  fi
}

DEST_WIN="$(to_windows_path "$DEST_IN")"

# Read sources
mapfile -t SOURCES < <(grep -vE '^\s*#' "${CONFIG}" | sed '/^\s*$/d')

if [[ ${#SOURCES[@]} -eq 0 ]]; then
  echo "Error: No sources found in config (after ignoring comments/blank lines)." >&2
  exit 5
fi

# Robocopy base options
# /E  = copy subdirs (including empty)
# /COPY:DAT = copy Data, Attributes, Timestamps
# /DCOPY:DAT = same for dirs
# /R:2 /W:5 = retry policies
# /NFL /NDL = reduce noise (file/dir listings); toggle with verbose
ROBO_OPTS=(/E /COPY:DAT /DCOPY:DAT /R:2 /W:5)
[[ $MIRROR -eq 1 ]] && ROBO_OPTS=(/MIR /COPY:DAT /DCOPY:DAT /R:2 /W:5)
[[ $DRY_RUN -eq 1 ]] && ROBO_OPTS+=(/L)
if [[ $VERBOSE -eq 0 ]]; then
  ROBO_OPTS+=(/NFL /NDL /NP)
fi

FAILS=0

for SRC in "${SOURCES[@]}"; do
  # Expand ~ and env vars for POSIX inputs
  eval SRC_EXPANDED="${SRC}" || SRC_EXPANDED="${SRC}"

  if [[ -d "$SRC_EXPANDED" ]]; then
    SRC_WIN="$(to_windows_path "$SRC_EXPANDED")"
    BASENAME=$(basename -- "$SRC_EXPANDED")
    DEST_SUB="${DEST_WIN}\\${BASENAME}"
    echo "[$(timestamp)] Directory: ${SRC_EXPANDED} -> ${DEST_SUB}"
    # robocopy expects existing or will create dest subdir
    if ! cmd.exe /c robocopy "$SRC_WIN" "$DEST_SUB" "${ROBO_OPTS[@]}" > /dev/null; then
      rc=$?
      # robocopy "success" codes are >=8 failure; 0-7 include "no files" and "copied"
      if (( rc >= 8 )); then
        echo "[$(timestamp)] ERROR: robocopy failed for ${SRC_EXPANDED} (exit $rc)"
        ((FAILS++)) || true
      fi
    fi
  elif [[ -f "$SRC_EXPANDED" ]]; then
    SRC_WIN="$(to_windows_path "$SRC_EXPANDED")"
    echo "[$(timestamp)] File: ${SRC_EXPANDED} -> ${DEST_WIN}"
    if [[ $DRY_RUN -eq 1 ]]; then
      if ! powershell.exe -NoProfile -Command "Copy-Item -LiteralPath \"$SRC_WIN\" -Destination \"$DEST_WIN\" -Force -WhatIf" >/dev/null; then
        echo "[$(timestamp)] ERROR: (dry-run) Copy-Item failed for ${SRC_EXPANDED}"
        ((FAILS++)) || true
      fi
    else
      if ! powershell.exe -NoProfile -Command "Copy-Item -LiteralPath \"$SRC_WIN\" -Destination \"$DEST_WIN\" -Force" >/dev/null; then
        echo "[$(timestamp)] ERROR: Copy-Item failed for ${SRC_EXPANDED}"
        ((FAILS++)) || true
      fi
    fi
  else
    echo "[$(timestamp)] WARN: Source not found (skipping): ${SRC_EXPANDED}"
  fi
done

if [[ $FAILS -gt 0 ]]; then
  echo "[$(timestamp)] Completed with ${FAILS} error(s). See log: ${LOGFILE}"
  exit 6
fi

echo
echo "[$(timestamp)] Backup complete. Log saved to: ${LOGFILE}"
