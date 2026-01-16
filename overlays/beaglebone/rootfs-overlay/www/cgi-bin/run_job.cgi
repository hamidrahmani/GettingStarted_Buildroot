#!/usr/bin/env sh
set -eu

read BODY || true
JOB=$(printf "%s" "$BODY" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

printf "Content-Type: application/json\r\n\r\n"

CMD="/www/whitelistcmd/$JOB"

if [ -x "$CMD" ]; then
    # Return JSON first, run job in background
    printf '{"status":"ok","id":"%s"}\n' "$JOB"
    ( sleep 1; "$CMD" ) &
else
    printf '{"error":"unknown_id"}\n'
fi
