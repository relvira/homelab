# {{ ansible_managed }}
#!/bin/bash

set -e

BACKUP_TYPE=${1:-incremental}
echo " "
echo "-------------------------------------"
echo "---  Starting backups at $(date)  ---"
echo "-------------------------------------"
echo " "

# Enable Nextcloud maintenance mode while backups
echo "+ Enabling Nextcloud maintenance mode for data and mysql backups..."
docker exec --user www-data nextcloud php occ maintenance:mode --on

echo "+ Sleeping 30 seconds until backups start..."
sleep 30

### Start Nextcloud data ###
echo "+ Running Duplicity for $NEXTCLOUD_DATA_SOURCE_PATH "
PASSPHRASE="$BACKUP_GPG_PASSPHRASE" duplicity --use-agent \
        --verbosity notice \
        --encrypt-key "$BACKUP_GPG_ENC_KEY" \
        --full-if-older-than 13D \
        --num-retries 3 \
        --archive-dir /root/.cache/duplicity \
        --volsize 200 \
      "$NEXTCLOUD_DATA_SOURCE_PATH" rsync://ret@anton.home.ret/"$NEXTCLOUD_DATA_DEST_PATH"

echo "+ Duplicity completed for $NEXTCLOUD_DATA_SOURCE_PATH "
### End Nextcloud data ###

### Start MySQL ###
echo "+ Running mysqldump, destination $MYSQL_SOURCE_PATH "
mysqldump --single-transaction \
          --routines --events --triggers --add-drop-table \
          --extended-insert -h 172.16.51.92 nextcloud_new \
          > "$MYSQL_SOURCE_PATH/db_$(date +"%H:%M_%d-%m-%Y").sql"
echo "+ mysqldump completed"

echo "+ Running Duplicity for $MYSQL_SOURCE_PATH "
PASSPHRASE="$BACKUP_GPG_PASSPHRASE" duplicity --use-agent \
        --verbosity notice \
        --encrypt-key "$BACKUP_GPG_ENC_KEY" \
        --full-if-older-than 13D \
        --num-retries 3 \
        --archive-dir /root/.cache/duplicity \
        --volsize 200 \
      "$MYSQL_SOURCE_PATH" rsync://ret@anton.home.ret/"$MYSQL_DEST_PATH"
echo "+ Duplicity completed for $MYSQL_SOURCE_PATH "
### End MySQL ###

# Disable Nextcloud maintenance mode, backups after this don't need it
echo "+ Disabling Nextcloud maintenance mode..."
docker exec --user www-data nextcloud php occ maintenance:mode --off

echo "+ Running Duplicity for $ETC_SOURCE_PATH "
PASSPHRASE="$BACKUP_GPG_PASSPHRASE" duplicity --use-agent \
        --verbosity notice \
        --encrypt-key "$BACKUP_GPG_ENC_KEY" \
        --full-if-older-than 13D \
        --num-retries 3 \
        --archive-dir /root/.cache/duplicity \
        --volsize 200 \
      "$ETC_SOURCE_PATH" rsync://ret@anton.home.ret/"$ETC_DEST_PATH"

### Start of www backup ###
echo "+ Running Duplicity for $WWW_SOURCE_PATH "
PASSPHRASE="$BACKUP_GPG_PASSPHRASE" duplicity --use-agent \
        --verbosity notice \
        --encrypt-key "$BACKUP_GPG_ENC_KEY" \
        --full-if-older-than 13D \
        --num-retries 3 \
        --archive-dir /root/.cache/duplicity \
        --volsize 200 \
      "$ETC_SOURCE_PATH" rsync://ret@anton.home.ret/"$WWW_DEST_PATH"

echo "+ Duplicity completed for $WWW_SOURCE_PATH "
### End of www backup ###

### Start of Plex library backup ###
echo "+ Running Duplicity for $PLEX_LIB_SOURCE_PATH "
PASSPHRASE="$BACKUP_GPG_PASSPHRASE" duplicity --use-agent \
        --verbosity notice \
        --encrypt-key "$BACKUP_GPG_ENC_KEY" \
        --full-if-older-than 13D \
        --num-retries 3 \
        --archive-dir /root/.cache/duplicity \
        --volsize 200 \
      "$ETC_SOURCE_PATH" rsync://ret@anton.home.ret/"$PLEX_LIB_DEST_PATH"

echo "+ Duplicity completed for $PLEX_LIB_SOURCE_PATH "
### End of Plex library backup ###

echo " "
echo "------------------------------------"
echo "---  Backup finished at $(date)  ---"
echo "------------------------------------"



