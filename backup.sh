#!/bin/bash
set -e

export PATH=$PATH:/usr/bin:/usr/local/bin:/bin
# Get timestamp
: ${BACKUP_SUFFIX:=.$(date +"%Y-%m-%d-%H-%M-%S")}
readonly tarball=$BACKUP_NAME$BACKUP_SUFFIX.tar.gz

# Create a gzip compressed tarball with the volume(s)
# Ignore exitcode 1 (suppressed messages, when BACKUP_TAR_OPTION = --warning=no-file-changed)
set +e
tar czf $tarball $BACKUP_TAR_OPTION $PATHS_TO_BACKUP
exitcode=$?

if [ "$exitcode" != "1" ] && [ "$exitcode" != "0" ]; then
  exit $exitcode
fi
set -e

# Create bucket, if it doesn't already exist
BUCKET_EXIST=$(aws s3 ls | grep $S3_BUCKET_NAME | wc -l)
if [ $BUCKET_EXIST -eq 0 ];
then
  aws s3 mb s3://$S3_BUCKET_NAME
fi

# Upload the backup to S3 with timestamp
aws s3 --region $AWS_DEFAULT_REGION cp $tarball s3://$S3_BUCKET_NAME/$tarball

# Clean up
rm $tarball

# Send alive signal after successful backup
if [ -n "$ALIVE_URL" ]; then
  wget --no-verbose --user $ALIVE_USERNAME --password $ALIVE_PASSWORD $ALIVE_URL -O /dev/null
fi
