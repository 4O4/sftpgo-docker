#!/bin/sh

set -eu

if ! [ -f "/etc/sftpgo/db/sftpgo.db" ]; then
    cp /etc/sftpgo/defaults/sftpgo.db /etc/sftpgo/db/sftpgo.db
fi;

chown -R "${PUID}:${PGID}" /data /etc/sftpgo /etc/sftpgo/config /etc/sftpgo/db /etc/sftpgo/keys /etc/sftpgo/backups \
        && exec su-exec "${PUID}:${PGID}" \
          /bin/sftpgo "$@"
