#!/bin/sh
# Simple CGI to force HTTP Basic auth re-challenge (logout)
# Returns 401 with WWW-Authenticate header matching the lighttpd realm.
printf 'Status: 401 Unauthorized\r\n'
printf 'WWW-Authenticate: Basic realm="BBB Web Login"\r\n'
printf 'Content-Type: text/plain\r\n\r\n'
printf 'Logged out\n'
