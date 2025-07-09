FROM apecloud/wal-g:postgres-1.1

WORKDIR /app
COPY .env.template ./src/docker-entrypoint.sh ./src/do-base-backup.sh ./src/do-wal-push.sh /app/
RUN chmod +x docker-entrypoint.sh do-base-backup.sh do-wal-push.sh
RUN ln -s /app/do-base-backup.sh /usr/local/bin/do-base-backup.sh
RUN ln -s /app/do-wal-push.sh /usr/local/bin/do-wal-push.sh

ENTRYPOINT [ "/app/docker-entrypoint.sh" ]
CMD ["sleep", "infinity"]
