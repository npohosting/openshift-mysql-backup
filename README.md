# openshift-mysql-backup

This container can be used to schedule backups of mysql services within OpenShift.
Currently you will need either a remote server accessible by ssh or an Amazon S3 bucket to use this.

## General settings

The container has several options you can specify, most of them are required:

 - **NAME** \
 *Default: mb-cron* \
 Sets the name of the cronjob and service. Only required when you wish to run multiple cronjobs within the same project

 - **MYSQL_SERVICE** \
 *required* \
 Sets the name of the MySQL service you wish to backup, it also sets the name of the secret used by mysqldump to authenticate

 - **MYSQL_SECRET** \
 *required* \
 Sets the name of the MySQL secret where the username and password keys reside in.

 - **MYSQL_SECRET_USER_KEY** \
 *required* \
 Sets the name of the MySQL secret key name for the username.

 - **MYSQL_SECRET_PASS_KEY** \
 *required* \
 Sets the name of the MySQL secret key name for the password.

 - **SCHEDULE** \
 *Default: 0 3 \* \* \** \
 Sets the schedule for when to run the cronjob using the regular cron syntax.

## Backup using rsync

Before we can create the cronjobs, we need to create some secrets storing the identity file used by rsync:

``$ ssh-keygen -f $filename`` \
``$ oc create secret generic mysql-backup-ssh-key --from-file=$filename``

### Rsync extra settings

 - **RSYNC_TARGET_HOST** \
 *Required* \
 Sets the hostname where the backupfile needs to be send to.

 - **RSYNC_TARGET_LOCATION** \
 *Required* \
 Sets the filesystem location at the target host.

 - **RSYNC_USER** \
 *Required* \
 Sets the user used to login on to the target host.

 - **RSYNC_SECRET_NAME** \
 *Default mysql-backup-ssh-key* \
 Sets the name of the secret used earlier to import the SSH key.

 - **RSYNC_KEY_NAME** \
 *Default mysql_backup* \
 Sets the key name of the SSH key inside the secret, this is the same as `$filename` used when making the SSH key.

### Run the cronjob

``$ oc process -p MYSQL_SERVICE=mariadb -p RSYNC_TARGET_HOST=example.com -p RSYNC_TARGET_LOCATION=mysql-backup -p RSYNC_USER=username -p RSYNC_SECRET_NAME=mysql-backup-ssh-key -p RSYNC_KEY_NAME=mysql_backup -f https://raw.githubusercontent.com/npohosting/openshift-mysql-backup/master/cron-rsync.yaml | oc create -f -``

### Delete the cronjob
``$ oc process -f cron-rsync.yaml | oc detele -f -``

## Backup using Amazon S3

Before you can use this method, you will need an Amazon s3 bucket and an account which can upload to this bucket, specifically you will need the access keys. These need to be stored in a secret in OpenShift:

``$ oc create secret generic awsauth --from-literal=aws_access_key_id=$accesskey --from-literal=aws_secret_access_key=$secretkey``

### S3 extra settings

 - **AWS_SECRET** \
 *Default: awsauth* \
 Sets the name of the secret in Openshift created earlier.

 - **AWS_S3_BUCKET** \
 *Required* \
 Sets the bucket used for the upload.

### Run the cronjob

``$ oc process -p MYSQL_SERVICE=mariadb -p AWS_S3_BUCKET=my-bucket -f https://raw.githubusercontent.com/npohosting/openshift-mysql-backup/master/cron-s3.yaml | oc create -f -``

### Delete the cronjob
``$ oc process -f cron-s3.yaml | oc detele -f -``

## Use of notifications

This container has the ability to notify you on Slack about it's status. Before you can configure this you will need to create an App in Slack, using these instructions: https://api.slack.com/

When you want to use this notifier you will first need to remove the comments before the "SLACK_API" lines in the yaml file, then you will need to append the following options to ``oc process``:

``-p NOTIFY_SLACK_ENABLED=true -p SLACK_API=$your_api_url``
