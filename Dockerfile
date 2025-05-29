FROM alpine:3.18

RUN apk add --no-cache \
    bash gzip mariadb-client curl mailx openrc borgbackup rsync openssh-client sshpass jq \
  && rm -rf /var/cache/apk/*

#COPY backup_mysql.sh /backup_mysql.sh
RUN chmod +x /backup_mysql.sh

# Crontab : backup tous les jours à 23h58
RUN echo "58 23 * * * /backup_mysql.sh >> /var/log/backup.log 2>&1" \
    > /etc/crontabs/root

CMD /backup_mysql.sh && crond -f
