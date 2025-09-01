FROM apecloud/wal-g:postgres-1.2

LABEL maintainer="Umami Creative GmbH <hello@umami-creative.de>"
LABEL org.opencontainers.image.title="wal-g-ntfy-env"
LABEL org.opencontainers.image.description="WAL-G container with NTFY support and flexible ENV configuration."
LABEL org.opencontainers.image.source="https://github.com/Umami-Creative-GmbH/wal-g-ntfy-env"
LABEL org.opencontainers.image.licenses="MIT"

WORKDIR /app
USER root

RUN apk add --no-cache curl

COPY ./src/docker-entrypoint.sh ./src/do-base-backup.sh ./src/do-wal-push.sh ./src/do-push-test.sh /app/
RUN chmod +x docker-entrypoint.sh do-base-backup.sh do-wal-push.sh do-push-test.sh
RUN chown -R ${WAL_USER}:${WAL_GROUP} /app/
RUN ln -s /app/do-base-backup.sh /usr/local/bin/do-base-backup.sh
RUN ln -s /app/do-wal-push.sh /usr/local/bin/do-wal-push.sh
RUN ln -s /app/do-push-test.sh /usr/local/bin/do-push-test.sh

ARG WAL_USER=1000
ARG WAL_GROUP=1000
USER ${WAL_USER}:${WAL_GROUP}

ENTRYPOINT [ "/app/docker-entrypoint.sh" ]

CMD ["sleep", "infinity"]
