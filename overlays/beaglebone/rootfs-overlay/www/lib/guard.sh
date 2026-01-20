#!/bin/sh

HOMER_ALLOW_FILE="/www/whitelistcmd/.allow"

require_folder_or_403() {
    folder=$(basename "$(dirname "$SCRIPT_FILENAME")")

    # maintainer always allowed
    if [ "$REMOTE_USER" = "maintainer" ]; then
        return 0
    fi

    # homer needs the folder listed in .allow
    if [ "$REMOTE_USER" = "homer" ]; then
        if grep -v '^#' "$HOMER_ALLOW_FILE" | grep -Fx "$folder" >/dev/null; then
            return 0
        else
            printf "Status: 403 Forbidden\r\n"
            printf "Content-Type: text/plain\r\n\r\n"
            printf "Forbidden\n"
            exit 0
        fi
    fi

    # default deny
    printf "Status: 403 Forbidden\r\n"
    printf "Content-Type: text/plain\r\n\r\n"
    printf "Forbidden\n"
    exit 0
}
