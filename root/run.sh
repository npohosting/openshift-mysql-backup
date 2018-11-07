#!/bin/bash

. /report_result.sh

# Set date
TIMESTAMP=$(date +%Y%m%d-%H%M)

# Cleanup before we start so we are 100% sure we aren't uploading something extra
rm -f /tmp/mysql-*.sql.gz

# Create and validate backup
if [ -z $MYSQL_USER ] ; then report_result no_mysql_user ; exit 1 ; fi
if [ -z $MYSQL_PASSWORD ] ; then report_result no_mysql_pass ; exit 1 ; fi
if [ -z $MYSQL_SERVICE ] ; then report_result no_mysql_svc ; exit 1 ; fi

DATABASE_LIST=$(echo "show databases" | /usr/bin/mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_SERVICE | /bin/egrep -v "^(Database|information_schema|performance_schema|mysql)")

# "Validate" Resultfile
if [ -z "$DATABASE_LIST" ] ; then
    report_result no_databases
    exit 1
fi

for database in $DATABASE_LIST;
do
  # Backup database
  mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_SERVICE $database --opt | /bin/gzip -c > /tmp/mysql-${database}-${TIMESTAMP}.sql.gz
  # Check if backup was created
  if [ ! -s "/tmp/mysql-${database}-${TIMESTAMP}.sql.gz" ] ; then
      report_result backup_file_empty $database
      exit 1
  fi
done


# Upload backup
if [ -z $STORAGE_METHOD ] ; then
    report_result no_storage_method
    exit 1
elif [ "$STORAGE_METHOD" == "rsync" ] ; then
    echo "Storage Method: rsync"

    # ssh needs a valid user to run.
    if ! whoami &> /dev/null; then
        if [ -w /etc/passwd ]; then
            echo "${USER_NAME:-default}:x:$(id -u):0:${USER_NAME:-default} user:${HOME}:/sbin/nologin" >> /etc/passwd
        fi
    fi

    if [ -z $RSYNC_TARGET_HOST ] ;          then report_result rsync_nohost ; exit 1 ; fi
    if [ -z $RSYNC_TARGET_LOCATION ] ;      then report_result rsync_no_target_location ; exit 1 ; fi
    if [ -z $RSYNC_IDENTITY_FILE ] ;        then report_result rsync_noident ; exit 1 ; fi
    if [ -z $RSYNC_USER ] ;                 then report_result rsync_nouser ; exit 1 ; fi

    rsync -rave "ssh  -i $RSYNC_IDENTITY_FILE -o StrictHostKeyChecking=no" /tmp/mysql-*.sql.gz ${RSYNC_USER}@${RSYNC_TARGET_HOST}:${RSYNC_TARGET_LOCATION}

    if [ "$?" == "0" ] ; then
        report_result job_success
        exit 0;
    fi

elif [ "$STORAGE_METHOD" == "s3" ] ; then
    echo "Storage Method: Amazon S3"

    # Verify environment variables
    if [ -z $AWS_S3_BUCKET ] ;              then report_result s3_nobucket ; exit 1 ; fi
    if [ -z $AWS_ACCESS_KEY_ID ] ;          then report_result s3_noaccess_key ; exit 1 ; fi
    if [ -z $AWS_SECRET_ACCESS_KEY ] ;      then report_result s3_nosecret_key ; exit 1 ; fi

    # Upload backup files
    S3_ERROR_COUNT=0
    for database_file in /tmp/mysql-*.sql.gz;
    do
      aws s3 cp $database_file s3://${AWS_S3_BUCKET}
      S3_ERROR_COUNT=$(( $? + S3_ERROR_COUNT ))
    done

    if [ "$S3_ERROR_COUNT" == "0" ] ; then
        report_result job_success
        exit 0;
    fi

fi

if [ "$DEBUG" == "true" ];
then
    echo "# STORAGE_METHOD: $STORAGE_METHOD"
    echo "# MYSQL_SERVICE: $MYSQL_SERVICE"

    while [ ! -f /tmp/stop ];
    do
        echo "-- Keepalive notice";
        sleep 60;
    done
fi
