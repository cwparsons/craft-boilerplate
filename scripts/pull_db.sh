#!/bin/bash

# Pull Database
#
# Pull remote database down from a remote and restore it to to local
#
# @author    nystudio107
# @copyright Copyright (c) 2017 nystudio107
# @link      https://nystudio107.com/
# @package   craft-scripts
# @since     1.2.2
# @license   MIT

# Get the directory of the currently executing script
DIR="$(dirname "${BASH_SOURCE[0]}")"

# Include files
INCLUDE_FILES=(
            "common/defaults.sh"
            ".env.sh"
            "common/common_env.sh"
            "common/common_db.sh"
            )
for INCLUDE_FILE in "${INCLUDE_FILES[@]}"
do
    if [ -f "${DIR}/${INCLUDE_FILE}" ]
    then
        source "${DIR}/${INCLUDE_FILE}"
    else
        echo "File ${DIR}/${INCLUDE_FILE} is missing, aborting."
        exit 1
    fi
done
if [ "${GLOBAL_DB_DRIVER}" == "mysql" ] ; then
    source "${DIR}/common/common_mysql.sh"
fi
# if [ "${GLOBAL_DB_DRIVER}" == "pgsql" ] ; then
#     source "${DIR}/common/common_pgsql.sh"
# fi

# Temporary db dump path (remote & local)
TMP_DB_PATH="/tmp/${REMOTE_DB_NAME}-db-dump-$(date '+%Y%m%d').sql"
BACKUP_DB_PATH="/tmp/${LOCAL_DB_NAME}-db-backup-$(date '+%Y%m%d').sql"

# Get the remote db dump
if [ "${GLOBAL_DB_DRIVER}" == "mysql" ] ; then
    if [ "${REMOTE_DB_USING_SSH}" == "yes" ] ; then
        # The database server requires ssh'ing in to connect to it
        ssh $REMOTE_SSH_LOGIN -p $REMOTE_SSH_PORT "$REMOTE_MYSQLDUMP_CMD $REMOTE_DB_CREDS $MYSQLDUMP_SCHEMA_ARGS > '$TMP_DB_PATH';"
        ssh $REMOTE_SSH_LOGIN -p $REMOTE_SSH_PORT "$REMOTE_MYSQLDUMP_CMD $REMOTE_DB_CREDS $REMOTE_IGNORED_DB_TABLES_STRING $MYSQLDUMP_DATA_ARGS >> '$TMP_DB_PATH' ;"
        ssh $REMOTE_SSH_LOGIN -p $REMOTE_SSH_PORT "gzip -f '$TMP_DB_PATH'"
    else
        # Connect to the database server directly
        $REMOTE_MYSQLDUMP_CMD $REMOTE_DB_CREDS $MYSQLDUMP_SCHEMA_ARGS > "${TMP_DB_PATH}"
        $REMOTE_MYSQLDUMP_CMD $REMOTE_DB_CREDS $REMOTE_IGNORED_DB_TABLES_STRING $MYSQLDUMP_DATA_ARGS >> "${TMP_DB_PATH}"
        gzip -f "${TMP_DB_PATH}"
    fi
fi
if [ "${GLOBAL_DB_DRIVER}" == "pgsql" ] ; then
    if [ "${REMOTE_DB_USING_SSH}" == "yes" ] ; then
        # The database server requires ssh'ing in to connect to it
        ssh $REMOTE_SSH_LOGIN -p $REMOTE_SSH_PORT "echo ${REMOTE_DB_HOST}:${REMOTE_DB_PORT}:${REMOTE_DB_NAME}:${REMOTE_DB_USER}:${REMOTE_DB_PASSWORD} > '$TMP_DB_DUMP_CREDS_PATH' ; chmod 600 '$TMP_DB_DUMP_CREDS_PATH' ; PGPASSFILE='$TMP_DB_DUMP_CREDS_PATH' $REMOTE_PG_DUMP_CMD $REMOTE_DB_CREDS $REMOTE_IGNORED_DB_TABLES_STRING $PG_DUMP_ARGS --schema='$REMOTE_DB_SCHEMA' --file='$TMP_DB_PATH' ; rm '$TMP_DB_DUMP_CREDS_PATH' ; gzip -f '$TMP_DB_PATH'"
    else
        # Connect to the database server directly
        echo ${REMOTE_DB_HOST}:${REMOTE_DB_PORT}:${REMOTE_DB_NAME}:${REMOTE_DB_USER}:${REMOTE_DB_PASSWORD} > "${TMP_DB_DUMP_CREDS_PATH}"
        chmod 600 "${TMP_DB_DUMP_CREDS_PATH}"
        PGPASSFILE="${TMP_DB_DUMP_CREDS_PATH}" $REMOTE_PG_DUMP_CMD $REMOTE_DB_CREDS $REMOTE_IGNORED_DB_TABLES_STRING $PG_DUMP_ARGS --schema="${REMOTE_DB_SCHEMA}" --file="${TMP_DB_PATH}"
        rm "${TMP_DB_DUMP_CREDS_PATH}"
        gzip -f "${TMP_DB_PATH}"
    fi
fi
# If the database dump was done remotely, copy it down locally
if [ "${REMOTE_DB_USING_SSH}" == "yes" ] ; then
    scp -P $REMOTE_SSH_PORT -- $REMOTE_SSH_LOGIN:"${TMP_DB_PATH}.gz" "${TMP_DB_PATH}.gz"
fi

# Backup the local db
if [ "${GLOBAL_DB_DRIVER}" == "mysql" ] ; then
    $LOCAL_MYSQLDUMP_CMD $LOCAL_DB_CREDS $MYSQLDUMP_SCHEMA_ARGS > "$BACKUP_DB_PATH"
    $LOCAL_MYSQLDUMP_CMD $LOCAL_DB_CREDS $LOCAL_IGNORED_DB_TABLES_STRING $MYSQLDUMP_DATA_ARGS >> "$BACKUP_DB_PATH"
fi
if [ "${GLOBAL_DB_DRIVER}" == "pgsql" ] ; then
    echo ${LOCAL_DB_HOST}:${LOCAL_DB_PORT}:${LOCAL_DB_NAME}:${LOCAL_DB_USER}:${LOCAL_DB_PASSWORD} > "${TMP_DB_DUMP_CREDS_PATH}"
    chmod 600 "${TMP_DB_DUMP_CREDS_PATH}"
    PGPASSFILE="${TMP_DB_DUMP_CREDS_PATH}" $LOCAL_PG_DUMP_CMD $LOCAL_DB_CREDS $LOCAL_IGNORED_DB_TABLES_STRING $PG_DUMP_ARGS --schema="${LOCAL_DB_SCHEMA}" --file="${BACKUP_DB_PATH}"
    rm "${TMP_DB_DUMP_CREDS_PATH}"
fi
gzip -f "$BACKUP_DB_PATH"
echo "*** Backed up local database to ${BACKUP_DB_PATH}.gz"

# Restore the local db from the remote db dump
if [ "${GLOBAL_DB_DRIVER}" == "mysql" ] ; then
    ${DB_ZCAT_CMD} "${TMP_DB_PATH}.gz" | $LOCAL_MYSQL_CMD $LOCAL_DB_CREDS
fi
if [ "${GLOBAL_DB_DRIVER}" == "pgsql" ] ; then
    echo ${LOCAL_DB_HOST}:${LOCAL_DB_PORT}:${LOCAL_DB_NAME}:${LOCAL_DB_USER}:${LOCAL_DB_PASSWORD} > "${TMP_DB_DUMP_CREDS_PATH}"
    chmod 600 "${TMP_DB_DUMP_CREDS_PATH}"
    ${DB_ZCAT_CMD} "${TMP_DB_PATH}.gz" | PGPASSFILE="${TMP_DB_DUMP_CREDS_PATH}" $LOCAL_PSQL_CMD $LOCAL_DB_CREDS --no-password >/dev/null
    rm "${TMP_DB_DUMP_CREDS_PATH}"
fi
echo "*** Restored local database from ${TMP_DB_PATH}.gz"

# Normal exit
exit 0
