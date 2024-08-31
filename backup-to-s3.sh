#!/bin/bash

# Load environment variables
set -a

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/.env"

set +a

# Run before...
eval "$BACKUP_PRE_SCRIPT"

# Create the backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
# Generate a filename with date
FILENAME="backup-$(date +'%Y-%m-%d').zip"
BACKUP_FILE="${BACKUP_DIR}/${FILENAME}"

echo "Backup File '${BACKUP_FILE}'."

# Check if the backup file already exists locally
if [ ! -f "$BACKUP_FILE" ]; then
    # Create a zip file of the source directory while excluding specific folders
    zip_command="zip -r \"${BACKUP_FILE}\" \"${SOURCE_DIR}\""
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        zip_command+=" --exclude '$pattern'"
    done
    eval $zip_command
else
    echo "Backup file ${BACKUP_FILE} already exists, skipping zip creation."
fi

# Upload the backup to Linode bucket, overwrite if it exists
aws s3 cp "${BACKUP_FILE}" "s3://${BUCKET_NAME}/${FILENAME}" --region $REGION --endpoint-url $ENDPOINT --force

# Delete local backups older than retention period
find "$BACKUP_DIR" -type f -name 'backup-*.zip' -mtime +$RETENTION_DAYS -exec rm {} \;

# Delete backups older than retention period from Linode bucket
aws s3 ls "s3://${BUCKET_NAME}/" --region $REGION --endpoint-url $ENDPOINT | while read -r line;
do
    createDate=`echo $line|awk {'print $1" "$2'}`
    createDate=`date -d"$createDate" +%s`
    olderThan=`date -d"$RETENTION_DAYS days ago" +%s`
    if [[ $createDate -lt $olderThan ]]
    then 
        fileName=`echo $line|awk {'print $4'}`
        if [[ $fileName != "" ]]
        then
            aws s3 rm "s3://${BUCKET_NAME}/${fileName}" --region $REGION --endpoint-url $ENDPOINT
        fi
    fi
done