#!/bin/bash

# Function for handling errors.

function report_result {
    # Define notifiers, these should be commented out in a
    # a later state.
    #NOTIFY_SLACK_ENABLED=true
    #NOTIFY_EMAIL_ENABLED=false
    #SLACK_API=https://hooks.slack.com/services/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

    # Result options
    case $1 in
        job_success)                    MESSAGE="Job status: \n name: *${NAME}* \n status: success \n Storage Method: ${STORAGE_METHOD}"  ;;
        # MySQL Error handling
        no_mysql_user)                  MESSAGE="Job *${NAME}*: Error: mysqldump: MySQL user not set." ;;
        no_mysql_pass)                  MESSAGE="Job *${NAME}*: Error: mysqldump: MySQL password not set." ;;
        no_mysql_svc)                   MESSAGE="Job *${NAME}*: Error: mysqldump: MySQL service or hostname not set." ;;
        backup_file_empty)              MESSAGE="Job *${NAME}*: Backup file is empty or not present for database '$2'." ;;
        no_databases)                   MESSAGE="Job *${NAME}*: No databases found to backup" ;;
        no_storage_method)              MESSAGE="Job *${NAME}*: Error: core: No storage method was defined." ;;
        # rsync error handling
        rsync_noident)                  MESSAGE="Job *${NAME}*: Error: rsync: No identity file was supplied for rsync." ;;
        rsync_nohost)                   MESSAGE="Job *${NAME}*: Error: rsync: No target host was supplied for rsync" ;;
        rsync_no_target_location)       MESSAGE="Job *${NAME}*: Error: rsync: No target location was supplied for rsync" ;;
        rsync_nouser)                   MESSAGE="Job *${NAME}*: Error: rsync: No ssh user was supplied for rsync" ;;
        # s3 error handling
        s3_nobucket)                    MESSAGE="Job *${NAME}*: Error: s3: No s3 bucket was supplied." ;;
        s3_noacccess_key)               MESSAGE="Job *${NAME}*: Error: s3: No s3 access key was supplied." ;;
        s3_nosecret_key)                MESSAGE="Job *${NAME}*: Error: s3: No s3 secret key was supplied." ;;
        *)                              MESSAGE="Job *${NAME}*: Something went wrong, but unfortunately I can't figure out what." ;;

    esac

    if [ -z $1 ] ; then
        echo "No parameters given. Terminating." ;
        exit 1
    fi

    if [ "$NOTIFY_SLACK_ENABLED" == "true" ] ; then
        echo "Notifying slack" >> /dev/stdout
        curl -X POST --data "payload={\"text\": \"${MESSAGE}\"}" ${SLACK_API} > /dev/null 2>&1
    fi

    if [ "$NOTIFY_EMAIL_ENABLED" == "true" ] ; then
        echo "Notifying email"
    fi

    if [ "$NOTIFY_STDOUT_ENABLED" == "true" ] ; then
        echo $MESSAGE >> /dev/stdout
    fi

}
