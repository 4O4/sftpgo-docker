FROM golang:1.13.5-alpine3.11 as builder

RUN apk add --no-cache git gcc g++ ca-certificates \
  && go get -d github.com/drakkan/sftpgo \
  && mkdir -p /sftpgo-rootfs/bin /sftpgo-rootfs/etc/sftpgo/web /sftpgo-rootfs/etc/sftpgo/defaults
WORKDIR /go/src/github.com/drakkan/sftpgo
# RUN git checkout `git rev-list --tags --max-count=1`
RUN go build -i -ldflags "-s -w -X github.com/drakkan/sftpgo/utils.commit=`git describe --always --dirty` -X github.com/drakkan/sftpgo/utils.date=`date -u +%FT%TZ`" -o /go/bin/sftpgo
RUN cp -fv /go/bin/sftpgo /sftpgo-rootfs/bin/ \
  && cp -fv /go/src/github.com/drakkan/sftpgo/sftpgo.json /sftpgo-rootfs/etc/sftpgo/sftpgo.json \
  && cp -rfv /go/src/github.com/drakkan/sftpgo/templates /sftpgo-rootfs/etc/sftpgo/web/templates \
  && cp -rfv /go/src/github.com/drakkan/sftpgo/static /sftpgo-rootfs/etc/sftpgo/web/static 

FROM keinos/sqlite3 as migrations

WORKDIR /tmp

COPY --from=builder /go/src/github.com/drakkan/sftpgo/sql/sqlite /tmp/sql
COPY --from=builder /sftpgo-rootfs /sftpgo-rootfs

RUN set -x \
  && find /tmp/sql -type f -iname '*.sql' -print | sort -n | xargs cat | sqlite3 /sftpgo-rootfs/etc/sftpgo/defaults/sftpgo.db

FROM node:12.14-alpine3.11

# git and rsync are optional, uncomment the next line to add support for them if needed
#RUN apk add --no-cache git rsync

COPY --from=migrations /sftpgo-rootfs /
COPY docker-entrypoint.sh /bin/entrypoint.sh
COPY mount-helper.js /bin/mount-helper.js

WORKDIR /etc/sftpgo

RUN apk add --no-cache ca-certificates su-exec mysql-client findmnt tzdata \
  && chmod +x /bin/entrypoint.sh /bin/mount-helper.js \
  && mkdir -p /data /sftp-jail /etc/sftpgo/web /etc/sftpgo/backups /etc/sftpgo/config

ENV SFTPGO_LOG_FILE_PATH=${SFTPGO_LOG_FILE_PATH:-} \
  SFTPGO_CONFIG_DIR=/etc/sftpgo/config \
  SFTPGO_HTTPD__TEMPLATES_PATH=${SFTPGO_HTTPD__TEMPLATES_PATH:-/etc/sftpgo/web/templates} \
  SFTPGO_HTTPD__STATIC_FILES_PATH=${SFTPGO_HTTPD__STATIC_FILES_PATH:-/etc/sftpgo/web/static} \
  SFTPGO_HTTPD__BACKUPS_PATH=${SFTPGO_HTTPD__BACKUPS_PATH:-/etc/sftpgo/backups}

VOLUME [ "/data", "/etc/sftpgo/config", "/etc/sftpgo/backups" ]
EXPOSE 2022 8080 

ENTRYPOINT ["/bin/entrypoint.sh"]
CMD ["serve"]
