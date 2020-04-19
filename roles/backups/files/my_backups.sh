# {{ ansible_managed }}
#!/bin/bash

set -e

BACKUP_TYPE=${1:-incremental}   

echo -ne "--- Starting backups at $(date) "

echo -e "--- Nextcloud maintenance mode ON "
docker exec --user www-data nextcloud php occ maintenance:mode --on

echo -e "--- Running Duplicity for $NEXTCLOUD_DATA_SOURCE_PATH "
PASSPHRASE="$BACKUP_GPG_PASSPHRASE" duplicity --use-agent \
        --verbosity notice \
        --encrypt-key "$BACKUP_GPG_ENC_KEY" \
        --full-if-older-than 13D \
        --num-retries 3 \
        --archive-dir /root/.cache/duplicity \
        --volsize 200 \
      "$NEXTCLOUD_DATA_SOURCE_PATH" rsync://ret@anton.home.ret/"$NEXTCLOUD_DATA_DEST_PATH"

echo -e "--- Duplicity completed for $NEXTCLOUD_DATA_SOURCE_PATH "

echo -e "--- Nextcloud maintenance mode OFF "
docker exec --user www-data nextcloud php occ maintenance:mode --off

echo -e "--- Running Duplicity for $ETC_SOURCE_PATH "
PASSPHRASE="$BACKUP_GPG_PASSPHRASE" duplicity --use-agent \
        --verbosity notice \
        --encrypt-key "$BACKUP_GPG_ENC_KEY" \
        --full-if-older-than 13D \
        --num-retries 3 \
        --archive-dir /root/.cache/duplicity \
        --volsize 200 \
      "$ETC_SOURCE_PATH" rsync://ret@anton.home.ret/"$ETC_DEST_PATH"

echo -e "--- Duplicity completed for $ETC_SOURCE_PATH "

echo -e "--- Running mysqldump, destination $MYSQL_SOURCE_PATH "
mysqldump --single-transaction \
          --routines --events --triggers --add-drop-table \
          --extended-insert -h 172.16.51.92 nextcloud_new \
          > "$MYSQL_SOURCE_PATH/db_$(date +"%H:%M_%d-%m-%Y").sql"
echo -e "--- mysqldump completed"

echo -e "--- Running Duplicity for $MYSQL_SOURCE_PATH "
PASSPHRASE="$BACKUP_GPG_PASSPHRASE" duplicity --use-agent \
        --verbosity notice \
        --encrypt-key "$BACKUP_GPG_ENC_KEY" \
        --full-if-older-than 13D \
        --num-retries 3 \
        --archive-dir /root/.cache/duplicity \
        --volsize 200 \
      "$MYSQL_SOURCE_PATH" rsync://ret@anton.home.ret/"$MYSQL_DEST_PATH"
echo -e "--- Duplicity completed for $MYSQL_SOURCE_PATH "


echo -ne "--- Backup finished at $(date) "



