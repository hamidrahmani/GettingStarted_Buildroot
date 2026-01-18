#!/bin/sh
# Simple & safe CGI job launcher with subfolder + .allow + logging
# BusyBox/ash compatible.
set -eu

# ---------------- Configuration ----------------
WHITELIST="/www/whitelistcmd"
TIMEOUT=300

# Choose a writable log file
if [ -d /var/log ] && [ -w /var/log ]; then
  LOG="/var/log/whitelistcmd.log"
else
  LOG="/tmp/whitelistcmd.log"
fi

# Small hardening
PATH="/usr/sbin:/usr/bin:/sbin:/bin"; export PATH
umask 077
LC_ALL=C; export LC_ALL

# ---------------- Helpers ----------------
ts() { date '+%Y-%m-%dT%H:%M:%S%z'; }
hdr() { printf "Status: %s\r\nContent-Type: application/json\r\n\r\n" "$1"; }
json() { printf "%s" "$1"; }
log() {
  # ts, remote, group, id, message
  printf '%s %s group="%s" id="%s" msg=%s\n' \
    "$(ts)" "${REMOTE_ADDR:--}" "${1:--}" "${2:--}" \
    "$(printf %s "$3" | sed 's/"/\\"/g')" >>"$LOG"
}
# exact-match check in .allow (ignoring comments/blanks)
allow_has() {
  _file="$1"; _name="$2"
  [ -r "$_file" ] || return 1
  sed -e 's/#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$_file" \
    | grep -xF -- "$_name" >/dev/null 2>&1
}
# minimal urldecode (supports + and a few %xx we might see)
urldecode() {
  s=$(printf '%s' "$1" | sed 's/+/ /g; s/%2D/-/ig; s/%5F/_/ig; s/%2E/./ig; s/%3A/:/ig; s/%2F/\//ig')
  printf '%s' "$s"
}

# ---------------- Enforce POST (optional but recommended) ----------------
if [ "${REQUEST_METHOD:-}" != "POST" ]; then
  hdr "405 Method Not Allowed"
  json '{"error":"method_not_allowed"}'
  log "-" "-" "method_not_allowed"
  exit 0
fi

# ---------------- Read request body robustly ----------------
BODY=""
CL="${CONTENT_LENGTH:-}"
case "$CL" in
  ''|*[!0-9]*)  # not a number -> try read a line
    read -r BODY || BODY=""
    ;;
  0)
    BODY=""
    ;;
  *)
    BODY="$(dd bs=1 count="$CL" 2>/dev/null || true)"
    ;;
esac
# Normalize to single line (remove CR/LF)
BODY="$(printf "%s" "$BODY" | tr -d '\r\n')"

# ---------------- Detect format + extract fields ----------------
GROUP=""; ID=""
is_json=0
printf '%s' "$BODY" | grep -q '^{.*}$' && is_json=1

if [ $is_json -eq 1 ]; then
  # JSON: {"group":"...","id":"..."} or {"id":"group/id"}
  GROUP=$(printf "%s" "$BODY" | sed -n 's/.*"group"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  ID=$(printf "%s" "$BODY"    | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
else
  # application/x-www-form-urlencoded: group=...&id=... OR id=group/id
  raw_group=$(printf '%s' "$BODY" | sed -n 's/.*[?&]*group=\([^&]*\).*/\1/p' | sed 's/[[:space:]]*$//')
  raw_id=$(printf    '%s' "$BODY" | sed -n 's/.*[?&]*id=\([^&]*\).*/\1/p'    | sed 's/[[:space:]]*$//')
  [ -n "$raw_group" ] && GROUP="$(urldecode "$raw_group")"
  [ -n "$raw_id" ] && ID="$(urldecode "$raw_id")"
fi

# If group empty but id contains '/', split "group/id"
if [ -z "$GROUP" ] && printf '%s' "$ID" | grep -q '/'; then
  GROUP="$(printf '%s' "$ID" | cut -d/ -f1)"
  ID="$(printf '%s' "$ID" | cut -d/ -f2-)"
fi

# Sanitization (allow letters, digits, underscore, dash)
echo "$GROUP" | grep -Eq '^[A-Za-z0-9_-]+$' || GROUP=""
echo "$ID"    | grep -Eq '^[A-Za-z0-9_-]+$' || ID=""

# If parsing failed, log raw body and return 400
if [ -z "$GROUP" ] || [ -z "$ID" ]; then
  printf '%s %s raw_body=%s\n' "$(ts)" "${REMOTE_ADDR:--}" "$(printf '%s' "$BODY" | sed 's/"/\\"/g')" >>"$LOG"
  hdr "400 Bad Request"
  json '{"error":"invalid_group_or_id"}'
  log "$GROUP" "$ID" 'invalid_group_or_id'
  exit 0
fi

# ---------------- .allow checks ----------------
# Root .allow (optional)
if [ -r "$WHITELIST/.allow" ] && ! allow_has "$WHITELIST/.allow" "$GROUP"; then
  hdr "403 Forbidden"
  json '{"error":"group_forbidden"}'
  log "$GROUP" "$ID" 'group_forbidden (root .allow)'
  exit 0
fi

# Group .allow (required)
GROUP_DIR="$WHITELIST/$GROUP"
GROUP_ALLOW="$GROUP_DIR/.allow"
if ! allow_has "$GROUP_ALLOW" "$ID"; then
  hdr "403 Forbidden"
  json '{"error":"id_forbidden"}'
  log "$GROUP" "$ID" 'id_forbidden (group .allow)'
  exit 0
fi

# ---------------- File checks ----------------
CMD="$GROUP_DIR/$ID"
if [ ! -f "$CMD" ]; then
  hdr "400 Bad Request"
  json '{"error":"cmd_missing"}'
  log "$GROUP" "$ID" "cmd_missing: $CMD"
  exit 0
fi
if [ ! -x "$CMD" ]; then
  hdr "400 Bad Request"
  json '{"error":"cmd_not_executable"}'
  log "$GROUP" "$ID" "cmd_not_executable: $CMD"
  exit 0
fi

# ---------------- Execute in background ----------------
hdr "200 OK"
json "{\"status\":\"ok\",\"group\":\"$GROUP\",\"id\":\"$ID\"}"
log "$GROUP" "$ID" "starting"

(
  if command -v timeout >/dev/null 2>&1; then
    timeout "$TIMEOUT" "$CMD" >>"$LOG" 2>&1
    RC=$?
  else
    "$CMD" >>"$LOG" 2>&1
    RC=$?
  fi
  if [ $RC -eq 0 ]; then
    log "$GROUP" "$ID" "finished rc=0"
  else
    log "$GROUP" "$ID" "finished rc=$RC"
  fi
) &

exit 0
