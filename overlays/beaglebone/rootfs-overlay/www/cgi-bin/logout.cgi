#!/bin/sh
# Simple CGI to force HTTP Basic auth re-challenge (logout)
# Returns 401 with WWW-Authenticate header matching the lighttpd realm.
# Also append a short entry to /var/log/whitelistcmd.log for diag.

LOG=/var/log/whitelistcmd.log
ts() { date '+%Y-%m-%dT%H:%M:%S%z'; }
user="${REMOTE_USER:-}${HTTP_REMOTE_USER:-}"
if [ -z "$user" ] && [ -n "${HTTP_AUTHORIZATION:-}" ]; then
	case "${HTTP_AUTHORIZATION}" in
		Basic*)
			b64=$(printf '%s' "${HTTP_AUTHORIZATION#Basic }" | tr -d '\r\n' | sed 's/^[[:space:]]*//')
			if command -v base64 >/dev/null 2>&1; then
				creds=$(printf '%s' "$b64" | base64 -d 2>/dev/null || true)
			else
				creds=""
			fi
			user=$(printf '%s' "$creds" | sed 's/:.*$//')
			;;
	esac
fi
printf '%s %s logout user="%s"\n' "$(ts)" "${REMOTE_ADDR:--}" "${user:--}" >>"$LOG" 2>/dev/null || true

printf 'Status: 401 Unauthorized\r\n'
printf 'WWW-Authenticate: Basic realm="BBB Web Login"\r\n'
printf 'Content-Type: text/plain\r\n\r\n'
printf 'Logged out\n'
