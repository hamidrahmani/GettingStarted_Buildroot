#!/usr/bin/env sh
# CGI: Whitelisted job launcher with subdirectory support (group/id)
# Works with POSIX sh (BusyBox ash, dash). No Bash-isms.

set -eu

# ---------------- Configuration ----------------
WHITELIST_DIR="/www/whitelistcmd"   # Root dir: contains subfolders like 'power-mgnt'
SLEEP_SECS="${SLEEP_SECS:-1}"       # Delay before background start
TIMEOUT_SECS="${TIMEOUT_SECS:-300}" # If 'timeout' exists, cap job runtime
# Choose a writable log file
if [ -d /var/log ] && [ -w /var/log ]; then
  LOG_FILE="/var/log/whitelistcmd.log"
else
  LOG_FILE="/tmp/whitelistcmd.log"
fi

# --------------- Helpers (CGI I/O) --------------
send_200() {
  printf "Status: 200 OK\r\nContent-Type: application/json\r\n\r\n"
}
send_400() {
  printf "Status: 400 Bad Request\r\nContent-Type: application/json\r\n\r\n"
}
json_escape() {
  # Minimal JSON escaper for simple values (no control chars expected due to sanitization)
  # Replaces backslash and quote.
  printf "%s" "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# --------------- Read request body ----------------
BODY=""
CL="${CONTENT_LENGTH:-}"
case "$CL" in
  ''|*[!0-9]*) : ;;   # not a number -> skip
  0) : ;;             # zero -> skip
  *)
    BODY=$(dd bs=1 count="$CL" 2>/dev/null || true)
    ;;
esac
if [ -z "${BODY:-}" ]; then
  IFS= read -r BODY || true
fi
BODY_CLEAN=$(printf "%s" "$BODY" | tr -d '\r\n')

# --------------- Parse JSON (jq or sed) ---------------
GROUP=""
ID=""

if command -v jq >/dev/null 2>&1; then
  # Prefer: {"group":"power-mgnt","id":"reboot"}; fallback: {"id":"power-mgnt/reboot"}
  GROUP=$(printf "%s" "$BODY_CLEAN" | jq -r '.group // ""' 2>/dev/null || printf "")
  ID=$(printf "%s" "$BODY_CLEAN"     | jq -r '.id // ""'    2>/dev/null || printf "")
else
  # Fallback: crude extraction (single-line JSON assumed)
  GROUP=$(printf "%s" "$BODY_CLEAN" \
    | sed -n 's/.*"group"[[:space:]]*:[[:space:]]*"\([^"\\]*\)".*/\1/p')
  ID=$(printf "%s" "$BODY_CLEAN" \
    | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"\\]*\)".*/\1/p')
fi

# If ID contains a slash and GROUP empty, split it as "group/id"
if [ -z "$GROUP" ] && printf "%s" "$ID" | grep -q '/'; then
  GROUP=$(printf "%s" "$ID" | cut -d/ -f1)
  ID=$(printf "%s" "$ID" | cut -d/ -f2-)
fi

# ------------ Strict sanitization (A-Za-z0-9 _ - only) ------------
# No slashes in either after split; only safe chars.
case "$GROUP" in
  ''|*[!A-Za-z0-9_-]*) GROUP="";;
esac
case "$ID" in
  ''|*[!A-Za-z0-9_-]*) ID="";;
esac

# --------------- Resolve command path safely ---------------
CMD=""
if [ -n "$GROUP" ] && [ -n "$ID" ]; then
  CANDIDATE="$WHITELIST_DIR/$GROUP/$ID"

  # Resolve absolute path and ensure it stays within WHITELIST_DIR
  # Prefer readlink -f; if unavailable, fall back to a simple prefix check
  if command -v readlink >/dev/null 2>&1; then
    # BusyBox readlink -f works on most systems
    RESOLVED=$(readlink -f -- "$CANDIDATE" 2>/dev/null || true)
    ROOT=$(readlink -f -- "$WHITELIST_DIR" 2>/dev/null || true)
    # Ensure non-empty and prefix match (RESOLVED starts with ROOT/)
    if [ -n "$RESOLVED" ] && [ -n "$ROOT" ] && [ "${RESOLVED#"$ROOT"/}" != "$RESOLVED" ]; then
      CMD="$RESOLVED"
    fi
  else
    # No readlink -f: perform a conservative check (no traversal due to sanitization)
    CMD="$CANDIDATE"
  fi
fi

# --------------- Decision & Response ---------------
if [ -n "$CMD" ] && [ -f "$CMD" ] && [ -x "$CMD" ]; then
  # Send response immediately
  send_200
  # Echo back identifiers (escaped, but they're sanitized anyway)
  jgroup=$(json_escape "$GROUP")
  jid=$(json_escape "$ID")
  printf '{"status":"ok","group":"%s","id":"%s"}\n' "$jgroup" "$jid"

  # Launch asynchronously, detached from CGI stdio, with logging & optional timeout
  (
    sleep "$SLEEP_SECS"
    if command -v timeout >/dev/null 2>&1; then
      timeout "$TIMEOUT_SECS" "$CMD" </dev/null >>"$LOG_FILE" 2>&1
    else
      "$CMD" </dev/null >>"$LOG_FILE" 2>&1
    fi
  ) &
else
  send_400
  # Hint helps clients fix requests without leaking filesystem details
  if [ -z "$GROUP" ] || [ -z "$ID" ]; then
    printf '{"error":"invalid_or_missing_group_or_id"}\n'
  else
    printf '{"error":"unknown_id"}\n'
  fi
fi
