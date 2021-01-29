# {{ ansible_managed }}
#!/bin/bash

set -e

BACKUP_TYPE=${1:-incremental}
echo " "
echo "-------------------------------------"
echo "---  Starting backups at $(date)  ---"
echo "-------------------------------------"
echo " "

# Set GPG things
export GPG_TTY=$(tty)
GPG_OPTS='--pinentry-mode loopback'

# Enable Nextcloud maintenance mode while backups
echo "+ Enabling Nextcloud maintenance mode for data and mysql backups..."
docker exec --user www-data nextcloud php occ maintenance:mode --on

echo "+ Sleeping 5 seconds until backups start..."
sleep 5

### Start Nextcloud data ###
echo "+ Running Duplicity for $NEXTCLOUD_DATA_SOURCE_PATH"
duplicity \
        --verbosity notice \
        --full-if-older-than 13D \
        --num-retries 3 \
        --archive-dir /root/.cache/duplicity \
        --volsize 200 \
      "$NEXTCLOUD_DATA_SOURCE_PATH" rsync://ret@anton.mad.home/"$NEXTCLOUD_DATA_DEST_PATH"

# Cleanup nextcloud data backups
duplicity cleanup --force rsync://ret@anton.mad.home/"$NEXTCLOUD_DATA_DEST_PATH"
duplicity remove-all-inc-of-but-n-full 2 --force rsync://ret@anton.mad.home/"$NEXTCLOUD_DATA_DEST_PATH"
duplicity remove-all-but-n-full 2 --force rsync://ret@anton.mad.home/"$NEXTCLOUD_DATA_DEST_PATH"

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
duplicity \
        --verbosity notice \
        --full-if-older-than 13D \
        --num-retries 3 \
        --archive-dir /root/.cache/duplicity \
        --volsize 200 \
      "$MYSQL_SOURCE_PATH" rsync://ret@anton.mad.home/"$MYSQL_DEST_PATH"

# Cleanup MySQL backups
duplicity cleanup --force rsync://ret@anton.mad.home/"$MYSQL_DEST_PATH"
duplicity remove-all-inc-of-but-n-full 2 --force rsync://ret@anton.mad.home/"$MYSQL_DEST_PATH"
duplicity remove-all-but-n-full 2 --force rsync://ret@anton.mad.home/"$MYSQL_DEST_PATH"

echo "+ Duplicity completed for $MYSQL_SOURCE_PATH "
### End MySQL ###

# Disable Nextcloud maintenance mode, backups after this don't need it
echo "+ Disabling Nextcloud maintenance mode..."
docker exec --user www-data nextcloud php occ maintenance:mode --off

echo "+ Running Duplicity for $ETC_SOURCE_PATH "
duplicity \
        --verbosity notice \
        --full-if-older-than 13D \
        --num-retries 3 \
        --archive-dir /root/.cache/duplicity \
        --volsize 200 \
      "$ETC_SOURCE_PATH" rsync://ret@anton.mad.home/"$ETC_DEST_PATH"

# Cleanup /etc backups
duplicity cleanup --force rsync://ret@anton.mad.home/"$ETC_DEST_PATH"
duplicity remove-all-inc-of-but-n-full 2 --force rsync://ret@anton.mad.home/"$ETC_DEST_PATH"
duplicity remove-all-but-n-full 2 --force rsync://ret@anton.mad.home/"$ETC_DEST_PATH"

### Start of www backup ###
echo "+ Running Duplicity for $WWW_SOURCE_PATH "
duplicity \
        --verbosity notice \
        --full-if-older-than 13D \
        --num-retries 3 \
        --archive-dir /root/.cache/duplicity \
        --volsize 200 \
      "$ETC_SOURCE_PATH" rsync://ret@anton.mad.home/"$WWW_DEST_PATH"

# Cleanup www backups
duplicity cleanup --force rsync://ret@anton.mad.home/"$WWW_DEST_PATH"
duplicity remove-all-inc-of-but-n-full 2 --force rsync://ret@anton.mad.home/"$WWW_DEST_PATH"
duplicity remove-all-but-n-full 2 --force rsync://ret@anton.mad.home/"$WWW_DEST_PATH"

echo "+ Duplicity completed for $WWW_SOURCE_PATH "
### End of www backup ###

### Start of Plex library backup ###
echo "+ Running Duplicity for $PLEX_LIB_SOURCE_PATH "
duplicity \
        --verbosity notice \
        --full-if-older-than 13D \
        --num-retries 3 \
        --archive-dir /root/.cache/duplicity \
        --volsize 200 \
      "$ETC_SOURCE_PATH" rsync://ret@anton.mad.home/"$PLEX_LIB_DEST_PATH"

# Cleanup plex backups
duplicity cleanup --force rsync://ret@anton.mad.home/"$PLEX_LIB_DEST_PATH"
duplicity remove-all-inc-of-but-n-full 2 --force rsync://ret@anton.mad.home/"$PLEX_LIB_DEST_PATH"
duplicity remove-all-but-n-full 2 --force rsync://ret@anton.mad.home/"$PLEX_LIB_DEST_PATH"

echo "+ Duplicity completed for $PLEX_LIB_SOURCE_PATH "
### End of Plex library backup ###

echo " "
echo "------------------------------------"
echo "---  Backup finished at $(date)  ---"
echo "------------------------------------"



