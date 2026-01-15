
#!/usr/bin/env sh
set -eu

# Optional: simple token check
# [ "${HTTP_X_API_KEY:-}" = "changeme" ] || { printf "Status: 403\r\n\r\n"; exit 0; }

read BODY || true
JOB=$(printf "%s" "$BODY" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

printf "Content-Type: application/json\r\n\r\n"

case "${JOB:-}" in
  calibrate)   /usr/local/bin/calibrate.sh && printf '{"status":"ok","id":"%s"}\n' "$JOB" || printf '{"status":"failed","id":"%s"}\n' "$JOB" ;;
  capture)     /usr/local/bin/capture.sh   && printf '{"status":"ok","id":"%s"}\n' "$JOB" || printf '{"status":"failed","id":"%s"}\n' "$JOB" ;;
  reboot-safe) /usr/sbin/shutdown -r +1     && printf '{"status":"ok","id":"%s"}\n' "$JOB" || printf '{"status":"failed","id":"%s"}\n' "$JOB" ;;
  *)           printf '{"error":"unknown_id"}\n' ;;
esac