#!/bin/sh

set -eu

# this is a simple webservice running as root so we can request `mount --bind` as regular user
/bin/mount-helper.js & 

if ! [ -f "/etc/sftpgo/db/sftpgo.db" ]; then
    cp /etc/sftpgo/defaults/sftpgo.db /etc/sftpgo/db/sftpgo.db
fi;

chown -R "${PUID}:${PGID}" /data /sftp-jail /etc/sftpgo /etc/sftpgo/config /etc/sftpgo/db /etc/sftpgo/keys /etc/sftpgo/backups \
        && exec su-exec "${PUID}:${PGID}" \
          /bin/sftpgo "$@"
