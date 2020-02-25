FROM golang:1.13.5-alpine3.11 as builder

RUN apk add --no-cache git gcc g++ ca-certificates \
  && go get -d github.com/drakkan/sftpgo
WORKDIR /go/src/github.com/drakkan/sftpgo
# RUN git checkout `git rev-list --tags --max-count=1`
RUN go build -i -ldflags "-s -w -X github.com/drakkan/sftpgo/utils.commit=`git describe --always --dirty` -X github.com/drakkan/sftpgo/utils.date=`date -u +%FT%TZ`" -o /go/bin/sftpgo


FROM keinos/sqlite3 as migrations

WORKDIR /tmp

COPY --from=builder /go/src/github.com/drakkan/sftpgo/sql/sqlite /tmp/sql

RUN set -x \
  && sqlite3 /tmp/sftpgo.db < /tmp/sql/20190828.sql \
  && sqlite3 /tmp/sftpgo.db < /tmp/sql/20191112.sql \
  && sqlite3 /tmp/sftpgo.db < /tmp/sql/20191230.sql \
  && sqlite3 /tmp/sftpgo.db < /tmp/sql/20200116.sql \
  && sqlite3 /tmp/sftpgo.db < /tmp/sql/20200208.sql

FROM node:12.14-alpine3.11


WORKDIR /etc/sftpgo

# git and rsync are optional, uncomment the next line to add support for them if needed
#RUN apk add --no-cache git rsync

COPY --from=builder /go/bin/sftpgo /bin/
COPY --from=builder /go/src/github.com/drakkan/sftpgo/sftpgo.json /etc/sftpgo/sftpgo.json
COPY --from=builder /go/src/github.com/drakkan/sftpgo/templates /etc/sftpgo/web/templates
COPY --from=builder /go/src/github.com/drakkan/sftpgo/static /etc/sftpgo/web/static
COPY --from=migrations /tmp/sftpgo.db /etc/sftpgo/defaults/sftpgo.db
COPY docker-entrypoint.sh /bin/entrypoint.sh

RUN apk add --no-cache ca-certificates su-exec mysql-client \
  && chmod +x /bin/entrypoint.sh \
  && mkdir -p /data /etc/sftpgo/web /etc/sftpgo/backups /etc/sftpgo/config

ENV SFTPGO_LOG_FILE_PATH=${SFTPGO_LOG_FILE_PATH:-} \
  SFTPGO_CONFIG_DIR=/etc/sftpgo/config \
  SFTPGO_HTTPD__TEMPLATES_PATH=${SFTPGO_HTTPD__TEMPLATES_PATH:-/etc/sftpgo/web/templates} \
  SFTPGO_HTTPD__STATIC_FILES_PATH=${SFTPGO_HTTPD__STATIC_FILES_PATH:-/etc/sftpgo/web/static} \
  SFTPGO_HTTPD__BACKUPS_PATH=${SFTPGO_HTTPD__BACKUPS_PATH:-/etc/sftpgo/backups}

VOLUME [ "/data", "/etc/sftpgo/config", "/etc/sftpgo/backups" ]
EXPOSE 2022 8080 

ENTRYPOINT ["/bin/entrypoint.sh"]
CMD ["serve"]
