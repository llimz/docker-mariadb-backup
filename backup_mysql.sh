#!/bin/bash

#set -x
set -euo pipefail

DIR="/data/db-backup"
MYSQL_USER="root"
MYSQL=/usr/bin/mariadb
MYSQL_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQLDUMP=/usr/bin/mariadb-dump

# Retry parameters
MAX_RETRIES=10
RETRY_COUNT=0

# Loop to retry connection
while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    echo "Attempt $((RETRY_COUNT + 1)) to connect to MySQL..."
    if echo "SELECT 1;" | mysql --skip-ssl -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h"$MYSQL_HOST" -P$MYSQL_PORT &> /dev/null; then
        echo "Successfully connected to MySQL."
        break
    else
        echo "Connection failed. Retrying in 3 seconds..."
        ((RETRY_COUNT++))
        sleep 3
    fi
done

# Si toujours pas connecté après les tentatives
if [[ $RETRY_COUNT -eq $MAX_RETRIES ]]; then
    echo "Unable to connect to MySQL after $MAX_RETRIES attempts."
    exit 1
fi

##LOOPSTART
find $DIR/* -mtime +30 -exec rm {} \;

TIMESTAMP2="$(date '+%Y%m%d%H%M')"
TIMESTAMP="$(date +"%F")"
BACKUP="mysql_$TIMESTAMP"

databases=`$MYSQL --skip-ssl --user=$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -P$MYSQL_PORT -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`
for db in $databases; do
GZFILE="$DIR/mysql_${TIMESTAMP2}_$db.sql.gz"
GZONLYFILE="mysql_${TIMESTAMP2}_$db.sql.gz"
echo $GZFILE
$MYSQLDUMP $db --skip-ssl --user=$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -P$MYSQL_PORT --skip-extended-insert -l --single-transaction -K --add-drop-table=TRUE --tables -c --hex-blob --default-character-set=utf8 | gzip > $GZFILE
RC=( "${PIPESTATUS[@]}" )
if [ "${RC[0]}" -ne "0" ] || [ "${RC[1]}" -ne "0" ]; then
	echo "erreur"
	echo "Problème durant la sauvegarde de base de données $db sur $HOSTNAME" | mail -s "Problème backup base de données $db" alerthigh@edservices.fr
fi
done
##LOOPEND
