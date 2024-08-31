#!/bin/bash

set -e

# Default MySQL path
DEFAULT_MYSQL_PATH="/usr/bin"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --mysql-host) MYSQL_HOST="$2"; shift ;;
    --mysql-user) MYSQL_USER="$2"; shift ;;
    --mysql-password) MYSQL_PASSWORD="$2"; shift ;;
    --mysql-port) MYSQL_PORT="$2"; shift ;;
    --ca-cert) CA_CERT="$2"; shift ;;
    --backup-dir) BACKUP_DIR="$2"; shift ;;
    --mysql-path) MYSQL_PATH="$2"; shift ;;
    --ignore-list) IFS=',' read -ra IGNORE_LIST <<< "$2"; shift ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# Set default values if not provided
MYSQL_PORT=${MYSQL_PORT:-3306}
BACKUP_DIR=${BACKUP_DIR:-"./backups"}
MYSQL_PATH=${MYSQL_PATH:-$DEFAULT_MYSQL_PATH}
IGNORE_LIST=${IGNORE_LIST:-("information_schema" "performance_schema" "mysql" "sys")}

# Validate required parameters
if [ -z "$MYSQL_HOST" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
  echo "Missing required parameters. Please check your input."
  exit 1
fi

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# Construct MySQL connection parameters
MYSQL_PARAMS="--host=$MYSQL_HOST --user=$MYSQL_USER --password=$MYSQL_PASSWORD --port=$MYSQL_PORT"

# Add CA certificate if provided
if [ ! -z "$CA_CERT" ]; then
  MYSQL_PARAMS="$MYSQL_PARAMS --ssl-ca=$CA_CERT --ssl-mode=VERIFY_CA"
fi

# Get list of databases
databases=$("$MYSQL_PATH/mysql" $MYSQL_PARAMS -e "SHOW DATABASES;" | grep -Ev "^(Database|information_schema|performance_schema|mysql|sys)$")

# Loop through each database and create a backup
for db in $databases; do
  # Check if the database is in the ignore list
  if [[ " ${IGNORE_LIST[@]} " =~ " ${db} " ]]; then
    echo "Skipping ignored database: $db"
    continue
  fi

  echo "Backing up database: $db"
  
  # Remove "tekprepp_" prefix from the filename
  cleaned_db_name=$(echo "$db" | sed 's/^tekprepp_//')
  
  backup_file="$BACKUP_DIR/${cleaned_db_name}.sql"
  "$MYSQL_PATH/mysqldump" $MYSQL_PARAMS --databases "$db" > "$backup_file"
done

echo "All database backups completed."